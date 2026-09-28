---
name: third-party-notices-es
description: Third-party software and asset notices
metadata:
  version: "0.1.0"
  lang: es
---

# Avisos de terceros

Este inventario registra el material de terceros utilizado por la interfaz Web opcional.

## Multilingüe

[English](../THIRD_PARTY_NOTICES.md) | [简体中文](../zh-CN/THIRD_PARTY_NOTICES.md) | [繁體中文(台灣)](../zh-TW/THIRD_PARTY_NOTICES.md) | [繁體中文(香港)](../zh-HK/THIRD_PARTY_NOTICES.md) | [हिन्दी](../hi/THIRD_PARTY_NOTICES.md) | **Español** | [العربية](../ar/THIRD_PARTY_NOTICES.md) | [Français](../fr/THIRD_PARTY_NOTICES.md)

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Historial de versiones: [LOG](LOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Avisos de terceros

La compilación Web incluye Vue (MIT), markdown-it (MIT), iconos Lucide (ISC) y la salida de Tailwind CSS (MIT). Aloja localmente Inter, Noto Sans SC, Noto Sans Arabic y Noto Sans Devanagari bajo la SIL Open Font License 1.1. Los textos de licencia de Vue, Tailwind CSS, markdown-it, los iconos y las fuentes se distribuyen en `src/web/public/licenses/` y se incluyen en la interfaz compilada. Las dependencias y sus versiones exactas se registran en `src/web/package-lock.json`.

Las herramientas del sistema utilizadas durante la ejecución (`smartctl`, `lsblk`, `dd`, `badblocks`, `systemd-run`) se obtienen por separado del equipo anfitrión y este repositorio no las distribuye. Aquí no se reivindica ninguna licencia ni atribución en nombre de sus respectivos proveedores. La [licencia MIT](../../LICENSE) propia del proyecto es independiente.
