---
name: project-design-es
description: Architecture, data model, and boundaries
metadata:
  version: "0.1.0"
  lang: es
---

# hdd-health-check — Diseño

Este documento describe el comportamiento, las restricciones y el estado en el equipo anfitrión de la integración `v2.3.0`. Esta documentación describe `v2.3.0`. En GitHub solo existe la etiqueta `v1.0.0`; el código fuente actual de `main` no tiene un nuevo GitHub Release. El usuario informa de que el código anterior `v2.2.0` se ejecutó en una máquina real, sin detalles sobre dispositivo, entorno ni cobertura. La puntuación revisada solo tiene validación simulada y aislada, no en un HDD real.

Las horas de encendido son información de uso y por sí solas no restan puntos de salud. Un atributo ATA cercano al umbral solo genera aviso con un contador bruto de errores no nulo. Los resultados antiguos sin esa prueba quedan pendientes de revisión sin deducción. Las tarjetas de atención muestran la causa registrada.

## Multi-language

[English](../DESIGN.md) | [简体中文](../zh_cn/DESIGN.md) | [繁體中文](../zh_tw/DESIGN.md) | [繁體中文(香港)](../zh_hk/DESIGN.md) | [हिन्दी](../hi/DESIGN.md) | **Español** | [العربية](../ar/DESIGN.md) | [Français](../fr/DESIGN.md)

## Documentation

- Presentación del proyecto: [README](README.md)
- Fundamentos de diseño: [DESIGN](DESIGN.md)
- Historial de versiones: [LOG](LOG.md)
- Inventario de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Design Goals

- Ofrecer una evaluación preliminar rápida de HDD basada en el estado y los atributos SMART, los registros de errores y autopruebas SMART, los montajes, los errores de E/S del kernel y las tendencias; presentar una puntuación heurística y una clasificación útil para actuar, no una probabilidad de fallo.
- Ofrecer autopruebas SMART internas de la unidad, cortas y largas e independientes; lecturas directas por muestreo; exploraciones reanudables de latencia de superficie; nuevas comprobaciones dirigidas y opcionales con `badblocks` de solo lectura; ejecución de `badblocks` de solo lectura en todo el disco; y pruebas de carga de lectura de la interfaz tras una reparación.
- Permitir selección interactiva, ejecución por lotes, resultados persistentes, reutilización e informes históricos; transferencia opcional a unidades transitorias de systemd para tareas largas.
- Excluir recuperación de datos, `badblocks` en modo de escritura, borrado seguro y modificación de sistemas de archivos. El comprobador Bash sigue ejecutándose una sola vez; un complemento Web local opcional ofrece un controlador permanente y comprobaciones rápidas programadas. La inclusión de SSD/NVMe es opcional, pero la puntuación para HDD no está diseñada para diagnosticar plenamente esos dispositivos. La instantánea JSON sirve a la interfaz Web; no se han implementado una puntuación SAS más profunda ni una específica de NVMe.

## Architecture

Un único script Bash 4.3+ enumera discos con `lsblk`, selecciona destinos mediante menú o CLI, comprueba el acceso SMART con `smartctl`, ejecuta los módulos solicitados y genera un informe compuesto. Los atributos SMART de ATA y los contadores de defectos/errores de SAS/SCSI siguen rutas de puntuación distintas. La comprobación rápida incluye información sobre montajes y registros del kernel; las comprobaciones de velocidad, superficie e interfaz utilizan lecturas directas del dispositivo. Los resultados y la identidad de cada dispositivo se conservan para que las comprobaciones posteriores puedan reutilizarlos. Las decisiones interactivas pueden transferirse a un proceso por lotes mediante un plan restringido; un bloqueo privado impide que varias instancias utilicen simultáneamente el mismo directorio de estado. Una unidad transitoria de `systemd-run` gestiona las tareas desacopladas cuando está disponible; `--status` y `--stop` consultan la instancia registrada.

Un lote completo marca la prueba SMART rápida, corta y larga, el muestreo de velocidad y la exploración de superficie terminada bajo un mismo identificador; repite SMART/ATA/CRC al final. Solo los resultados completos, válidos y del mismo lote permiten una puntuación global numérica. Reutilización, interrupción, caducidad, estado antiguo sin marcador y verificación posterior de interfaz dejan los registros anteriores como históricos/pendientes de revisión y el grado general parcial/desconocido; consultar un informe no actualiza la base de comparación rápida. La verificación de interfaz registra aparte si se resolvió el problema; no atribuye de nuevo errores antiguos ni convierte el lote anterior en actual. Un total ATA sin contador previo conserva un descuento de 5 puntos por riesgo no resuelto en revisiones y evaluaciones completas posteriores, también si el registro antiguo carece del campo de riesgo. Una subida resta 20 puntos; la estabilidad no es un nuevo error ni prueba una reparación, y la verificación de interfaz sola no atribuye los errores ATA antiguos a ella. Las lecturas lentas aisladas exigen revisar el rendimiento, no diagnostican sectores defectuosos; los fallos repetidos de lectura de superficie siguen restando 40 puntos. Son pesos heurísticos, no probabilidades de fallo.

En unidades SSD, las caídas de las muestras de velocidad y las variaciones de velocidad media entre ejecuciones son datos de rendimiento y no restan puntos de salud; los errores reales de lectura sí los restan. Los resultados anteriores se interpretan igual sin modificar sus archivos de estado. La lista Web distribuye automáticamente los discos según el ancho disponible del navegador, hasta cuatro columnas en pantallas amplias; al cambiar el zoom, los discos se reorganizan. La tarjeta de discos del panel lleva directamente a la lista.

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

Las comprobaciones no utilizan por sí mismas ninguna API de red. El servicio Web local opcional añade una API HTTP en bucle local en modo manual; el instalador permite acceso desde la LAN con autenticación, mientras que `--json` proporciona una instantánea estructurada de solo lectura que usa la misma función de puntuación compuesta que el informe de terminal. `--no-install` desactiva la instalación de paquetes durante las llamadas desatendidas. La arquitectura Web, la programación y los límites de seguridad se describen en [WEB](WEB.md). Los scripts pueden usar los códigos de salida `0` (correcto), `1` (requiere atención), `2` (peligro) y `3` (fallo de ejecución); consulte [Guía de uso](README.md#guía-de-uso).

El inicio de sesión Web entrega una cookie de sesión HttpOnly de duración limitada. La lista IPv4 exacta omite la contraseña para operaciones normales, pero editarla requiere una sesión con contraseña. Los detalles SMART se consultan al abrir un disco y el resultado SMART bruto no sustituye la puntuación compuesta.

La página principal permite elegir por separado el grupo de discos (SATA, HDD, SSD, NVMe o todos) y la prueba (rápida, SMART corta/larga, velocidad, superficie, badblocks, interfaz o completa). El servidor selecciona los discos enumerados y ejecuta la prueba elegida en segundo plano. Solo la evaluación completa puede producir una puntuación compuesta actual; las puntuaciones SSD/NVMe siguen reglas de HDD. La lista distingue SATA SSD y NVMe SSD según el medio y el transporte y obtiene la temperatura en segundo plano sin despertar HDD en reposo. Los detalles muestran el formato solo si el dispositivo lo informa; SATA o NVMe no permiten deducir que sea M.2. Los datos disponibles del enlace SATA o PCIe proceden de smartctl y Linux sysfs. Pulse las horas de uso para alternar con años, días y horas.

La tarjeta de atención filtra los discos con avisos o errores. Los detalles muestran motivos y puntos descontados; si un resultado antiguo no guardó el motivo, piden repetir la prueba. Se conservan la aceptación, ejecución, finalización, detención o fallo de la tarea y el final del registro. Si pasan 15 segundos sin confirmación de ejecución ni estado final, se muestra estado sin confirmar. Los códigos 1 y 2 indican una prueba terminada con problemas, no un fallo al iniciarla.
