# hdd-health-check

Esta herramienta Bash ejecutada como root evalúa la salud de los HDD en Debian/Ubuntu mediante datos SMART y comprobaciones de disco de solo lectura. El código fuente de v2.2.0 está disponible en este repositorio público de GitHub. El usuario informa de pruebas en una máquina real, sin indicar dispositivos, entorno ni alcance; no hay etiqueta v2.2.0 ni GitHub Release.

## Multi-language

[English](../../README.md) | [简体中文](../zh_cn/README.md) | [繁體中文](../zh_tw/README.md) | [繁體中文（香港）](../zh_hk/README.md) | [हिन्दी](../hi/README.md) | **Español** | [العربية](../ar/README.md) | [Français](../fr/README.md)

## Documentation

- Presentación del proyecto: [README](README.md)
- Fundamentos de diseño y efectos en el equipo anfitrión: [DESIGN](DESIGN.md)
- Decisiones, errores e historial de versiones: [LOG](LOG.md)
- Inventario de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Introduction

El menú interactivo o la CLI por lotes seleccionan unidades, realizan una evaluación rápida de SMART, montajes y registros del kernel, y presentan una puntuación heurística de 0 a 100 y un nivel de riesgo. Otros módulos ofrecen autopruebas SMART cortas y largas, medición de velocidad de lectura por muestreo, exploración reanudable de la latencia de lectura de todo el disco con una nueva comprobación dirigida y opcional mediante `badblocks`, ejecución de `badblocks` de solo lectura en todo el disco y pruebas de lectura de la interfaz tras una reparación. La evaluación completa ejecuta las comprobaciones rápida, corta, larga, de velocidad y de superficie; no incluye el módulo independiente de `badblocks` para todo el disco ni el de interfaz. Los resultados pueden reutilizarse, compararse con el historial de contadores SMART y reunirse en un informe. Véanse los [problemas conocidos](LOG.md#bugs) y los [objetivos](DESIGN.md#design-goals).

**«Solo lectura» se refiere a los datos del disco de destino, no al equipo anfitrión.** El programa escribe registros, ajustes, progreso e historial en el equipo anfitrión; puede activar SMART, iniciar autopruebas internas de la unidad, leer dispositivos enteros bajo carga sostenida, instalar paquetes previa confirmación e iniciar unidades transitorias de systemd. No sustituye a las copias de seguridad. No se implementa ninguna exploración de superficie con escritura destructiva, borrado ni escritura en el sistema de archivos.

## Requirements

- Mínimos: root, Bash 4.3+, utilidades de dispositivos de bloques de Linux (`lsblk`, `blockdev`), `smartctl` (`smartmontools`), `dd` (`coreutils`) y `flock`; la plataforma prevista es Debian/Ubuntu. En otras distribuciones se muestra una advertencia; la instalación automática de dependencias utiliza `apt-get`.
- Recomendados: `badblocks` (`e2fsprogs`) para comprobaciones de superficie; systemd con `systemd-run` para tareas desacopladas. Si faltan paquetes, puede ofrecerse su instalación interactiva mediante `apt-get update`/instalación (o confirmarse automáticamente con `-y`). Compruebe las dependencias antes de una ejecución desatendida. No se incluye código de terceros con versiones fijadas ni se necesita un archivo de bloqueo de dependencias.
- Para evaluar la salud real se necesitan un HDD físico y acceso SMART. Se pueden incluir SSD/NVMe explícitamente, pero la puntuación orientada a HDD no constituye una evaluación calibrada de SSD/NVMe.

## Install

### Quick Install

Desde una copia de trabajo de confianza, ejecute `sudo bash ./hdd-health-check.sh --help` para consultar las opciones sin iniciar una exploración. No envíe un script remoto sin revisar mediante una tubería a un intérprete de comandos con privilegios de root.

### Normal Install

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
bash -n hdd-health-check.sh
sudo bash ./hdd-health-check.sh --help
```

Revise e instale usted mismo los paquetes necesarios del sistema operativo antes de explorar para evitar la solicitud de instalación del script. Para actualizar una copia de trabajo existente, haga primero una copia de seguridad de los registros del equipo anfitrión que quiera conservar y de `${HDD_STATE_DIR:-/var/lib/hdd-health}`; sustituya el script por el de una copia de trabajo revisada, conserve ese directorio de estado para el historial y la reanudación, y después consulte `--help` y ejecute las comprobaciones elegidas. El análisis del estado de v2.2 solo acepta campos de datos conocidos; un estado anterior de v2.2 que no se ajuste a ellos puede rechazarse. Para volver a una versión anterior hay que restaurar el script anterior **y la copia de seguridad correspondiente de su estado**; no dé por hecho que el estado más reciente sea compatible hacia atrás. No se garantiza la migración del estado ni el comportamiento de la CLI de v1.

## Guía de uso

Ejecute la herramienta únicamente sobre unidades que tenga autorización para examinar; una exploración de lectura sostenida puede generar una carga considerable. Los comandos siguientes son **ejemplos, no instrucciones para validar este entorno**:

```bash
sudo bash ./hdd-health-check.sh                 # terminal menu
sudo bash ./hdd-health-check.sh -a              # all rotational disks, default quick scan
sudo bash ./hdd-health-check.sh -d sdb -r quick,short
sudo bash ./hdd-health-check.sh -d sdb -r full -y
sudo bash ./hdd-health-check.sh -d sdb -r iface --duration 30 --detach
sudo bash ./hdd-health-check.sh --status
sudo bash ./hdd-health-check.sh --stop
```

`-d/--disk` acepta nombres de dispositivos separados por comas; `-a/--all` selecciona discos mecánicos y `--include-ssd` amplía la selección. `-r/--run` acepta `quick,short,long,speed,surface,badblocks,iface,full`; el valor predeterminado es `quick` y el modo por lotes siempre añade un informe. `--duration` fija los minutos de la prueba de interfaz (15 por defecto). `--rescan` reinicia en vez de reutilizar o reanudar resultados anteriores; de forma predeterminada, la comprobación rápida se repite en modo por lotes, los demás resultados se reutilizan mientras sean válidos y las exploraciones de superficie interrumpidas se reanudan. `-q/--quiet` suprime la salida del terminal, **no la escritura de registros**; `-y/--yes` confirma automáticamente las solicitudes, incluidas las instalaciones de paquetes. `--detach` requiere el modo por lotes y que `systemd-run` esté disponible; la desconexión del terminal durante tareas interactivas largas aptas también puede transferirlas a systemd. `--stop` solicita una parada segura y conserva el progreso de la exploración de superficie, pero **no** cancela las autopruebas SMART internas de la unidad. `-l/--log FILE` cambia la ruta del registro; `HDD_LOG_DIR` y `HDD_STATE_DIR` sustituyen los directorios predeterminados. `NO_COLOR` desactiva el color; `HDD_NO_BG` desactiva la transferencia automática de tareas interactivas a segundo plano. Los ajustes del menú se guardan en el directorio de estado.

El analizador también asigna `-t short|long` a la autoprueba correspondiente, `-s` a la prueba de velocidad y `-b` a badblocks; **`-w/--wait` se ignora** y no espera a que finalice una prueba. Estos alias no reproducen el comportamiento de v1. Consulte `--help` para ver las opciones del script instalado.

Códigos de salida: `0`, todo correcto; `1`, aviso/advertencia; `2`, peligro; `3`, error de ejecución. Los registros se guardan por defecto en `/var/log/disk-health/hdd-health-<timestamp>.log`; el estado, en `/var/lib/hdd-health`. Las escrituras en el equipo anfitrión y los límites operativos se detallan en [DESIGN](DESIGN.md#data-design).

## Desinstalación

- Elimine la copia de trabajo o el script instalado para retirar la herramienta sin borrar registros ni historial. No se instala permanentemente ningún servicio de systemd; compruebe si hay tareas transitorias activas antes de retirar el script.
- Para eliminarlo todo, detenga primero cualquier tarea y haga una copia de seguridad de los registros que quiera conservar; después elimine manualmente el directorio `HDD_STATE_DIR` configurado (por defecto `/var/lib/hdd-health`) y `HDD_LOG_DIR` (por defecto `/var/log/disk-health`), una vez comprobadas sus rutas y su contenido. Esto borra informes, progreso, historial, notas de reparación y registros; nunca elimine a ciegas un directorio compartido o cuya ruta se haya sobrescrito. Los paquetes instalados mediante `apt-get` no se eliminan automáticamente.

## License

MIT (SPDX: MIT); consulte [LICENSE](../../LICENSE).
