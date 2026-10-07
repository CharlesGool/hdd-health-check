---
name: project-log-es
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: "es"
---

# hdd-health-check — Registro

Este registro conserva decisiones históricas aceptadas, limitaciones conocidas e historial de versiones. La versión actual es `v4.1.0`. El usuario informa de que ejecutó el código anterior `v2.2.0` en una máquina real, sin detalles sobre el dispositivo, el entorno ni la cobertura. La puntuación revisada cuenta con pruebas sintéticas y comprobaciones Web en un NAS Debian, pero no con una evaluación completa y controlada en HDD reales.

## Idiomas

[简体中文](../LOG.md) | [English](../en/LOG.md) | **Español**

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Estado del proyecto: [LOG](LOG.md)
- Registros históricos: [HISTORY](HISTORY.md)
- Historial de cambios: [CHANGELOG](CHANGELOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Registros

- [HISTORY](HISTORY.md)
- [CHANGELOG](CHANGELOG.md)

## Errores

- [ ] El usuario informa de pruebas de v2.2.0 en una máquina real, sin especificar dispositivos, entorno ni alcance; no se han confirmado pruebas de ejecución como root, instalación de paquetes ni comportamiento de systemd; las comprobaciones de la versión anterior v1.0.0 tampoco contaron con un HDD real ni datos SMART (solo sintaxis y ayuda). Según los informes, el script se había utilizado antes de la normalización original, pero eso no sustituye una prueba controlada con hardware.
- [ ] La puntuación revisada por lotes y la repetición final de SMART/ATA/CRC solo cuentan con pruebas sintéticas, no con validación de este código en un HDD real. La resolución temporal del registro de autopruebas del firmware y la reanudación entre ejecuciones pueden causar una cobertura parcial/desconocida; no se pueden atribuir de nuevo automáticamente los errores históricos tras reparar. Se mantiene declarada esta limitación de validación de hardware; se sigue recomendando repetir las pruebas en un HDD autorizado.
- [ ] Los pesos heurísticos de salud no son probabilidades de fallo calibradas; la puntuación SAS/SCSI se ha probado menos que la ATA y el acceso directo a SMART mediante USB/RAID puede fallar. La información de temperatura dependiente del fabricante es incompleta.
- [ ] Se comprobó el servicio Web autenticado en LAN y el inventario real de discos en un NAS Debian. Siguen sin verificarse la evaluación completa en HDD reales y la recuperación tras reiniciar. Se rechaza el estado v2.2 anterior no conforme. No se ofrece exportación CSV.
- [x] La normalización de v1.0.0 corrigió instrucciones de clonación que apuntaban a la ruta inexistente `hdd-health-check-repo/main` y caracteres mezclados de chino tradicional en el README en chino simplificado.
- [x] En una captura del usuario posterior a `test-771001c`, el subrayado de la pestaña activa del detalle del disco sobrepasaba la pestaña seleccionada. El indicador anterior escalaba una línea de un píxel según el ancho entero del botón. Ahora anima directamente el ancho fraccionario medido del botón; las comprobaciones locales en Chromium coincidieron con los botones SMART y Checks a ancho reducido, incluso con zoom y RTL. No se disponía de la configuración exacta del navegador de la captura para reproducirla.
- [x] Problema de animación de retroceso en historial: `5b8e2db` ya eliminó las transiciones de página según el estándar actual. Esta migración continúa adoptando navegación inmediata, sin crear una versión de corrección formal.

## Limitaciones

- El texto de terminal del detector en Bash y la información SMART cruda aún no admiten multilingüismo en tiempo de ejecución; la interfaz de terminal existente está en chino simplificado y el diagnóstico del fabricante es salida cruda. La interfaz Web utiliza recursos de idioma; los fallos de operaciones del servidor incluyen el error crudo del sistema.

- El servicio Debian instalado conserva su disposición `/root/apps/hdd-health-check/web/` en el host para mantener la compatibilidad de actualización; el código fuente está en `src/web/` y la salida generada en `dist/web/`.

### Puntos de entrada de compatibilidad

Base: `35f24e5`
Motivo: Los comandos CLI existentes y las instrucciones de instalación invocan el punto de entrada shell de la raíz del repositorio; la implementación reside ahora en `src/checker/`.
Límite de actualización: Conservar el despachador de la raíz hasta que una migración de ruta CLI comunicada por separado sustituya el comando establecido.

- `hdd-health-check.sh` -> `src/checker/hdd-health-check.sh`

## Decisiones

| Fecha | Decisión | Estado | Motivo |
| --- | --- | --- | --- |
| 2026-08-12 | Dividir el proyecto local en un árbol de trabajo Git y copias de versiones separadas; rechazar una disposición local plana. | Aceptada | Era necesario separar las copias históricas de versiones del código bajo control de versiones. El nombre `main/` utilizado entonces era solo local y nunca formó parte de la copia de trabajo de GitHub; se planearon etiquetas y copias mediante `git archive`. |
| 2026-08-13 | Renombrar el directorio local `main/` a `repo/`; corregir rutas de instalación, encabezados bilingües y `.gitignore`; mantener las rutas de la réplica privada y de las copias de versiones fuera del estado público. Rechazar el registro sin cambios de documentos obsoletos ya preparados. | Aceptada | La copia de trabajo de GitHub sitúa el script en la raíz. Las instrucciones antiguas fallarían inmediatamente después de clonar; las rutas locales y los errores de traducción no debían figurar en la documentación pública. |
| 2026-08-13 | No simular una comprobación de publicación con un HDD real en el disco virtual disponible; declarar el alcance menor de la validación. | Aceptada | No se disponía de hardware SMART utilizable ni de `smartmontools`; instalar paquetes para explorar un disco virtual no habría probado la lógica para HDD. |
| 2026-08-13 | Sustituir el historial público de v1.0.0 por un único commit limpio con identidad noreply y una etiqueta anotada, conservando el historial original en un archivo privado renombrado; rechazar forzar el envío del repositorio público anterior o conservar su commit intermedio sustituido. | Aceptada | El commit público anterior contenía una dirección de correo personal en los metadatos de Git. Las copias y bifurcaciones existentes no se migran automáticamente y no puede garantizarse que la exposición anterior se haya eliminado de las cachés. Es un hecho histórico, no una autorización para volver a reescribir el historial. |
| Registro histórico | Integración actual: Adoptar el comportamiento v2.2.0 suministrado sin garantías de compatibilidad con v1 y conservar la licencia MIT existente. | Aceptada | El nuevo script añade estado persistente y tareas opcionales en segundo plano; `-w` se ignora. Esta integración no implica publicación, etiqueta ni validación con hardware. |

## Traspaso

[简体中文](../LOG.md#交接)
