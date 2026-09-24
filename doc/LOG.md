# hdd-health-check — Log

This record preserves accepted historical decisions, known limitations and release history; v2.2.0 is integrated locally but not released.

## Multi-language

**English** | [简体中文](zh_cn/LOG.md) | [繁體中文](zh_tw/LOG.md) | [繁體中文（香港）](zh_hk/LOG.md) | [हिन्दी](hi/LOG.md) | [Español](es/LOG.md) | [العربية](ar/LOG.md) | [Français](fr/LOG.md)

## Documentation

- Project overview: [README](../README.md)
- Design rationale: [DESIGN](DESIGN.md)
- Release history: [LOG](LOG.md)
- Third-party inventory: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Bugs

- [ ] Real-HDD integration, root/package installation and systemd behavior remain unverified in this integration; previous v1.0.0 release checks also lacked a real HDD and SMART data (syntax and help only). The script was reportedly used before the original normalization, which is not a replacement for a controlled hardware test.
- [ ] Heuristic health weights are not calibrated failure probabilities; SAS/SCSI scoring is less exercised than ATA and USB/RAID SMART passthrough may fail. Vendor-dependent temperature reporting is incomplete.
- [ ] No structured JSON/CSV output. Nonconforming pre-existing v2.2 state is rejected. The current integration includes isolated mocks for custom `TMPDIR` instance detection/safe stop and invalid surface progress; real systemd and HDD behavior remain unverified.
- [x] v1.0.0 normalization corrected clone instructions pointing to the nonexistent `hdd-health-check-repo/main` path and mixed Traditional Chinese characters in the Simplified Chinese README.

## Decisions

| Decisions | Reasons |
| --- | --- |
| 2026-08-12: Split the local project into a Git working tree and separate snapshots; reject a flat local layout. | Historical release snapshots needed separation from tracked source. The then-current `main/` naming was local only and never part of the GitHub checkout; tags and `git archive` snapshots were planned. |
| 2026-08-13: Rename local `main/` to `repo/`; repair install paths, bilingual headers and `.gitignore`; keep private mirror and snapshot paths out of public status. Reject committing the stale staged docs unchanged. | The GitHub checkout places the script at its root. Old snippets would fail immediately after cloning; local paths and translation errors did not belong in public documentation. |
| 2026-08-13: Do not simulate a real-HDD release check on the available virtual disk; disclose the weaker validation. | No usable SMART hardware or `smartmontools` was available; installing packages to scan a virtual disk would not test HDD logic. |
| 2026-08-13: Replace the public v1.0.0 history with one clean noreply-identity commit and annotated tag, retaining the original history in a private renamed archive; reject force-pushing the prior public repository or preserving its superseded intermediate commit. | The prior public commit contained a personal email in Git metadata. Existing clones/forks do not migrate automatically and prior exposure cannot be guaranteed erased from caches. This is historical, not authorization for another rewrite. |
| Current integration: Adopt the supplied v2.2.0 behavior without v1 compatibility guarantees and retain the existing MIT license. | The new script adds persistent state and optional background tasks; `-w` is ignored. This integration is not a release, tag or hardware-validation claim. |

## Changelog

### Unreleased — v2.2.0 integration (no release date)

#### Added

- Persistent per-disk results, SMART counter history, repair records and reports; interactive menu, sampled read profiling, resumable surface latency scanning with targeted bad-block rechecks, full read-only `badblocks`, interface read stress checks and optional transient systemd background execution.

#### Changed

- Default batch quick checks, reusable timed results and `--rescan`; `-r/--run` selects modules and `--status`/`--stop` manage a running instance. `-t short|long`, `-s` and `-b` map to modules; `-w/--wait` is ignored rather than waiting. New behavior is not v1 CLI compatibility.
- Host state and logs are written separately; supplied v2.2.0 integration constrains state/plan parsing and path/device handling. No real HDD, root or systemd integration test has been performed here.

### v1.0.0 — 2026-08-08

#### Added

- Initial 12-dimension HDD health check: device/interface data, SMART capability and overall verdict, ATA attributes or SAS defect/error counters, error and self-test logs, short/long self-test launch, lifespan/load, kernel I/O errors, mount and read-only detection, optional read-only `hdparm` benchmark and `badblocks` scan.
- Heuristic 0–100 score and four grades with process exit codes 0/1/2/3, SMART passthrough auto-detection, interactive and batch disk selection, and offered `apt` installation of missing `smartmontools`.
- The complete v1.0.0 design and usage documents remain in the `v1.0.0` Git tag (for example, `git show v1.0.0:DESIGN.md` and `git show v1.0.0:README.zh.md`); obsolete v1 commands are not current guidance.
