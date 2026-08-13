# hdd-health-check

**English** | [简体中文](README.zh.md)

A multi-dimensional health-scan script for mechanical hard drives (HDDs) on Debian/Ubuntu,
built on `smartmontools`, run as root.

## What it does

- Device/interface/firmware basic info
- SMART support and enabled-state detection
- Overall SMART health verdict (PASSED/FAILED)
- Key SMART attribute parsing (reallocated sectors, pending sectors, uncorrectable sectors,
  CRC errors, spin retries, etc.)
- SMART error log analysis
- Self-test log review, with the ability to launch short/long self-tests
- Lifespan and load assessment (power-on hours, power-on cycles, head load cycles)
- Kernel log (dmesg) I/O error scan
- Mount status and read-only-degradation detection
- Optional: `hdparm` sequential read benchmark (read-only, safe)
- Optional: `badblocks` read-only surface scan
- Composite score (0–100) and a health-grade verdict
- Results saved to a log file; supports batch and interactive disk selection

## Requirements

- Debian / Ubuntu
- root privileges
- `smartmontools` (the script prompts to auto-install it if missing); optionally `hdparm`,
  `e2fsprogs`

## Install

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
chmod +x hdd-health-check.sh
```

## Quick start

```bash
sudo ./hdd-health-check.sh                  # interactive disk selection
sudo ./hdd-health-check.sh -a               # scan all mechanical disks
sudo ./hdd-health-check.sh -d sdb,sdc       # scan only the specified disks
sudo ./hdd-health-check.sh -a -t short -w   # also run a short self-test and wait for it
sudo ./hdd-health-check.sh -a -q -y         # quiet mode, suited to a cron health check
```

Full option reference:

```bash
sudo ./hdd-health-check.sh --help
```

## Verify it works

Run it against at least one real HDD:

```bash
sudo ./hdd-health-check.sh -a
```

You should see a per-disk report ending in a composite score (0–100) and a health-grade
verdict, and the process should exit with one of the documented exit codes below. If
`smartmontools` is missing, the script detects this and prompts to install it rather than
failing silently.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | All disks healthy |
| 1 | Some disks have notices/warnings worth attention |
| 2 | High-risk disk(s) present — back up and replace immediately |
| 3 | Runtime error (insufficient privileges, missing dependency, etc.) |

## Configuration

No environment-variable configuration — all options are CLI flags (see `--help`). The one
path a user commonly overrides:

| Flag | Meaning | Default |
|---|---|---|
| `-l, --log <file>` | Log file path | `/var/log/disk-health/hdd-health-<timestamp>.log` |

## License

MIT
