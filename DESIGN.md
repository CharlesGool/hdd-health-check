# hdd-health-check — Design

**English** | [简体中文](DESIGN.zh.md)

## Goals & non-goals

**Goal:** give a sysadmin a single command that turns raw SMART/kernel-log/mount-state data for
one or more mechanical HDDs into a plain-language health verdict (0–100 score + grade), suitable
both for interactive one-off checks and for unattended cron monitoring.

**Non-goals:**
- Not a monitoring daemon — it's a point-in-time scan, not a long-running service. Scheduling is
  the caller's job (cron, systemd timer).
- Not a data-recovery tool — it reports risk, it doesn't image or recover data.
- Not a general storage-health tool for all media — SSD/NVMe are explicitly out of the default
  scan scope (see `--include-ssd`); several scored metrics (spin retries, load-cycle count,
  rotational-media temperature bands) are meaningless for solid-state storage.
- Destructive operations (write-mode `badblocks`, secure erase, etc.) are intentionally excluded
  — the optional surface scan uses `badblocks -s` (read-only mode) only, never the destructive
  `-w` write-test mode.

## Architecture

Single self-contained bash script, no daemon, no external state beyond the log file it writes.
Everything runs synchronously in one process.

```
main()
├── enumerate_disks()      lsblk -> D_NAME[]/D_SIZE[]/D_MODEL[]/D_ROTA[]/D_TRAN[]
├── select_targets()       -a | -d <list> | interactive menu -> TARGETS[]
└── for each target: check_disk()
    ├── 1. basic info + mount/read-only-degradation check
    ├── 2. SMART availability (auto-detect smartctl -d option for USB bridges/RAID)
    ├── 3. overall SMART health verdict (PASSED/FAILED)
    ├── 4. key attribute parsing + per-attribute scoring (ATA path or SAS defect-list path)
    ├── 5. temperature
    ├── 6. lifespan & load (power-on hours/cycles, head load-cycle count)
    ├── 7. SMART error log
    ├── 8. self-test log (+ optionally launch a new short/long self-test)
    ├── 9. kernel log (dmesg) I/O error scan
    ├── 10. optional: hdparm sequential-read benchmark
    ├── 11. optional: badblocks read-only surface scan
    └── 12. composite score -> grade -> per-disk SUMMARY[] entry
-> print SUMMARY[] table, compute worst-case exit code, write everything to LOG_FILE
```

Each `check_disk()` step starts from a fixed budget (`SCORE=100`) and subtracts weighted
penalties as it finds specific issues, accumulating human-readable strings into `ISSUES[]`
alongside the score. The final grade for a disk is threshold-based on the resulting score, and
the worst grade across all scanned disks decides the process exit code (0/1/2).

**Why a single flat script instead of a modular tool:** this is meant to be copy-pasted onto a
box and run with zero install step beyond `apt install smartmontools` — a single file with no
external code dependencies is easier to audit and trust for something that runs as root against
disk hardware.

## Tech stack

| Component | Choice | Why |
|---|---|---|
| Language | Bash (`set -o pipefail`) | Zero-install on any Debian/Ubuntu box; this is glue over existing CLI tools, not a program with real data structures |
| SMART data | `smartmontools` (`smartctl`) | The standard Linux SMART tool; required, auto-installed via `apt` if missing |
| Disk enumeration | `util-linux` (`lsblk`) | Standard, structured (`-P` key=value output), reliably distinguishes rotational vs. solid-state via `ROTA` |
| Optional read benchmark | `hdparm -tT` | Read-only, safe; simplest way to get a sequential-read number without writing test files |
| Optional surface scan | `e2fsprogs` (`badblocks -s`, read-only mode) | Read-only surface scan catches media defects SMART attributes alone might miss; deliberately never runs write-mode `badblocks -w` |

No database, no config file format, no network calls — everything is either a `lsblk`/`smartctl`/
`dmesg` invocation or a CLI flag.

## Reproduction requirements

### Environment

- Debian or Ubuntu (checked via `/etc/os-release`; other distros get a warning, not a hard
  failure, since `smartctl`/`lsblk` themselves are distro-agnostic — only the `apt`
  auto-install path is Debian-specific).
- root privileges (`EUID -eq 0` is enforced).
- At least one real block device to scan — SMART/kernel-log behavior can't be meaningfully
  exercised against a virtual disk or in a container without device passthrough.

### External dependencies

- `smartmontools` — required; the script detects it's missing and offers to `apt install` it.
- `hdparm` — only required if `-s/--speed` is used.
- `e2fsprogs` (`badblocks`) — only required if `-b/--badblocks` is used.
- No API keys, no network services, no files outside version control are needed to run this
  script from a clean checkout.

### Paths & mounts

- `LOG_DIR` / `-l, --log <file>` — the only host-specific path. Defaults to
  `/var/log/disk-health/`; always overridable per-invocation via `-l`, never hardcoded elsewhere
  in the script.

### Configuration reference

No environment-variable configuration. See `README.md` § Configuration for the one path-related
CLI flag (`-l`/`--log`).

## Setup from scratch

1. `git clone https://github.com/CharlesGool/hdd-health-check.git && cd hdd-health-check`
2. `chmod +x hdd-health-check.sh`
3. `sudo ./hdd-health-check.sh -a` — auto-installs `smartmontools` if missing (prompts unless
   `-y` is passed), scans all detected mechanical disks.
4. **Verify it works:** confirm you see a per-disk report ending in a composite score + grade,
   a summary table, and an exit code matching the worst grade seen (0/1/2; 3 means the run
   itself failed — check the printed error).

## Data model / file layout

No database or structured data file — the only persistent output is a plain-text log:

```
${LOG_DIR:-/var/log/disk-health}/hdd-health-<YYYYMMDD-HHMMSS>.log
```

Content is the exact terminal output with ANSI color codes stripped (`out()` writes to both
terminal and log; the log copy is passed through `sed -r 's/\x1B\[[0-9;]*[mK]//g'`). No JSON/CSV
output format exists today — see How to extend.

## Known limitations & gotchas

- **SAS/SCSI disks take a different scoring path.** The standard ATA SMART-attribute table
  (reallocated sectors, pending sectors, etc.) doesn't exist on SAS/SCSI drives; the script
  falls back to parsing the grown defect list and read/write unrecoverable-error counts instead
  (`check_disk()` § SAS branch). The scoring weights on that path are separate from, and less
  battle-tested than, the ATA path.
- **USB-bridge/RAID-controller passthrough is heuristic.** `detect_dopt()` tries a fixed list of
  `smartctl -d` options (`sat`, `sat,12`, `scsi`, `ata`, several USB-bridge chipset names) and
  picks the first one that returns a parseable device model. Uncommon bridge chipsets or
  RAID controllers (e.g. MegaRAID) may not be in this list — the script prints the manual
  `smartctl -d megaraid,0` workaround when detection fails rather than guessing further.
- **Temperature attribute ID varies by vendor.** The script reads attribute 194
  (Temperature_Celsius), falls back to 190 (Airflow_Temperature_Cel), then falls back to parsing
  the free-text "Current Drive Temperature" line. A drive that reports temperature under a
  different attribute ID entirely will show as unreadable rather than wrong — this fails safe,
  but coverage isn't exhaustive.
- **Scoring weights are heuristic, not derived from a failure-rate model.** The point deductions
  per issue (e.g. −25 for a temperature ≥60°C, −60 for a FAILED overall SMART verdict) reflect
  practical judgment about severity, not a calibrated statistical model of actual drive-failure
  probability. Treat the score as a triage signal, not a precise probability.
- **No structured (JSON/CSV) output.** Only a human-readable log. Anything that wants to
  aggregate results across many machines currently has to parse the log text.
- **`badblocks` in this script is always read-only (`-s`, no `-w`).** This is intentional (see
  Goals & non-goals) — don't add a write-mode flag without a very deliberate, separately-flagged
  opt-in, since `-w` destroys data on the target disk.

## How to extend

- **Structured output:** add a `--json` or `--csv` flag that emits the same per-disk
  score/grade/issues data as structured output alongside (or instead of) the human-readable log,
  for fleet-wide aggregation.
- **More SAS-path coverage:** the ATA path has ~10 scored attributes; the SAS path currently only
  scores the grown defect list and unrecoverable read/write error counts. Extending SAS scoring
  parity would help multi-disk-shelf / enterprise-SAS deployments.
- **NVMe support:** currently NVMe is excluded from the default scan (`--include-ssd` brings it
  into enumeration, but the scored checks are HDD-specific and won't produce a meaningful score
  for it). A parallel NVMe-specific check path (media errors, percentage-used, temperature
  thresholds from the NVMe SMART log) would need its own scoring logic.
- **Alerting integration:** the exit code (0/1/2/3) is already suitable for cron + a notification
  wrapper (e.g. a MOTD/email/webhook script that only fires on non-zero exit) — this is
  deliberately left to the caller rather than built in, to keep the script dependency-free.
