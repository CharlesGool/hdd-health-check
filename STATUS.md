# Status — updated 2026-08-13

**Version:** v1.0.0 (tagged on a rebuilt clean history — see In progress) · **Branch:** main
**Repo:** https://github.com/CharlesGool/hdd-health-check (public)
**Notion:** private mirror (not published)
**Snapshots:** maintained privately (not published)
**In progress:** Finished the stalled normalization from a previous session, then discovered and remediated a personal-email exposure: the repo's only prior commit had a personal Gmail in its author/committer metadata, already pushed publicly. Per the same remediation Anytls-Serve used, the original repo was made private and renamed `hdd-health-check-private-archive`, and this `v1.0.0` tag ships on a single clean commit (noreply identity) in a newly created repo. Also fixed a real bug present in 4 docs (README/DESIGN, both languages) where install/setup instructions pointed at a nonexistent `hdd-health-check-repo/main` path; fixed Traditional Chinese characters that had leaked into README.zh.md; unified bilingual doc headers; corrected `.gitignore`; desensitized this file for public-repo distribution. Remaining: push, export the first snapshot, sync Notion, make the new repo public once the clean-history review passes.
**Next:** No planned work after v1.0.0 ships. Possible future extensions are listed in `DESIGN.md` § How to extend (structured JSON/CSV output, deeper SAS scoring parity, NVMe support).
**Known issues:**
- Scoring weights are heuristic, not derived from a calibrated failure-rate model (see
  `DESIGN.md` § Known limitations) — treat the score as a triage signal.
- SAS/SCSI scoring path is less battle-tested than the ATA path.
- No structured output format (JSON/CSV) — only a human-readable log.
- The "clean environment" release gate could not be run against real HDD hardware or real SMART data in this environment (only a virtual disk with no SMART support is present, and `smartmontools` isn't installed here); verification was limited to a bash syntax check and `--help` output. The script was already in real-world use before this normalization (per `DECISIONS.md`), which is why v1.0.0 proceeds anyway — but this is weaker verification than a true clean-install test.
**Blocked on:** Nothing currently.
