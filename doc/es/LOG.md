---
name: project-log-es
description: Project decisions, limitations, handoff, and release history
metadata:
  version: "0.1.0"
  lang: es
---

# hdd-health-check — Registro

Este registro conserva decisiones históricas aceptadas, limitaciones conocidas e historial de versiones. Esta documentación describe `v3.0.0`. La etiqueta de código fuente `v3.0.0` marca esta versión mayor; no se crea un GitHub Release. El usuario informa de que el código anterior `v2.2.0` se ejecutó en una máquina real, sin detalles sobre dispositivo, entorno ni cobertura. La puntuación revisada solo tiene validación simulada y aislada, no en un HDD real.

## Multilingüe

[English](../LOG.md) | [简体中文](../zh-CN/LOG.md) | [繁體中文(台灣)](../zh-TW/LOG.md) | [繁體中文(香港)](../zh-HK/LOG.md) | [हिन्दी](../hi/LOG.md) | **Español** | [العربية](../ar/LOG.md) | [Français](../fr/LOG.md)

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Historial de versiones: [LOG](LOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Errores

- [ ] El usuario informa de pruebas de v2.2.0 en una máquina real, sin especificar dispositivos, entorno ni alcance; no se han confirmado pruebas de ejecución como root, instalación de paquetes ni comportamiento de systemd; las comprobaciones de la versión anterior v1.0.0 tampoco contaron con un HDD real ni datos SMART (solo sintaxis y ayuda). Según los informes, el script se había utilizado antes de la normalización original, pero eso no sustituye una prueba controlada con hardware.
- [ ] La puntuación revisada por lotes y la repetición final de SMART/ATA/CRC solo cuentan con pruebas sintéticas, no con validación de este código en un HDD real. La resolución temporal del registro de autopruebas del firmware y la reanudación entre ejecuciones pueden causar una cobertura parcial/desconocida; no se pueden atribuir de nuevo automáticamente los errores históricos tras reparar. Se mantiene declarada esta limitación de validación de hardware; se sigue recomendando repetir las pruebas en un HDD autorizado.
- [ ] Los pesos heurísticos de salud no son probabilidades de fallo calibradas; la puntuación SAS/SCSI se ha probado menos que la ATA y el acceso directo a SMART mediante USB/RAID puede fallar. La información de temperatura dependiente del fabricante es incompleta.
- [ ] Se comprobó el servicio Web autenticado en LAN y el inventario real de discos en un NAS Debian. Siguen sin verificarse la evaluación completa en HDD reales y la recuperación tras reiniciar. Se rechaza el estado v2.2 anterior no conforme. No se ofrece exportación CSV.
- [x] La normalización de v1.0.0 corrigió instrucciones de clonación que apuntaban a la ruta inexistente `hdd-health-check-repo/main` y caracteres mezclados de chino tradicional en el README en chino simplificado.

## Limitaciones

- El servicio Debian instalado conserva su disposición `/root/apps/hdd-health-check/web/` en el host para mantener la compatibilidad de actualización; el código fuente está en `src/web/` y la salida generada en `dist/web/`.

### Puntos de entrada de compatibilidad

Base: `35f24e5`
Motivo: Los comandos CLI existentes y las instrucciones de instalación invocan el punto de entrada shell de la raíz del repositorio; la implementación reside ahora en `src/checker/`.
Límite de actualización: Conservar el despachador de la raíz hasta que una migración de ruta CLI comunicada por separado sustituya el comando establecido.

- `hdd-health-check.sh` -> `src/checker/hdd-health-check.sh`

## Decisiones

| Decisiones | Motivos |
| --- | --- |
| 2026-08-12: Dividir el proyecto local en un árbol de trabajo Git y copias de versiones separadas; rechazar una disposición local plana. | Era necesario separar las copias históricas de versiones del código bajo control de versiones. El nombre `main/` utilizado entonces era solo local y nunca formó parte de la copia de trabajo de GitHub; se planearon etiquetas y copias mediante `git archive`. |
| 2026-08-13: Renombrar el directorio local `main/` a `repo/`; corregir rutas de instalación, encabezados bilingües y `.gitignore`; mantener las rutas de la réplica privada y de las copias de versiones fuera del estado público. Rechazar el registro sin cambios de documentos obsoletos ya preparados. | La copia de trabajo de GitHub sitúa el script en la raíz. Las instrucciones antiguas fallarían inmediatamente después de clonar; las rutas locales y los errores de traducción no debían figurar en la documentación pública. |
| 2026-08-13: No simular una comprobación de publicación con un HDD real en el disco virtual disponible; declarar el alcance menor de la validación. | No se disponía de hardware SMART utilizable ni de `smartmontools`; instalar paquetes para explorar un disco virtual no habría probado la lógica para HDD. |
| 2026-08-13: Sustituir el historial público de v1.0.0 por un único commit limpio con identidad noreply y una etiqueta anotada, conservando el historial original en un archivo privado renombrado; rechazar forzar el envío del repositorio público anterior o conservar su commit intermedio sustituido. | El commit público anterior contenía una dirección de correo personal en los metadatos de Git. Las copias y bifurcaciones existentes no se migran automáticamente y no puede garantizarse que la exposición anterior se haya eliminado de las cachés. Es un hecho histórico, no una autorización para volver a reescribir el historial. |
| Integración actual: Adoptar el comportamiento v2.2.0 suministrado sin garantías de compatibilidad con v1 y conservar la licencia MIT existente. | El nuevo script añade estado persistente y tareas opcionales en segundo plano; `-w` se ignora. Esta integración no implica publicación, etiqueta ni validación con hardware. |

## Traspaso

2026-09-28. Rama `feat/standards-alignment`; este árbol de trabajo local no tiene commits nuevos. No se encontraron reglas temporales del proyecto.

- Completado: se reorganizó el código fuente en `src/checker/` y `src/web/`, se trasladó la salida Web generada a `dist/web/`, se conservó el punto de entrada CLI compatible en la raíz, se actualizaron las rutas del instalador y de las pruebas, y se normalizaron los nombres de los directorios de idiomas y la navegación documental. Las instalaciones desde código fuente siguen copiando al diseño existente del servicio Debian. La interfaz ahora ofrece ocho colores de acento y modos claro/oscuro en Ajustes, los conserva por separado y usa un enlace real a Changelog en la navegación superior.
- Seguridad: se añadió una página específica de Security Settings con un período de verificación de contraseña de administrador de cinco minutos, impuesto por el servidor. La verificación renueva la sesión; una sesión admitida solo por IP no puede leer ni modificar la lista de permisos o la contraseña. Durante ese período, el cambio de contraseña solo pide la nueva contraseña y su confirmación e invalida todas las sesiones. La admisión por IP tiene un interruptor de activación, acepta solo direcciones exactas RFC 1918 IPv4 o ULA IPv6, rechaza las entradas heredadas no permitidas, utiliza el par de conexión en vez de encabezados de reenvío suministrados por el cliente y comprueba el Host/Origin original y un encabezado de petición del mismo origen para las mutaciones.
- Privacidad y versión: las respuestas de instantáneas y SMART ahora ocultan los números de serie; una solicitud autenticada para mostrarlos recupera el número completo solo tras una acción explícita del usuario, y la vista lo borra al ocultarlo o cerrarse. El enlace de versión está junto al nombre del proyecto y abre Changelog; una compilación sin etiqueta usa el marcador `test-<sha>` y ofrece el mismo valor en `/api/build`.
- Comportamiento no publicado: La evaluación completa de SSD/NVMe ahora ejecuta SMART rápido, autopruebas corta y larga y una lectura completa de solo lectura; omite el muestreo de velocidad. Un lote completo sin anomalías obtiene 100 puntos; las lecturas lentas por sí solas no descuentan puntos. Las opciones del lote dependen de los tipos de disco seleccionados. La capacidad y los datos escritos en SSD cambian entre unidades decimales y binarias; un HDD en reposo se puede activar individualmente desde sus detalles SMART. Pasaron las pruebas simuladas; no se inició una evaluación integral de discos reales en esta actualización.
- Pruebas: pasaron la comprobación de tipos Vue y la compilación de producción. Pasaron todas las pruebas shell y Python Web, incluidas admisión por IP, caducidad de permisos, renovación de sesión, cambio de contraseña y revelación y ocultación de series. El comprobador de temas aprobó los ocho colores de acento en ambos modos. Pasaron los controles de multilingüismo, formato documental (cero errores y ocho advertencias), enlaces locales y estructura del proyecto tras trasladar los artefactos del navegador fuera de la raíz del código fuente. Chromium local mostró Security Settings y ajustes de apariencia adaptables en modo oscuro a 390 px sin desbordamiento horizontal; la navegación directa a Changelog mostró primero la sección v3.0.0. El entorno aislado del navegador devolvió las respuestas 503 previstas para el estado de discos porque carece del proceso del comprobador.
- Pendiente: revisar el diff final y probar el flujo de seguridad actualizado en el NAS después de autorizar un despliegue. El punto de entrada compatible de la raíz figura en Limitations con su referencia anterior al traslado. No se realizó ninguna actualización del NAS, operación de disco real ni prueba de reinicio en este árbol de trabajo; estos cambios sin commit no se han publicado.
- Próximo paso: revisar la rama y decidir si se despliega en el NAS para comprobar Security Settings en vivo.

## Bases históricas del código fuente

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

## Historial de cambios

### v3.0.0 — 2026-09-27

Esta versión mayor añade la interfaz Web persistente y autenticada y el instalador Debian al comprobador de discos existente. El servicio se verificó en un NAS Debian con 13 discos enumerados; siguen pendientes una evaluación completa de HDD reales y la recuperación tras reiniciar. La etiqueta contiene código fuente; no se publicó un GitHub Release ni una interfaz precompilada.

#### Corregido en el seguimiento del NAS

- Las tarjetas de discos se distribuyen en una a cuatro columnas según el ancho disponible, incluido el zoom del navegador, sin ocultar controles ni generar desbordamiento horizontal.
- Las caídas de velocidad y los cambios de velocidad media de SSD/NVMe son información de rendimiento; los errores reales de lectura siguen penalizados y los resultados guardados se reinterpretan. La lista se organiza en columnas adaptables y la tarjeta del panel lleva a la lista.
- Durante una autoprueba SMART de todos los discos, el estado Web consulta el registro de ejecución y el tramo reciente del log, sin sondear cada unidad. La lista se actualiza por separado y reutiliza el último resultado válido mientras hay una lectura en segundo plano.
- La temperatura NVMe se colorea por separado de la puntuación. Usa los umbrales de advertencia y críticos del controlador cuando existen, o bandas visuales de 70/80 °C; la temperatura sola no resta puntos. Las evaluaciones anteriores permanecen igual hasta otra comprobación.
- Se interpretan correctamente los campos guardados vacíos y una comprobación limpia con cobertura parcial no produce un código de salida de advertencia.
- Las cuatro categorías del panel tienen páginas principales propias y la evaluación en un clic sigue en la página de discos.

#### Añadido

- Servicio Web Python, interfaz Vue, comprobaciones rápidas programadas, control de tareas, historial SMART y unidad de despliegue. El instalador habilita acceso LAN autenticado; la ejecución manual permanece en loopback.
- Acceso y salida Web, lista IPv4 exacta gestionada por usuarios autenticados en Ajustes, tarjetas con datos básicos y pestañas separadas de SMART y comprobaciones. El historial de cambios se presenta como Markdown.
- Versión y velocidad negociada SATA, o generación, ancho y velocidad PCIe NVMe cuando están disponibles; tiempo de encendido alternable; lotes para SATA, HDD, SSD, NVMe o todos, con cualquiera de los ocho módulos. La lista muestra bus, tipo de medio y temperatura en caché; el detalle SMART solo muestra el formato si se informa. Solo la evaluación completa da una puntuación actual; las puntuaciones SSD/NVMe no se calibran por separado.
- Instalador Debian que comprueba requisitos, instala paquetes apt ausentes, despliega la interfaz compilada y el servicio, y guarda una copia de reversión durante las actualizaciones.
- Las instantáneas `--json` reutilizan la puntuación compuesta Bash. `--no-install` impide instalar dependencias automáticamente en tareas Web. Los lanzamientos guardan estados aceptado, en curso y final; la tarjeta de atención filtra discos y los detalles muestran deducciones registradas, con aviso claro para datos antiguos sin causa.

#### Validación

- Pasaron la compilación y tipos de la UI, las pruebas shell de estado y puntuación y las comprobaciones HTTP locales de autenticación. El servicio LAN autenticado se instaló y comprobó en un NAS Debian con 13 discos. La evaluación completa de HDD reales y la recuperación tras reiniciar siguen sin verificarse.

### v1.0.0 — 2026-08-08

#### Added

- Comprobación inicial de salud de HDD de 12 dimensiones: datos de dispositivo e interfaz, capacidad SMART y evaluación global, atributos ATA o contadores de defectos/errores SAS, registros de errores y autopruebas, inicio de autopruebas cortas/largas, vida útil/carga, errores de E/S del kernel, detección de montajes y de solo lectura, medición opcional de rendimiento con `hdparm` de solo lectura y exploración con `badblocks`.
- Puntuación heurística de 0 a 100 y cuatro niveles con códigos de salida del proceso 0/1/2/3, detección automática del acceso directo a SMART, selección interactiva y por lotes de discos, y oferta de instalación mediante `apt` de `smartmontools` si faltaba.
- Los documentos completos de diseño y uso de v1.0.0 se conservan en la etiqueta Git `v1.0.0` (por ejemplo, `git show v1.0.0:DESIGN.md` y `git show v1.0.0:README.zh.md`); los comandos antiguos de v1 no son instrucciones actuales.

## Historial de commits

Historial completo de la rama principal: `git log main --stat`. `HEAD` identifica este commit de entrega.

- 2026-09-28 | `35f24e5` | `docs(handoff): record NAS Web update verification` | `git show 35f24e5`
- 2026-09-28 | `c60d602` | `fix(web): defer option watcher until labels initialize` | `git show c60d602`
- 2026-09-28 | `261247f` | `fix(web): initialize assessment scope before options` | `git show 261247f`
- 2026-09-28 | `f882a8d` | `docs: record SSD full assessment behavior` | `git show f882a8d`
- 2026-09-28 | `bfed16f` | `feat: assess SSDs with full read-only scan` | `git show bfed16f`
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
