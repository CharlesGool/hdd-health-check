---
name: project-changelog-en
description: Changelog
metadata:
  version: "1.0.0"
  lang: "en"
---

# Changelog

## Multi-language

[简体中文](../CHANGELOG.md) | **English** | [Español](../es/CHANGELOG.md)

## Documentation

- Project overview: [README](README.md)

- Design rationale: [DESIGN](DESIGN.md)

- Project status: [LOG](LOG.md)
- Historical records: [HISTORY](HISTORY.md)
- Version changelog: [CHANGELOG](CHANGELOG.md)

- Third-party notices: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Changelog

### v4.1.0 — 2026-09-29

This release updates the Web interface and disk details. The previous test build was checked on a Debian NAS with 13 enumerated disks; the formal build is checked separately before publication.

#### Added

- Disk cards open full detail pages with breadcrumbs, Back navigation, per-disk checks, SMART attributes and explanations. Serial values remain masked until an authenticated reveal; copying is available only after reveal. SSD/NVMe details show host reads and writes when the device supplies counters with known units.
- The Web interface follows the shared visual reference for the login, Dashboard, function pages, Settings, Security and Changelog. It adds responsive layouts, localized controls, icons and optional page and resize motion.

#### Changed

- The Changelog can open from the login screen before authentication and shows the matching build version. Disk-detail controls use a measured tab indicator, and repeated copy feedback restarts its dismissal timer.
- The NAS service unit keeps `/var/lib/hdd-health` at mode 700 after restart. The installer continues to preserve the prior application, unit and Web password on updates.

#### Fixed

- Correct the active SMART and Checks underline width and position at narrow widths and tested zoom levels, including RTL. Refine disk-detail feedback, SMART counter explanations and interrupted route-motion cleanup.

#### Known issues and validation

- The animation when returning from disk detail has a user-reported issue and remains deferred. A complete assessment on real HDDs, real mobile-browser motion and service recovery after a host reboot remain unverified. The health score remains a heuristic, not a calibrated failure probability.
- Vue type checking, production build, project and translation checks, and local Chromium layout checks passed for the test build. The NAS test deployment passed authenticated version and disk-list API checks and browser checks of both tab underlines; no disk scan, password change or reboot was performed.

### v4.0.0 — 2026-09-28

This major version updates the local Web controller, its security model and source layout. The authenticated test build was checked on a Debian NAS with 13 enumerated disks. A complete assessment on real HDDs and service recovery after a host reboot remain unverified.

#### Added

- Full SSD/NVMe assessments now run quick SMART checks, short and long self-tests, and a full read-only scan without HDD speed sampling. A completed clean batch scores 100 under the existing heuristic; slow reads alone do not deduct points, while actual read errors and SMART findings still can. Mixed-disk batch controls offer the union of supported checks and skip ineligible SSDs for HDD-only modules.
- Task history records completed, stopped and failed Web runs separately from the latest per-disk check result and SMART counter trends. Disk detail can request standby for an eligible SATA HDD or wake one sleeping HDD at a time.
- Settings now offers eight accent colors and light/dark modes. The version beside the project name links to Changelog, and the runtime `/api/build` reports the same embedded build identifier. Disk serials stay masked in normal responses and are retrieved only after an authenticated reveal action.

#### Changed

- Security Settings has a separate route with a server-enforced five-minute administrator-password verification window. Verification rotates the session; changing the password during that window requires the new value and confirmation and invalidates all sessions. Password-free IP admission now has an enable switch and accepts only exact RFC 1918 IPv4 or unique-local IPv6 addresses. IP admission cannot read or change security settings. State-changing requests require a same-origin header, and client-supplied forwarding headers do not establish the peer address.
- Source files now live under `src/checker/` and `src/web/`, with generated frontend files in `dist/web/`; the root CLI entry point and installed NAS layout remain compatible. Documentation locales use BCP-47 directory names. The disk overview reflows with available viewport width, and the dashboard keeps its four functions on dedicated pages.

#### Fixed

- Keep task status responsive during all-disk self-tests, show distinct SMART short and long results, and retain separate historical task receipts. Correct NVMe temperature display bands and avoid health deductions for temperature alone or SSD speed variation. Clean checks with partial assessment coverage no longer return a warning solely for that partial coverage.
- The Debian installer now includes the required request header in its authenticated health probe and rolls back when an explicit installation error occurs after the file swap starts.

#### Validation

- Shell and Python tests, Vue type checking and production build, document and structure checks, and local browser checks passed. The NAS test deployment passed authenticated API and Security Settings browser checks, including serial masking and a 390 px layout without horizontal overflow. No disk scan, password change or reboot was performed as part of this release preparation; the health score is not a calibrated failure probability.

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

### v2.3.0 — 2026-09-24

#### Changed

This source baseline includes the previously untagged v2.2 integration: persistent per-drive results, SMART counter history, interactive and batch modules, resumable read-only surface scans, interface verification, optional transient systemd tasks, and safer data-only state parsing. It does not preserve v1 CLI or state compatibility: `-w/--wait` is ignored rather than waiting; back up host state before upgrading and restore matching state with an older script. The revised scoring below has synthetic, not real-HDD, coverage.

#### Fixed

- Recognize a newly completed first SMART self-test record; older, incomplete or wrong-type entries do not count as a completed new test.
- Recheck SMART/ATA/CRC after a complete assessment; show a numeric composite score only for completed, unexpired checks in one batch. Keep legacy, reused, interrupted, expired or post-interface-verification old results as historical/pending review with partial/unknown overall grade, without wiping earlier risks or refreshing the baseline when viewing reports. Separate resolved interface verification from old penalties: unknown first ATA totals retain a 5-point unresolved-risk deduction across checks (also for legacy records without the risk field); newly increased totals deduct 20, and unchanged historical counts are not new errors or proof of resolution. Interface verification alone cannot attribute old ATA errors to a repaired interface. Sparse slow surface reads prompt performance retesting rather than a bad-sector finding; surface read errors still deduct 40. Synthetic scoring-state tests pass; this revised code has not been tested on a real HDD.

### v1.0.0 — 2026-08-08

#### Added

- Initial 12-dimension HDD health check: device/interface data, SMART capability and overall verdict, ATA attributes or SAS defect/error counters, error and self-test logs, short/long self-test launch, lifespan/load, kernel I/O errors, mount and read-only detection, optional read-only `hdparm` benchmark and `badblocks` scan.
- Heuristic 0–100 score and four grades with process exit codes 0/1/2/3, SMART passthrough auto-detection, interactive and batch disk selection, and offered `apt` installation of missing `smartmontools`.
- The complete v1.0.0 design and usage documents remain in the `v1.0.0` Git tag (for example, `git show v1.0.0:DESIGN.md` and `git show v1.0.0:README.zh.md`); obsolete v1 commands are not current guidance.
