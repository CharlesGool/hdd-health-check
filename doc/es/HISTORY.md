---
name: project-history-es
description: Historial
metadata:
  version: "1.0.0"
  lang: "es"
---

# Historial

## Multilingüe

[简体中文](../HISTORY.md) | [English](../en/HISTORY.md) | **Español**

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Estado del proyecto: [LOG](LOG.md)
- Registros históricos: [HISTORY](HISTORY.md)
- Historial de cambios: [CHANGELOG](CHANGELOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)


## Registros históricos

| Fecha | Requisito o decisión | Estado y evidencia en ese momento |
| --- | --- | --- |
| 2026-08-13 | Publicar el primer comprobador HDD y normalizar directorios | La etiqueta `v1.0.0` conserva el código fuente inicial; en ese momento solo se completaron verificaciones de sintaxis y ayuda, sin verificación controlada de HDD/SMART. |
| 2026-09-24 | Integrar resultados persistentes, historial, tareas en segundo plano y puntuación por lotes | La etiqueta `v2.3.0` incluye la integración temprana de v2.2; puntuación y estado usan pruebas sintéticas, no se promete compatibilidad con v1. |
| 2026-09-27 | Introducir controlador Web Python/Vue | La etiqueta `v3.0.0` conserva la distribución original de `web/`; el historial informa del servicio autenticado en NAS Debian y verificación de inventario de discos reales, la evaluación completa HDD y la recuperación tras reinicio siguen incompletas. |
| 2026-09-28 | Actualizar seguridad Web, evaluación SSD y distribución de código fuente | El GitHub Release de `v4.0.0` fue publicado; verificación reciente de administrador, aislamiento de permisos por IP e historial de tareas incorporados a la versión. |
| 2026-09-29 | Actualizar apariencia Web, detalles de disco y posicionamiento de etiquetas | El GitHub Release de `v4.1.0` fue publicado; la verificación con HDD real y tras reinicio sigue incompleta. |
| 2026-09-29 | Eliminar transiciones de página | `5b8e2db` completó la navegación inmediata; la animación de retroceso anterior ya no es funcionalidad actual. |
| 2026-10-08 | Alinear especificación del proyecto, corregir determinación de entorno de lectura y limitación de inicio de sesión | `a228d8d`, `0d0564f`, `2184495` fueron commiteados y publicados correctamente; CI en checkout limpio pasó, sin despliegue ni nueva Release. |

Los requisitos antiguos, el estado original de finalización y el código fuente completo pueden rastrearse mediante `git log` y las etiquetas anteriores. Esta tabla es un resumen reorganizado según Git y el alcance de verificación registrado, no amplía las comprobaciones NAS históricas a una verificación integral de hardware.
