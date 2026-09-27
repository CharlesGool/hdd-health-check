---
name: third-party-notices
description: Third-party software and asset notices
metadata:
  version: "0.1.0"
  lang: en
---

# Third-party notices

This inventory records third-party material used by the optional Web UI.

## Multi-language

**English** | [简体中文](zh_cn/THIRD_PARTY_NOTICES.md) | [繁體中文](zh_tw/THIRD_PARTY_NOTICES.md) | [繁體中文(香港)](zh_hk/THIRD_PARTY_NOTICES.md) | [हिन्दी](hi/THIRD_PARTY_NOTICES.md) | [Español](es/THIRD_PARTY_NOTICES.md) | [العربية](ar/THIRD_PARTY_NOTICES.md) | [Français](fr/THIRD_PARTY_NOTICES.md)

## Documentation

- Project overview: [README](../README.md)
- Design rationale: [DESIGN](DESIGN.md)
- Release history: [LOG](LOG.md)
- Third-party inventory: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

The Web build bundles Vue (MIT), markdown-it (MIT), Lucide icons (ISC), and Tailwind CSS output (MIT). It self-hosts Inter, Noto Sans SC, Noto Sans Arabic, and Noto Sans Devanagari under the SIL Open Font License 1.1. License texts for Vue, Tailwind CSS, markdown-it, the icons and fonts are delivered under `web/public/licenses/` and included in the built UI. Build dependencies and exact versions are recorded in `web/package-lock.json`.

Runtime system tools (`smartctl`, `lsblk`, `dd`, `badblocks`, `systemd-run`) are obtained separately from the host and are not distributed by this repository. No upstream license or attribution is claimed on their behalf here. The project's own [MIT license](../LICENSE) is separate.
