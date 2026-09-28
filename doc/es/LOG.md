---
name: project-log-es
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: es
---

# hdd-health-check — Registro

Este registro conserva decisiones históricas aceptadas, limitaciones conocidas e historial de versiones. Esta documentación describe `v3.0.0`. La etiqueta de código fuente `v3.0.0` marca esta versión mayor; no se crea un GitHub Release. El usuario informa de que el código anterior `v2.2.0` se ejecutó en una máquina real, sin detalles sobre dispositivo, entorno ni cobertura. La puntuación revisada solo tiene validación simulada y aislada, no en un HDD real.

## Multi-language

[English](../LOG.md) | [简体中文](../zh_cn/LOG.md) | [繁體中文](../zh_tw/LOG.md) | [繁體中文(香港)](../zh_hk/LOG.md) | [हिन्दी](../hi/LOG.md) | **Español** | [العربية](../ar/LOG.md) | [Français](../fr/LOG.md)

- En esta etapa se pueden elegir cinco grupos y ocho tipos de prueba. La lista distingue SATA/NVMe y muestra la temperatura leída en segundo plano; los detalles muestran el formato informado por el dispositivo. Pasaron la compilación y las pruebas simuladas de comandos, temperatura y protección del reposo; falta comprobarlo en el NAS.

## Documentation

- Presentación del proyecto: [README](README.md)
- Fundamentos de diseño: [DESIGN](DESIGN.md)
- Historial de versiones: [LOG](LOG.md)
- Inventario de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Bugs

- [ ] El usuario informa de pruebas de v2.2.0 en una máquina real, sin especificar dispositivos, entorno ni alcance; no se han confirmado pruebas de ejecución como root, instalación de paquetes ni comportamiento de systemd; las comprobaciones de la versión anterior v1.0.0 tampoco contaron con un HDD real ni datos SMART (solo sintaxis y ayuda). Según los informes, el script se había utilizado antes de la normalización original, pero eso no sustituye una prueba controlada con hardware.
- [ ] La puntuación revisada por lotes y la repetición final de SMART/ATA/CRC solo cuentan con pruebas sintéticas, no con validación de este código en un HDD real. La resolución temporal del registro de autopruebas del firmware y la reanudación entre ejecuciones pueden causar una cobertura parcial/desconocida; no se pueden atribuir de nuevo automáticamente los errores históricos tras reparar. Se mantiene declarada esta limitación de validación de hardware; se sigue recomendando repetir las pruebas en un HDD autorizado.
- [ ] Los pesos heurísticos de salud no son probabilidades de fallo calibradas; la puntuación SAS/SCSI se ha probado menos que la ATA y el acceso directo a SMART mediante USB/RAID puede fallar. La información de temperatura dependiente del fabricante es incompleta.
- [ ] Se comprobó el servicio Web autenticado en LAN y el inventario real de discos en un NAS Debian. Siguen sin verificarse la evaluación completa en HDD reales y la recuperación tras reiniciar. Se rechaza el estado v2.2 anterior no conforme. No se ofrece exportación CSV.
- [x] La normalización de v1.0.0 corrigió instrucciones de clonación que apuntaban a la ruta inexistente `hdd-health-check-repo/main` y caracteres mezclados de chino tradicional en el README en chino simplificado.

## Decisions

| Decisiones | Motivos |
| --- | --- |
| 2026-08-12: Dividir el proyecto local en un árbol de trabajo Git y copias de versiones separadas; rechazar una disposición local plana. | Era necesario separar las copias históricas de versiones del código bajo control de versiones. El nombre `main/` utilizado entonces era solo local y nunca formó parte de la copia de trabajo de GitHub; se planearon etiquetas y copias mediante `git archive`. |
| 2026-08-13: Renombrar el directorio local `main/` a `repo/`; corregir rutas de instalación, encabezados bilingües y `.gitignore`; mantener las rutas de la réplica privada y de las copias de versiones fuera del estado público. Rechazar el registro sin cambios de documentos obsoletos ya preparados. | La copia de trabajo de GitHub sitúa el script en la raíz. Las instrucciones antiguas fallarían inmediatamente después de clonar; las rutas locales y los errores de traducción no debían figurar en la documentación pública. |
| 2026-08-13: No simular una comprobación de publicación con un HDD real en el disco virtual disponible; declarar el alcance menor de la validación. | No se disponía de hardware SMART utilizable ni de `smartmontools`; instalar paquetes para explorar un disco virtual no habría probado la lógica para HDD. |
| 2026-08-13: Sustituir el historial público de v1.0.0 por un único commit limpio con identidad noreply y una etiqueta anotada, conservando el historial original en un archivo privado renombrado; rechazar forzar el envío del repositorio público anterior o conservar su commit intermedio sustituido. | El commit público anterior contenía una dirección de correo personal en los metadatos de Git. Las copias y bifurcaciones existentes no se migran automáticamente y no puede garantizarse que la exposición anterior se haya eliminado de las cachés. Es un hecho histórico, no una autorización para volver a reescribir el historial. |
| Integración actual: Adoptar el comportamiento v2.2.0 suministrado sin garantías de compatibilidad con v1 y conservar la licencia MIT existente. | El nuevo script añade estado persistente y tareas opcionales en segundo plano; `-w` se ignora. Esta integración no implica publicación, etiqueta ni validación con hardware. |

## Entrega - 2026-09-28

- Rama `main`: la etiqueta anotada `v3.0.0` se publicó sobre el commit `434ac7d`; el commit posterior solo registra la entrega. No se creó un GitHub Release ni una interfaz precompilada.
- Despliegue: se instaló la etiqueta `v3.0.0` en el NAS Debian mediante `hdd-health-web.service`, bajo `/root/apps/hdd-health-check`. El instalador conservó la contraseña y copias de la aplicación y unidad anteriores; antes del cambio se guardó otra copia del estado y los registros. El servicio está activo y habilitado en `0.0.0.0:8765`. Tras iniciar sesión desde el navegador LAN aparecieron 13 discos y `v3.0.0`; respondieron las API autenticadas de discos, estado, historial de tareas y cambios. No se inició una nueva prueba de discos ni se reinició el NAS; se verificó la habilitación al arranque, pero no la recuperación tras un reinicio.
- Completado: la instalación LAN autenticada en un NAS Debian enumeró 13 discos; arrancó el servicio y el navegador mostró datos de discos, tareas, diálogos y diseño adaptable. El instalador conservó la contraseña y el estado del host. La comprobación final de la interfaz no inició un escaneo ni reinició el equipo.
- Pruebas: pasaron tipos y compilación Vue, sintaxis shell, pruebas sintéticas de puntuación y estado, autenticación y tareas Web, lecturas de API y navegador LAN. La evaluación completa en HDD real y la recuperación tras reinicio siguen sin comprobarse. Los avisos antiguos sin prueba bruta esperan una nueva revisión.
- Verificación de versión: la copia limpia de la etiqueta y el archivo fuente compilaron y mostraron `v3.0.0`; la rama remota y la etiqueta se verificaron por separado. La copia local `snapshots/v3.0.0` contiene 87 archivos fuente, sin `web/dist` precompilado.
- Siguiente acción: observar el uso normal del NAS y una futura tarea Web completada. Corregir más adelante los problemas de estructura del proyecto y navegación multilingüe. No se encontraron reglas temporales del proyecto.

## Historial de commits

Historial completo de la rama principal: `git log main --stat`. `HEAD` identifica este commit de entrega.

- 2026-09-28 | `HEAD` | `docs(handoff): record NAS v3.0.0 deployment` | `git show HEAD`
- 2026-09-27 | `97f775f` | `docs(handoff): record v3.0.0 tag publication` | `git show 97f775f`
- 2026-09-27 | `434ac7d` | `chore(release): prepare v3.0.0 source tag` | `git show 434ac7d`
- 2026-09-27 | `65acbd0` | `docs(install): point source install to main` | `git show 65acbd0`
- 2026-09-27 | `b963e06` | `docs(handoff): confirm source publication` | `git show b963e06`
- 2026-09-27 | `88474d2` | `feat(web): publish LAN dashboard and docs` | `git show 88474d2`
- 2026-09-24 | `a46b392` | `feat(scoring): improve batch assessment for v2.3.0` | `git show a46b392`
- 2026-09-24 | `3126bcc` | `docs: clarify public source and reported real-machine testing` | `git show 3126bcc`
- 2026-09-24 | `7e69fdd` | `feat!: integrate unreleased v2.2.0 HDD health checks` | `git show 7e69fdd`
- 2026-08-13 | `7b18ca7` | `docs(status): record v1.0.0 release completion` | `git show 7b18ca7`
- 2026-08-13 | `4e01f52` | `chore(release): v1.0.0 (clean history)` | `git show 4e01f52`

## Changelog

### Actualización de desarrollo — 2026-09-28 (después de la etiqueta v3.0.0)

- La evaluación completa de SSD/NVMe ahora ejecuta SMART rápido, autopruebas corta y larga y una lectura completa de solo lectura; omite el muestreo de velocidad. Un lote completo sin anomalías obtiene 100 puntos; las lecturas lentas por sí solas no descuentan puntos. Las opciones del lote dependen de los tipos de disco seleccionados. La capacidad y los datos escritos en SSD cambian entre unidades decimales y binarias; un HDD en reposo se puede activar individualmente desde sus detalles SMART. Pasaron las pruebas simuladas; no se inició una evaluación integral de discos reales en esta actualización.

### v3.0.0 — 2026-09-27

Esta versión mayor añade una interfaz Web persistente con autenticación y un instalador Debian al comprobador de discos. El servicio Web se comprobó en un NAS Debian con 13 discos; siguen sin verificarse la evaluación completa en HDD reales y la recuperación tras reinicio. La etiqueta contiene el código fuente; no se publica un GitHub Release ni una interfaz compilada.

Corrección para NAS: durante las autopruebas SMART, el estado Web ya no consulta cada disco de forma secuencial; la lista y el estado se actualizan por separado. La temperatura NVMe se colorea según los umbrales del dispositivo y no resta puntos por sí sola. También se corrigen los campos de problemas vacíos y la advertencia causada solo por una evaluación incompleta.

La página principal permite una evaluación completa de todos los discos SATA, HDD, SSD, NVMe o todos los discos. El servidor selecciona los discos enumerados y lanza una tarea `full --rescan` en segundo plano. Incluye pruebas SMART cortas/largas, muestreo de velocidad y lectura completa; puede tardar horas. La puntuación SSD/NVMe usa reglas orientadas a HDD sin calibración propia. La versión y velocidad SATA proceden de smartctl; cuando existen, Linux sysfs aporta la velocidad SATA o la generación, ancho y velocidad PCIe de NVMe. Los datos ausentes figuran como desconocidos. Pulse las horas de uso para alternar con años de 365 días, días y horas.

Esta actualización Web añade inicio y cierre de sesión en la página, lista de IPv4 exactas en Ajustes, datos básicos de discos, pestañas SMART y comprobaciones, e historial de cambios en Markdown. Pasaron la compilación local y las pruebas de sesiones, acceso IP y SMART simulado; falta actualizar el NAS y validar discos reales.


Las caídas de velocidad y los cambios de velocidad media de SSD/NVMe pasan a ser información de rendimiento; se mantienen las penalizaciones por errores reales de lectura y se reinterpretan los resultados anteriores. La lista se adapta a tres, dos o una columna y la tarjeta de discos del panel permite saltar a ella.

- Las tarjetas de discos se reorganizan automáticamente entre una y cuatro columnas según el ancho disponible, incluido el zoom del navegador, sin ocultar botones ni generar desbordamiento horizontal.

#### Añadido

- Servicio Web Python, interfaz Vue, comprobaciones programadas, control de tareas, historial SMART y unidad systemd. El instalador permite acceso LAN autenticado; el modo manual permanece en loopback.
- Las instantáneas `--json` reutilizan la función de puntuación compuesta de Bash. `--no-install` impide instalar automáticamente dependencias para las tareas iniciadas desde la Web.

#### Validación

- Pasaron la compilación y comprobación de tipos de la UI, las pruebas shell de estado y puntuación y las pruebas HTTP locales de autenticación. El servicio LAN autenticado se comprobó en un NAS Debian con 13 discos enumerados; siguen sin verificarse la evaluación completa en HDD reales y la recuperación tras reiniciar.

### v2.3.0 — 2026-09-24 (untagged source baseline)

#### Changed

Esta versión incluye la integración v2.2 antes no etiquetada: resultados persistentes por disco, historial de contadores SMART, módulos interactivos y por lotes, exploraciones de superficie reanudables y de solo lectura, verificación de interfaz, tareas transitorias opcionales de systemd y análisis más seguro de estados como datos. No conserva la compatibilidad con la CLI ni el estado de v1: `-w/--wait` se ignora en vez de esperar; guarde el estado antes de actualizar y restaure el estado correspondiente al volver a un script anterior. La puntuación revisada siguiente solo tiene pruebas sintéticas, no en un HDD real.

#### Fixed

- Reconoce el primer registro de autoprueba SMART recién completada; los registros antiguos, incompletos o de otro tipo no cuentan como prueba nueva completada.
- Un lote completo marca la prueba SMART rápida, corta y larga, el muestreo de velocidad y la exploración de superficie terminada bajo un mismo identificador; repite SMART/ATA/CRC al final. Solo los resultados completos, válidos y del mismo lote permiten una puntuación global numérica. Reutilización, interrupción, caducidad, estado antiguo sin marcador y verificación posterior de interfaz dejan los registros anteriores como históricos/pendientes de revisión y el grado general parcial/desconocido; consultar un informe no actualiza la base de comparación rápida. La verificación de interfaz registra aparte si se resolvió el problema; no atribuye de nuevo errores antiguos ni convierte el lote anterior en actual. Un total ATA sin contador previo conserva un descuento de 5 puntos por riesgo no resuelto en revisiones y evaluaciones completas posteriores, también si el registro antiguo carece del campo de riesgo. Una subida resta 20 puntos; la estabilidad no es un nuevo error ni prueba una reparación, y la verificación de interfaz sola no atribuye los errores ATA antiguos a ella. Las lecturas lentas aisladas exigen revisar el rendimiento, no diagnostican sectores defectuosos; los fallos repetidos de lectura de superficie siguen restando 40 puntos. Son pesos heurísticos, no probabilidades de fallo.

### v2.2.0 — historial de integración sin etiqueta (no publicado)

#### Added

- Resultados persistentes por disco, historial de contadores SMART, registros de reparaciones e informes; menú interactivo, medición de lectura por muestreo, exploración reanudable de latencia de superficie con nuevas comprobaciones dirigidas de bloques defectuosos, ejecución de `badblocks` de solo lectura en todo el disco, pruebas de carga de lectura de interfaz y ejecución opcional en segundo plano mediante unidades transitorias de systemd.

#### Changed

- Comprobaciones rápidas predeterminadas en modo por lotes, resultados reutilizables con validez temporal y `--rescan`; `-r/--run` selecciona módulos y `--status`/`--stop` gestionan una instancia en ejecución. `-t short|long`, `-s` y `-b` se asignan a módulos; `-w/--wait` se ignora en vez de esperar. El nuevo comportamiento no es compatible con la CLI de v1.
- El estado y los registros del equipo anfitrión se escriben por separado; v2.2.0 no conserva la compatibilidad con la CLI ni con el estado de v1. Haga una copia del estado antes de actualizar; al restaurar un script anterior, restaure también su copia de estado correspondiente. Los registros de estado solo admiten campos de datos permitidos; los incompatibles pueden rechazarse.

#### Fixed

- Se rechazan registros de estado ejecutables o mal formados y entradas de estado que sean enlaces simbólicos; los planes en segundo plano se limitan a campos validados y al directorio privado de estado, y se validan los nombres de dispositivos y las rutas de registros y estado para reducir el manejo inseguro de archivos.
- Los puntos de control de superficie incompletos o inválidos inician un nuevo análisis en vez de calcular el progreso con un denominador cero; se admite un `TMPDIR` personalizado al detectar instancias activas y detenerlas de forma segura.

El usuario informa de pruebas de v2.2.0 en una máquina real, sin especificar dispositivos, entorno ni alcance; no se han confirmado de forma independiente la ejecución como root, la instalación de paquetes ni el comportamiento de systemd.


### v1.0.0 — 2026-08-08

#### Added

- Comprobación inicial de salud de HDD de 12 dimensiones: datos de dispositivo e interfaz, capacidad SMART y evaluación global, atributos ATA o contadores de defectos/errores SAS, registros de errores y autopruebas, inicio de autopruebas cortas/largas, vida útil/carga, errores de E/S del kernel, detección de montajes y de solo lectura, medición opcional de rendimiento con `hdparm` de solo lectura y exploración con `badblocks`.
- Puntuación heurística de 0 a 100 y cuatro niveles con códigos de salida del proceso 0/1/2/3, detección automática del acceso directo a SMART, selección interactiva y por lotes de discos, y oferta de instalación mediante `apt` de `smartmontools` si faltaba.
- Los documentos completos de diseño y uso de v1.0.0 se conservan en la etiqueta Git `v1.0.0` (por ejemplo, `git show v1.0.0:DESIGN.md` y `git show v1.0.0:README.zh.md`); los comandos antiguos de v1 no son instrucciones actuales.
