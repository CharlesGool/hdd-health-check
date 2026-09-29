---
name: project-log
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: en
---

# hdd-health-check — Log

This record preserves accepted historical decisions, known limitations and release history. The current major-version release is `v4.0.0`. The user reports running the earlier `v2.2.0` code on a real machine, without device, environment or coverage details. The revised scoring has synthetic tests and Web verification on a Debian NAS, but no controlled complete assessment on real HDDs.

## Multi-language

**English** | [简体中文](zh-CN/LOG.md) | [繁體中文 (台灣)](zh-TW/LOG.md) | [繁體中文 (香港)](zh-HK/LOG.md) | [हिन्दी](hi/LOG.md) | [Español](es/LOG.md) | [العربية](ar/LOG.md) | [Français](fr/LOG.md)

## Documentation

- Project overview: [README](../README.md)

- Design rationale: [DESIGN](DESIGN.md)

- Release history: [LOG](LOG.md)

- Third-party notices: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Bugs

- [ ] The user reports testing v2.2.0 on a real machine, but did not provide device, environment or test-coverage details. Testing of root execution, package installation and systemd behavior is unconfirmed; previous v1.0.0 release checks also lacked a real HDD and SMART data (syntax and help only). The script was reportedly used before the original normalization, which is not a replacement for a controlled hardware test.
- [ ] The revised batch scoring and final SMART/ATA/CRC recheck have only synthetic test coverage, not real-HDD validation of this code. Firmware self-test log time resolution and cross-run resumed scans can produce partial/unknown coverage; historical errors cannot be automatically reattributed after repair. This hardware-validation limitation remains disclosed; authorized HDD retesting remains recommended.
- [ ] Heuristic health weights are not calibrated failure probabilities; SAS/SCSI scoring is less exercised than ATA and USB/RAID SMART passthrough may fail. Vendor-dependent temperature reporting is incomplete.
- [ ] The authenticated Web UI and LAN service were checked on a Debian NAS with real disk inventory, but a complete assessment on real HDDs and recovery after a reboot remain unverified. Nonconforming pre-existing v2.2 state is rejected. CSV export is not provided.
- [x] v1.0.0 normalization corrected clone instructions pointing to the nonexistent `hdd-health-check-repo/main` path and mixed Traditional Chinese characters in the Simplified Chinese README.

## Limitations

- The installed Debian service keeps its existing `/root/apps/hdd-health-check/web/` host layout for upgrade compatibility; the source layout is `src/web/` with generated output in `dist/web/`.

### Compatibility entry points

Baseline: `35f24e5`
Reason: existing CLI commands and installation instructions invoke the repository-root shell entry point; the implementation now lives under `src/checker/`.
Update boundary: retain the root dispatcher until a separately communicated CLI path migration replaces the established command.

- `hdd-health-check.sh` -> `src/checker/hdd-health-check.sh`

## Decisions

| Decisions | Reasons |
| --- | --- |
| 2026-08-12: Split the local project into a Git working tree and separate snapshots; reject a flat local layout. | Historical release snapshots needed separation from tracked source. The then-current `main/` naming was local only and never part of the GitHub checkout; tags and `git archive` snapshots were planned. |
| 2026-08-13: Rename local `main/` to `repo/`; repair install paths, bilingual headers and `.gitignore`; keep private mirror and snapshot paths out of public status. Reject committing the stale staged docs unchanged. | The GitHub checkout places the script at its root. Old snippets would fail immediately after cloning; local paths and translation errors did not belong in public documentation. |
| 2026-08-13: Do not simulate a real-HDD release check on the available virtual disk; disclose the weaker validation. | No usable SMART hardware or `smartmontools` was available; installing packages to scan a virtual disk would not test HDD logic. |
| 2026-08-13: Replace the public v1.0.0 history with one clean noreply-identity commit and annotated tag, retaining the original history in a private renamed archive; reject force-pushing the prior public repository or preserving its superseded intermediate commit. | The prior public commit contained a personal email in Git metadata. Existing clones/forks do not migrate automatically and prior exposure cannot be guaranteed erased from caches. This is historical, not authorization for another rewrite. |
| Current integration: Adopt the supplied v2.2.0 behavior without v1 compatibility guarantees and retain the existing MIT license. | The new script adds persistent state and optional background tasks; `-w` is ignored. At integration time, no release, tag or hardware validation was claimed. |

## Handoff

2026-09-29. Branch `main`; the `v4.0.0` release is published. No temporary project rules were found.

- NAS installer follow-up: the first NAS run of `test-bf14ed5` started the new service, but its health probe received HTTP 403 because it omitted the required `X-HDD-CSRF` header. The installer then reported failure without rolling back because its `die` path bypassed the rollback trap. The service remained active and the prior application remained available. Commit `cd7d69b` adds the header and calls rollback for explicit errors after installation starts. A fresh installation of `test-cd7d69b` then passed the installer health check. The service is active and enabled on `0.0.0.0:8765`; the installer preserved the previous application and unit backups. The Web password matched the previous backup, and `/var/lib/hdd-health` and `/var/log/disk-health` remained in place.

- Completed: reorganized the source into `src/checker/` and `src/web/`, moved generated Web output to `dist/web/`, retained the root CLI compatibility entry point, updated installer and test paths, and standardized locale directory names and document navigation. Source installs still copy into the existing Debian service layout. The UI now offers eight accent presets and light/dark modes in ordinary Settings, persists them independently, and uses a real Changelog link in top navigation.
- Security: added a dedicated Security Settings page with a server-enforced five-minute administrator-password verification window. Verification rotates the session; an IP-only session cannot read or change the allowlist or password. Password change requests only the new password and confirmation during that window and invalidates all sessions. IP admission has an enable switch, accepts only exact RFC 1918 IPv4 or ULA IPv6 addresses, rejects disallowed legacy entries, uses the connection peer rather than client-supplied forwarding headers, and checks the original Host/Origin and a same-origin request header for mutations.
- Privacy and version: snapshot and SMART responses now mask serials; an authenticated reveal request retrieves a full serial only on explicit user action, and the view clears it when hidden or closed. The version link sits beside the project name and opens Changelog; an untagged build uses a `test-<sha>` marker and serves the same value at `/api/build`.
- Unreleased behavior: SSD/NVMe full assessments run quick SMART, short/long self-tests and a full read-only scan without speed sampling. Clean completed batches score 100; slow reads alone do not deduct points. Batch choices follow selected disk types; capacity and SSD host writes can switch decimal/binary units, and a sleeping HDD can be woken individually. Synthetic tests passed, with no real full-disk assessment started for this update.
- Checks: Vue type check and production build passed. All shell and Python Web tests passed, including IP admission, permission expiry, session rotation, password change, serial reveal and masking. The theme checker passed all eight accents in both modes. Multilingual, document format (zero errors, eight warnings), local-link and project structure checks passed after browser artifacts were moved out of the source root. Shell syntax, Python compilation and `git diff --check` passed. Local Chromium showed the Security Settings page and responsive dark-mode appearance settings at 390 px with no horizontal overflow; direct Changelog navigation rendered the v3.0.0 section first. The isolated browser harness returned expected 503 responses for disk status because it has no checker process. The final review also changed source-archive builds to use a `test-archive-<package version>` marker instead of a bare release version.
- NAS verification: the installed `/api/build` matched the `test-cd7d69b` artifact. Password login, rejection of unauthenticated Security Settings, administrator verification, session rotation, protected allowlist read and serial masking in a 13-disk snapshot passed. The LAN Security page and favicon returned HTTP 200; an unauthenticated LAN request to the ordinary and protected APIs returned 401. An authenticated Chromium session opened Security Settings and showed the saved IP controls and password-change form; at 390 px, document scroll width equaled the viewport width. The browser session was closed and its local temporary password file removed. No disk scan, password change or reboot was run. The installed test build is not a formal release.
- Release-time status: service recovery after a real reboot and a controlled full assessment on real HDDs remained unverified. The root compatibility entry point is recorded with its pre-move baseline under Limitations. At publication, the NAS ran `test-cd7d69b`; that release task did not deploy the formal build.
- Release: `main` and `feat/standards-alignment` were pushed at `3cf9da0`. The annotated `v4.0.0` tag points to that commit, and the formal GitHub Release includes the 6,697,392-byte prebuilt Web archive and `SHA256SUMS`; the archive SHA-256 is `491a0c61a99525f9a293b1b49c2de500e47c7b60e20bad5c4e955ecc048121d4`. The `../snapshots/v4.0.0` source snapshot was exported, and the complete Changelog was verified on the project's Notion child page under `My Projects`.
- Release checks: all shell and Python tests, Vue type checking, production build, document and link checks, multilingual and project structure checks passed. The production build from the exact `v4.0.0` tag served `/api/build`, `version.json`, the main and deep routes, and the favicon with matching `v4.0.0` metadata. Document checking reported zero errors and eight existing English-language warnings. No real disk scan, password change or reboot was performed for the release.
- Translation recovery: all seven core-document translations were resynchronized with current English, including Handoff and Commit History, under the documented recovery rule. Structural and protected-token checks passed; the English release documents and translations were committed together.
- Web design alignment: the login header and card now use the shared dimensions. The login-card footer contains the build-version Changelog link and a language selector available before authentication. Login, administrator-verification, new-password and confirmation fields each start masked and have an independent labeled show/hide control with a 44 px touch target. The controls preserve input values without moving focus; language and password-control labels cover all eight UI languages. No NAS deployment was made for this change.
- Web checks: Vue type checking and production build passed in a separate local build tree. In local Chromium, the login layout had no page-level horizontal overflow at 1280 px and 320 px; Chinese and Arabic login layouts, English language persistence, a failed-login error, login password toggling, and independent new/confirmation password toggles were checked. The isolated server could not read real disk data because its checker was not run as root; that expected API error was outside the login-layout check. Document and project checks are recorded with this handoff commit.
- Changelog navigation follow-up: the login-card version link now opens the bundled Changelog for an unauthenticated visitor; that page shows the linked version beside the brand and a labeled Changelog navigation entry. Local Chromium followed the version link, rendered the v4.0.0 entry, and returned to login. Unauthenticated `/api/build`, `/api/access`, and `/api/snapshot` requests still returned 401. Vue type checking and production build passed after this change.
- NAS UI deployment: built current `main` commit `2e6201e` as `test-2e6201e` in a clean local checkout. Vue type checking and production build passed, and the transferred archive checksum matched. The Debian installer upgraded the existing LAN service on port 8765, preserving the Web password and timestamped application and unit backups. The service is active and enabled; the existing state and log directories remain in place. Authenticated `/api/build` returned `test-2e6201e`, `/api/snapshot` listed 13 disks, the LAN disk and Changelog pages returned HTTP 200, and unauthenticated `/api/build` returned 401. LAN Chromium showed the revised login page with its version link and language selector, then followed the version link to the v4.0.0 Changelog entry. No disk scan, password change or reboot was performed.
- Version and Changelog follow-up: added the post-v4.0.0 Web changes to the English Changelog and all seven translated Changelogs, and synchronized their older Handoff and Commit History sections with the English source through commit `3c3451f`. The clean build embeds `test-3c3451f`; Vue type checking and production build passed. Multilingual, project structure, document format, local-link and diff checks passed; document format reported one existing warning for language names in the English navigation. The transferred package checksum matched. The NAS installer retained the Web password, application and unit backups, and the existing state and log directories. The service is active and enabled on port 8765; authenticated `/api/build` returned `test-3c3451f`, `/api/snapshot` listed 13 disks, the LAN disk and Changelog pages returned HTTP 200, and unauthenticated `/api/build` returned 401. LAN Chromium showed the same version on the login card and Changelog page, with the new Simplified Chinese entry above v4.0.0. No disk scan, password change or reboot was performed.
- Web design standardization on `main`: the authenticated header now has linked brand/version and Home, Changelog, Settings, Sign out in the prescribed order; each child page has a Back control. Settings and protected Security use responsive section navigation, each route has a distinct matching favicon, and the login card always offers IP access with a server-checked error path. Appearance contains a Beta page-transition switch with persistent choice and a mobile-off default; browser history, viewport resize and reduced motion are handled separately. The exact test build identifier heads a localized candidate Changelog entry in all eight UI languages, followed by formal versions; the English Changelog no longer carries an unversioned post-release section. Existing `v4.0.0` tag and Release are unchanged.
- Local verification for this Web change: Vue type checking and production build passed in an isolated build tree. Chromium checked the Settings and Security layouts at desktop and 390 px, each language's candidate entry above `v4.0.0`, favicon changes, browser Back/Forward, the page-motion off path without calling View Transitions, the enabled path, and repeated resizes from 320 to 1280 px without horizontal overflow or a persistent transform. The multilingual and project structure checkers passed; document and local-link checks passed with zero errors and five format warnings in the three checked English documents. No real mobile-browser visual transition check was run.
- NAS deployment of `test-c7b6252`: a clean checkout of commit `c7b6252` passed Vue type checking and production build; `version.json` embedded the same test marker. The transferred package SHA-256 matched `afe858f9ba2a9e8ea19964bc98382f4068085fd5b042fb76f971fc3e54bc6ceb`. The installer upgraded `/root/apps/hdd-health-check`, kept the Web password unchanged, and retained application backup `/root/apps/hdd-health-check.backup-20260929-012509-2525461` and matching service-unit backup. Existing `/var/lib/hdd-health` and `/var/log/disk-health` were not modified by the package. The service is active and enabled under systemd, listening on `0.0.0.0:8765`; a reboot was not performed. Authenticated `/api/build` returned `test-c7b6252`; logout then made `/api/build` return 401. LAN requests for disk, Settings, Security and Changelog routes and their icon assets returned HTTP 200, while unauthenticated `/api/build` returned 401. Live Chromium showed the login card version, always-visible IP action and its denied-address guidance, then opened the exact test Changelog entry followed by `v4.0.0`; the 390 px Changelog had no horizontal overflow. No disk scan, password change or reboot was performed. No temporary project rules were found.
- Web UI reference v1.2.3 migration on `main`: mapped login, Dashboard, Attention, Tasks, Schedule, Settings, Security, Changelog, and disk detail to the tagged AI-Configs reference. Imported the tagged reference stylesheet, adapted the common header, content width, dashboard cards, settings navigation and cards, forms, switch and private-value states, localized release cards, theme transitions, and route/resize motion. Added the page mapping and the business, permission, and browser differences to `doc/DESIGN.md`. Existing API calls and server-side permissions were not changed. All eight Web locale catalogs gained matching labels and descriptions. No temporary project rules were found.
- UI migration checks: an isolated clean build tree passed Vue type checking and production build. The theme checker passed eight palettes in both modes; multilingual, project structure and local-link checks passed. Document format found zero errors and four existing warnings in the checked English files. Chromium at 1280 × 800 compared the reference and target login, Dashboard, Attention, Tasks, Schedule, Settings, Security and Changelog views; Settings used the same 192 px sidebar and 856 px card, and Changelog used full-width cards. Dark/teal switching persisted and a 390 px Settings view had no horizontal overflow. A mocked one-disk API verified the detail drawer, tab switching, explicit serial reveal and clearing on close. Static preview and mocked data do not establish live NAS behavior, a real disk scan, password change, or reboot recovery.
- Test-host deployment follow-up: the first `test-486be47` install exposed a systemd unit omission: after restart, `/var/lib/hdd-health` changed from mode 700 to 755. Its mode was immediately restored, and commit `ce70010` added `StateDirectoryMode=0700`. A clean build of `ce70010` passed Vue type checking and production build, embedded `test-ce70010`, and was installed from a checksum-matched archive (SHA-256 `e809016f4bd5e01bb5ae3eefcc6c8e1893addf5daec4d796a283c0802b184aa4`). The installer retained the prior application at `/root/apps/hdd-health-check.backup-20260929-111224-3324946` and the matching service-unit backup. The service is active and enabled on `0.0.0.0:8765`; the installed unit explicitly keeps the state directory at mode 700 after restart. The Web password file remains mode 600 with its previous checksum, and existing state and log paths remain in place. LAN routes for disks, attention, tasks, schedule, Settings, Security, Changelog and icon assets returned HTTP 200. Unauthenticated protected APIs returned 401; password login returned `test-ce70010` from `/api/build`, 13 serial-masked disks from `/api/snapshot`, and an idle task status. Logout restored 401. Live Chromium showed `test-ce70010` on the login card and atop the Changelog, followed by `v4.0.0`. No disk scan, password change, or reboot was performed. This is a test build, not a new formal release.
- Disk-detail refinement: reserved a stable scrollbar gutter to reduce the small final shift when opening cards. The administrator verification card now spans the Security page content width while its form remains readable. Disk cards link to full detail pages at `/disks/:id` or `/attention/:id`, with browser history, direct reload and narrow-screen layout. A serial button toggles its masked/full value without extra show/hide text; copying appears only after authenticated reveal and supports the LAN HTTP clipboard fallback. SMART attributes have localized hover/focus explanations and a note about vendor-dependent values. SSD/NVMe facts show host reads as well as writes when NVMe Data Units or ATA Device Statistics supply known units. The candidate Changelog describes the new detail and SMART behavior in all eight Web languages; the formal `v4.0.0` record remains historical.
- Local checks for this refinement: a clean isolated Vue type check and production build passed. `tests/web-smart.py` and Python compilation passed; multilingual and project-structure checks found zero errors. Focused document and local-link checks found zero errors and five existing document warnings. In mocked Chromium, a disk detail used its own URL, survived reload, supported browser Back/Forward, masked/revealed/copied/hid its serial, and had no horizontal overflow at 390 px. The HTTP clipboard fallback was exercised. A Security challenge card measured 1,072 px within a 1,120 px main frame at 1280 px viewport and had no 390 px overflow. The mocked disk is not hardware evidence. No temporary project rules were found.
- First test-host pass for `test-aa183e4`: built from clean commit `aa183e4`; the transferred package checksum matched SHA-256 `fe2ebb97a1524a93f83942d1e157c256185575bbfd6fb34101ba65f714d50605`. The installer retained `/root/apps/hdd-health-check.backup-20260929-114536-3447848` and the matching service-unit backup. The service is active/enabled on `0.0.0.0:8765`; `/var/lib/hdd-health` remains mode 700 and the unchanged Web password file mode 600. LAN pages and a direct disk-detail route returned 200; protected APIs returned 401 before login. Authenticated `/api/build` returned `test-aa183e4`; the snapshot listed 13 serial-masked disks and one real NVMe SMART detail supplied both read and write totals. Logout restored 401. Live Chromium showed the same login and Changelog version, full disk detail, localized SMART guidance, and successful reveal/copy/hide on LAN HTTP. A 390 px detail view had no horizontal overflow. Four NVMe table keys still used generic help; this follow-up maps them to specific explanations. No scan, password change, or reboot was performed.
- Corrected test-host deployment: built clean commit `f0b58be` with Vue type checking and production build; `version.json` embedded `test-f0b58be`. The 6,532,350-byte archive matched SHA-256 `96a029b49dc9a09bb2b1edad414c682dffb8ef357c2e9d6ee55c9721af7c78e5` before installation. The installer retained `/root/apps/hdd-health-check.backup-20260929-115210-3485325` and the matching service-unit backup. The service is active/enabled on `0.0.0.0:8765`, with the state directory at mode 700 and the unchanged password file at mode 600. LAN disk, direct detail, Security and Changelog routes returned 200; protected APIs returned 401 before and after an authenticated session. During that session, `/api/build` returned `test-f0b58be`, the snapshot listed 13 serial-masked disks, and a real NVMe SMART response supplied both read and write totals. Live Chromium showed the matching login and Changelog marker, both new candidate notes, a full detail page, specific help for the previously generic NVMe counters, and no horizontal overflow at 390 px. The reserved scrollbar gutter kept document width stable across a card route transition; the route-cover and animation classes cleared after it settled. The first installed build's LAN HTTP serial reveal/copy/hide flow passed; the correction changed only explanatory labels. Browser sessions were closed. No scan, password change, or reboot was performed.
- Disk detail interaction follow-up: copy feedback now temporarily changes its button icon to a checkmark while keeping the success toast. The toast is larger and has enter/exit motion. Both the page Back button and browser Back return with a reverse page slide so the disk model is not stretched into a narrow card. The SMART/Checks accent indicator slides between tabs, and the SMART table has clearer rows, values and focusable help icons with floating explanations. The administrator verification and password-change form content is centered and fills its readable column. `doc/DESIGN.md` records the detail-return difference from the reference. No API or permission behavior changed.
- Local checks for this follow-up: Vue type checking and production build passed in an isolated build tree; `tests/web-smart.py`, multilingual and project structure checks passed. Focused document and local-link checks found zero errors and five existing document warnings. Mocked Chromium verified the temporary copy checkmark and toast, SMART help on hover, tab state, both Back paths and cleared route-animation state. At 390 px, the settled disk detail and Security pages had no page-level horizontal overflow. The mocked disk does not establish live hardware behavior; no temporary project rules were found.
- Test-host deployment of `test-b6a0ba7`: built from clean commit `b6a0ba7`; Vue type checking and production build passed and `version.json` embedded that exact marker. The transferred archive checksum matched SHA-256 `81aedb34c94bd607e76025c28927c0f221511f79cf418c0e1800108d50956afe`. The installer retained `/root/apps/hdd-health-check.backup-20260929-120631-3533408` and a matching service-unit backup. The Web service is active and enabled on `0.0.0.0:8765`; `/var/lib/hdd-health` remains mode 700 and the existing Web password file mode 600 with the same checksum as the backup. LAN disk and detail routes returned 200, and an unauthenticated build API returned 401. An authenticated build API returned `test-b6a0ba7`, a snapshot listed 13 serial-masked disks, and a real NVMe SMART response supplied both host read and write totals. Live Chromium confirmed the temporary copy checkmark and toast, SMART explanations, tab indicator, and reverse slide on Back with no remaining cover or motion class. The visible Changelog and version link showed `test-b6a0ba7`; at 390 px, the detail, Security and Changelog pages had no horizontal overflow. No disk scan, password change or reboot was performed.
- Disk-return and toast correction: frame captures found that the reverse slide visibly split the detail and Dashboard, while Home from detail briefly shrank the Dashboard into an illegible miniature. Detail-to-listing and detail-to-Dashboard navigation now fades the full-size pages in sequence, including the Back button, Home/brand/breadcrumb links and browser history; other routes keep their existing motion. Toasts now close automatically after 4.2 seconds and still have a manual close action. The Web UI instruction received a narrowly scoped exception for data-rich detail routes absent from the reference, and `doc/DESIGN.md` records the difference. Local Vue type checking and production build passed. Mocked Chromium checked intermediate return frames, browser Back/Forward, Home/history paths, motion-off behavior, and timed toast removal; temporary route classes and covers cleared. Deployment to the test host remains pending; no temporary project rules were found.
- Remaining: observe service recovery after a real reboot when convenient. A controlled full assessment on real HDDs remains unverified. The root compatibility entry point is recorded with its pre-move baseline under Limitations.
- Next action: build this fix from its clean commit, deploy to the existing test Web service, and verify the live return frames and toast timing. Reboot recovery and a controlled HDD assessment remain separate operational checks. The published `v4.0.0` tag and release remain unchanged.

## Historical Source Baselines

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

## Changelog

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

### v1.0.0 — 2026-08-08

#### Added

- Initial 12-dimension HDD health check: device/interface data, SMART capability and overall verdict, ATA attributes or SAS defect/error counters, error and self-test logs, short/long self-test launch, lifespan/load, kernel I/O errors, mount and read-only detection, optional read-only `hdparm` benchmark and `badblocks` scan.
- Heuristic 0–100 score and four grades with process exit codes 0/1/2/3, SMART passthrough auto-detection, interactive and batch disk selection, and offered `apt` installation of missing `smartmontools`.
- The complete v1.0.0 design and usage documents remain in the `v1.0.0` Git tag (for example, `git show v1.0.0:DESIGN.md` and `git show v1.0.0:README.zh.md`); obsolete v1 commands are not current guidance.

## Commit History

Complete primary-branch history: `git log main --stat`. The `HEAD` entry identifies this handoff commit.

- 2026-09-29 | intended | `fix(web): correct disk return and toast timing` | this commit
- 2026-09-29 | `8633851` | `docs(handoff): record disk detail UI deployment` | `git show 8633851`
- 2026-09-29 | `b6a0ba7` | `fix(web): refine disk detail feedback and motion` | `git show b6a0ba7`
- 2026-09-29 | `c289147` | `docs(handoff): record final disk UI test deployment` | `git show c289147`
- 2026-09-29 | `f0b58be` | `fix(web): explain NVMe SMART counters` | `git show f0b58be`
- 2026-09-29 | `aa183e4` | `feat(web): expand disk details and SMART guidance` | `git show aa183e4`
- 2026-09-29 | `dd4cd84` | `docs(handoff): record corrected test deployment` | `git show dd4cd84`
- 2026-09-29 | `ce70010` | `fix(deploy): keep HDD state directory private` | `git show ce70010`
- 2026-09-29 | `486be47` | `feat(web): migrate UI to reference v1.2.3` | `git show 486be47`
- 2026-09-29 | `d52366b` | `docs(handoff): record NAS Web design deployment` | `git show d52366b`
- 2026-09-29 | `c7b6252` | `feat(web): align pages with current design standard` | `git show c7b6252`
- 2026-09-28 | `c0e7ae7` | `docs(handoff): record version and Changelog deployment` | `git show c0e7ae7`
- 2026-09-28 | `3c3451f` | `docs(changelog): record latest Web update` | `git show 3c3451f`
- 2026-09-28 | `0a91897` | `docs(handoff): record NAS UI deployment` | `git show 0a91897`
- 2026-09-28 | `2e6201e` | `fix(web): open changelog before login` | `git show 2e6201e`
- 2026-09-28 | `c38e6d6` | `fix(web): align login with updated design rules` | `git show c38e6d6`
- 2026-09-28 | `df35b42` | `docs(handoff): record v4.0.0 publication` | `git show df35b42`
- 2026-09-28 | `3cf9da0` | `chore(release): prepare v4.0.0` | `git show 3cf9da0`
- 2026-09-28 | `ebf6e39` | `docs(handoff): record NAS browser verification` | `git show ebf6e39`
- 2026-09-28 | `0b5f053` | `docs(handoff): record NAS installer and security verification` | `git show 0b5f053`
- 2026-09-28 | `cd7d69b` | `fix(deploy): verify authenticated service with CSRF header` | `git show cd7d69b`
- 2026-09-28 | `bf14ed5` | `feat(web): align project layout and security settings` | `git show bf14ed5`
- 2026-09-28 | `35f24e5` | `docs(handoff): record NAS Web update verification` | `git show 35f24e5`
- 2026-09-28 | `a6086ff` | `feat(web): unify history and add per-disk standby` | `git show a6086ff`
- 2026-09-28 | `f5f5dc7` | `docs(handoff): record SSD assessment deployment` | `git show f5f5dc7`
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
