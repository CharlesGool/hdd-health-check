---
name: web-guide-es
description: Instalación y uso de la interfaz Web local
metadata:
  version: "0.1.0"
  lang: es
---

# Interfaz Web local

La interfaz Web muestra los resultados de los discos locales, el historial reciente de contadores SMART, las tareas activas y una programación configurable de comprobaciones rápidas. Inicia las comprobaciones seleccionadas mediante la herramienta Bash existente. No presenta los resultados parciales o caducados como puntuación actual. Solo un lote de evaluación completo y vigente puede mostrar una puntuación numérica.

Las tarjetas de atención muestran la causa registrada. Las horas de encendido por sí solas no reducen la puntuación; los avisos antiguos de umbral sin contador de errores quedan pendientes de revisión. Las confirmaciones usan un diálogo integrado y el detalle muestra el modelo sobre la ruta del dispositivo.

## Requisitos

- Debian o Ubuntu con Python 3.10+, una versión de Node.js compatible con la versión de Vite incluida, systemd y `systemd-run`.
- Las dependencias del comprobador: `smartmontools`, `util-linux`, `coreutils` y, opcionalmente, `e2fsprogs` para badblocks.
- La página Web usa una contraseña de inicio de sesión y la API usa sesiones. Abra TCP 8765 solo en una LAN de confianza; HTTP no cifra la contraseña.

## Instalar Web UI desde main

La rama `main` no incluye el directorio compilado `web/dist`. En un sistema Debian con systemd, instale primero Node.js 20.19+ o 22.12+ y npm; compile la interfaz y ejecute el instalador. Node.js solo se necesita para compilar.

```bash
git clone --branch main --depth 1 https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/web
npm ci
npm run build
cd ..
sudo bash deploy/install.sh
```

## Compilación y ejecución

Tras extraer el archivo precompilado en el NAS Debian, entre en el directorio extraído y ejecute:

```bash
sudo bash deploy/install.sh
```

Tras instalar, abra `http://<NAS-IP>:8765` e introduzca la contraseña en la página de acceso. Léala con `sudo cat /root/apps/hdd-health-check/web-password`. Las actualizaciones conservan la contraseña y respaldan la versión anterior; el NAS no necesita Node.js.

Desde una copia de trabajo de confianza:

```bash
cd web
npm ci
npm run build
cd ..
sudo python3 web/server.py --port 8765
```

Abra `http://127.0.0.1:8765`. El proceso Python sirve la interfaz compilada; Node no hace falta durante la ejecución. La copia del código fuente y su directorio `web/dist` deben permanecer juntos. `npm run dev` ejecuta Vite en otro puerto local y redirige `/api` al servicio Python.

Para un servicio permanente, use el instalador anterior; la unidad systemd necesita el archivo de contraseña que genera.

Para retirar el servicio Web, ejecute `sudo systemctl disable --now hdd-health-web.service`, elimine el archivo de unidad instalado y ejecute `sudo systemctl daemon-reload`. Revise las comprobaciones transitorias activas antes de eliminar la copia de trabajo. Conserve o elimine el estado y los registros por separado, según las instrucciones de [desinstalación de la CLI](README.md#desinstalación).

La dirección `site-preview` de Codex solo sirve archivos estáticos. Muestra la interfaz y el registro de cambios incluido, pero no dispone del backend `/api` para ver discos o iniciar pruebas. Para consultar datos reales, abra la dirección del servicio Python. Desde otro equipo, ejecute allí `ssh -L 8765:127.0.0.1:8765 user@nas-host` y abra `http://127.0.0.1:8765`.

## Comportamiento y límites

- Las comprobaciones rápidas automáticas están desactivadas inicialmente. Al habilitarlas, se ejecuta una comprobación cada 6–168 horas. Si no hay ninguna comprobación programada anteriormente, la primera comienza poco después de habilitarlas. La programación solo incluye discos mecánicos e inicia el trabajo mediante una unidad transitoria de systemd.
- Las comprobaciones manuales se seleccionan por disco. Las profundas se limitan a discos mecánicos; un SSD incluido explícitamente solo puede recibir una comprobación rápida. La herramienta puede activar SMART o iniciar autopruebas internas de la unidad. Una parada segura conserva el progreso de la exploración de superficie, pero no cancela una autoprueba interna.
- `--no-install` impide que el servicio Web apruebe la instalación de paquetes al iniciar tareas. Instale por separado las dependencias ausentes. El servicio solo acepta nombres de comprobación fijos y dispositivos enumerados en ese momento; no utiliza un intérprete de comandos para construir las órdenes.
- El directorio privado de estado sigue siendo `/var/lib/hdd-health` y los registros permanecen en `/var/log/disk-health` de forma predeterminada. `web-schedule.json` se guarda en el directorio de estado con permisos 600. El navegador obtiene resultados e historial reciente mediante puntos de conexión JSON del mismo origen.
- El servicio valida Host y Origin. La API requiere una sesión con contraseña o una IPv4 de origen autorizada. Solo una sesión con contraseña puede editar la lista. No publique el puerto en Internet.
- Los controles están disponibles en los idiomas del proyecto. Los resúmenes detallados de comprobación y los registros de tareas en tiempo real proceden del comprobador Bash existente en chino y, por ahora, permanecen en chino en todos los idiomas de la interfaz.

## API

`GET /api/snapshot` devuelve la instantánea estructurada de discos del comprobador. `GET /api/status` devuelve el estado de la tarea activa. `GET /api/history/<device>` devuelve hasta 30 filas de contadores SMART. `GET` y `POST /api/schedule` gestionan el intervalo de comprobación rápida. `POST /api/jobs` inicia una comprobación fija en un dispositivo enumerado; `POST /api/jobs/stop` solicita una parada segura. Las rutas API desconocidas devuelven 404. La salida `--json` del comprobador es la fuente de la puntuación; el servicio Web no la vuelve a calcular.

Si SMART confirma el reposo, la lista y los detalles muestran En reposo; una lectura pendiente muestra Leyendo y una lectura fallida sigue siendo desconocida. La política se guarda en `/var/lib/hdd-health/web-preferences.json` y empieza desactivada. Cualquier usuario autenticado puede editar la lista IP y la política; el cambio de contraseña exige la contraseña actual.

## Interface and access

Arriba aparecen Panel, Registro de cambios y Ajustes, en ese orden. Panel permanece activo en Discos, Atención, Tareas (incluido su historial) y Controles programados. Pulsarlo en esas páginas conserva la página actual; desde Ajustes o Registro de cambios vuelve a `/disks`. El logo superior izquierdo siempre enlaza a `/disks`. Las cuatro tarjetas abren `/disks`, `/attention`, `/tasks` y `/schedule`; la evaluación con un clic sigue en Discos. Registro de cambios abre la página independiente `/changelog`, que también admite acceso directo.

La marca HDD Health de la esquina superior izquierda enlaza con el panel de discos en `/disks`. La pestaña del navegador usa el icono del proyecto de `web/public/favicon.svg`, incluido en la compilación de producción.

Ajustes reúne apariencia, la lista de IPv4 exactas sin contraseña, la política de reposo y la contraseña de acceso. Cualquier usuario que haya entrado puede editar la lista IP y la política. Quien entre por IP también ve directamente el formulario de cambio de contraseña; el servidor comprueba la contraseña actual. De forma predeterminada se dejan dormir los HDD, pero puede elegirse despertarlos uno a uno al abrir la página para leer su temperatura. Cada disco ofrece pestañas SMART y comprobaciones; los cambios se muestran como Markdown en una página separada.

La página principal permite elegir por separado el grupo de discos (SATA, HDD, SSD, NVMe o todos) y la prueba (rápida, SMART corta/larga, velocidad, superficie, badblocks, interfaz o completa). El servidor selecciona los discos enumerados y ejecuta la prueba elegida en segundo plano. Solo la evaluación completa puede producir una puntuación compuesta actual; las puntuaciones SSD/NVMe siguen reglas de HDD. La lista distingue SATA SSD y NVMe SSD según el medio y el transporte y obtiene la temperatura en segundo plano sin despertar HDD en reposo. Los detalles muestran el formato solo si el dispositivo lo informa; SATA o NVMe no permiten deducir que sea M.2. Los datos disponibles del enlace SATA o PCIe proceden de smartctl y Linux sysfs. Pulse las horas de uso para alternar con años, días y horas.

La tarjeta Atención filtra discos con avisos o errores. Los detalles muestran causas y descuentos; un resultado antiguo sin causa pide repetir la prueba. Tareas muestra la tarea activa y su registro detallado desplegable, además de un historial separado de las 30 tareas más recientes. Al terminar, detenerse o fallar, el recibo sale del panel activo y se guarda en `web-job-history/`; permanecen los resultados por disco y los registros del host. Los códigos 1 y 2 indican una prueba terminada con problemas.

La página principal suma la capacidad de los discos físicos y el uso de los sistemas de archivos montados, sin duplicar UUID. RAID y volúmenes sin montar pueden hacer que las cifras no sean comparables. SMART muestra las escrituras de SSD desde el contador NVMe estándar o estadísticas ATA con tamaño de sector conocido; no se infieren unidades de contadores del fabricante. La asignación de pools ZFS reconocidos también cuenta como uso. El control de capacidad alterna TB/TiB y un botón separado abre los detalles.

Tareas conserva la tarea activa y añade un historial separado con las 30 tareas Web más recientes terminadas, detenidas o fallidas. Puede mostrar la parte final del registro si aún existe. Los recibos nuevos se guardan en `web-job-history/`; los ya eliminados no pueden reconstruirse de forma fiable. Dashboard sigue activo arriba en Discos, Atención, Tareas y Controles programados.
