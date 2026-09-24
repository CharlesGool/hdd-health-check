# hdd-health-check — Registro

Este registro conserva decisiones históricas aceptadas, limitaciones conocidas e historial de versiones; v2.2.0 está integrado localmente, pero no se ha publicado.

## Multi-language

[English](../LOG.md) | [简体中文](../zh_cn/LOG.md) | [繁體中文](../zh_tw/LOG.md) | [繁體中文（香港）](../zh_hk/LOG.md) | [हिन्दी](../hi/LOG.md) | **Español** | [العربية](../ar/LOG.md) | [Français](../fr/LOG.md)

## Documentation

- Presentación del proyecto: [README](README.md)
- Fundamentos de diseño: [DESIGN](DESIGN.md)
- Historial de versiones: [LOG](LOG.md)
- Inventario de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Bugs

- [ ] La integración con HDD reales, la ejecución como root e instalación de paquetes, y el comportamiento de systemd siguen sin verificarse en esta integración; las comprobaciones de la versión anterior v1.0.0 tampoco contaron con un HDD real ni datos SMART (solo sintaxis y ayuda). Según los informes, el script se había utilizado antes de la normalización original, pero eso no sustituye una prueba controlada con hardware.
- [ ] Los pesos heurísticos de salud no son probabilidades de fallo calibradas; la puntuación SAS/SCSI se ha probado menos que la ATA y el acceso directo a SMART mediante USB/RAID puede fallar. La información de temperatura dependiente del fabricante es incompleta.
- [ ] No hay salida estructurada JSON/CSV. Se rechaza el estado v2.2 preexistente que no se ajuste al formato; las pruebas simuladas y aisladas cubren la detección y parada segura de tareas con `TMPDIR` personalizado y el progreso de superficie anómalo; el comportamiento real de systemd y HDD sigue sin verificarse.
- [x] La normalización de v1.0.0 corrigió instrucciones de clonación que apuntaban a la ruta inexistente `hdd-health-check-repo/main` y caracteres mezclados de chino tradicional en el README en chino simplificado.

## Decisions

| Decisiones | Motivos |
| --- | --- |
| 2026-08-12: Dividir el proyecto local en un árbol de trabajo Git y copias de versiones separadas; rechazar una disposición local plana. | Era necesario separar las copias históricas de versiones del código bajo control de versiones. El nombre `main/` utilizado entonces era solo local y nunca formó parte de la copia de trabajo de GitHub; se planearon etiquetas y copias mediante `git archive`. |
| 2026-08-13: Renombrar el directorio local `main/` a `repo/`; corregir rutas de instalación, encabezados bilingües y `.gitignore`; mantener las rutas de la réplica privada y de las copias de versiones fuera del estado público. Rechazar el registro sin cambios de documentos obsoletos ya preparados. | La copia de trabajo de GitHub sitúa el script en la raíz. Las instrucciones antiguas fallarían inmediatamente después de clonar; las rutas locales y los errores de traducción no debían figurar en la documentación pública. |
| 2026-08-13: No simular una comprobación de publicación con un HDD real en el disco virtual disponible; declarar el alcance menor de la validación. | No se disponía de hardware SMART utilizable ni de `smartmontools`; instalar paquetes para explorar un disco virtual no habría probado la lógica para HDD. |
| 2026-08-13: Sustituir el historial público de v1.0.0 por un único commit limpio con identidad noreply y una etiqueta anotada, conservando el historial original en un archivo privado renombrado; rechazar forzar el envío del repositorio público anterior o conservar su commit intermedio sustituido. | El commit público anterior contenía una dirección de correo personal en los metadatos de Git. Las copias y bifurcaciones existentes no se migran automáticamente y no puede garantizarse que la exposición anterior se haya eliminado de las cachés. Es un hecho histórico, no una autorización para volver a reescribir el historial. |
| Integración actual: Adoptar el comportamiento v2.2.0 suministrado sin garantías de compatibilidad con v1 y conservar la licencia MIT existente. | El nuevo script añade estado persistente y tareas opcionales en segundo plano; `-w` se ignora. Esta integración no implica publicación, etiqueta ni validación con hardware. |

## Changelog

### Sin publicar — integración v2.2.0 (sin fecha de publicación)

#### Added

- Resultados persistentes por disco, historial de contadores SMART, registros de reparaciones e informes; menú interactivo, medición de lectura por muestreo, exploración reanudable de latencia de superficie con nuevas comprobaciones dirigidas de bloques defectuosos, ejecución de `badblocks` de solo lectura en todo el disco, pruebas de carga de lectura de interfaz y ejecución opcional en segundo plano mediante unidades transitorias de systemd.

#### Changed

- Comprobaciones rápidas predeterminadas en modo por lotes, resultados reutilizables con validez temporal y `--rescan`; `-r/--run` selecciona módulos y `--status`/`--stop` gestionan una instancia en ejecución. `-t short|long`, `-s` y `-b` se asignan a módulos; `-w/--wait` se ignora en vez de esperar. El nuevo comportamiento no es compatible con la CLI de v1.
- El estado y los registros del equipo anfitrión se escriben por separado; la integración v2.2.0 suministrada restringe el análisis del estado y los planes, así como el tratamiento de rutas y dispositivos. Aquí no se han realizado pruebas de integración con HDD reales, root ni systemd.

### v1.0.0 — 2026-08-08

#### Added

- Comprobación inicial de salud de HDD de 12 dimensiones: datos de dispositivo e interfaz, capacidad SMART y evaluación global, atributos ATA o contadores de defectos/errores SAS, registros de errores y autopruebas, inicio de autopruebas cortas/largas, vida útil/carga, errores de E/S del kernel, detección de montajes y de solo lectura, medición opcional de rendimiento con `hdparm` de solo lectura y exploración con `badblocks`.
- Puntuación heurística de 0 a 100 y cuatro niveles con códigos de salida del proceso 0/1/2/3, detección automática del acceso directo a SMART, selección interactiva y por lotes de discos, y oferta de instalación mediante `apt` de `smartmontools` si faltaba.
- Los documentos completos de diseño y uso de v1.0.0 se conservan en la etiqueta Git `v1.0.0` (por ejemplo, `git show v1.0.0:DESIGN.md` y `git show v1.0.0:README.zh.md`); los comandos antiguos de v1 no son instrucciones actuales.
