---
name: project-log
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: en
---

# hdd-health-check — Log

This record preserves accepted historical decisions, known limitations and release history. This documentation describes `v3.0.0`. The `v3.0.0` source tag is the major-version boundary; no GitHub Release is created. The user reports running the earlier `v2.2.0` code on a real machine, without device, environment or coverage details. The revised scoring has only isolated mock validation, not real-HDD validation.

## Multi-language

**English** | [简体中文](zh_cn/LOG.md) | [繁體中文](zh_tw/LOG.md) | [繁體中文(香港)](zh_hk/LOG.md) | [हिन्दी](hi/LOG.md) | [Español](es/LOG.md) | [العربية](ar/LOG.md) | [Français](fr/LOG.md)

## Documentation

- Project overview: [README](../README.md)
- Design rationale: [DESIGN](DESIGN.md)
- Release history: [LOG](LOG.md)
- Third-party inventory: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Bugs

- [ ] The user reports testing v2.2.0 on a real machine, but did not provide device, environment or test-coverage details. Testing of root execution, package installation and systemd behavior is unconfirmed; previous v1.0.0 release checks also lacked a real HDD and SMART data (syntax and help only). The script was reportedly used before the original normalization, which is not a replacement for a controlled hardware test.
- [ ] The revised batch scoring and final SMART/ATA/CRC recheck have only synthetic test coverage, not real-HDD validation of this code. Firmware self-test log time resolution and cross-run resumed scans can produce partial/unknown coverage; historical errors cannot be automatically reattributed after repair. This hardware-validation limitation remains disclosed; authorized HDD retesting remains recommended.
- [ ] Heuristic health weights are not calibrated failure probabilities; SAS/SCSI scoring is less exercised than ATA and USB/RAID SMART passthrough may fail. Vendor-dependent temperature reporting is incomplete.
- [ ] The authenticated Web UI and LAN service were checked on a Debian NAS with real disk inventory, but a complete assessment on real HDDs and recovery after a reboot remain unverified. Nonconforming pre-existing v2.2 state is rejected. CSV export is not provided.
- [x] v1.0.0 normalization corrected clone instructions pointing to the nonexistent `hdd-health-check-repo/main` path and mixed Traditional Chinese characters in the Simplified Chinese README.

## Decisions

| Decisions | Reasons |
| --- | --- |
| 2026-08-12: Split the local project into a Git working tree and separate snapshots; reject a flat local layout. | Historical release snapshots needed separation from tracked source. The then-current `main/` naming was local only and never part of the GitHub checkout; tags and `git archive` snapshots were planned. |
| 2026-08-13: Rename local `main/` to `repo/`; repair install paths, bilingual headers and `.gitignore`; keep private mirror and snapshot paths out of public status. Reject committing the stale staged docs unchanged. | The GitHub checkout places the script at its root. Old snippets would fail immediately after cloning; local paths and translation errors did not belong in public documentation. |
| 2026-08-13: Do not simulate a real-HDD release check on the available virtual disk; disclose the weaker validation. | No usable SMART hardware or `smartmontools` was available; installing packages to scan a virtual disk would not test HDD logic. |
| 2026-08-13: Replace the public v1.0.0 history with one clean noreply-identity commit and annotated tag, retaining the original history in a private renamed archive; reject force-pushing the prior public repository or preserving its superseded intermediate commit. | The prior public commit contained a personal email in Git metadata. Existing clones/forks do not migrate automatically and prior exposure cannot be guaranteed erased from caches. This is historical, not authorization for another rewrite. |
| Current integration: Adopt the supplied v2.2.0 behavior without v1 compatibility guarantees and retain the existing MIT license. | The new script adds persistent state and optional background tasks; `-w` is ignored. At integration time, no release, tag or hardware validation was claimed. |

## Handoff — 2026-09-28

- Current handoff: development build `dev-c60d602` is installed on the Debian NAS at `/root/apps/hdd-health-check`; `hdd-health-web.service` is active and enabled on `0.0.0.0:8765`. The installer retained the existing password and previous application/unit backups. LAN browser loaded the login page without a JavaScript initialization error; authenticated read-only snapshot, status and Changelog requests succeeded (13 disks, no running task). The local preview had no page-wide horizontal overflow at 390 px. Shell and Web synthetic tests and the Vue production build passed. A real SSD full scan, individual wake action and post-reboot recovery were not run; next action is user observation, followed by hardware checks only when convenient.
- Branch `main`: the annotated `v3.0.0` tag is published on commit `434ac7d`; this later commit records the handoff only. No GitHub Release or prebuilt UI asset was created.
- Deployment: installed the `v3.0.0` tag on the Debian NAS as `hdd-health-web.service` under `/root/apps/hdd-health-check`. The installer retained the password and previous application/unit copies; a separate state and log backup was made before the change. The service is active and enabled on `0.0.0.0:8765`. LAN browser login showed 13 disks and `v3.0.0`; authenticated snapshot, status, job-history, and Changelog APIs returned successfully. No new disk check or reboot was run; boot enablement was verified, but recovery after a reboot remains unverified.
- Completed: authenticated LAN installation was checked on a Debian NAS with 13 enumerated drives. The service started and the browser showed disk data, task pages, themed confirmations, and responsive layouts. The installer preserved the existing password and host state. No new disk scan or reboot was run during the final UI checks.
- Checks: Vue type check/build, shell syntax, synthetic scoring/state tests, Web authentication/job/assessment/SMART tests, authenticated API reads, LAN browser interactions, and documentation format checks passed. Hardware-wide full assessment and post-reboot service recovery remain unverified. Old threshold-only findings without raw evidence remain pending review until a future check.
- Release checks: the clean tag checkout and source archive both built and displayed `v3.0.0`; remote branch and annotated tag refs were verified separately. The local `snapshots/v3.0.0` source export contains 87 files and no prebuilt `web/dist`.
- Versioned installation examples now clone `v3.0.0` and build `web/dist` before using the Debian installer. The source tag does not include a prebuilt UI.
- Remaining documentation work: the project-structure checker reports 62 existing layout errors and the multilingual checker reports 60 existing directory-name and navigation-template mismatches. The content formatter reports zero errors and six warnings. These structural issues do not affect the documented source installation path.
- Next action: observe normal NAS use and a future completed Web task. Later fix the existing project-layout and multilingual navigation mismatches. No temporary project rules were found.

## Commit History

Complete primary-branch history: `git log main --stat`. The `HEAD` entry identifies this handoff commit.

- 2026-09-28 | `HEAD` | `docs(handoff): record SSD assessment deployment` | `git show HEAD`
- 2026-09-28 | `c60d602` | `fix(web): defer option watcher until labels initialize` | `git show c60d602`
- 2026-09-28 | `261247f` | `fix(web): initialize assessment scope before options` | `git show 261247f`
- 2026-09-28 | `f882a8d` | `docs: record SSD full assessment behavior` | `git show f882a8d`
- 2026-09-28 | `bfed16f` | `feat: assess SSDs with full read-only scan` | `git show bfed16f`
- 2026-09-27 | `97f775f` | `docs(handoff): record v3.0.0 tag publication` | `git show 97f775f`
- 2026-09-27 | `434ac7d` | `chore(release): prepare v3.0.0 source tag` | `git show 434ac7d`
- 2026-09-27 | `65acbd0` | `docs(install): point source install to main` | `git show 65acbd0`
- 2026-09-27 | `b963e06` | `docs(handoff): confirm source publication` | `git show b963e06`
- 2026-09-27 | `88474d2` | `feat(web): publish LAN dashboard and docs` | `git show 88474d2`
- 2026-09-24 | `a46b392` | `feat(scoring): improve batch assessment for v2.3.0` | `git show a46b392`
- 2026-09-24 | `3126bcc` | `docs: clarify public source and reported real-machine testing` | `git show 3126bcc`
- 2026-09-24 | `7e69fdd` | `feat!: integrate unreleased v2.2.0 HDD health checks` | `git show 7e69fdd`
- 2026-08-13 | `7b18ca7` | `docs(status): record v1.0.0 release completion` | `git show 7b18ca7`
- 2026-08-13 | `4e01f52` | `chore(release): v1.0.0 (clean history)` | `git show 4e01f52`

## Changelog

### Development update — 2026-09-28 (after the v3.0.0 tag)

- SSD/NVMe full assessments now run quick SMART, short/long self-tests and a full read-only scan, omitting speed sampling. A completed clean batch scores 100; slow reads alone do not deduct health points. Batch check options follow the selected disk types. Capacity and SSD host-write values can switch decimal/binary units, and a sleeping HDD can be woken individually from SMART detail. Synthetic tests passed; no real full-disk assessment was started for this update.

### v3.0.0 — 2026-09-27

This major version adds the authenticated persistent Web UI and Debian installer to the existing disk checker. The Web service was checked on a Debian NAS with 13 enumerated disks; a complete assessment on real HDDs and post-reboot recovery remain unverified. The tag contains source code; no GitHub Release or prebuilt UI asset is published.

#### Fixed in NAS follow-up

- Reflow disk cards from available viewport width, including browser zoom: one to four columns while keeping controls visible and avoiding horizontal overflow.
- Treat SSD/NVMe speed-sample dips and average-speed changes as performance information, retaining penalties for actual read failures and reinterpreting older saved results. Arrange the disk overview in responsive columns and let the dashboard disk card jump to the list.

- Keep task updates responsive during an all-disk SMART self-test by reading the run record and recent log without polling every drive from the Web status endpoint. Refresh the disk list separately and reuse its last successful snapshot while one background read is in progress.
- Color NVMe temperature independently from health scoring. Use controller warning and critical thresholds when available, or 70/80 °C display bands; temperature-only NVMe warnings do not deduct points. Saved historical assessments remain unchanged until rechecked.
- Decode empty saved fields correctly and avoid a warning exit code when a clean check has only partial assessment coverage.
- Move the four dashboard categories into dedicated top-level pages and keep one-click assessment on the disk home page.

#### Added

- A Python Web service, Vue interface, scheduled quick checks, task controls, SMART history view, and deployment unit. The installer configures authenticated LAN access; manual execution remains loopback-only.
- A Web login and logout, an exact IPv4 passwordless list managed by authenticated users in Settings, disk cards with hardware basics, and separate SMART information and check tabs. The update record renders the Changelog section as Markdown.
- Available SATA version and negotiated speed or NVMe PCIe generation, width, and rate; a switchable power-on time display; and batch checks scoped to SATA, HDD, SSD, NVMe, or all disks with any of the eight existing modules. The list labels bus and media type and shows cached temperature; SMART detail shows form factor only when reported. Only a full assessment can create a current composite score. SSD/NVMe scores remain HDD-oriented and are not separately calibrated.
- A Debian installer that checks prerequisites, installs missing apt packages, deploys the prebuilt UI and service, and keeps a rollback copy during updates.
- `--json` snapshots reuse the Bash composite scoring function. `--no-install` blocks automatic dependency installation for Web-initiated jobs. Web launches now persist accepted, running and terminal task states; the attention card filters disks and check details show recorded deductions, including a clear fallback for older records without a cause.

#### Validation

- The UI builds and type-checks; shell state/scoring tests and local HTTP authentication checks pass. The authenticated LAN service was installed and checked on a Debian NAS with 13 enumerated disks. A complete assessment on real HDDs and post-reboot recovery remain unverified.

### v2.3.0 — 2026-09-24 (untagged source baseline)

#### Changed

This source baseline includes the previously untagged v2.2 integration: persistent per-drive results, SMART counter history, interactive and batch modules, resumable read-only surface scans, interface verification, optional transient systemd tasks, and safer data-only state parsing. It does not preserve v1 CLI or state compatibility: `-w/--wait` is ignored rather than waiting; back up host state before upgrading and restore matching state with an older script. The revised scoring below has synthetic, not real-HDD, coverage.

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
