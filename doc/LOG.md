# hdd-health-check — Log

This record preserves accepted historical decisions, known limitations and release history. This documentation describes `v2.3.0`. See GitHub Releases for tagged versions and downloads. The user reports running the earlier `v2.2.0` code on a real machine, without device, environment or coverage details. The revised scoring has only isolated mock validation, not real-HDD validation.

## Multi-language

**English** | [简体中文](zh_cn/LOG.md) | [繁體中文](zh_tw/LOG.md) | [繁體中文（香港）](zh_hk/LOG.md) | [हिन्दी](hi/LOG.md) | [Español](es/LOG.md) | [العربية](ar/LOG.md) | [Français](fr/LOG.md)

## Documentation

- Project overview: [README](../README.md)
- Design rationale: [DESIGN](DESIGN.md)
- Release history: [LOG](LOG.md)
- Third-party inventory: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Bugs

- [ ] The user reports testing v2.2.0 on a real machine, but did not provide device, environment or test-coverage details. Testing of root execution, package installation and systemd behavior is unconfirmed; previous v1.0.0 release checks also lacked a real HDD and SMART data (syntax and help only). The script was reportedly used before the original normalization, which is not a replacement for a controlled hardware test.
- [ ] The revised batch scoring and final SMART/ATA/CRC recheck have only synthetic test coverage, not real-HDD validation of this code. Firmware self-test log time resolution and cross-run resumed scans can produce partial/unknown coverage; historical errors cannot be automatically reattributed after repair. This hardware-validation limitation remains disclosed; authorized HDD retesting remains recommended.
- [ ] Heuristic health weights are not calibrated failure probabilities; SAS/SCSI scoring is less exercised than ATA and USB/RAID SMART passthrough may fail. Vendor-dependent temperature reporting is incomplete.
- [ ] No structured JSON/CSV output. Nonconforming pre-existing v2.2 state is rejected. The current integration includes isolated mocks for custom `TMPDIR` instance detection/safe stop and invalid surface progress.
- [x] v1.0.0 normalization corrected clone instructions pointing to the nonexistent `hdd-health-check-repo/main` path and mixed Traditional Chinese characters in the Simplified Chinese README.

## Decisions

| Decisions | Reasons |
| --- | --- |
| 2026-08-12: Split the local project into a Git working tree and separate snapshots; reject a flat local layout. | Historical release snapshots needed separation from tracked source. The then-current `main/` naming was local only and never part of the GitHub checkout; tags and `git archive` snapshots were planned. |
| 2026-08-13: Rename local `main/` to `repo/`; repair install paths, bilingual headers and `.gitignore`; keep private mirror and snapshot paths out of public status. Reject committing the stale staged docs unchanged. | The GitHub checkout places the script at its root. Old snippets would fail immediately after cloning; local paths and translation errors did not belong in public documentation. |
| 2026-08-13: Do not simulate a real-HDD release check on the available virtual disk; disclose the weaker validation. | No usable SMART hardware or `smartmontools` was available; installing packages to scan a virtual disk would not test HDD logic. |
| 2026-08-13: Replace the public v1.0.0 history with one clean noreply-identity commit and annotated tag, retaining the original history in a private renamed archive; reject force-pushing the prior public repository or preserving its superseded intermediate commit. | The prior public commit contained a personal email in Git metadata. Existing clones/forks do not migrate automatically and prior exposure cannot be guaranteed erased from caches. This is historical, not authorization for another rewrite. |
| Current integration: Adopt the supplied v2.2.0 behavior without v1 compatibility guarantees and retain the existing MIT license. | The new script adds persistent state and optional background tasks; `-w` is ignored. At integration time, no release, tag or hardware validation was claimed. |

## Changelog

### v2.3.0 — 2026-09-24

#### Changed

This release includes the previously untagged v2.2 integration: persistent per-drive results, SMART counter history, interactive and batch modules, resumable read-only surface scans, interface verification, optional transient systemd tasks, and safer data-only state parsing. It does not preserve v1 CLI or state compatibility: `-w/--wait` is ignored rather than waiting; back up host state before upgrading and restore matching state with an older script. The revised scoring below has synthetic, not real-HDD, coverage.

#### Fixed

- Recognize a newly completed first SMART self-test record; older, incomplete or wrong-type entries do not count as a completed new test.
- Recheck SMART/ATA/CRC after a complete assessment; show a numeric composite score only for completed, unexpired checks in one batch. Keep legacy, reused, interrupted, expired or post-interface-verification old results as historical/pending review with partial/unknown overall grade, without wiping earlier risks or refreshing the baseline when viewing reports. Separate resolved interface verification from old penalties: unknown first ATA totals retain a 5-point unresolved-risk deduction across checks (also for legacy records without the risk field); newly increased totals deduct 20, and unchanged historical counts are not new errors or proof of resolution. Interface verification alone cannot attribute old ATA errors to a repaired interface. Sparse slow surface reads prompt performance retesting rather than a bad-sector finding; surface read errors still deduct 40. Synthetic scoring-state tests pass; this revised code has not been tested on a real HDD.

### v2.2.0 — untagged integration history (not released)

#### Added

- Persistent per-disk results, SMART counter history, repair records and reports; interactive menu, sampled read profiling, resumable surface latency scanning with targeted bad-block rechecks, full read-only `badblocks`, interface read stress checks and optional transient systemd background execution.

#### Changed

- Default batch quick checks, reusable timed results and `--rescan`; `-r/--run` selects modules and `--status`/`--stop` manage a running instance. `-t short|long`, `-s` and `-b` map to modules; `-w/--wait` is ignored rather than waiting. New behavior is not v1 CLI compatibility.
- Host state and logs are written separately; v2.2.0 does not preserve v1 CLI or state compatibility. Back up host state before upgrading; restoring a previous script requires its matching state backup. State records use an allowlisted data-only format; incompatible records may be rejected.

#### Fixed

- Reject executable or malformed state records and symlinked state inputs, restrict background plans to validated fields and the private state directory, and validate device names and log/state paths to reduce unsafe file handling.
- Treat invalid or incomplete surface checkpoints as new scans instead of calculating progress from a zero denominator; support custom `TMPDIR` in running-instance detection and safe stop.

The user reports testing v2.2.0 on a real machine, but did not provide device, environment or test-coverage details. Root execution, package installation and systemd behavior have not been independently confirmed.

### v1.0.0 — 2026-08-08

#### Added

- Initial 12-dimension HDD health check: device/interface data, SMART capability and overall verdict, ATA attributes or SAS defect/error counters, error and self-test logs, short/long self-test launch, lifespan/load, kernel I/O errors, mount and read-only detection, optional read-only `hdparm` benchmark and `badblocks` scan.
- Heuristic 0–100 score and four grades with process exit codes 0/1/2/3, SMART passthrough auto-detection, interactive and batch disk selection, and offered `apt` installation of missing `smartmontools`.
- The complete v1.0.0 design and usage documents remain in the `v1.0.0` Git tag (for example, `git show v1.0.0:DESIGN.md` and `git show v1.0.0:README.zh.md`); obsolete v1 commands are not current guidance.
