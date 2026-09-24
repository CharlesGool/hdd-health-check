# hdd-health-check — Diseño

Este documento describe el comportamiento, las restricciones y el estado en el equipo anfitrión de la integración v2.2.0. El código fuente de v2.2.0 está disponible en este repositorio público de GitHub. El usuario informa de pruebas en una máquina real, sin indicar dispositivos, entorno ni alcance; no hay etiqueta v2.2.0 ni GitHub Release.

## Multi-language

[English](../DESIGN.md) | [简体中文](../zh_cn/DESIGN.md) | [繁體中文](../zh_tw/DESIGN.md) | [繁體中文（香港）](../zh_hk/DESIGN.md) | [हिन्दी](../hi/DESIGN.md) | **Español** | [العربية](../ar/DESIGN.md) | [Français](../fr/DESIGN.md)

## Documentation

- Presentación del proyecto: [README](README.md)
- Fundamentos de diseño: [DESIGN](DESIGN.md)
- Historial de versiones: [LOG](LOG.md)
- Inventario de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Design Goals

- Ofrecer una evaluación preliminar rápida de HDD basada en el estado y los atributos SMART, los registros de errores y autopruebas SMART, los montajes, los errores de E/S del kernel y las tendencias; presentar una puntuación heurística y una clasificación útil para actuar, no una probabilidad de fallo.
- Ofrecer autopruebas SMART internas de la unidad, cortas y largas e independientes; lecturas directas por muestreo; exploraciones reanudables de latencia de superficie; nuevas comprobaciones dirigidas y opcionales con `badblocks` de solo lectura; ejecución de `badblocks` de solo lectura en todo el disco; y pruebas de carga de lectura de la interfaz tras una reparación.
- Permitir selección interactiva, ejecución por lotes, resultados persistentes, reutilización e informes históricos; transferencia opcional a unidades transitorias de systemd para tareas largas.
- Excluir recuperación de datos, `badblocks` en modo de escritura, borrado seguro, modificación de sistemas de archivos y un demonio de supervisión permanente. La inclusión de SSD/NVMe es opcional, pero la puntuación para HDD no está diseñada para diagnosticar plenamente esos dispositivos. No se han implementado los objetivos de salida estructurada JSON/CSV, puntuación SAS más profunda ni puntuación específica de NVMe.

## Architecture

Un único script Bash 4.3+ enumera discos con `lsblk`, selecciona destinos mediante menú o CLI, comprueba el acceso SMART con `smartctl`, ejecuta los módulos solicitados y genera un informe compuesto. Los atributos SMART de ATA y los contadores de defectos/errores de SAS/SCSI siguen rutas de puntuación distintas. La comprobación rápida incluye información sobre montajes y registros del kernel; las comprobaciones de velocidad, superficie e interfaz utilizan lecturas directas del dispositivo. Los resultados y la identidad de cada dispositivo se conservan para que las comprobaciones posteriores puedan reutilizarlos. Las decisiones interactivas pueden transferirse a un proceso por lotes mediante un plan restringido; un bloqueo privado impide que varias instancias utilicen simultáneamente el mismo directorio de estado. Una unidad transitoria de `systemd-run` gestiona las tareas desacopladas cuando está disponible; `--status` y `--stop` consultan la instancia registrada.

## Design Constraints

- Para un diagnóstico útil se necesitan acceso root y comunicación SMART directa con el dispositivo físico. La detección de puentes USB/RAID es heurística; si falla el acceso directo, se informa del fallo en lugar de inferir que el dispositivo está sano. La puntuación SAS es distinta y se ha probado menos que la ATA. La temperatura y los umbrales dependen de los datos del fabricante.
- Todas las lecturas de superficie e interfaz del dispositivo se envían a `/dev/null`; `badblocks` se invoca sin el modo destructivo `-w`. **La activación de SMART y las autopruebas pueden modificar el estado del firmware de la unidad**; las rutas del equipo anfitrión permiten escritura. No describa esta ejecución como carente de efectos secundarios.
- La selección explícita y `--include-ssd` no demuestran que sea seguro someter un dispositivo a carga. Una exploración de toda la superficie puede durar horas; las escrituras del sistema operativo por otros procesos continúan. `--stop` no detiene las autopruebas que se ejecutan dentro de la unidad.
- Los datos de estado y del plan se analizan según los campos permitidos, no se ejecutan como código de shell. Un estado existente que no se ajuste a ellos puede rechazarse. El directorio de estado del equipo anfitrión no debe ser un enlace simbólico; el script comprueba los enlaces simbólicos del directorio y del registro de salida, pero quienes lo utilicen deben proteger igualmente las rutas elegidas.

## Data Design

`HDD_STATE_DIR` tiene como valor predeterminado `/var/lib/hdd-health` (se crea con permisos 700). Contiene `settings.conf` (días de validez, política de reutilización, paralelismo, tamaño de fragmento de exploración, parámetros de muestreo, inclusión de SSD y política de nueva comprobación automática), archivos de resultados `.env` por unidad, `history.csv` de contadores SMART, registros de reparación, mapas/puntos de control de superficie, historial de informes y listas opcionales de bloques defectuosos. Un archivo `.lock`, los datos de la instancia en ejecución y los planes temporales en segundo plano coordinan la ejecución. Los valores predeterminados incluyen siete días de validez de resultados, fragmentos de superficie de 64 MiB y 24 muestras de velocidad de 128 MiB. El menú puede guardar ajustes; `--rescan` anula la reutilización. Al borrar resultados, se puede conservar o eliminar el historial de contadores y reparaciones; el usuario también puede optar por borrar los registros antiguos por separado.

`HDD_LOG_DIR` tiene como valor predeterminado `/var/log/disk-health`; `-l/--log` selecciona un registro individual. Los registros son texto sin formato, pueden incluir identificadores de dispositivos, datos del equipo anfitrión y el kernel e información de salud, y deben protegerse. Se crea un directorio temporal de trabajo en `/run` o, si no es posible, en otro directorio temporal. No suponga que el registro es la única salida persistente ni que se puede volver a una versión anterior con un directorio de estado de una versión posterior sin su copia de seguridad correspondiente.

## External Interfaces

| Interfaz | Responsabilidad y efectos |
| --- | --- |
| `lsblk`, `blockdev`, `/proc/mounts`, kernel log | Enumeración de dispositivos, geometría, estado de montaje y errores de E/S; la visibilidad depende de los permisos del equipo anfitrión. |
| `smartctl` | Lee diagnósticos SMART; puede activar SMART o iniciar pruebas internas. La detección automática de opciones de acceso directo es heurística. |
| `dd`, `badblocks` | Lecturas directas del dispositivo para muestreo, carga de interfaz, exploración de latencia o pruebas de bloques defectuosos de solo lectura. Las lecturas pueden someter a esfuerzo al hardware deteriorado. |
| `apt-get` | Ofrece instalar paquetes ausentes; `-y` puede aceptar automáticamente. Esto modifica los paquetes del equipo anfitrión y puede requerir acceso a la red. |
| `systemd-run` | Unidad transitoria opcional para tareas desacopladas; `--stop` solicita detener el proceso registrado del script, no una autoprueba del hardware. |

Las comprobaciones de salud no utilizan ninguna API de red. Los scripts y las integraciones pueden usar los códigos de salida de proceso `0` (correcto), `1` (requiere atención), `2` (peligro) y `3` (fallo de ejecución); consulte [Guía de uso](README.md#guía-de-uso). No existe una API estable de salida estructurada.
