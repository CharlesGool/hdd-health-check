---
name: project-log-en
description: Project defects, limitations, decisions, and handoff
metadata:
  version: "1.0.0"
  lang: "en"
---

# Log

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

- [History](HISTORY.md)
- [Changelog](CHANGELOG.md)

## Bugs

- [ ] Full HDD evaluation and NAS reboot recovery lack completed controlled verification. Synthetic tests and UI screenshots cannot substitute for hardware testing.
- [ ] USB/RAID SMART passthrough and SAS/SCSI vendor data coverage is limited; it cannot be guaranteed that all devices provide the same fields.
- [ ] Firmware self-test log time precision may make newly completed records difficult to distinguish; in such cases the result is conservatively shown as incomplete or unknown.

## Limitations

- The health score is a heuristic metric, not calibrated as a failure probability; SSD/NVMe use current check rules and do not represent vendor lifespan guarantees.
- The Bash terminal and persisted check summaries retain Simplified Chinese literal output; vendor raw diagnostics are not translated; Web controls support eight languages. Changing state text and CLI recognition logic requires a separate compatibility migration.
- The installer supports only Debian and a fixed application/service layout. Default LAN HTTP does not encrypt credentials and is intended only for a trusted local network or SSH tunnel.
- No v1 CLI/state migration guarantee is provided; old v2.2 state that does not conform to the current format is rejected.

## Decisions

| Date | Decision | Status | Rationale |
| --- | --- | --- | --- |
| 2026-10-08 | Root and `doc/` are Simplified Chinese source docs; translations retain only `en` and `es` | Accepted | User requested removal of old docs and complete rewrite per the current template. |
| 2026-10-08 | Other UI languages fall back to English for changelog entries | Accepted | Preserves compatibility between eight UI languages and the new doc layout. |
| 2026-10-08 | Introduction screenshots come from a synthetic demo, saved per language | Accepted | Showcases the current build while avoiding exposure of real devices or credentials. |
| 2026-10-08 | Retain published tags, root CLI entry points, and matching state backup requirements | Accepted | Rewriting docs does not modify existing release history or data interfaces. |

## Handoff

[简体中文](../LOG.md#交接)
