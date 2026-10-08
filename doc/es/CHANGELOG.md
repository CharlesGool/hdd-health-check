---
name: project-changelog-es
description: Registro de cambios
metadata:
  version: "1.0.0"
  lang: "es"
---

# Registro de cambios

## Multilingüe

[简体中文](../CHANGELOG.md) | [English](../en/CHANGELOG.md) | **Español**

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Estado del proyecto: [LOG](LOG.md)
- Registros históricos: [HISTORY](HISTORY.md)
- Historial de cambios: [CHANGELOG](CHANGELOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)


## Historial de cambios

Aquí se reproducen los cambios formales de versiones ya existentes, no se crea una nueva versión por el trabajo de documentación de esta ronda. Las fechas provienen de etiquetas existentes o GitHub Release; las etiquetas tempranas no tienen página de GitHub Release correspondiente.

### v4.1.0 — 2026-09-29

#### Añadido

- Se amplían los detalles de disco, la descripción de atributos SMART y la visualización de lecturas/escrituras del host soportadas para SSD.
- Se actualiza la apariencia Web, los temas y la retroalimentación de controles, se proporcionan iconos para distintas páginas.

#### Cambiado

- La página de inicio de sesión muestra versión, idioma y control independiente de visibilidad de contraseña, el registro de cambios es legible antes de iniciar sesión.

#### Corregido

- Se corrige el posicionamiento medido del subrayado de etiquetas de detalle, se mantienen permisos privados del directorio de estado Web.

### v4.0.0 — 2026-09-28

#### Añadido

- Verificación reciente de administrador independiente, actualización de contraseña, control preciso de acceso por IP privada e historial de tareas en segundo plano.
- Evaluación completa SSD/NVMe y operaciones de despertar/standby por disco individual.

#### Cambiado

- El código fuente se mueve a `src/checker/` y `src/web/`, los artefactos del frontend se mueven a `dist/web/`.
- La comprobación por lotes de discos mixtos proporciona la unión de módulos soportados, las comprobaciones específicas de HDD se omiten para SSD.

### v3.0.0 — 2026-09-27

#### Añadido

- Servicio Web Python, interfaz Vue, verificación rápida programada, historial SMART e instalador Debian.
- Instantáneas estructuradas de disco, recibos de tareas Web y control `--no-install`.

### v2.3.0 — 2026-09-24

#### Añadido

- Resultados e historial por disco, lectura de superficie resumible, revisión de interfaces tras reparación, procesamiento por lotes y tareas en segundo plano con systemd.

#### Cambiado

- Solo las comprobaciones completas, válidas y pertenecientes al mismo lote producen una puntuación global actual; los resultados antiguos se conservan como evidencia histórica.

#### Corregido

- El estado se analiza según campos de datos conocidos, evitando ejecutar registros persistentes como código Shell.

### v1.0.0 — 2026-08-13

#### Añadido

- Atributos SMART, errores y registro de autopruebas, verificación de montaje y errores del kernel, medición de velocidad de solo lectura y escaneo con badblocks.
- Selección interactiva/por lotes de discos, puntuación heurística 0–100, registros y códigos de salida.
