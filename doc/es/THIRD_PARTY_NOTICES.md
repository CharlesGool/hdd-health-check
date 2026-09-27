---
name: third-party-notices-es
description: Third-party software and asset notices
metadata:
  version: "0.1.0"
  lang: es
---

# Avisos de terceros

Este inventario registra el material de terceros utilizado por la interfaz Web opcional.

## Multi-language

[English](../THIRD_PARTY_NOTICES.md) | [简体中文](../zh_cn/THIRD_PARTY_NOTICES.md) | [繁體中文](../zh_tw/THIRD_PARTY_NOTICES.md) | [繁體中文(香港)](../zh_hk/THIRD_PARTY_NOTICES.md) | [हिन्दी](../hi/THIRD_PARTY_NOTICES.md) | **Español** | [العربية](../ar/THIRD_PARTY_NOTICES.md) | [Français](../fr/THIRD_PARTY_NOTICES.md)

## Documentation

- Presentación del proyecto: [README](README.md)
- Fundamentos de diseño: [DESIGN](DESIGN.md)
- Historial de versiones: [LOG](LOG.md)
- Inventario de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

La compilación Web incluye Vue (MIT), los iconos Lucide (ISC) y la salida de Tailwind CSS (MIT). Aloja localmente Inter, Noto Sans SC, Noto Sans Arabic y Noto Sans Devanagari bajo la SIL Open Font License 1.1. Los textos de licencia de los iconos y las fuentes se distribuyen en `web/public/licenses/` y se incluyen en la interfaz compilada. Las dependencias de compilación y sus versiones exactas se registran en `web/package-lock.json`.

Las herramientas del sistema utilizadas durante la ejecución (`smartctl`, `lsblk`, `dd`, `badblocks`, `systemd-run`) se obtienen por separado del equipo anfitrión y este repositorio no las distribuye. Aquí no se reivindica ninguna licencia ni atribución en nombre de sus respectivos proveedores. La [licencia MIT](../../LICENSE) propia del proyecto es independiente.

La compilación Web también incluye markdown-it (MIT) para mostrar el historial en Markdown; su licencia está en `web/public/licenses/Markdown-It-MIT.txt`.
