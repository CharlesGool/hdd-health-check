---
name: project-log-es
description: Defectos, limitaciones, decisiones y traspaso del proyecto
metadata:
  version: "1.0.0"
  lang: "es"
---

# Registro

## Multilingüe

[简体中文](../LOG.md) | [English](../en/LOG.md) | **Español**

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Estado del proyecto: [LOG](LOG.md)
- Registros históricos: [HISTORY](HISTORY.md)
- Historial de cambios: [CHANGELOG](CHANGELOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)


## Registros

- [Historial](HISTORY.md)
- [Registro de cambios](CHANGELOG.md)

## Errores

- [ ] La evaluación completa de HDD real y la recuperación tras reinicio de NAS no han completado verificación controlada. Las pruebas sintéticas y capturas de interfaz no sustituyen pruebas de hardware.
- [ ] La cobertura de reenvío SMART por USB/RAID y datos de fabricante SAS/SCSI es limitada, no se garantiza que todos los dispositivos proporcionen los mismos campos.
- [ ] La precisión de tiempo del registro de autoprueba de firmware puede dificultar distinguir registros recién completados, en cuyo caso se muestra conservadoramente incompleto o desconocido.

## Limitaciones

- La puntuación de salud es un indicador heurístico, no calibrado como probabilidad de fallo; SSD/NVMe usan las reglas de comprobación actuales, no representan garantía de vida del fabricante.
- El terminal Bash y los resúmenes de comprobación persistentes usan salida literal en chino simplificado, los diagnósticos originales del fabricante no se traducen; los controles Web tienen ocho idiomas. Cambiar el texto de estado y la lógica de reconocimiento CLI requiere una migración de compatibilidad separada.
- El instalador solo soporta Debian y una distribución fija de aplicación/servicio. El HTTP LAN por defecto no cifra credenciales, solo apto para LAN confiable o túnel SSH.
- No se ofrece garantía de migración de CLI/estado v1, los estados v2.2 antiguos que no cumplan el formato actual serán rechazados.

## Decisiones

| Fecha | Decisión | Estado | Razón |
| --- | --- | --- | --- |
| 2026-10-08 | La raíz y `doc/` son documentos fuente en chino simplificado, las traducciones solo conservan `en` y `es` | Aceptada | El usuario solicitó eliminar documentos antiguos y reescribir completamente según la plantilla actual. |
| 2026-10-08 | Los registros de cambios de otros idiomas de interfaz recurren al inglés | Aceptada | Conservar compatibilidad entre los ocho idiomas de interfaz y la nueva distribución de documentos. |
| 2026-10-08 | Las capturas de introducción provienen de una demostración sintética, guardadas por idioma | Aceptada | Mostrar la compilación actual y evitar exponer dispositivos o credenciales reales. |
| 2026-10-08 | Conservar etiquetas publicadas, entrada CLI de raíz y requisitos de respaldo de estado coincidente | Aceptada | Reescribir documentos no modifica el historial de publicación ni la interfaz de datos existentes. |

## Traspaso

[简体中文](../LOG.md#交接)
