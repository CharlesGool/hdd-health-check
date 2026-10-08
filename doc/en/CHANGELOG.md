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

This restates formal changes for existing versions; no new version is created for this round of documentation work. Dates come from existing tags or GitHub Releases; early tags have no corresponding GitHub Release page.

### v4.1.0 — 2026-09-29

#### Added

- Extended disk details, SMART attribute descriptions, and supported SSD host read/write volume display.
- Updated Web appearance, themes, and control feedback; provided icons for different pages.

#### Changed

- Login page displays version, language, and a standalone password-show control; changelog is readable before login.

#### Fixed

- Corrected measured positioning of the detail tab underline; maintained private permissions on the Web state directory.

### v4.0.0 — 2026-09-28

#### Added

- Standalone recent admin verification, password update, precise private IP access control, and background task history.
- Full SSD/NVMe evaluation and single-disk wake/standby operations.

#### Changed

- Source moved into `src/checker/` and `src/web/`; frontend artifacts moved into `dist/web/`.
- Mixed-disk batch checks use the union of supported modules; HDD-specific checks skip SSD.

### v3.0.0 — 2026-09-27

#### Added

- Python Web service, Vue UI, scheduled quick checks, SMART history, and Debian installer.
- Structured disk snapshots, Web task receipts, and `--no-install` control.

### v2.3.0 — 2026-09-24

#### Added

- Per-disk results and history, resumable reads, post-repair interface rechecks, batch processing, and systemd background tasks.

#### Changed

- Only complete, valid checks belonging to the same batch produce a current composite score; old results remain as historical evidence.

#### Fixed

- State is parsed by known data fields, avoiding execution of persisted records as Shell code.

### v1.0.0 — 2026-08-13

#### Added

- SMART attributes, errors and self-test logs, mount and kernel error checks, read-only speed testing, and badblocks scanning.
- Interactive/batch disk selection, 0–100 heuristic scoring, logging, and exit codes.
