---
name: project-overview
description: Project overview and usage
metadata:
  version: "0.1.0"
  lang: en
---

# hdd-health-check

This root-run Bash tool evaluates HDD health on Debian/Ubuntu through SMART data and read-only disk checks. Current `main` contains the v3.0.0 core code and the optional local Web UI. The `v3.0.0` source tag is available on GitHub; no GitHub Release is created. The Web service has been checked on a Debian NAS with real disk inventory, but a complete assessment on real HDDs remains unverified.

## Multi-language

**English** | [简体中文](doc/zh-CN/README.md) | [繁體中文 (台灣)](doc/zh-TW/README.md) | [繁體中文 (香港)](doc/zh-HK/README.md) | [हिन्दी](doc/hi/README.md) | [Español](doc/es/README.md) | [العربية](doc/ar/README.md) | [Français](doc/fr/README.md)

## Documentation

- Project overview: [README](README.md)

- Design rationale: [DESIGN](doc/DESIGN.md)

- Release history: [LOG](doc/LOG.md)

- Third-party notices: [THIRD_PARTY_NOTICES](doc/THIRD_PARTY_NOTICES.md)

## Introduction

The interactive menu or batch CLI selects drives, performs a quick SMART, mount and kernel-log assessment, and reports a heuristic 0–100 score and risk grade. Other modules offer SMART short/long self-tests, sampled read-speed profiling, resumable full-disk read-latency scanning with optional targeted `badblocks` recheck, full-disk read-only `badblocks`, and post-repair interface read testing. For HDDs, a full assessment runs quick, short, long, speed and full read-only scan checks; for SSDs, it runs quick, short, long and a full read-only surface scan without speed sampling; it does not include the separate full-disk `badblocks` or interface module. Results can be reused, compared against SMART counter history, and assembled into a report. See [known issues](doc/LOG.md#bugs) and [goals](doc/DESIGN.md#design-goals).

A complete assessment repeats the quick SMART/ATA/CRC check after the long reads. A 0–100 composite score is shown only when the required quick, short, long and completed surface checks (and speed sampling for HDDs) belong to the same unexpired assessment batch. Reused, interrupted, expired and older-format results remain visible as historical evidence, but yield a partial/unknown grade instead of a current score; reviewing a report does not refresh the baseline. After interface repair, use the separate interface verification and repeat the full assessment to establish a new score. A resolved interface check does not erase historical errors. An ATA error count with no prior comparison is an unresolved unknown cause (5-point deduction), retained across repeated checks and full assessments; a stable counter alone does not prove resolution. Newly increased ATA errors deduct 20 points; unchanged historical counts do not count as new errors. Existing interface verification does not attribute ATA errors to an interface repair. Sparse slow surface reads are performance prompts to retest, not proof of bad sectors; confirmed read errors remain medium-risk evidence (40-point surface deduction). Power-on hours alone do not deduct health points, and an ATA near-threshold warning requires a nonzero raw error count; old threshold-only notices without raw evidence are marked for review. Back up important data before testing a suspect drive.

**Read-only refers to target disk data, not the host.** The program writes logs, settings, progress and history on the host; it can enable SMART, launch drive-internal self-tests, read whole devices under sustained load, install packages after confirmation, and start transient systemd units. Do not use it as a substitute for backups. No destructive write-mode surface scan, erase or filesystem write is implemented.

## Requirements

- Minimum: root, Bash 4.3+, Linux block-device utilities (`lsblk`, `blockdev`), `smartctl` (`smartmontools`), `dd` (`coreutils`) and `flock`; Debian/Ubuntu is the intended platform. Other distributions receive a warning; automatic dependency installation uses `apt-get`.
- Recommended: `badblocks` (`e2fsprogs`) for surface checks; systemd with `systemd-run` for detached tasks. Missing packages may trigger an interactive `apt-get update`/install offer (or automatic confirmation with `-y`). Check dependencies before unattended runs. No pinned third-party code is vendored and no dependency lock file applies.
- Real HDD and SMART access are needed to assess actual health. SSD/NVMe can be included explicitly. A completed SSD full assessment scores 100 when SMART checks, self-tests and the full read-only scan report no issues; actual read errors and SMART findings lower that heuristic score. It is not a calibrated failure probability.

## Install

### Quick Install

From a trusted checkout, run `sudo bash ./hdd-health-check.sh --help` to inspect options without starting a scan. Do not pipe an unreviewed remote script into a root shell.

### Normal Install

The following checkout uses the current source branch. The repository-root command remains a thin entry point; its implementation is in `src/checker/`.

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
bash -n hdd-health-check.sh src/checker/hdd-health-check.sh
sudo bash ./hdd-health-check.sh --help
```

Review and install the required OS packages yourself before scanning to avoid the script's package-install prompt. To upgrade an existing checkout, back up any desired host logs and `${HDD_STATE_DIR:-/var/lib/hdd-health}` first; replace the script from a reviewed checkout, keep that state directory for history/resume, then review `--help` and run the chosen checks. v2.2 state parsing accepts only known data fields; nonconforming prior v2.2 state may be rejected. A rollback requires restoring the previous script **and its matching state backup**; do not assume newer state is backwards compatible. No v1 CLI behavior or state migration is promised.

### Web UI from current source

The current source does not track generated assets in `dist/web`. On a Debian systemd host, install Node.js 20.19+ or 22.12+ and npm, build the UI, then run the installer:

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/src/web
npm ci
npm run build
cd ../..
sudo bash deploy/install.sh
```

The installer checks and installs missing Debian runtime packages, starts the password-protected service on LAN port 8765, and does not start a disk scan. Read the generated password with `sudo cat /root/apps/hdd-health-check/web-password`. Node.js is only needed to build the UI. See [WEB](doc/WEB.md) for updates, security boundaries, and rollback.

## Guidance

Run only on drives you are authorized to examine; a sustained read scan can add significant load. The commands below are **examples, not validation instructions for this environment**:

```bash
sudo bash ./hdd-health-check.sh                 # terminal menu
sudo bash ./hdd-health-check.sh -a              # all rotational disks, default quick scan
sudo bash ./hdd-health-check.sh -d sdb -r quick,short
sudo bash ./hdd-health-check.sh -d sdb -r full -y
sudo bash ./hdd-health-check.sh -d sdb -r iface --duration 30 --detach
sudo bash ./hdd-health-check.sh --status
sudo bash ./hdd-health-check.sh --stop
```

`-d/--disk` accepts comma-separated device names; `-a/--all` selects mechanical disks and `--include-ssd` extends selection. `-r/--run` accepts `quick,short,long,speed,surface,badblocks,iface,full`; default is `quick`, and batch mode always adds a report. `--duration` sets interface-test minutes (default 15). `--rescan` restarts instead of reusing/resuming prior results; by default batch quick is repeated, other results are reused while valid, and interrupted surface scans resume. `-q/--quiet` suppresses terminal output, **not log writes**; `-y/--yes` auto-confirms prompts, including package installs. `--detach` requires batch mode and available `systemd-run`; terminal disconnect during eligible interactive long tasks may also hand off to systemd. `--stop` requests a safe stop and preserves surface progress, but does **not** cancel drive-internal SMART self-tests. `-l/--log FILE` changes the log path; `HDD_LOG_DIR` and `HDD_STATE_DIR` override default directories. `NO_COLOR` disables color; `HDD_NO_BG` disables automatic interactive background handoff. Menu settings are saved in the state directory.

The parser also maps `-t short|long` to the matching self-test, `-s` to speed and `-b` to badblocks; **`-w/--wait` is ignored** and does not wait for a test. These aliases do not provide v1 behavior. Refer to `--help` for the installed script's options.

Exit codes: `0` all healthy; `1` notice/warning; `2` danger; `3` runtime error. Logs default to `/var/log/disk-health/hdd-health-<timestamp>.log`; state defaults to `/var/lib/hdd-health`. The host writes and operational boundaries are detailed in [DESIGN](doc/DESIGN.md#data-design).

## Upgrade

For the current source layout, update the checkout, build in `src/web`, then run `sudo bash deploy/install.sh` from the repository root. The installer copies `src/checker/hdd-health-check.sh`, `src/web/server.py`, and `dist/web` into the existing service layout, preserves the Web password and keeps timestamped application and unit backups. Review changes before running the installer as root. The historical `v3.0.0` tag retains its original `web/` source layout and its own installation instructions.

## Uninstall

- Remove the checkout or installed script to remove the CLI while retaining logs and history. The CLI installs no permanent systemd service; if you installed the optional Web service, stop and disable it first as described in [WEB](doc/WEB.md). Check for active transient tasks before removing the script.
- For full removal, first stop any task and back up desired records, then manually remove the configured `HDD_STATE_DIR` (default `/var/lib/hdd-health`) and `HDD_LOG_DIR` (default `/var/log/disk-health`) after verifying their paths and contents. This deletes reports, progress, history, repair notes and logs; never blindly delete a shared or overridden directory. Packages installed via `apt-get` are not removed automatically.

## Acknowledgements

Third-party code and font credits are listed in [THIRD_PARTY_NOTICES](doc/THIRD_PARTY_NOTICES.md).

## License

MIT (SPDX: MIT); see [LICENSE](LICENSE).

## Current SSD assessment and controls

A full SSD/NVMe assessment runs SMART quick, short and long self-tests plus a full read-only scan. It omits speed sampling; slow reads alone do not deduct health points. A completed clean batch scores 100, while SMART findings or actual read errors may reduce the heuristic score. Batch controls show the union of checks supported by the selected drives; HDD-only checks skip selected SSDs. Capacity and host-write values switch between decimal and binary units by clicking the value. A SATA HDD can be woken or put in standby from its SMART detail.
