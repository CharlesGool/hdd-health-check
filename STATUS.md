# Status — updated 2026-08-13

**Version:** v1.0.0 (tagged, pushed on a rebuilt clean history) · **Branch:** main
**Repo:** https://github.com/CharlesGool/hdd-health-check (public)
**Notion:** private mirror (not published)
**Snapshots:** maintained privately (not published)
**In progress:** Nothing — v1.0.0 shipped. Summary: finished a previous session's stalled normalization, then discovered the repo's only prior commit had a personal Gmail in its author/committer metadata (already pushed publicly). Remediated like Anytls-Serve: original repo made private and renamed `hdd-health-check-private-archive`; a new `hdd-health-check` repo was created with a single clean `v1.0.0` commit under the project's noreply identity, pushed, audited, and made public. Also fixed a real install-path bug present in 4 docs, fixed Traditional Chinese characters that had leaked into README.zh.md, unified bilingual doc headers, corrected `.gitignore`, and desensitized this file for public-repo distribution. First snapshot exported; Notion page created and synced.
**Next:** No planned work after v1.0.0 ships. Possible future extensions are listed in `DESIGN.md` § How to extend (structured JSON/CSV output, deeper SAS scoring parity, NVMe support).
**Known issues:**
- Scoring weights are heuristic, not derived from a calibrated failure-rate model (see
  `DESIGN.md` § Known limitations) — treat the score as a triage signal.
- SAS/SCSI scoring path is less battle-tested than the ATA path.
- No structured output format (JSON/CSV) — only a human-readable log.
- The "clean environment" release gate could not be run against real HDD hardware or real SMART data in this environment (only a virtual disk with no SMART support is present, and `smartmontools` isn't installed here); verification was limited to a bash syntax check and `--help` output. The script was already in real-world use before this normalization (per `DECISIONS.md`), which is why v1.0.0 proceeds anyway — but this is weaker verification than a true clean-install test.
**Blocked on:** Nothing currently.
