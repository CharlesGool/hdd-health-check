---
name: project-overview-es
description: Project overview and usage
metadata:
  version: "0.1.0"
  lang: es
---

# hdd-health-check

Esta herramienta Bash ejecutada como root evalúa la salud de los HDD en Debian/Ubuntu mediante datos SMART y comprobaciones de solo lectura. La versión `v4.1.0` incluye el comprobador y la interfaz Web local opcional, con código fuente y un archivo Web Debian precompilado en GitHub. El servicio Web se comprobó en un NAS Debian con inventario real de discos y ajustes de seguridad autenticados, pero siguen sin verificarse una evaluación completa en HDD reales y la recuperación tras reiniciar el equipo.

Las horas de encendido son información de uso y por sí solas no restan puntos de salud. Un atributo ATA cercano al umbral solo genera aviso con un contador bruto de errores no nulo. Los resultados antiguos sin esa prueba quedan pendientes de revisión sin deducción. Las tarjetas de atención muestran la causa registrada.

## Multilingüe

[English](../../README.md) | [简体中文](../zh-CN/README.md) | [繁體中文(台灣)](../zh-TW/README.md) | [繁體中文(香港)](../zh-HK/README.md) | [हिन्दी](../hi/README.md) | **Español** | [العربية](../ar/README.md) | [Français](../fr/README.md)

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Historial de versiones: [LOG](LOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Introducción

El menú interactivo o la CLI por lotes seleccionan unidades, realizan una evaluación rápida de SMART, montajes y registros del kernel, y presentan una puntuación heurística de 0 a 100 y un nivel de riesgo. Otros módulos ofrecen autopruebas SMART cortas y largas, medición de velocidad de lectura por muestreo, exploración reanudable de la latencia de lectura de todo el disco con una nueva comprobación dirigida y opcional mediante `badblocks`, ejecución de `badblocks` de solo lectura en todo el disco y pruebas de lectura de la interfaz tras una reparación. En HDD, la evaluación completa ejecuta las comprobaciones rápida, corta, larga, de velocidad y de superficie; en SSD ejecuta las comprobaciones rápida, corta, larga y una exploración integral de solo lectura sin muestreo de velocidad; no incluye el módulo independiente de `badblocks` para todo el disco ni el de interfaz. Los resultados pueden reutilizarse, compararse con el historial de contadores SMART y reunirse en un informe. Véanse los [problemas conocidos](LOG.md) y los [objetivos](DESIGN.md).

**«Solo lectura» se refiere a los datos del disco de destino, no al equipo anfitrión.** El programa escribe registros, ajustes, progreso e historial en el equipo anfitrión; puede activar SMART, iniciar autopruebas internas de la unidad, leer dispositivos enteros bajo carga sostenida, instalar paquetes previa confirmación e iniciar unidades transitorias de systemd. No sustituye a las copias de seguridad. No se implementa ninguna exploración de superficie con escritura destructiva, borrado ni escritura en el sistema de archivos.

La evaluación completa repite SMART/ATA/CRC tras las lecturas prolongadas. Solo muestra una puntuación global de 0 a 100 si las pruebas rápida, corta, larga y de superficie terminada, además del muestreo de velocidad para HDD, son del mismo lote, están completas y vigentes. Los resultados reutilizados, interrumpidos, caducados o antiguos siguen visibles como históricos, con clasificación parcial/desconocida; consultar informes no actualiza la base de comparación. Tras reparar la interfaz, verifíquela por separado y repita la evaluación completa para obtener una puntuación nueva; resolverla no borra errores anteriores. Un primer total de errores ATA tiene causa desconocida y conserva un descuento de 5 puntos por riesgo no resuelto en revisiones sucesivas, incluso después de la evaluación completa. Un aumento resta 20 puntos; un contador estable no es un error nuevo ni prueba que el riesgo se haya resuelto. La verificación de interfaz por sí sola no atribuye los errores ATA antiguos a una reparación. Las lecturas lentas aisladas aconsejan repetir la prueba de rendimiento, no prueban sectores defectuosos; los errores confirmados de superficie siguen restando 40 puntos. Haga copias de seguridad antes de probar un disco sospechoso.

## Requisitos

- Mínimos: root, Bash 4.3+, utilidades de dispositivos de bloques de Linux (`lsblk`, `blockdev`), `smartctl` (`smartmontools`), `dd` (`coreutils`) y `flock`; la plataforma prevista es Debian/Ubuntu. En otras distribuciones se muestra una advertencia; la instalación automática de dependencias utiliza `apt-get`.
- Recomendados: `badblocks` (`e2fsprogs`) para comprobaciones de superficie; systemd con `systemd-run` para tareas desacopladas. Si faltan paquetes, puede ofrecerse su instalación interactiva mediante `apt-get update`/instalación (o confirmarse automáticamente con `-y`). Compruebe las dependencias antes de una ejecución desatendida. No se incluye código de terceros con versiones fijadas ni se necesita un archivo de bloqueo de dependencias.
- Para evaluar la salud real se necesitan un HDD físico y acceso SMART. Se pueden incluir SSD/NVMe explícitamente. Una evaluación SSD completa y limpia obtiene 100 puntos, pero la puntuación no es una probabilidad calibrada de fallo.

## Instalación

### Instalación rápida

Desde una copia de trabajo de confianza, ejecute `sudo bash ./hdd-health-check.sh --help` para consultar las opciones sin iniciar una exploración. No envíe un script remoto sin revisar mediante una tubería a un intérprete de comandos con privilegios de root.

### Instalación normal


La siguiente copia utiliza la etiqueta de versión `v4.1.0`. El comando de la raíz del repositorio es un punto de entrada ligero; su implementación está en `src/checker/`.

```bash
git clone --branch v4.1.0 --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check
bash -n hdd-health-check.sh src/checker/hdd-health-check.sh
sudo bash ./hdd-health-check.sh --help
```

Revise e instale usted mismo los paquetes necesarios del sistema operativo antes de explorar para evitar la solicitud de instalación del script. Para actualizar una copia de trabajo existente, haga primero una copia de seguridad de los registros del equipo anfitrión que quiera conservar y de `${HDD_STATE_DIR:-/var/lib/hdd-health}`; sustituya el script por el de una copia de trabajo revisada, conserve ese directorio de estado para el historial y la reanudación, y después consulte `--help` y ejecute las comprobaciones elegidas. El análisis del estado de v2.2 solo acepta campos de datos conocidos; un estado anterior de v2.2 que no se ajuste a ellos puede rechazarse. Para volver a una versión anterior hay que restaurar el script anterior **y la copia de seguridad correspondiente de su estado**; no dé por hecho que el estado más reciente sea compatible hacia atrás. No se garantiza la migración del estado ni el comportamiento de la CLI de v1.

### Interfaz Web desde la etiqueta v4.1.0

La etiqueta de código fuente no incluye los archivos generados de `dist/web` en el control de versiones. En un equipo Debian con systemd, instale Node.js 20.19+ o 22.12+ y npm, compile la interfaz y ejecute el instalador. GitHub Release también ofrece un archivo Web precompilado para instalarla sin Node.js en el NAS:

```bash
git clone --branch v4.1.0 --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/src/web
npm ci
npm run build
cd ../..
sudo bash deploy/install.sh
```

El instalador comprueba e instala los paquetes de ejecución ausentes de Debian, inicia el servicio protegido con contraseña en el puerto LAN 8765 y no inicia ninguna exploración de disco. Lea la contraseña generada con `sudo cat /root/apps/hdd-health-check/web-password`. Node.js solo es necesario para compilar la interfaz. Consulte [WEB](WEB.md) para conocer las actualizaciones, los límites de seguridad y la reversión.

## Orientaciones

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

Códigos de salida: `0`, todo correcto; `1`, aviso/advertencia; `2`, peligro; `3`, error de ejecución. Los registros se guardan por defecto en `/var/log/disk-health/hdd-health-<timestamp>.log`; el estado, en `/var/lib/hdd-health`. Las escrituras en el equipo anfitrión y los límites operativos se detallan en [DESIGN](DESIGN.md).

## Actualización

Para el diseño actual del código fuente, actualice la copia, compile la interfaz en `src/web` y ejecute `sudo bash deploy/install.sh` desde la raíz del repositorio. El instalador copia `src/checker/hdd-health-check.sh`, `src/web/server.py` y `dist/web` al diseño de servicio existente, conserva la contraseña Web y guarda copias con fecha de la aplicación y de la unidad. Revise los cambios antes de ejecutarlo como root. La etiqueta histórica `v3.0.0` conserva su antiguo diseño de código fuente `web/` y sus propias instrucciones de instalación.

## Desinstalación

- Elimine la copia de trabajo o el script instalado para retirar la CLI sin borrar registros ni historial. La CLI no instala ningún servicio permanente de systemd; si instaló el servicio Web opcional, deténgalo y desactívelo primero según [WEB](WEB.md). Compruebe si hay tareas transitorias activas antes de retirar el script.
- Para eliminarlo todo, detenga primero cualquier tarea y haga una copia de seguridad de los registros que quiera conservar; después elimine manualmente el directorio `HDD_STATE_DIR` configurado (por defecto `/var/lib/hdd-health`) y `HDD_LOG_DIR` (por defecto `/var/log/disk-health`), una vez comprobadas sus rutas y su contenido. Esto borra informes, progreso, historial, notas de reparación y registros; nunca elimine a ciegas un directorio compartido o cuya ruta se haya sobrescrito. Los paquetes instalados mediante `apt-get` no se eliminan automáticamente.

## Agradecimientos

Los créditos del código y las fuentes de terceros figuran en [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md).

## Licencia

MIT (SPDX: MIT); consulte [LICENSE](../../LICENSE).

## Evaluación y controles actuales de SSD

La evaluación completa de SSD/NVMe ejecuta una comprobación SMART rápida, autopruebas corta y larga y una lectura completa del disco. Omite el muestreo de velocidad; las lecturas lentas por sí solas no restan puntos de salud. Un lote completo sin anomalías obtiene 100 puntos; los hallazgos SMART o errores reales de lectura pueden reducir esta puntuación heurística. Los controles por lotes muestran la unión de las comprobaciones admitidas por los discos seleccionados; los módulos exclusivos de HDD omiten los SSD seleccionados. Al pulsar la capacidad o los datos escritos se alternan unidades decimales y binarias. En los detalles SMART de un HDD en reposo hay un botón para activar solo ese disco.
