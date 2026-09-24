# hdd-health-check — Registro

Este registro conserva decisiones históricas aceptadas, limitaciones conocidas e historial de versiones. Esta documentación describe `v2.3.0`. Consulta GitHub Releases para ver las versiones etiquetadas y las descargas. El usuario informa de que el código anterior `v2.2.0` se ejecutó en una máquina real, sin detalles sobre dispositivo, entorno ni cobertura. La puntuación revisada solo tiene validación simulada y aislada, no en un HDD real.

## Multi-language

[English](../LOG.md) | [简体中文](../zh_cn/LOG.md) | [繁體中文](../zh_tw/LOG.md) | [繁體中文（香港）](../zh_hk/LOG.md) | [हिन्दी](../hi/LOG.md) | **Español** | [العربية](../ar/LOG.md) | [Français](../fr/LOG.md)

## Documentation

- Presentación del proyecto: [README](README.md)
- Fundamentos de diseño: [DESIGN](DESIGN.md)
- Historial de versiones: [LOG](LOG.md)
- Inventario de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Bugs

- [ ] El usuario informa de pruebas de v2.2.0 en una máquina real, sin especificar dispositivos, entorno ni alcance; no se han confirmado pruebas de ejecución como root, instalación de paquetes ni comportamiento de systemd; las comprobaciones de la versión anterior v1.0.0 tampoco contaron con un HDD real ni datos SMART (solo sintaxis y ayuda). Según los informes, el script se había utilizado antes de la normalización original, pero eso no sustituye una prueba controlada con hardware.
- [ ] La puntuación revisada por lotes y la repetición final de SMART/ATA/CRC solo cuentan con pruebas sintéticas, no con validación de este código en un HDD real. La resolución temporal del registro de autopruebas del firmware y la reanudación entre ejecuciones pueden causar una cobertura parcial/desconocida; no se pueden atribuir de nuevo automáticamente los errores históricos tras reparar. Se mantiene declarada esta limitación de validación de hardware; se sigue recomendando repetir las pruebas en un HDD autorizado.
- [ ] Los pesos heurísticos de salud no son probabilidades de fallo calibradas; la puntuación SAS/SCSI se ha probado menos que la ATA y el acceso directo a SMART mediante USB/RAID puede fallar. La información de temperatura dependiente del fabricante es incompleta.
- [ ] No hay salida estructurada JSON/CSV. Se rechaza el estado v2.2 preexistente que no se ajuste al formato; las pruebas simuladas y aisladas cubren la detección y parada segura de tareas con `TMPDIR` personalizado y el progreso de superficie anómalo.
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

### v2.3.0 — 2026-09-24

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
