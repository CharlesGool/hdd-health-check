#!/usr/bin/env python3
"""Web controller for hdd-health-check."""

import argparse
import csv
import fcntl
import hmac
import ipaddress
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import socket
import stat
import subprocess
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from http.cookies import SimpleCookie
from urllib.parse import parse_qs, urlparse

SERVER_DIR = Path(__file__).resolve().parent
SOURCE_LAYOUT = SERVER_DIR.parent.name == "src"
ROOT = SERVER_DIR.parent.parent if SOURCE_LAYOUT else SERVER_DIR.parent
SCRIPT = ROOT / ("src/checker/hdd-health-check.sh" if SOURCE_LAYOUT else "hdd-health-check.sh")
ASSETS = ROOT / "dist/web" if SOURCE_LAYOUT else SERVER_DIR / "dist"
STATE = Path(os.environ.get("HDD_STATE_DIR", "/var/lib/hdd-health"))
LOG_DIR = Path(os.environ.get("HDD_LOG_DIR", "/var/log/disk-health"))
SCHEDULE = STATE / "web-schedule.json"
ACCESS = STATE / "web-access.json"
PREFERENCES = STATE / "web-preferences.json"
SYS_BLOCK = Path("/sys/class/block")
SYS_ATA_LINK = Path("/sys/class/ata_link")
MODULES = {"quick", "short", "long", "speed", "surface", "badblocks", "iface", "full"}
SSD_MODULES = {"quick", "short", "long", "surface", "full"}
ASSESS_SCOPES = {"sata", "hdd", "ssd", "nvme", "all"}
MIME = {".js": "text/javascript", ".css": "text/css", ".html": "text/html", ".svg": "image/svg+xml", ".woff2": "font/woff2", ".woff": "font/woff", ".txt": "text/plain", ".ico": "image/x-icon"}
gate = threading.Lock()
session_lock = threading.Lock()
sessions = {}
login_attempts = {}
SESSION_SECONDS = 12 * 3600
SECURITY_SECONDS = 5 * 60
PRIVATE_V4 = (ipaddress.ip_network("10.0.0.0/8"), ipaddress.ip_network("172.16.0.0/12"), ipaddress.ip_network("192.168.0.0/16"))
PRIVATE_V6 = ipaddress.ip_network("fc00::/7")
temperature_pool = ThreadPoolExecutor(max_workers=3)
temperature_lock = threading.Lock()
temperature_cache = {}
temperature_pending = set()
wake_lock = threading.Lock()
wake_in_progress = False
waking_disks = set()
snapshot_pool = ThreadPoolExecutor(max_workers=1)
snapshot_lock = threading.Lock()
snapshot_cache = None
snapshot_stamp = 0.0
snapshot_future = None



def verify_password_attempt(ip, supplied, expected, now=None):
    """Check and record an attempt atomically; retain only the active window."""
    now = time.time() if now is None else now
    with session_lock:
        for address, stamps in list(login_attempts.items()):
            recent = [stamp for stamp in stamps if now - stamp < 600]
            if recent:
                login_attempts[address] = recent
            else:
                login_attempts.pop(address, None)
        attempts = login_attempts.get(ip, [])
        if len(attempts) >= 10:
            return 429
        valid = isinstance(supplied, str) and hmac.compare_digest(
            supplied.encode("utf-8"), expected.encode("utf-8"))
        if valid:
            login_attempts.pop(ip, None)
            return 200
        # Bound memory without evicting live entries, which would reset their limits.
        if ip not in login_attempts and len(login_attempts) >= 4096:
            return 429
        login_attempts.setdefault(ip, []).append(now)
        return 401

def smart_temperature(raw):
    value = (raw.get("temperature") or {}).get("current") if isinstance(raw.get("temperature"), dict) else None
    nvme = raw.get("nvme_smart_health_information_log")
    if value is None and isinstance(nvme, dict):
        value = nvme.get("temperature")
    if value is None:
        ata = raw.get("ata_smart_attributes")
        table = ata.get("table", []) if isinstance(ata, dict) else []
        for item in table if isinstance(table, list) else []:
            if isinstance(item, dict) and item.get("id") in (190, 194):
                entry = item.get("raw")
                value = entry.get("value") if isinstance(entry, dict) else None
                break
    return value if isinstance(value, (int, float)) and not isinstance(value, bool) and -20 <= value <= 120 else None


def smart_standby(raw, returncode):
    if not returncode & 2 or not isinstance(raw, dict):
        return False
    ctl = raw.get("smartctl")
    messages = ctl.get("messages", []) if isinstance(ctl, dict) else []
    return isinstance(messages, list) and any(
        isinstance(item, dict) and re.search(r"\b(?:STANDBY|SLEEP)\b", str(item.get("string", "")), re.I)
        for item in messages)


def nvme_temperature_thresholds(raw):
    values = raw.get("nvme_composite_temperature_threshold")
    if not isinstance(values, dict):
        return {"temperatureWarning": None, "temperatureCritical": None}
    def valid(value):
        return value if isinstance(value, (int, float)) and not isinstance(value, bool) and 20 <= value <= 120 else None
    return {"temperatureWarning": valid(values.get("warning")),
            "temperatureCritical": valid(values.get("critical"))}


def probe_temperature(name, transport):
    try:
        args = ["smartctl", "-j", "-i", "-A"] if transport == "nvme" or name.startswith("nvme") else ["smartctl", "-j", "-A"]
        if transport != "nvme" and not name.startswith("nvme"):
            args += ["-n", "standby"]
        result = subprocess.run([*args, "/dev/" + name], capture_output=True, text=True, timeout=25, check=False)
        raw = json.loads(result.stdout)
        value = smart_temperature(raw) if isinstance(raw, dict) else None
        sleeping = smart_standby(raw, result.returncode)
        thresholds = nvme_temperature_thresholds(raw) if isinstance(raw, dict) else nvme_temperature_thresholds({})
    except (OSError, subprocess.TimeoutExpired, ValueError):
        value = None
        sleeping = False
        thresholds = nvme_temperature_thresholds({})
    with temperature_lock:
        temperature_cache[name] = (time.monotonic(), value, thresholds, sleeping)
        temperature_pending.discard(name)


def cached_temperature(name, transport):
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", name):
        return None
    now = time.monotonic()
    with temperature_lock:
        stamp, value, thresholds, sleeping = temperature_cache.get(name, (0, None, nvme_temperature_thresholds({}), False))
        if now - stamp >= 60 and name not in temperature_pending:
            temperature_pending.add(name)
            temperature_pool.submit(probe_temperature, name, str(transport or "").lower())
        if now - stamp < 180:
            return value, thresholds, "sleeping" if sleeping else "available" if value is not None else "unavailable"
        return None, nvme_temperature_thresholds({}), "checking" if name in temperature_pending else "unavailable"


def normalize_ip(value):
    if not isinstance(value, str) or len(value) > 45 or value != value.strip():
        raise ValueError("Use one private IPv4 or IPv6 address")
    try:
        address = ipaddress.ip_address(value)
    except ValueError as exc:
        raise ValueError("Use one private IPv4 or IPv6 address") from exc
    if isinstance(address, ipaddress.IPv6Address) and address.ipv4_mapped:
        address = address.ipv4_mapped
    allowed = (any(address in network for network in PRIVATE_V4)
               if isinstance(address, ipaddress.IPv4Address) else address in PRIVATE_V6)
    if not allowed:
        raise ValueError("Only private IPv4 or unique-local IPv6 addresses are allowed")
    return str(address)


def access_settings():
    try:
        if ACCESS.is_symlink():
            return {"enabled": False, "ips": []}
        value = json.loads(ACCESS.read_text())
        if not isinstance(value, dict):
            return {"enabled": False, "ips": []}
        entries = value.get("ips", [])
        if not isinstance(entries, list) or len(entries) > 32:
            return {"enabled": False, "ips": []}
        valid = set()
        for item in entries:
            try:
                valid.add(normalize_ip(item))
            except ValueError:
                continue
        enabled = value.get("enabled", bool(entries))
        return {"enabled": enabled if type(enabled) is bool else False, "ips": sorted(valid)}
    except (OSError, ValueError, TypeError):
        return {"enabled": False, "ips": []}


def access_ips():
    settings = access_settings()
    return settings["ips"] if settings["enabled"] else []


def save_access_settings(enabled, entries):
    if type(enabled) is not bool or not isinstance(entries, list) or len(entries) > 32:
        raise ValueError("An enabled switch and up to 32 IP addresses are required")
    clean = sorted({normalize_ip(item) for item in entries})
    STATE.mkdir(mode=0o700, parents=True, exist_ok=True)
    if ACCESS.is_symlink():
        raise ValueError("Access settings cannot be a symbolic link")
    temporary = ACCESS.with_name("web-access." + secrets.token_hex(8) + ".tmp")
    try:
        fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "w") as stream:
            json.dump({"enabled": enabled, "ips": clean}, stream)
        os.replace(temporary, ACCESS)
    finally:
        temporary.unlink(missing_ok=True)
    return {"enabled": enabled, "ips": clean}


def lsblk_details():
    result = subprocess.run(["lsblk", "-J", "-b", "-d", "-o", "NAME,TYPE,SIZE,MODEL,SERIAL,TRAN,ROTA,VENDOR"],
                            capture_output=True, text=True, timeout=10, check=False)
    if result.returncode:
        return {}
    try:
        rows = json.loads(result.stdout).get("blockdevices", [])
        if not isinstance(rows, list):
            return {}
        return {row["name"]: row for row in rows if isinstance(row, dict) and row.get("type") == "disk" and isinstance(row.get("name"), str)}
    except (ValueError, KeyError, TypeError):
        return {}


def storage_usage(disk_names, details):
    """Physical capacity and recognized filesystem/pool use; never probe sleeping media."""
    total = sum(row.get("size", 0) for name, row in details.items()
                if name in disk_names and isinstance(row.get("size"), int) and row["size"] > 0)
    try:
        result = subprocess.run(["lsblk", "-J", "-b", "-o", "NAME,TYPE,FSUSED,FSTYPE,UUID,MOUNTPOINTS"],
                                capture_output=True, text=True, timeout=10, check=False)
        roots = json.loads(result.stdout).get("blockdevices", []) if result.returncode == 0 else []
    except (OSError, ValueError, subprocess.TimeoutExpired):
        roots = []
    seen = set()
    used = 0
    known = False

    def visit(node):
        nonlocal used, known
        if not isinstance(node, dict):
            return
        mounts = node.get("mountpoints") or []
        if isinstance(mounts, list) and any(isinstance(m, str) and m.startswith("/") for m in mounts):
            key = node.get("uuid") or node.get("name")
            amount = node.get("fsused")
            if key and key not in seen and isinstance(amount, (str, int)) and str(amount).isdigit():
                seen.add(key)
                used += int(amount)
                known = True
        for child in node.get("children", []) if isinstance(node.get("children"), list) else []:
            visit(child)

    for root in roots if isinstance(roots, list) else []:
        if isinstance(root, dict) and root.get("name") in disk_names:
            visit(root)
    if any(isinstance(root, dict) and root.get("name") in disk_names and
           any(isinstance(child, dict) and child.get("fstype") == "zfs_member"
               for child in root.get("children", []) or []) for root in roots if isinstance(roots, list)):
        zfs_used = zpool_allocated(disk_names)
        if zfs_used is not None:
            used += zfs_used
            known = True
    return {"totalBytes": total, "usedBytes": used if known else None}


def zpool_allocated(disk_names):
    """Count pools only when every listed leaf maps to an enumerated disk."""
    if not shutil.which("zpool"):
        return None
    try:
        status = subprocess.run(["zpool", "status", "-P", "-L"], capture_output=True, text=True, timeout=10, check=False)
        listing = subprocess.run(["zpool", "list", "-H", "-p", "-o", "name,alloc"],
                                 capture_output=True, text=True, timeout=10, check=False)
        if status.returncode or listing.returncode:
            return None
    except (OSError, subprocess.TimeoutExpired):
        return None
    leaves = {}
    pool = None
    for line in status.stdout.splitlines():
        match = re.match(r"^\s*pool:\s*(\S+)", line)
        if match:
            pool = match.group(1)
            leaves.setdefault(pool, [])
        elif pool and (match := re.search(r"(/dev/\S+)", line)):
            leaves[pool].append(match.group(1))
    total = 0
    matched = False
    for line in listing.stdout.splitlines():
        fields = line.split()
        if len(fields) != 2 or not fields[1].isdigit():
            continue
        devices = leaves.get(fields[0], [])
        if devices and all(any(re.fullmatch(r"/dev/" + re.escape(name) + r"(?:p?\d+)?", path)
                               for name in disk_names if isinstance(name, str)) for path in devices):
            total += int(fields[1])
            matched = True
    return total if matched else None


def smart_io_bytes(raw, direction):
    """Return host I/O only when the counter's unit is established."""
    if direction not in ("read", "written"):
        return None, ""
    nvme = raw.get("nvme_smart_health_information_log")
    if isinstance(nvme, dict):
        units = nvme.get("data_units_" + direction)
        if isinstance(units, int) and not isinstance(units, bool) and units >= 0:
            return units * 512000, "nvme"
    stats = raw.get("ata_device_statistics")
    pages = stats.get("pages", []) if isinstance(stats, dict) else []
    sector_size = raw.get("logical_block_size")
    if not isinstance(sector_size, int) or not 512 <= sector_size <= 65536:
        return None, ""
    for page in pages if isinstance(pages, list) else []:
        if not isinstance(page, dict):
            continue
        for item in page.get("table", []) if isinstance(page.get("table"), list) else []:
            if isinstance(item, dict) and item.get("name") == ("Logical Sectors Read" if direction == "read" else "Logical Sectors Written"):
                value = item.get("value")
                flags = item.get("flags")
                if isinstance(value, int) and not isinstance(value, bool) and value >= 0 and (not isinstance(flags, dict) or flags.get("valid") is not False):
                    return value * sector_size, "ata-statistics"
    return None, ""


def smart_written_bytes(raw):
    return smart_io_bytes(raw, "written")


def masked_serial(value):
    serial = str(value or "")
    if not serial:
        return ""
    visible = 4 if len(serial) >= 8 else 2 if len(serial) >= 4 else 0
    return "•" * min(max(len(serial) - visible, 4), 12) + serial[-visible:] if visible else "•" * min(max(len(serial), 4), 12)


def sys_value(path):
    try:
        return path.read_text().strip()[:80]
    except OSError:
        return ""


def pcie_generation(speed):
    try:
        rate = float(speed.split()[0])
    except (ValueError, IndexError):
        return ""
    return {2.5: "1.0", 5.0: "2.0", 8.0: "3.0", 16.0: "4.0", 32.0: "5.0", 64.0: "6.0"}.get(rate, "")


def interface_link(name, transport):
    """Read the negotiated link from sysfs without waking a disk."""
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", name):
        return {}
    device = SYS_BLOCK / name / "device"
    if not device.exists():
        return {}
    resolved = device.resolve()
    if name.startswith("nvme") or transport == "nvme":
        for ancestor in (resolved, *resolved.parents):
            speed = sys_value(ancestor / "current_link_speed")
            width = sys_value(ancestor / "current_link_width")
            if speed and width:
                max_speed = sys_value(ancestor / "max_link_speed")
                return {"kind": "nvme", "version": pcie_generation(speed), "speed": speed,
                        "width": width, "maxSpeed": max_speed, "maxVersion": pcie_generation(max_speed),
                        "maxWidth": sys_value(ancestor / "max_link_width")}
    if transport == "sata" or any(re.fullmatch(r"ata\d+", part.name) for part in (resolved, *resolved.parents)):
        for ancestor in (resolved, *resolved.parents):
            match = re.fullmatch(r"ata(\d+)", ancestor.name)
            if match:
                link = SYS_ATA_LINK / ("link" + match.group(1))
                speed = sys_value(link / "sata_spd")
                maximum = sys_value(link / "hw_sata_spd_limit")
                if speed or maximum:
                    return {"kind": "sata", "speed": speed, "maxSpeed": maximum}
                break
    return {}


def smart_details(disk):
    args = ["smartctl", "-j", "-a"]
    if disk["rotation"] == "1":
        args += ["-n", "standby"]
    result = subprocess.run([*args, "/dev/" + disk["name"]], capture_output=True, text=True, timeout=25, check=False)
    try:
        raw = json.loads(result.stdout)
    except ValueError:
        return {"available": False, "error": (result.stderr.strip() or "SMART data unavailable")[:300], "temperatureState": "unavailable"}
    if not isinstance(raw, dict):
        return {"available": False, "error": "SMART data unavailable", "temperatureState": "unavailable"}
    sleeping = smart_standby(raw, result.returncode)
    nvme = raw.get("nvme_smart_health_information_log")
    power_on = raw.get("power_on_time")
    capacity = raw.get("user_capacity")
    health = raw.get("smart_status")
    sata_version = raw.get("sata_version")
    speeds = raw.get("interface_speed")
    nvme, power_on, capacity, health = [item if isinstance(item, dict) else {} for item in (nvme, power_on, capacity, health)]
    passed = health.get("passed")
    if passed is None and isinstance(nvme.get("critical_warning"), int):
        passed = nvme["critical_warning"] == 0
    attributes = []
    ata = raw.get("ata_smart_attributes")
    table = ata.get("table", []) if isinstance(ata, dict) else []
    for item in table if isinstance(table, list) else []:
        if isinstance(item, dict):
            value = item.get("raw", {})
            if isinstance(value, dict):
                value = value.get("string", value.get("value"))
            attributes.append({"key": str(item.get("name", item.get("id", ""))), "value": str(value if value is not None else "—")[:100],
                               "id": item.get("id"), "normalized": item.get("value"), "threshold": item.get("thresh")})
    if nvme:
        for key, value in nvme.items():
            if isinstance(value, (str, int, float, bool)):
                attributes.append({"key": key, "value": str(value)[:100]})
    ctl = raw.get("smartctl")
    messages = ctl.get("messages", []) if isinstance(ctl, dict) else []
    if not isinstance(messages, list):
        messages = []
    error = "; ".join(str(item.get("string", "")) for item in messages if isinstance(item, dict))[:300]
    link = interface_link(disk["name"], disk.get("transport", ""))
    if isinstance(sata_version, dict) and isinstance(sata_version.get("string"), str):
        link["sataVersion"] = sata_version["string"][:80]
        link.setdefault("kind", "sata")
    if isinstance(speeds, dict):
        for key, field in (("current", "speed"), ("max", "maxSpeed")):
            item = speeds.get(key)
            if isinstance(item, dict) and isinstance(item.get("string"), str):
                link[field] = item["string"][:80]
                link.setdefault("kind", "sata")
    form_factor = raw.get("form_factor")
    form_factor = form_factor.get("name", "") if isinstance(form_factor, dict) else ""
    temperature = smart_temperature(raw)
    written_bytes, written_source = smart_io_bytes(raw, "written")
    read_bytes, read_source = smart_io_bytes(raw, "read")
    return {"available": bool(attributes or passed is not None), "error": error if not attributes and passed is None else "",
            "model": str(raw.get("model_name") or disk.get("model") or ""),
            "serial": masked_serial(raw.get("serial_number")) or str(disk.get("serial") or ""),
            "protocol": str((raw.get("device") if isinstance(raw.get("device"), dict) else {}).get("protocol") or disk.get("transport") or ""),
            "capacity": capacity.get("bytes"), "passed": passed,
            "temperature": temperature, "temperatureState": "sleeping" if sleeping else "available" if temperature is not None else "unavailable",
            **nvme_temperature_thresholds(raw), "formFactor": str(form_factor)[:80],
            "powerOnHours": power_on.get("hours"), "writtenBytes": written_bytes,
            "writtenSource": written_source, "readBytes": read_bytes, "readSource": read_source,
            "attributes": attributes, "link": link}


def script(*args, timeout=30):
    return subprocess.run(["bash", str(SCRIPT), *args], capture_output=True, text=True, timeout=timeout, check=False)


def web_job(running=False):
    file = STATE / "web-job.json"
    try:
        if file.is_symlink() or file.stat().st_size > 4096:
            return None
        job = json.loads(file.read_text())
        if not isinstance(job, dict) or not re.fullmatch(r"[0-9a-f]{24}", str(job.get("id", ""))):
            return None
        if job.get("state") not in ("accepted", "running", "completed", "failed", "stopped"):
            return None
        if job["state"] in ("completed", "failed", "stopped"):
            archive = STATE / "web-job-history"
            archive.mkdir(mode=0o700, exist_ok=True)
            archived = archive / (job["id"] + ".json")
            if not archived.exists():
                archived.write_text(json.dumps(job))
                archived.chmod(0o600)
            file.unlink(missing_ok=True)
            return None
        started = job.get("started")
        if not isinstance(started, int) or started < 0:
            return None
        job["targets"] = str(job.get("targets", ""))[:300]
        job["module"] = str(job.get("module", ""))[:50]
        job["output"] = ""
        log = Path(str(job.get("log", "")))
        if log.is_file() and not log.is_symlink() and log.resolve().is_relative_to(LOG_DIR.resolve()):
            with log.open("rb") as stream:
                stream.seek(0, os.SEEK_END)
                stream.seek(max(0, stream.tell() - 10000))
                job["output"] = stream.read().decode(errors="replace")[-8000:]
        if not running and time.time() - started > 15:
            file.unlink(missing_ok=True)
            return None
        return job
    except (OSError, ValueError, TypeError):
        return None


def web_job_history():
    directory = STATE / "web-job-history"
    if not directory.is_dir() or directory.is_symlink():
        return []
    jobs = []
    for file in directory.glob("*.json"):
        try:
            if file.is_symlink() or not re.fullmatch(r"[0-9a-f]{24}\.json", file.name) or file.stat().st_size > 4096:
                continue
            job = json.loads(file.read_text())
            if job.get("id") + ".json" != file.name or job.get("state") not in ("completed", "failed", "stopped"):
                continue
            if not isinstance(job.get("finished"), int) or job["finished"] <= 0:
                continue
            jobs.append({"id": job["id"], "state": job["state"], "module": str(job.get("module", ""))[:50],
                         "targets": str(job.get("targets", ""))[:300], "started": job.get("started", 0),
                         "finished": job["finished"], "exitCode": job.get("exitCode", 3)})
        except (OSError, ValueError, TypeError, AttributeError):
            continue
    return sorted(jobs, key=lambda item: item["finished"], reverse=True)


def smart_history_samples():
    samples = []
    for disk in web_snapshot()["disks"]:
        name = disk["name"]
        file = STATE / disk["id"] / "history.csv"
        if not file.is_file() or file.is_symlink():
            continue
        with file.open(newline="") as stream:
            for index, row in enumerate(csv.reader(stream)):
                if len(row) in (8, 9) and all(part.isdigit() for part in row):
                    samples.append({"disk": name, "index": index, "values": [int(part) for part in row]})
    return sorted(samples, key=lambda item: item["values"][0], reverse=True)


def delete_smart_sample(name, index):
    if not re.fullmatch(r"[A-Za-z0-9_-]+", name) or not re.fullmatch(r"\d+", index):
        raise ValueError("Unknown history entry")
    disk = next((item for item in web_snapshot()["disks"] if item["name"] == name), None)
    if disk is None:
        raise ValueError("Unknown disk")
    file = STATE / disk["id"] / "history.csv"
    if not file.is_file() or file.is_symlink():
        raise ValueError("Unknown history entry")
    with (STATE / ".lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            raise RuntimeError("A disk check is running; try again later") from exc
        with file.open(newline="") as stream:
            rows = list(csv.reader(stream))
        number = int(index)
        if number >= len(rows) or len(rows[number]) not in (8, 9) or not all(part.isdigit() for part in rows[number]):
            raise ValueError("Unknown history entry")
        rows.pop(number)
        temp = file.with_name(file.name + ".web-tmp")
        try:
            with temp.open("w", newline="") as stream:
                csv.writer(stream).writerows(rows)
                stream.flush()
                os.fsync(stream.fileno())
            temp.chmod(0o600)
            os.replace(temp, file)
        finally:
            temp.unlink(missing_ok=True)


def delete_web_job(job_id):
    if not re.fullmatch(r"[0-9a-f]{24}", job_id):
        raise ValueError("Unknown job")
    record = STATE / "web-job-history" / (job_id + ".json")
    if not record.is_file() or record.is_symlink() or record.stat().st_size > 4096:
        raise ValueError("Unknown job")
    job = json.loads(record.read_text())
    if job.get("id") != job_id or job.get("state") not in ("completed", "failed", "stopped"):
        raise ValueError("Unknown job")
    log = Path(str(job.get("log", "")))
    record.unlink()
    if log.is_file() and not log.is_symlink() and log.resolve().is_relative_to(LOG_DIR.resolve()):
        log.unlink()


def snapshot():
    result = script("--json", timeout=60)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Snapshot failed")
    data = json.loads(result.stdout)
    details = lsblk_details()
    disk_names = {disk.get("name") for disk in data.get("disks", []) if isinstance(disk, dict)}
    data["storage"] = storage_usage(disk_names, details)
    for disk in data.get("disks", []):
        item = details.get(disk.get("name"), {})
        disk["serial"] = masked_serial(item.get("serial"))
        disk["vendor"] = str(item.get("vendor") or "")
        disk["bytes"] = item.get("size") if isinstance(item.get("size"), int) else None
        if not disk.get("transport"):
            disk["transport"] = str(item.get("tran") or "")
        disk["link"] = interface_link(disk.get("name"), disk.get("transport", ""))
        disk["temperature"], thresholds, disk["temperatureState"] = cached_temperature(disk.get("name"), disk.get("transport"))
        disk.update(thresholds)
    return data


def web_snapshot():
    """Serve the last disk list while a single background refresh reads hardware."""
    global snapshot_cache, snapshot_stamp, snapshot_future
    with snapshot_lock:
        if snapshot_future is not None and snapshot_future.done():
            try:
                snapshot_cache = snapshot_future.result()
                snapshot_stamp = time.monotonic()
            except Exception:
                pass  # The last successful disk list remains available.
            snapshot_future = None
        if snapshot_future is None and (snapshot_cache is None or time.monotonic() - snapshot_stamp >= 15):
            snapshot_future = snapshot_pool.submit(snapshot)
        cached = snapshot_cache if time.monotonic() - snapshot_stamp < 180 else None
        future = snapshot_future
    if cached is not None:
        return cached
    result = future.result(timeout=65)
    with snapshot_lock:
        snapshot_cache = result
        snapshot_stamp = time.monotonic()
        if snapshot_future is future:
            snapshot_future = None
    return result


def public_snapshot():
    data = web_snapshot()
    return {**data, "disks": [{key: value for key, value in disk.items() if key != "id"}
                              for disk in data.get("disks", [])]}


def config():
    try:
        value = json.loads(SCHEDULE.read_text())
        return {"enabled": value.get("enabled") is True, "hours": int(value.get("hours", 24)), "last": int(value.get("last", 0)), "attempt": int(value.get("attempt", 0)), "error": str(value.get("error", ""))}
    except (OSError, ValueError, TypeError):
        return {"enabled": False, "hours": 24, "last": 0, "attempt": 0, "error": ""}


def save_config(value):
    STATE.mkdir(mode=0o700, parents=True, exist_ok=True)
    temp = SCHEDULE.with_suffix(".tmp")
    fd = os.open(temp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as output:
        json.dump(value, output)
    os.replace(temp, SCHEDULE)


def preferences():
    try:
        if PREFERENCES.is_symlink():
            return {"wakeSleepingOnVisit": False}
        value = json.loads(PREFERENCES.read_text())
        return {"wakeSleepingOnVisit": isinstance(value, dict) and value.get("wakeSleepingOnVisit") is True}
    except (OSError, ValueError, TypeError):
        return {"wakeSleepingOnVisit": False}


def save_preferences(value):
    if type(value) is not bool:
        raise ValueError("Wake preference must be a boolean")
    STATE.mkdir(mode=0o700, parents=True, exist_ok=True)
    if PREFERENCES.is_symlink():
        raise ValueError("Preferences cannot be a symbolic link")
    temp = PREFERENCES.with_name(PREFERENCES.name + "." + secrets.token_hex(8) + ".tmp")
    try:
        fd = os.open(temp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as output:
            json.dump({"wakeSleepingOnVisit": value}, output)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temp, PREFERENCES)
    finally:
        temp.unlink(missing_ok=True)
    return {"wakeSleepingOnVisit": value}


def wake_sleeping_drives():
    global wake_in_progress
    try:
        for name, details in lsblk_details().items():
            if not preferences()["wakeSleepingOnVisit"]:
                break
            if not re.fullmatch(r"[A-Za-z0-9_-]+", name) or details.get("rota") not in (1, "1", True):
                continue
            try:
                wake_disk(name)
            except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired):
                continue
    finally:
        with wake_lock:
            wake_in_progress = False


def start_wake_on_visit():
    global wake_in_progress
    if not preferences()["wakeSleepingOnVisit"]:
        return {"started": False, "reason": "disabled"}
    with wake_lock:
        if wake_in_progress:
            return {"started": False, "reason": "in-progress"}
        wake_in_progress = True
    try:
        threading.Thread(target=wake_sleeping_drives, daemon=True).start()
    except RuntimeError:
        with wake_lock:
            wake_in_progress = False
        raise
    return {"started": True}


def wake_disk(name):
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", name):
        raise ValueError("Unknown disk")
    details = lsblk_details().get(name)
    if not details or details.get("rota") not in (1, "1", True):
        raise ValueError("Only an enumerated hard drive can be woken")
    with wake_lock:
        if name in waking_disks:
            return {"started": False, "reason": "in-progress"}
        waking_disks.add(name)
    try:
        device = "/dev/" + name
        checked = subprocess.run(["smartctl", "-j", "-A", "-n", "standby", device],
                                 capture_output=True, text=True, timeout=25, check=False)
        try:
            raw = json.loads(checked.stdout)
        except json.JSONDecodeError as exc:
            raise RuntimeError("Could not read drive power state") from exc
        sleeping = smart_standby(raw, checked.returncode)
        if checked.returncode & 2 and not sleeping:
            raise RuntimeError("Could not determine drive power state")
        if sleeping:
            result = subprocess.run(["smartctl", "-j", "-A", device],
                                    capture_output=True, text=True, timeout=90, check=False)
            if result.returncode & 2:
                raise RuntimeError("Could not wake the drive")
        probe_temperature(name, str(details.get("tran") or "").lower())
        return {"started": sleeping, "reason": "woken" if sleeping else "already-awake"}
    finally:
        with wake_lock:
            waking_disks.discard(name)


def sleep_disk(name):
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", name):
        raise ValueError("Unknown disk")
    details = lsblk_details().get(name)
    if not details or details.get("rota") not in (1, "1", True) or str(details.get("tran") or "").lower() != "sata":
        raise ValueError("Manual standby is available only for enumerated SATA hard drives")
    with wake_lock:
        if name in waking_disks:
            raise RuntimeError("Drive power operation already in progress")
        waking_disks.add(name)
    try:
        active = script("--status-brief", timeout=8)
        if active.returncode or "没有正在运行的实例" not in active.stdout:
            raise RuntimeError("Cannot put a drive in standby during a check")
        result = subprocess.run(["smartctl", "-s", "standby,now", "/dev/" + name],
                                capture_output=True, text=True, timeout=30, check=False)
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "Could not put the drive in standby")
        with temperature_lock:
            temperature_cache.pop(name, None)
        return {"requested": True}
    finally:
        with wake_lock:
            waking_disks.discard(name)


def start_job(disk, module):
    if module not in MODULES:
        raise ValueError("Unknown check type")
    disks = snapshot()["disks"]
    match = next((item for item in disks if item["name"] == disk), None)
    if match is None or not re.fullmatch(r"[A-Za-z0-9_-]+", disk):
        raise ValueError("Unknown disk")
    if match["rotation"] != "1" and module not in SSD_MODULES:
        raise ValueError("This check is limited to HDDs")
    job_id = secrets.token_hex(12)
    args = ["-d", disk, "-r", module, "--detach", "--no-install", "-y", "--web-job-id", job_id]
    if match["rotation"] != "1":
        args.append("--include-ssd")
    result = script(*args, timeout=30)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "Could not start check")
    return {"message": result.stdout.strip(), "jobId": job_id}


def assess_disks(scope, module):
    if scope not in ASSESS_SCOPES:
        raise ValueError("Unknown assessment scope")
    if module not in MODULES:
        raise ValueError("Unknown check type")
    disks = snapshot()["disks"]
    def included(disk):
        transport = str(disk.get("transport") or "").lower()
        if scope == "sata":
            return transport == "sata"
        if scope == "hdd":
            return disk.get("rotation") == "1"
        if scope == "ssd":
            return disk.get("rotation") == "0"
        if scope == "nvme":
            return transport == "nvme" or disk.get("name", "").startswith("nvme")
        return True
    selected = [disk for disk in disks if isinstance(disk.get("name"), str) and included(disk)
                and re.fullmatch(r"[A-Za-z0-9_-]+", disk["name"])]
    if not selected:
        raise ValueError("No disks in this assessment scope")
    eligible = [disk for disk in selected if disk.get("rotation") == "1" or module in SSD_MODULES]
    if not eligible:
        raise ValueError("No selected disks support this check")
    names = [disk["name"] for disk in eligible]
    skipped = [disk["name"] for disk in selected if disk not in eligible]
    job_id = secrets.token_hex(12)
    args = ["-d", ",".join(names), "-r", module, "--rescan", "--detach", "--no-install", "-y", "--web-job-id", job_id]
    if any(disk.get("rotation") != "1" for disk in eligible):
        args.append("--include-ssd")
    result = script(*args, timeout=30)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "Could not start assessment")
    return {"message": result.stdout.strip(), "disks": names, "skipped": skipped, "scope": scope, "module": module, "jobId": job_id}


def run_schedule():
    while True:
        time.sleep(30)
        with gate:
            setting = config()
            if not setting["enabled"] or time.time() - setting["last"] < setting["hours"] * 3600 or time.time() - setting["attempt"] < 300:
                continue
            setting["attempt"] = int(time.time())
            try:
                disks = [d["name"] for d in snapshot()["disks"] if d["rotation"] == "1"]
                if not disks:
                    setting["error"] = "No rotational disks found"
                else:
                    result = script("-d", ",".join(disks), "-r", "quick", "--detach", "--no-install", "-y", "--web-job-id", secrets.token_hex(12), timeout=30)
                    if result.returncode == 0:
                        setting["last"] = int(time.time())
                        setting["error"] = ""
                    else:
                        setting["error"] = (result.stderr.strip() or result.stdout.strip() or "Could not start scheduled check")[:500]
            except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as exc:
                setting["error"] = str(exc)[:500]
            try:
                save_config(setting)
            except OSError:
                pass


class Handler(BaseHTTPRequestHandler):
    server_version = "HDDHealthWeb/0.1"

    def send_json(self, status, data, cookies=()):
        body = json.dumps(data, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        for cookie in cookies:
            self.send_header("Set-Cookie", cookie)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def trusted(self):
        host = self.headers.get("Host", "")
        local_address = self.connection.getsockname()[0]
        address_host = "[%s]" % local_address if ":" in local_address else local_address
        allowed = {"%s:%d" % (address_host, self.server.server_port)}
        if local_address == "127.0.0.1":
            allowed.add("localhost:%d" % self.server.server_port)
        if host not in allowed:
            return False
        origin = self.headers.get("Origin")
        return not origin or origin in ("http://" + host,)

    def cookies(self):
        jar = SimpleCookie()
        try:
            jar.load(self.headers.get("Cookie", ""))
        except Exception:
            return {}
        return {key: value.value for key, value in jar.items()}

    def client_ip(self):
        try:
            return normalize_ip(self.client_address[0])
        except ValueError:
            return None

    def session(self):
        token = self.cookies().get("hdd_session", "")
        with session_lock:
            record = sessions.get(token)
            if record and record["expires"] <= time.time():
                sessions.pop(token, None)
                return None
            return record

    def auth_method(self):
        if self.server.password is None:
            return "local"
        if self.session():
            return "password"
        if self.cookies().get("hdd_logout") != "1" and self.client_ip() in access_ips():
            return "ip"
        return None

    def security_permitted(self):
        if self.server.password is None:
            return False
        record = self.session()
        return bool(record and record["security_until"] > time.time())

    def auth_state(self):
        method = self.auth_method()
        return {"authenticated": method is not None, "method": method,
                "ipAllowed": self.client_ip() in access_ips(),
                "canManageAccess": self.security_permitted()}

    def require_security(self):
        if not self.security_permitted():
            self.send_json(403, {"error": "Verify the administrator password to open Security Settings"})
            return False
        return True

    def permitted(self):
        if not self.trusted():
            self.send_json(403, {"error": "Untrusted origin"})
            return False
        if not self.auth_method():
            self.send_json(401, {"error": "Authentication required"})
            return False
        return True

    def do_GET(self):
        if not self.trusted():
            return self.send_json(403, {"error": "Untrusted origin"})
        path = urlparse(self.path).path
        if path == "/api/auth":
            return self.send_json(200, self.auth_state())
        if path.startswith("/api/") and not self.permitted():
            return
        try:
            if path == "/api/snapshot":
                return self.send_json(200, public_snapshot())
            if path == "/api/build":
                version = ASSETS / "version.json"
                return self.send_json(200, json.loads(version.read_text()) if version.is_file() else {"version": "unknown"})
            if path == "/api/schedule":
                return self.send_json(200, config())
            if path == "/api/preferences":
                return self.send_json(200, preferences())
            if path == "/api/access":
                if not self.require_security():
                    return
                return self.send_json(200, access_settings())
            if path == "/api/changelog":
                requested = parse_qs(urlparse(self.path).query).get("lang", ["en"])[0]
                lang = {"en": "en", "zh-CN": "", "zh-TW": "zh-TW", "zh-HK": "zh-HK", "hi": "hi", "es": "es", "ar": "ar", "fr": "fr"}.get(requested, "en")
                file = ROOT / "doc" / lang / "CHANGELOG.md"
                return self.send_json(200, {"text": file.read_text()[:40000]})
            if path == "/api/status":
                result = script("--status-brief", timeout=8)
                if result.returncode:
                    raise RuntimeError(result.stderr.strip() or "Status failed")
                output = result.stdout.strip()
                running = bool(output and "没有正在运行的实例" not in output)
                return self.send_json(200, {"running": running, "text": output, "job": web_job(running)})
            if path == "/api/jobs/history":
                return self.send_json(200, {"jobs": web_job_history()})
            if path == "/api/history/samples":
                return self.send_json(200, {"samples": smart_history_samples()})
            if path.startswith("/api/jobs/history/"):
                job_id = path.removeprefix("/api/jobs/history/")
                if not re.fullmatch(r"[0-9a-f]{24}", job_id):
                    return self.send_json(404, {"error": "Unknown job"})
                record = STATE / "web-job-history" / (job_id + ".json")
                if not record.is_file() or record.is_symlink() or record.stat().st_size > 4096:
                    return self.send_json(404, {"error": "Unknown job"})
                job = json.loads(record.read_text())
                if job.get("id") != job_id or job.get("state") not in ("completed", "failed", "stopped"):
                    return self.send_json(404, {"error": "Unknown job"})
                log = Path(str(job.get("log", "")))
                output = ""
                if log.is_file() and not log.is_symlink() and log.resolve().is_relative_to(LOG_DIR.resolve()):
                    with log.open("rb") as stream:
                        stream.seek(0, os.SEEK_END)
                        stream.seek(max(0, stream.tell() - 10000))
                        output = stream.read().decode(errors="replace")[-8000:]
                return self.send_json(200, {"output": output})
            if path.startswith("/api/history/"):
                name = path.split("/")[-1]
                disk = next((d for d in snapshot()["disks"] if d["name"] == name), None)
                if disk is None:
                    return self.send_json(404, {"error": "Unknown disk"})
                file = STATE / disk["id"] / "history.csv"
                rows = []
                if file.is_file() and not file.is_symlink():
                    with file.open(newline="") as stream:
                        for row in list(csv.reader(stream))[-30:]:
                            if len(row) in (8, 9) and all(part.isdigit() for part in row):
                                rows.append([int(part) for part in row])
                return self.send_json(200, {"rows": rows})
            if path.startswith("/api/disks/") and path.endswith("/smart"):
                name = path.split("/")[3]
                disk = next((d for d in snapshot()["disks"] if d["name"] == name), None)
                if disk is None or not re.fullmatch(r"[A-Za-z0-9_-]+", name):
                    return self.send_json(404, {"error": "Unknown disk"})
                return self.send_json(200, smart_details(disk))
            if path.startswith("/api/disks/") and path.endswith("/serial"):
                name = path.split("/")[3]
                if path != f"/api/disks/{name}/serial" or not re.fullmatch(r"[A-Za-z0-9_-]+", name):
                    return self.send_json(404, {"error": "Unknown disk"})
                details = lsblk_details()
                if name not in details:
                    return self.send_json(404, {"error": "Unknown disk"})
                return self.send_json(200, {"serial": str(details[name].get("serial") or "")})
            if path.startswith("/api/"):
                return self.send_json(404, {"error": "Unknown API route"})
            relative = "index.html" if path in ("/", "/disks", "/attention", "/tasks", "/schedule", "/settings", "/security", "/changelog") or re.fullmatch(r"/(?:disks|attention)/[A-Za-z0-9_-]+", path) else path.lstrip("/")
            file = (ASSETS / relative).resolve()
            if not file.is_relative_to(ASSETS.resolve()) or not file.is_file():
                return self.send_json(404, {"error": "Asset not found"})
            body = file.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", MIME.get(file.suffix, "application/octet-stream"))
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as exc:
            self.send_json(503, {"error": str(exc)})

    def do_POST(self):
        if not self.trusted():
            return self.send_json(403, {"error": "Untrusted origin"})
        path = urlparse(self.path).path
        if path not in ("/api/auth/login", "/api/auth/ip-login", "/api/auth/logout") and not self.permitted():
            return
        if self.server.password is not None and self.headers.get("X-HDD-CSRF") != "1":
            return self.send_json(403, {"error": "Request token required"})
        if self.headers.get("Content-Type", "").split(";")[0] != "application/json":
            return self.send_json(415, {"error": "JSON required"})
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length < 0 or length > 4096:
                return self.send_json(413, {"error": "Request too large"})
            body = json.loads(self.rfile.read(length))
            if not isinstance(body, dict):
                raise ValueError("JSON object required")
            if path.startswith("/api/disks/") and path.endswith("/wake"):
                name = path.split("/")[3]
                if path != f"/api/disks/{name}/wake":
                    return self.send_json(404, {"error": "Unknown API route"})
                return self.send_json(200, wake_disk(name))
            if path.startswith("/api/disks/") and path.endswith("/sleep"):
                name = path.split("/")[3]
                if path != f"/api/disks/{name}/sleep":
                    return self.send_json(404, {"error": "Unknown API route"})
                return self.send_json(200, sleep_disk(name))
            if path == "/api/auth/login":
                if self.server.password is None:
                    return self.send_json(400, {"error": "Password login is disabled"})
                ip = self.client_address[0]
                verdict = verify_password_attempt(ip, body.get("password"), self.server.password)
                if verdict == 429:
                    return self.send_json(429, {"error": "Too many login attempts; try again later"})
                if verdict != 200:
                    return self.send_json(401, {"error": "Incorrect password"})
                token = secrets.token_urlsafe(32)
                with session_lock:
                    sessions[token] = {"expires": time.time() + SESSION_SECONDS, "security_until": time.time() + SECURITY_SECONDS}
                    login_attempts.pop(ip, None)
                return self.send_json(200, {"authenticated": True, "method": "password", "ipAllowed": self.client_ip() in access_ips(), "canManageAccess": True},
                                      (f"hdd_session={token}; HttpOnly; SameSite=Strict; Path=/; Max-Age={SESSION_SECONDS}",
                                       "hdd_logout=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0"))
            if path == "/api/auth/logout":
                token = self.cookies().get("hdd_session", "")
                with session_lock:
                    sessions.pop(token, None)
                return self.send_json(200, {"authenticated": False, "ipAllowed": self.client_ip() in access_ips()},
                                      ("hdd_session=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0",
                                       f"hdd_logout=1; HttpOnly; SameSite=Strict; Path=/; Max-Age={SESSION_SECONDS}"))
            if path == "/api/auth/ip-login":
                if self.client_ip() not in access_ips():
                    return self.send_json(403, {"error": "IP access is not allowed"})
                return self.send_json(200, {"authenticated": True, "method": "ip", "ipAllowed": True, "canManageAccess": False},
                                      ("hdd_logout=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0",))
            if path == "/api/auth/security-verify":
                if self.server.password is None:
                    return self.send_json(403, {"error": "Password login is disabled"})
                ip = self.client_address[0]
                verdict = verify_password_attempt(ip, body.get("password"), self.server.password)
                if verdict == 429:
                    return self.send_json(429, {"error": "Too many login attempts; try again later"})
                if verdict != 200:
                    return self.send_json(401, {"error": "Incorrect administrator password"})
                old_token = self.cookies().get("hdd_session", "")
                token = secrets.token_urlsafe(32)
                with session_lock:
                    sessions.pop(old_token, None)
                    sessions[token] = {"expires": time.time() + SESSION_SECONDS,
                                       "security_until": time.time() + SECURITY_SECONDS}
                    login_attempts.pop(ip, None)
                return self.send_json(200, {"verified": True, "canManageAccess": True},
                                      (f"hdd_session={token}; HttpOnly; SameSite=Strict; Path=/; Max-Age={SESSION_SECONDS}",
                                       "hdd_logout=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0"))
            with gate:
                if path == "/api/auth/change-password":
                    if self.server.password_file is None or self.server.password is None:
                        return self.send_json(403, {"error": "Password login is disabled"})
                    if not self.require_security():
                        return
                    new, confirmation = body.get("newPassword"), body.get("confirmPassword")
                    if new != confirmation:
                        raise ValueError("New passwords do not match")
                    if not isinstance(new, str) or not 12 <= len(new) <= 128 or "\n" in new or "\r" in new or new != new.strip():
                        raise ValueError("New password must be 12–128 characters without leading or trailing whitespace")
                    if hmac.compare_digest(self.server.password.encode("utf-8"), new.encode("utf-8")):
                        raise ValueError("New password must differ from the current password")
                    file = self.server.password_file
                    info = file.lstat()
                    if not stat.S_ISREG(info.st_mode) or info.st_uid != os.geteuid() or info.st_mode & 0o077:
                        raise RuntimeError("Password file permissions are invalid")
                    temp = file.with_name(file.name + "." + secrets.token_hex(8) + ".tmp")
                    try:
                        fd = os.open(temp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
                        with os.fdopen(fd, "w", encoding="utf-8") as output:
                            output.write(new + "\n")
                            output.flush()
                            os.fsync(output.fileno())
                        os.replace(temp, file)
                    finally:
                        temp.unlink(missing_ok=True)
                    self.server.password = new
                    with session_lock:
                        sessions.clear()
                    return self.send_json(200, {"changed": True},
                                          ("hdd_session=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0",
                                           f"hdd_logout=1; HttpOnly; SameSite=Strict; Path=/; Max-Age={SESSION_SECONDS}"))
                if path == "/api/access":
                    if not self.require_security():
                        return
                    result = save_access_settings(body.get("enabled"), body.get("ips"))
                elif path == "/api/preferences":
                    result = save_preferences(body.get("wakeSleepingOnVisit"))
                elif path == "/api/disks/wake-on-visit":
                    result = start_wake_on_visit()
                elif path == "/api/jobs":
                    result = start_job(body.get("disk"), body.get("module"))
                elif path == "/api/jobs/assess":
                    result = assess_disks(body.get("scope"), body.get("module"))
                elif path == "/api/jobs/stop":
                    stopped = script("--stop", timeout=70)
                    result = {"message": stopped.stdout.strip()}
                elif path == "/api/schedule":
                    hours = body.get("hours")
                    if type(body.get("enabled")) is not bool or type(hours) is not int or not 6 <= hours <= 168:
                        raise ValueError("Schedule must use a 6–168 hour interval")
                    result = config()
                    result.update(enabled=body["enabled"], hours=hours, attempt=0, error="")
                    save_config(result)
                else:
                    return self.send_json(404, {"error": "Unknown API route"})
            self.send_json(200, result)
        except (ValueError, TypeError, json.JSONDecodeError) as exc:
            self.send_json(400, {"error": str(exc)})
        except (OSError, RuntimeError, subprocess.TimeoutExpired) as exc:
            self.send_json(503, {"error": str(exc)})

    def do_DELETE(self):
        if not self.trusted():
            return self.send_json(403, {"error": "Untrusted origin"})
        if not self.permitted():
            return
        if self.server.password is not None and self.headers.get("X-HDD-CSRF") != "1":
            return self.send_json(403, {"error": "Request token required"})
        path = urlparse(self.path).path
        try:
            with gate:
                if path.startswith("/api/jobs/history/"):
                    delete_web_job(path.removeprefix("/api/jobs/history/"))
                elif path.startswith("/api/history/samples/"):
                    match = re.fullmatch(r"/api/history/samples/([A-Za-z0-9_-]+)/(\d+)", path)
                    if not match:
                        return self.send_json(404, {"error": "Unknown history entry"})
                    delete_smart_sample(*match.groups())
                else:
                    return self.send_json(404, {"error": "Unknown API route"})
            return self.send_json(200, {"deleted": True})
        except (ValueError, TypeError, json.JSONDecodeError) as exc:
            self.send_json(400, {"error": str(exc)})
        except (OSError, RuntimeError) as exc:
            self.send_json(503, {"error": str(exc)})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--bind", default="127.0.0.1", help="IPv4 or IPv6 address to listen on")
    parser.add_argument("--password-file", type=Path, help="root-owned file containing the Web password")
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error("Run as root to read SMART and private state")
    if not ASSETS.is_dir():
        parser.error("Build the Web UI first: cd src/web && npm ci && npm run build")
    try:
        bind_address = ipaddress.ip_address(args.bind)
    except ValueError:
        parser.error("--bind must be an IPv4 or IPv6 address")
    if args.password_file is None and not bind_address.is_loopback:
        parser.error("A password file is required for non-loopback access")
    password = None
    if args.password_file is not None:
        try:
            info = args.password_file.lstat()
            if not stat.S_ISREG(info.st_mode) or info.st_uid != 0 or info.st_mode & 0o077:
                parser.error("Password file must be a root-owned regular file with mode 600")
            password = args.password_file.read_text(encoding="utf-8").strip()
            if not 12 <= len(password) <= 128:
                parser.error("Password must have 12–128 characters")
        except OSError as exc:
            parser.error("Cannot read password file: %s" % exc)
    threading.Thread(target=run_schedule, daemon=True).start()
    server_class = ThreadingHTTPServer
    if bind_address.version == 6:
        class IPv6Server(ThreadingHTTPServer):
            address_family = socket.AF_INET6
        server_class = IPv6Server
    server = server_class((str(bind_address), args.port), Handler)
    server.password = password
    server.password_file = args.password_file
    print("HDD Health Web listening on %s:%d" % (bind_address, args.port), flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
