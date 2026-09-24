# hdd-health-check — Design

This document describes the v2.2.0 integration's behavior, constraints and host-side state; this version has not been released or exercised on real HDDs in this integration.

## Multi-language

**English** | [简体中文](zh_cn/DESIGN.md) | [繁體中文](zh_tw/DESIGN.md) | [繁體中文（香港）](zh_hk/DESIGN.md) | [हिन्दी](hi/DESIGN.md) | [Español](es/DESIGN.md) | [العربية](ar/DESIGN.md) | [Français](fr/DESIGN.md)

## Documentation

- Project overview: [README](../README.md)
- Design rationale: [DESIGN](DESIGN.md)
- Release history: [LOG](LOG.md)
- Third-party inventory: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Design Goals

- Provide quick HDD triage using SMART status and attributes, SMART error/self-test logs, mounts, kernel I/O errors and trends; present a heuristic score and actionable grade, not a failure probability.
- Offer independent drive-internal short/long SMART tests, sampled raw reads, resumable surface latency scans, optional targeted read-only `badblocks` rechecks, full read-only `badblocks`, and post-repair interface read stress checks.
- Support interactive selection, batch execution, persistent results, reuse and historical reports; optional transient systemd handoff for long-running tasks.
- Exclude data recovery, write-mode `badblocks`, secure erase, filesystem modification, and a permanent monitoring daemon. SSD/NVMe inclusion is optional but HDD scoring is not designed to diagnose those devices fully. Structured JSON/CSV, deeper SAS scoring and NVMe-specific scoring are not implemented goals.

## Architecture

One Bash 4.3+ script enumerates disks with `lsblk`, chooses targets by menu or CLI, probes SMART access with `smartctl`, performs requested modules and generates a composite report. ATA SMART attributes and SAS/SCSI defect/error counters take separate scoring paths. The quick check includes mount and kernel-log evidence; speed, surface and interface checks use raw device reads. Results and per-device identity are persisted so later checks can reuse them. Interactive decisions can be transferred to a batch process via a constrained plan; a private lock prevents concurrent instances using the same state directory. A transient `systemd-run` unit handles detached jobs where available; `--status` and `--stop` consult the recorded instance.

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

No network API is used by the health checks themselves. Scripts and integrations may use process exit codes `0` healthy, `1` attention, `2` danger, `3` runtime failure; see [Guidance](../README.md#guidance). There is no stable structured output API.
