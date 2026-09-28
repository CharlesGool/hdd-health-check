---
name: project-design
description: Architecture, data model, and boundaries
metadata:
  version: "0.1.0"
  lang: en
---

# hdd-health-check — Design

This document describes the `v3.0.0` behavior, constraints and host-side state. This documentation describes `v3.0.0`. The `v3.0.0` source tag is the major-version boundary; no GitHub Release is created. The user reports running the earlier `v2.2.0` code on a real machine, without device, environment or coverage details. The revised scoring has only isolated mock validation, not real-HDD validation.

## Multi-language

**English** | [简体中文](zh_cn/DESIGN.md) | [繁體中文](zh_tw/DESIGN.md) | [繁體中文(香港)](zh_hk/DESIGN.md) | [हिन्दी](hi/DESIGN.md) | [Español](es/DESIGN.md) | [العربية](ar/DESIGN.md) | [Français](fr/DESIGN.md)

## Documentation

- Project overview: [README](../README.md)
- Design rationale: [DESIGN](DESIGN.md)
- Release history: [LOG](LOG.md)
- Third-party inventory: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Design Goals

- Provide quick HDD triage using SMART status and attributes, SMART error/self-test logs, mounts, kernel I/O errors and trends; present a heuristic score and actionable grade, not a failure probability.
- Offer independent drive-internal short/long SMART tests, sampled raw reads, resumable surface latency scans, optional targeted read-only `badblocks` rechecks, full read-only `badblocks`, and post-repair interface read stress checks.
- Support interactive selection, batch execution, persistent results, reuse and historical reports; optional transient systemd handoff for long-running tasks.
- Exclude data recovery, write-mode `badblocks`, secure erase and filesystem modification. The Bash checker remains one-shot; an optional local Web companion provides a persistent controller and scheduled quick checks. SSD/NVMe inclusion is optional but HDD scoring is not designed to diagnose those devices fully. The JSON snapshot supports the Web UI; deeper SAS scoring and NVMe-specific scoring are not implemented goals.

## Architecture

One Bash 4.3+ script enumerates disks with `lsblk`, chooses targets by menu or CLI, probes SMART access with `smartctl`, performs requested modules and generates a composite report. ATA SMART attributes and SAS/SCSI defect/error counters take separate scoring paths. The quick check includes mount and kernel-log evidence; speed, surface and interface checks use raw device reads. Results and per-device identity are persisted so later checks can reuse them. Interactive decisions can be transferred to a batch process via a constrained plan; a private lock prevents concurrent instances using the same state directory. A transient `systemd-run` unit handles detached jobs where available; `--status` and `--stop` consult the recorded instance.

A full batch records quick, short and long SMART tests and a completed read-only surface scan under one batch marker; HDDs additionally require speed sampling. SSD slow reads are recorded as performance variation without a health penalty, while actual read errors still deduct points. The batch repeats the quick SMART/ATA/CRC probe at the end to capture post-scan changes. Only completed, valid results from that batch qualify for a numeric composite score. Reuse, interruption, expiry, legacy state without a batch marker and later interface verification leave older records visible as historical/pending review and the overall grade partial/unknown. Merely generating a report does not update the quick-check comparison baseline. Interface verification records its own resolved/unresolved conclusion; it does not reattribute old errors or make an old batch current. An ATA total with no previous quick-check counter is unresolved (5-point deduction); this risk persists through subsequent checks and complete assessments, including older records lacking a risk field. An increased total deducts 20 points; stability alone neither proves resolution nor makes an old error new. Interface verification cannot independently attribute ATA errors to an interface repair. Isolated slow reads prompt performance retesting rather than a bad-sector diagnosis; repeated surface read failures still deduct 40 points. These are heuristic weights, not failure probabilities.

Quick-check power-on hours are displayed as usage information and never deduct health points on their own. Near-threshold ATA Pre-fail warnings require a nonzero raw error count as corroboration; historical threshold-only warnings without stored raw evidence become pending review without a deduction. New warning records include the SMART attribute and measured values. The Attention cards show the saved check cause directly. Web check and stop confirmations use an accessible in-page dialog, and the detail drawer uses the model as its heading with the device path beneath it.

For solid-state drives, speed-sample dips and average-speed changes between runs are performance observations and do not reduce the health score; actual read failures still do. Previously saved speed results are interpreted the same way without changing their state files. The Web disk list fits as many cards as the available CSS viewport width allows, up to four on wider screens; browser zoom changes that width and reflows the cards. The dashboard disk card scrolls to the list.

## Design Constraints

- Root access and physical SMART passthrough are needed for useful diagnosis. USB/RAID bridge detection is heuristic; failed passthrough is reported, not inferred healthy. SAS scoring is distinct and less exercised than ATA scoring. Temperature and thresholds depend on vendor data.
- All device surface and interface reads go to `/dev/null`; `badblocks` is invoked without destructive `-w`. **SMART enablement and self-tests can modify drive firmware state**; host paths are writable. Do not describe this as zero-side-effect execution.
- Explicit selection and `--include-ssd` are not proof a device is safe to load. An entire surface scan may take hours; operating-system writes by other processes continue. `--stop` does not terminate self-tests running inside the drive.
- State and plan data are parsed using allowed fields, not executed as shell code. Existing nonconforming state can be rejected. The host-state directory must not be a symlink; script checks directory and output-log symlinks, but callers must still protect their chosen paths.

## Data Design

`HDD_STATE_DIR` defaults to `/var/lib/hdd-health` (created with mode 700). It holds `settings.conf` (validity days, reuse policy, parallelism, scan chunk size, sampling parameters, SSD inclusion and automatic recheck policy), per-drive `.env` result files, SMART counter `history.csv`, repair logs, surface maps/checkpoints, report history and optional bad-block lists. A `.lock`, running-instance data and temporary background plans coordinate execution. Defaults include seven-day result validity, 64 MiB surface chunks and 24 × 128 MiB speed samples. The menu can save settings; `--rescan` overrides reuse. Clearing results can preserve counter/repair history or delete it; users can separately opt to delete old logs.

`HDD_LOG_DIR` defaults to `/var/log/disk-health`; `-l/--log` selects an individual log. Logs are plain text, may include device identifiers, host/kernel details and health data, and should be protected. A temporary work directory is created under `/run` or a temporary directory fallback. Do not assume a log is the only persistent output or that a state directory from a later version can be rolled back without its matching backup.

## External Interfaces

| Interface | Responsibility and effects |
| --- | --- |
| `lsblk`, `blockdev`, `/proc/mounts`, kernel log | Device enumeration, geometry, mount state and I/O errors; visibility depends on host permissions. |
| `smartctl` | Reads SMART diagnostics; can enable SMART or launch internal tests. Passthrough option auto-detection is heuristic. |
| `dd`, `badblocks` | Raw device reads for sampling, interface load, latency scan or read-only bad-block testing. Reads can stress degraded hardware. |
| `apt-get` | Offers missing-package installation; `-y` can accept it automatically. This changes host packages and may require network access. |
| `systemd-run` | Optional transient unit for detached tasks; `--stop` requests shutdown of the script's recorded process, not a hardware self-test. |

The checks themselves use no network API. The optional local Web service uses a loopback API in manual mode; the installer enables authenticated LAN access, while `--json` provides a structured read-only snapshot using the same composite-scoring function as the terminal report. The Web login issues a short-lived, HTTP-only session cookie. A private exact-IPv4 allowlist may bypass the password for ordinary operations. Any authenticated visitor, including one admitted by that list, may edit it and the disk sleep policy; changing the Web password requires the current password. The service reads SMART details on demand when a disk is opened; its raw SMART verdict does not replace the checker's composite score. `--no-install` disables package installation during unattended calls. Web architecture, schedule and security boundaries are described in [WEB](WEB.md). Scripts may use exit codes `0` healthy, `1` attention, `2` danger, `3` runtime failure; see [Guidance](../README.md#guidance).

Disk capacity uses a shared decimal/binary unit toggle and a separate detail button, leaving the row itself noninteractive. The disk snapshot includes physical capacity and mounted filesystem use from `lsblk`, deduplicating mounted filesystems by UUID, plus allocation from ZFS pools mapped to enumerated disks. These have different scopes when RAID or unmounted volumes exist. SSD detail derives host writes from NVMe Data Units Written or ATA Device Statistics with an explicit logical sector size, leaving vendor-specific counters unknown. The Web assessment endpoint filters the current server-side enumeration by SATA transport, rotation, SSD rotation, NVMe identity, or all disks. It validates a check module available for every selected disk and launches one detached `<module> --rescan` batch for the selected names, adding `--include-ssd` when needed. Device names are never accepted from the browser for this operation. Link data comes from smartctl's SATA version/current speed and the nearest available Linux sysfs SATA or NVMe PCIe link; absent fields remain unknown. The dashboard classifies media with rotation and transport separately and reads temperature in bounded background SMART probes that do not wake standby SATA disks by default. A private Web preference can opt into serially waking sleeping rotational disks once per page visit; standby is identified explicitly and shown as such instead of a missing temperature. The SMART detail shows device-reported form factor when present; transport alone cannot establish M.2 shape. SSD/NVMe can run quick, short and long SMART checks, a full read-only scan, and full assessment. The UI hides speed sampling, badblocks and interface recheck for a selection containing SSDs. An SSD full batch omits speed sampling; a complete batch creates a current heuristic score, with 100 when all required checks have no findings. This score is not a calibrated failure probability. A sleeping HDD can be woken individually from its SMART detail.

The detached launcher writes an accepted Web task receipt before asking systemd to start a transient unit. The worker updates it to running and records completed, stopped, or failed at exit. The Web status endpoint pairs an active receipt with the existing live process status and a bounded log tail. It removes terminal receipts and submitted receipts lacking a live process for over 15 seconds; per-disk results and host logs remain. A nonzero health result (`1` or `2`) remains a completed check rather than a launch failure. The UI uses the same warning result set for its attention count, filtered list, and detail causes. Each saved deduction records a reason; legacy records without one are shown as incomplete evidence instead of "no anomaly."

## Current SSD assessment and controls

A full SSD/NVMe assessment runs SMART quick, short and long self-tests plus a full read-only scan. It omits speed sampling; slow reads alone do not deduct health points. A completed clean batch scores 100, while SMART findings or actual read errors may reduce the heuristic score. When selected drives include SSDs, the Web UI offers only quick, short, long, read-only scan and full assessment. Capacity and host-write values switch between decimal and binary units by clicking the value. The SMART detail of a sleeping HDD offers a button to wake that drive alone.
