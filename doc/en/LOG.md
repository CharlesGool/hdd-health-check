---
name: project-log-en
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: "en"
---

# hdd-health-check — Log

This record preserves accepted historical decisions, known limitations and release history. The current release is `v4.1.0`. The user reports running the earlier `v2.2.0` code on a real machine, without device, environment or coverage details. The revised scoring has synthetic tests and Web verification on a Debian NAS, but no controlled complete assessment on real HDDs.

## Multi-language

[简体中文](../LOG.md) | **English** | [Español](../es/LOG.md)

## Documentation

- Project overview: [README](README.md)

- Design rationale: [DESIGN](DESIGN.md)

- Project status: [LOG](LOG.md)
- Historical records: [HISTORY](HISTORY.md)
- Version changelog: [CHANGELOG](CHANGELOG.md)

- Third-party notices: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Records

- [HISTORY](HISTORY.md)
- [CHANGELOG](CHANGELOG.md)

## Bugs

- [ ] The user reports testing v2.2.0 on a real machine, but did not provide device, environment or test-coverage details. Testing of root execution, package installation and systemd behavior is unconfirmed; previous v1.0.0 release checks also lacked a real HDD and SMART data (syntax and help only). The script was reportedly used before the original normalization, which is not a replacement for a controlled hardware test.
- [ ] The revised batch scoring and final SMART/ATA/CRC recheck have only synthetic test coverage, not real-HDD validation of this code. Firmware self-test log time resolution and cross-run resumed scans can produce partial/unknown coverage; historical errors cannot be automatically reattributed after repair. This hardware-validation limitation remains disclosed; authorized HDD retesting remains recommended.
- [ ] Heuristic health weights are not calibrated failure probabilities; SAS/SCSI scoring is less exercised than ATA and USB/RAID SMART passthrough may fail. Vendor-dependent temperature reporting is incomplete.
- [ ] The authenticated Web UI and LAN service were checked on a Debian NAS with real disk inventory, but a complete assessment on real HDDs and recovery after a reboot remain unverified. Nonconforming pre-existing v2.2 state is rejected. CSV export is not provided.
- [x] The disk-detail tab underline extended past the selected tab in a user screenshot after `test-771001c`. The previous indicator scaled a one-pixel line using an integer button width. It now animates the button's fractional measured width directly; local Chromium checks matched the selected SMART and Checks buttons at narrow width, including zoom and RTL. The screenshot's exact browser configuration was not available to reproduce.
- [ ] The user reports an issue with the animation when returning from disk detail and asked to leave it for later. No return-animation code was changed in the tab-underline fix.
- [x] v1.0.0 normalization corrected clone instructions pointing to the nonexistent `hdd-health-check-repo/main` path and mixed Traditional Chinese characters in the Simplified Chinese README.

## Limitations

- Terminal text and SMART raw output from the Bash detector do not yet support runtime multilingual display; the existing terminal interface is in Simplified Chinese, and vendor diagnostics are raw output. The Web interface uses language resources; server-side operation failures include the raw system error.

- The installed Debian service keeps its existing `/root/apps/hdd-health-check/web/` host layout for upgrade compatibility; the source layout is `src/web/` with generated output in `dist/web/`.

### Compatibility entry points

Baseline: `35f24e5`
Reason: existing CLI commands and installation instructions invoke the repository-root shell entry point; the implementation now lives under `src/checker/`.
Update boundary: retain the root dispatcher until a separately communicated CLI path migration replaces the established command.

- `hdd-health-check.sh` -> `src/checker/hdd-health-check.sh`

## Decisions

| Date | Decision | Status | Reason |
| --- | --- | --- | --- |
| 2026-08-12 | Split the local project into a Git working tree and separate snapshots; reject a flat local layout. | Accepted | Historical release snapshots needed separation from tracked source. The then-current `main/` naming was local only and never part of the GitHub checkout; tags and `git archive` snapshots were planned. |
| 2026-08-13 | Rename local `main/` to `repo/`; repair install paths, bilingual headers and `.gitignore`; keep private mirror and snapshot paths out of public status. Reject committing the stale staged docs unchanged. | Accepted | The GitHub checkout places the script at its root. Old snippets would fail immediately after cloning; local paths and translation errors did not belong in public documentation. |
| 2026-08-13 | Do not simulate a real-HDD release check on the available virtual disk; disclose the weaker validation. | Accepted | No usable SMART hardware or `smartmontools` was available; installing packages to scan a virtual disk would not test HDD logic. |
| 2026-08-13 | Replace the public v1.0.0 history with one clean noreply-identity commit and annotated tag, retaining the original history in a private renamed archive; reject force-pushing the prior public repository or preserving its superseded intermediate commit. | Accepted | The prior public commit contained a personal email in Git metadata. Existing clones/forks do not migrate automatically and prior exposure cannot be guaranteed erased from caches. This is historical, not authorization for another rewrite. |
| Historical record | Current integration: Adopt the supplied v2.2.0 behavior without v1 compatibility guarantees and retain the existing MIT license. | Accepted | The new script adds persistent state and optional background tasks; `-w` is ignored. At integration time, no release, tag or hardware validation was claimed. |

## Handoff

[简体中文](../LOG.md#交接)
