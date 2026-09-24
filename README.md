# hdd-health-check

This root-run Bash tool evaluates HDD health on Debian/Ubuntu through SMART data and read-only disk checks. The v2.2.0 source is available in this public GitHub repository. The user reports testing it on a real machine, but did not provide device, environment or test-coverage details. No v2.2.0 tag or GitHub Release exists.

## Multi-language

**English** | [简体中文](doc/zh_cn/README.md) | [繁體中文](doc/zh_tw/README.md) | [繁體中文（香港）](doc/zh_hk/README.md) | [हिन्दी](doc/hi/README.md) | [Español](doc/es/README.md) | [العربية](doc/ar/README.md) | [Français](doc/fr/README.md)

## Documentation

- Project overview: [README](README.md)
- Design rationale and host-side effects: [DESIGN](doc/DESIGN.md)
- Decisions, bugs and version history: [LOG](doc/LOG.md)
- Third-party inventory: [THIRD_PARTY_NOTICES](doc/THIRD_PARTY_NOTICES.md)

## Introduction

The interactive menu or batch CLI selects drives, performs a quick SMART, mount and kernel-log assessment, and reports a heuristic 0–100 score and risk grade. Other modules offer SMART short/long self-tests, sampled read-speed profiling, resumable full-disk read-latency scanning with optional targeted `badblocks` recheck, full-disk read-only `badblocks`, and post-repair interface read testing. The full assessment runs quick, short, long, speed and surface checks; it does not include the separate full-disk `badblocks` or interface module. Results can be reused, compared against SMART counter history, and assembled into a report. See [known issues](doc/LOG.md#bugs) and [goals](doc/DESIGN.md#design-goals).

**Read-only refers to target disk data, not the host.** The program writes logs, settings, progress and history on the host; it can enable SMART, launch drive-internal self-tests, read whole devices under sustained load, install packages after confirmation, and start transient systemd units. Do not use it as a substitute for backups. No destructive write-mode surface scan, erase or filesystem write is implemented.

## Requirements

- Minimum: root, Bash 4.3+, Linux block-device utilities (`lsblk`, `blockdev`), `smartctl` (`smartmontools`), `dd` (`coreutils`) and `flock`; Debian/Ubuntu is the intended platform. Other distributions receive a warning; automatic dependency installation uses `apt-get`.
- Recommended: `badblocks` (`e2fsprogs`) for surface checks; systemd with `systemd-run` for detached tasks. Missing packages may trigger an interactive `apt-get update`/install offer (or automatic confirmation with `-y`). Check dependencies before unattended runs. No pinned third-party code is vendored and no dependency lock file applies.
- Real HDD and SMART access are needed to assess actual health. SSD/NVMe can be included explicitly, but HDD-oriented scoring is not a calibrated SSD/NVMe assessment.

## Install

### Quick Install

From a trusted checkout, run `sudo bash ./hdd-health-check.sh --help` to inspect options without starting a scan. Do not pipe an unreviewed remote script into a root shell.

### Normal Install

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
bash -n hdd-health-check.sh
sudo bash ./hdd-health-check.sh --help
```

Review and install the required OS packages yourself before scanning to avoid the script's package-install prompt. To upgrade an existing checkout, back up any desired host logs and `${HDD_STATE_DIR:-/var/lib/hdd-health}` first; replace the script from a reviewed checkout, keep that state directory for history/resume, then review `--help` and run the chosen checks. v2.2 state parsing accepts only known data fields; nonconforming prior v2.2 state may be rejected. A rollback requires restoring the previous script **and its matching state backup**; do not assume newer state is backwards compatible. No v1 CLI behavior or state migration is promised.

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

## Uninstall

- Remove the checkout or installed script to remove the tool while retaining logs and history. No systemd service is installed permanently; check for active transient tasks before removing the script.
- For full removal, first stop any task and back up desired records, then manually remove the configured `HDD_STATE_DIR` (default `/var/lib/hdd-health`) and `HDD_LOG_DIR` (default `/var/log/disk-health`) after verifying their paths and contents. This deletes reports, progress, history, repair notes and logs; never blindly delete a shared or overridden directory. Packages installed via `apt-get` are not removed automatically.

## License

MIT (SPDX: MIT); see [LICENSE](LICENSE).
