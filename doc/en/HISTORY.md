---
name: project-history-en
description: History
metadata:
  version: "1.0.0"
  lang: "en"
---

# History

## Multi-language

[简体中文](../HISTORY.md) | **English** | [Español](../es/HISTORY.md)

## Documentation

- Project overview: [README](README.md)

- Design rationale: [DESIGN](DESIGN.md)

- Project status: [LOG](LOG.md)
- Historical records: [HISTORY](HISTORY.md)
- Version changelog: [CHANGELOG](CHANGELOG.md)

- Third-party notices: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)


## Historical Records

| Date | Requirement or decision | Status and evidence at the time |
| --- | --- | --- |
| 2026-08-13 | Published the first HDD checker and normalized directories | `v1.0.0` tag retains the initial source; at the time only syntax and help checks were completed, with no controlled HDD/SMART verification. |
| 2026-09-24 | Integrated persisted results, history, background tasks, and batch scoring | `v2.3.0` tag contains the early v2.2 integration; scoring and state use synthetic tests, with no v1 compatibility promise. |
| 2026-09-27 | Introduced the Python/Vue Web controller | `v3.0.0` tag saves the original `web/` layout; history records report authentication service and real disk inventory verification on a Debian NAS; full HDD evaluation and reboot recovery were still incomplete. |
| 2026-09-28 | Updated Web security, SSD evaluation, and source layout | `v4.0.0` GitHub Release published; recent admin verification, IP privilege separation, and task history included in the release. |
| 2026-09-29 | Updated Web appearance, disk details, and tab positioning | `v4.1.0` GitHub Release published; real HDD and reboot verification still incomplete. |
| 2026-09-29 | Removed page transitions | `5b8e2db` completed immediate navigation; the old back-navigation animation is no longer a current feature. |
| 2026-10-08 | Aligned project spec, fixed read-environment determination and login rate limiting | `a228d8d`, `0d0564f`, `2184495` committed and pushed normally; clean-checkout CI passed; no deployment or new Release was created. |

Old requirements, original completion status, and full source can be traced via `git log` and the tags above. This table is a summary reorganized based on Git and recorded verification scope; it does not expand historical NAS checks into comprehensive hardware verification.
