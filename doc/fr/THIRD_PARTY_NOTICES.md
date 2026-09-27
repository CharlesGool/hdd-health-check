---
name: third-party-notices-fr
description: Third-party software and asset notices
metadata:
  version: "0.1.0"
  lang: fr
---

# Avis relatifs aux tiers

Cet inventaire recense les composants tiers utilisés par l’interface Web facultative.

## Multi-language

[English](../THIRD_PARTY_NOTICES.md) | [简体中文](../zh_cn/THIRD_PARTY_NOTICES.md) | [繁體中文](../zh_tw/THIRD_PARTY_NOTICES.md) | [繁體中文(香港)](../zh_hk/THIRD_PARTY_NOTICES.md) | [हिन्दी](../hi/THIRD_PARTY_NOTICES.md) | [Español](../es/THIRD_PARTY_NOTICES.md) | [العربية](../ar/THIRD_PARTY_NOTICES.md) | **Français**

## Documentation

- Présentation du projet : [README](README.md)
- Conception : [DESIGN](DESIGN.md)
- Historique des versions : [LOG](LOG.md)
- Inventaire des composants tiers : [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

La compilation Web inclut Vue (MIT), les icônes Lucide (ISC) et la sortie de Tailwind CSS (MIT). Elle héberge localement Inter, Noto Sans SC, Noto Sans Arabic et Noto Sans Devanagari sous SIL Open Font License 1.1. Les textes des licences des icônes et des polices sont fournis dans `web/public/licenses/` et inclus dans l’interface compilée. Les dépendances de compilation et leurs versions exactes figurent dans `web/package-lock.json`.

Les outils système utilisés à l’exécution (`smartctl`, `lsblk`, `dd`, `badblocks`, `systemd-run`) sont obtenus séparément sur l’hôte et ne sont pas distribués par ce dépôt. Aucun avis de licence ou d’attribution provenant de leurs projets d’origine n’est revendiqué ici en leur nom. La [licence MIT](../../LICENSE) propre au projet est distincte.

La compilation Web inclut aussi markdown-it (MIT) pour afficher l’historique en Markdown ; sa licence figure dans `web/public/licenses/Markdown-It-MIT.txt`.
