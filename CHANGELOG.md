# Changelog

## v1.0.0 — 2026-08-08

### Added
- Initial release: 12-dimension HDD health scan (device/interface info, SMART support and
  overall health verdict, key SMART attributes with per-attribute scoring, SMART error log,
  self-test log + optional short/long self-test launch, lifespan/load assessment, kernel
  `dmesg` I/O error scan, mount and read-only-degradation detection, optional `hdparm`
  sequential-read benchmark, optional read-only `badblocks` surface scan).
- Composite 0–100 health score with grade thresholds (良好/注意/警告/危险) and process exit
  codes (0/1/2/3) suited for cron monitoring.
- ATA and SAS/SCSI scoring paths (SAS falls back to grown defect list + unrecoverable error
  counts, since standard SMART attributes don't exist on SAS disks).
- Auto-detection of the correct `smartctl -d` option for USB-bridge and RAID-passthrough disks.
- Interactive and non-interactive (`-a`, `-d`, `-q -y`) disk selection modes.
- Auto-install of missing `smartmontools` dependency via `apt`.
