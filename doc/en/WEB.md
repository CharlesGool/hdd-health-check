---
name: project-web-en
description: Setup and operation of the local Web UI
metadata:
  version: "0.1.0"
  lang: "en"
---

# Local Web UI

The Web UI shows local disk results, recent SMART counter history, active jobs and a configurable quick-check schedule. It starts selected checks through the existing Bash tool. It does not turn partial or expired results into a current score. Only a complete, unexpired assessment batch can show a numeric score.

## Multi-language

**English** | [简体中文](../WEB.md) | [繁體中文 (台灣)](../zh-TW/WEB.md) | [繁體中文 (香港)](../zh-HK/WEB.md) | [हिन्दी](../hi/WEB.md) | [Español](../es/WEB.md) | [العربية](../ar/WEB.md) | [Français](../fr/WEB.md)

## Documentation

- Project overview: [README](README.md)

- Design rationale: [DESIGN](DESIGN.md)

- Release history: [LOG](LOG.md)

- Third-party notices: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

- Web UI guide: [WEB](WEB.md)

## Requirements

- Debian or Ubuntu with Python 3.10+, Node.js compatible with the checked-in Vite version, systemd and `systemd-run`.
- The existing checker dependencies: `smartmontools`, `util-linux`, `coreutils`, and optionally `e2fsprogs` for badblocks.
- Root access for the Web service. The Debian installer listens on IPv4 port 8765 and uses a Web login page and a session for its API. Use `http://<NAS-IP>:8765` on the same trusted LAN; do not forward this port to the Internet. LAN HTTP does not encrypt the password. An SSH local port forward remains available when encrypted transport is needed.

## Build and run

The current source contains Web UI code in `src/web/` and does not track the generated `dist/web/` build. The historical `v3.0.0` tag retains the former `web/` layout. On a Debian systemd host, install Node.js 22.12+ or 24+ and npm 10+, build the UI, then run the installer:

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/src/web
npm ci
npm run check
cd ../..
sudo bash deploy/install.sh
```

Repeat the build and installer steps after updating the checkout. Node.js is only needed while building; the installed service runs with Python and the checker dependencies. Review `deploy/install.sh` before running it as root.

For the prebuilt Debian NAS archive, extract it, enter its directory, and run:

```bash
sudo bash deploy/install.sh
```

The installer checks Debian, systemd, Python 3.10+, package files, and port 8765; installs missing packages through apt; copies the checker and built UI to `/root/apps/hdd-health-check`; and enables and checks `hdd-health-web.service`. It does not run a disk scan. On an update it keeps the previous application and unit as timestamped backups and attempts to restore them if startup fails. It does not modify existing disk state or logs. The prebuilt archive needs no Node.js or frontend build on the NAS.

After installation, open `http://<NAS-IP>:8765` from a computer on the same LAN. The Web login page asks for the generated password. Read it on the NAS with `sudo cat /root/apps/hdd-health-check/web-password`; the installer preserves it during updates. The password file is readable only by root. Security Settings asks for the administrator password before exposing the IP list or password-change form. After verification, enter and confirm a new password of 12–128 characters without repeating the old password during the five-minute verification window. The change invalidates existing Web sessions and requires a new login. If the page does not open, check `sudo systemctl status hdd-health-web.service` and whether the NAS firewall allows TCP 8765 from the LAN. The installer does not change firewall rules.

To check service status later, run `sudo systemctl status hdd-health-web.service`. The manual build and run steps below are for development or installations without the prebuilt archive.

From a trusted checkout:

```bash
cd src/web
npm ci
npm run check
cd ../..
sudo python3 src/web/server.py --port 8765
```

Open `http://127.0.0.1:8765`. This manual command keeps the service on loopback without a password. The UI build is served by the Python process; Node is not needed at runtime. Keep the source checkout and its `dist/web` together. `npm run dev` runs Vite on another local port and proxies `/api` to the Python service.

The Codex `site-preview` address serves static files only. It displays the layout and bundled update record, but cannot show disks or run checks because it has no `/api` backend. Open the Python service address above for live data. For encrypted access from another computer, forward the NAS loopback port with `ssh -L 8765:127.0.0.1:8765 user@nas-host`, then open `http://127.0.0.1:8765` on that computer. An installer deployment still shows its password login page through the tunnel.

Use the installer above for a persistent service: its systemd unit requires the password file created during installation. Before upgrading, back up `/var/lib/hdd-health` with the matching script version. The Web UI does not change the script's state migration policy.

To remove the Web service, run `sudo systemctl disable --now hdd-health-web.service`, remove its installed unit file, and run `sudo systemctl daemon-reload`. Review active transient checks before removing the checkout. Keep or remove the state and logs separately, according to the CLI uninstall guidance.

## Behavior and boundaries

- Automatic quick checks are disabled initially. Enabling them runs a check every 6–168 hours. The first run starts shortly after enabling, if no check has previously been scheduled. The schedule runs only rotational disks and starts through a transient systemd unit.
- Manual checks are selected per disk. The per-disk controls offer quick, SMART short/long, read-only surface scan and full checks for an SSD. Batch controls show the union of checks supported by selected disks. In mixed HDD/SSD selections, HDD-only checks run on eligible HDDs and skip SSDs; SSD-only selections offer only their supported checks. The full-device read-only check is labeled as such in the Web UI for both media types. The tool may still enable SMART or start drive-internal self-tests. A safe stop preserves surface progress but does not cancel a drive-internal self-test.
- `--no-install` prevents the Web service from approving package installation while launching jobs. Install missing dependencies separately. The Web service accepts only fixed check names and currently enumerated devices and does not use a shell for command construction.
- The private state directory remains `/var/lib/hdd-health` and logs remain `/var/log/disk-health` by default. `web-schedule.json`, `web-job.json`, completed task receipts in `web-job-history/`, and the private-address allowlist and enable switch in `web-access.json` are stored in the private state directory with restricted permissions. The browser sees health results and recent history through same-origin JSON endpoints.
- The installer deployment binds to all IPv4 interfaces but accepts only a Host matching the destination IP and port. It checks Origin and requires a password session or an allowlisted source IPv4 address for APIs. Static assets are public so the login page can load. Only a recently password-verified administrator session can read or edit the private-use IP allowlist and its enable switch; IP admission alone grants ordinary dashboard access. Logging out sets a browser cookie that suppresses automatic IP access until the user chooses IP login again. It has no TLS; anyone able to inspect LAN HTTP traffic can see the password. Use a trusted LAN or the SSH tunnel, and keep TCP 8765 closed to the Internet. The manual `python3 src/web/server.py` command remains loopback-only unless `--bind` and `--password-file` are supplied.
- Controls are available in the project's eight languages. Detailed check summaries and live task logs originate in the existing Chinese Bash checker and currently remain in Chinese regardless of the selected interface language.

## API

`GET /api/auth` reports the login state; `POST /api/auth/login`, `/api/auth/logout`, and `/api/auth/ip-login` manage sessions. `POST /api/auth/security-verify` checks the administrator password, rotates the session cookie and grants a fixed five-minute Security Settings permission. `POST /api/auth/change-password` requires that permission and matching new-password/confirmation fields; it atomically replaces the root-owned password file and invalidates existing sessions. `GET` and `POST /api/access` require the same short-lived permission; they read or edit the enable switch and exact RFC 1918 IPv4 or IPv6 unique-local addresses. `GET` and `POST /api/preferences` read and save whether sleeping disks should wake on page entry for any authenticated visitor. `POST /api/disks/wake-on-visit` starts the opted-in wake operation in the background for authenticated visitors. `GET /api/disks/<device>/smart` reads SMART details on demand without waking a standby HDD; authenticated `POST /api/disks/<device>/wake` wakes only a currently enumerated rotational disk. `GET /api/snapshot` returns the checker's structured disk snapshot. `GET /api/status` returns the active task display and a bounded live log tail. Completed, stopped, failed, and stale Web task receipts are removed from the active display when status is read; completed task receipts are archived separately. `GET /api/jobs/history` returns all archived Web task summaries and `GET /api/jobs/history/<id>` returns a bounded log tail when its host log remains available. Older tasks whose receipts were already deleted cannot be reconstructed reliably. `GET /api/history/<device>` returns up to 30 SMART counter rows for compatibility. `GET /api/history/samples` returns all enumerated drives’ SMART trend samples for the unified history page. Authenticated `DELETE /api/history/samples/<device>/<index>` removes one SMART sample from the drive history, changing the next comparison baseline if the last row is removed. `DELETE /api/jobs/history/<id>` removes a completed Web task receipt and its associated log. `POST /api/disks/<device>/sleep` requests ATA standby for an enumerated SATA HDD only and refuses while a check runs; normal OS I/O may wake it again. `GET` and `POST /api/schedule` manage the quick-check interval. `POST /api/jobs` starts a fixed check on an enumerated device; `POST /api/jobs/assess` accepts a `scope` of `sata`, `hdd`, `ssd`, `nvme`, or `all` and a `module` of `quick`, `short`, `long`, `speed`, `surface`, `badblocks`, `iface`, or `full`. It starts one batch on matching enumerated drives. `POST /api/jobs/stop` requests a safe stop. Unknown API routes return 404. The checker `--json` output is the scoring source; the Web service does not recalculate scores.

## Interface

The upper-left HDD Health brand links to the disk dashboard at `/disks`. A separate adjacent version link opens Changelog; untagged builds are labeled `test-<sha>` (with `-dirty` for modified trees), and `/api/build` reports the version embedded in that build. The browser tab uses the project favicon from `src/web/public/favicon.svg`, included in the production build.

The four overview cards open Disks (`/disks`), Attention (`/attention`), Tasks (`/tasks`), and Scheduled checks (`/schedule`). Dashboard, Changelog, and Settings appear in the top bar. Dashboard stays active across Disks, Attention, Tasks (including its history section), and Scheduled checks. Clicking Dashboard on those pages leaves the current page in place; clicking it from Settings or Changelog opens `/disks`. Changelog opens `/changelog`, while the upper-left brand remains a link to `/disks`. The Disks home page contains the disk list and one-click batch check; Attention contains only disks with warning or bad check results; Tasks shows the active Web job and recent completed-task history; Scheduled checks contains the interval controls. Settings contains language, eight accent colors and a light/dark mode switch, plus the disk sleep policy and a link to a dedicated Security Settings page. Accent and mode persist independently across reloads. That page challenges for the administrator password when the short-lived verification permission is absent, then shows the IP allowlist, its enable switch and the password-change form. The default policy keeps sleeping HDDs asleep. An administrator can instead choose to wake them one at a time when a visitor opens the page; the page does not wait for spin-up. An IP-admitted visitor may use the ordinary disk and sleep-policy controls, but must verify the administrator password to open protected Security Settings. Password change invalidates every Web session and requires a new login. The disk list uses the drive model as its title and labels its `/dev/` path separately. Disk capacity, home total/used capacity, detail capacity and SSD lifetime host writes switch between decimal and binary units when their value is clicked. Each disk row has a dedicated View details button; clicking the rest of the row does not open it. The snapshot and SMART APIs send only masked serial numbers, and the public snapshot omits the internal disk ID because it can contain a serial. The SMART detail tab fetches the full serial through a separate authenticated request after the user activates its show control, and clears it when hidden or when the detail view closes. It also shows capacity, bus-qualified media type, interface link, and a periodically refreshed temperature when available. Temperatures below 50 °C are green, 50–59 °C blue, and 60 °C or higher red; this display color does not itself deduct a score. Batch checks have separate disk-group and check-type selectors. Groups are all SATA drives, rotational drives, solid-state drives, NVMe drives, or all drives. The server selects currently enumerated devices and launches one detached `<module> --rescan` batch; it does not accept client-supplied device paths. Only the `full` module can establish a current composite score. A full assessment includes SMART quick and short/long tests and a complete read-only scan; HDDs also run speed sampling. It can take hours and add substantial load. SSD slow reads do not reduce health points. A clean completed SSD batch scores 100, while SMART findings or actual read errors can reduce that heuristic score; it is not a calibrated failure probability.

The dashboard sums the enumerated physical disk capacities and reports used bytes from mounted filesystems under those disks, deduplicated by filesystem UUID, plus allocation from ZFS pools whose leaf devices all map to listed disks. RAID and unmounted volumes can make the two figures incomparable. ZFS allocation includes pool metadata and may differ from dataset payload size. SSD SMART details show lifetime host writes from NVMe Data Units Written (512,000 bytes per unit) or ATA Device Statistics Logical Sectors Written when logical sector size is reported; vendor-specific SMART attribute 241 is not converted without a known unit. Opening a disk shows SMART information and project checks in separate tabs. The SMART tab displays a form factor only when the device reports one; NVMe or SATA transport does not establish whether a drive uses an M.2, U.2, or expansion-card form factor. Dashboard temperature probes run in the background with a bounded worker pool; non-NVMe probes use `smartctl -n standby` to avoid waking sleeping HDDs by default. Confirmed standby or sleep appears as “Sleeping” in the disk list and SMART detail, pending probes appear as “Reading,” and unsupported or failed readings remain unknown. A sleeping HDD also has an individual Wake button in SMART detail. The opt-in wake worker checks each enumerated rotational disk with `-n standby` before requesting SMART attributes without that skip option; it runs serially and refreshes temperature afterward. SATA version and negotiated speed come from smartctl when reported; Linux sysfs supplies a negotiated SATA speed or NVMe PCIe generation, lane width, and link rate when available. Missing fields remain unknown, particularly behind bridges. Click the power-on hours to switch between hours and approximate years/days/hours (365 days per year). The Changelog tab opens a separate `/changelog` page that renders the Changelog section as Markdown and supports direct page visits. SMART support and health fields can be unavailable for a sleeping disk, unsupported bridge, or failed `smartctl` query; an unknown result is not reported as healthy.

The Attention cards show the warning module and its recorded cause directly. Quick-check power-on hours are informational rather than health deductions. A legacy ATA near-threshold notice with no stored raw count is shown as pending review and no longer contributes points; new near-threshold findings require a nonzero raw error count and include the attribute, normalized value, threshold, and raw count. The disk detail uses the model as its heading and the `/dev/` path beneath it. Check-start and task-stop confirmations use a themed in-page dialog with keyboard cancellation.

The disk detail keeps the latest result for each check module, including distinct SMART short and long tests. This per-disk result differs from the Tasks page archive of Web job runs and from the 30-row SMART counter trend. The check tab shows each recorded cause and deduction; older records with a deduction but no saved cause explicitly ask for a new check. A background launch first shows as submitted, then running, completed, stopped, or failed. The Tasks page shows a short natural-language state summary by default and a button to reveal the bounded raw log. Its separate history section lists the latest 30 completed, stopped, or failed Web tasks and can show a detailed log tail. When a task ends, its active Web receipt disappears; its archived receipt, saved per-disk check results, and host log files remain. If a submitted task has no live process after 15 seconds, its stale Web receipt is removed. Exit codes 1 and 2 mean completed checks with attention or danger, while 3 indicates a runtime failure. Partial assessment coverage alone does not set a warning exit code.

## Current SSD assessment and controls

A full SSD/NVMe assessment runs SMART quick, short and long self-tests plus a full read-only scan. It omits speed sampling; slow reads alone do not deduct health points. A completed clean batch scores 100, while SMART findings or actual read errors may reduce the heuristic score. When selected drives include SSDs, the Web UI offers only quick, short, long, read-only scan and full assessment. Capacity and host-write values switch between decimal and binary units by clicking the value. The SMART detail of a sleeping HDD offers a button to wake that drive alone.
