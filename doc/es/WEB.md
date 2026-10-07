---
name: project-web-es
description: Instalación y uso de la interfaz Web local
metadata:
  version: "0.1.0"
  lang: "es"
---

# Interfaz Web local

La interfaz Web muestra los resultados de los discos locales, el historial reciente de contadores SMART, las tareas activas y una programación configurable de comprobaciones rápidas. Inicia las comprobaciones seleccionadas mediante la herramienta Bash existente. No presenta los resultados parciales o caducados como puntuación actual. Solo un lote de evaluación completo y vigente puede mostrar una puntuación numérica.

Las tarjetas de atención muestran la causa registrada. Las horas de encendido por sí solas no reducen la puntuación; los avisos antiguos de umbral sin contador de errores quedan pendientes de revisión. Las confirmaciones usan un diálogo integrado y el detalle muestra el modelo sobre la ruta del dispositivo.

## Multilingüe

[English](../en/WEB.md) | [简体中文](../WEB.md) | [繁體中文(台灣)](../zh-TW/WEB.md) | [繁體中文(香港)](../zh-HK/WEB.md) | [हिन्दी](../hi/WEB.md) | **Español** | [العربية](../ar/WEB.md) | [Français](../fr/WEB.md)

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Historial de versiones: [LOG](LOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

- Guía de la interfaz Web: [WEB](WEB.md)

## Requisitos

- Debian o Ubuntu con Python 3.10+, una versión de Node.js compatible con la versión de Vite incluida, systemd y `systemd-run`.
- Las dependencias del comprobador: `smartmontools`, `util-linux`, `coreutils` y, opcionalmente, `e2fsprogs` para badblocks.
- El servicio Web requiere root. El instalador Debian escucha en el puerto IPv4 8765 y usa una página de acceso y sesiones para la API. Abra `http://<NAS-IP>:8765` solo desde la misma LAN de confianza; no reenvíe el puerto a Internet. HTTP en LAN no cifra la contraseña. El reenvío local por SSH permite un transporte cifrado.

## Compilación y ejecución

El código Web UI actual está en `src/web/` y no incluye el resultado generado `dist/web/`. La etiqueta histórica `v3.0.0` conserva el antiguo diseño `web/`. En un equipo Debian con systemd, instale Node.js 22.12+ o 24+ y npm 10+, compile la interfaz y ejecute el instalador:

```bash
git clone https://github.com/CharlesGool/hdd-health-check.git
cd hdd-health-check/src/web
npm ci
npm run check
cd ../..
sudo bash deploy/install.sh
```


Tras extraer el archivo precompilado en el NAS Debian, entre en el directorio extraído y ejecute:

```bash
sudo bash deploy/install.sh
```

Tras instalar, abra `http://<NAS-IP>:8765` e introduzca la contraseña generada. Léala con `sudo cat /root/apps/hdd-health-check/web-password`; el instalador la conserva al actualizar y solo root puede leer el archivo. Security Settings solicita la contraseña administrativa antes de mostrar la lista IP o el formulario de cambio. Durante los cinco minutos de permiso, introduzca y confirme una contraseña nueva de 12–128 caracteres sin repetir la anterior; el cambio invalida todas las sesiones. Si la página no abre, compruebe `sudo systemctl status hdd-health-web.service` y que el cortafuegos permita TCP 8765 desde la LAN. El instalador no modifica las reglas del cortafuegos.

Desde una copia de trabajo de confianza:

```bash
cd src/web
npm ci
npm run check
cd ../..
sudo python3 src/web/server.py --port 8765
```

Abra `http://127.0.0.1:8765`. El proceso Python sirve la interfaz compilada; Node no hace falta durante la ejecución. La copia del código fuente y su directorio `dist/web` deben permanecer juntos. `npm run dev` ejecuta Vite en otro puerto local y redirige `/api` al servicio Python.

Para un servicio permanente, use el instalador anterior; la unidad systemd necesita el archivo de contraseña que genera.

Para retirar el servicio Web, ejecute `sudo systemctl disable --now hdd-health-web.service`, elimine el archivo de unidad instalado y ejecute `sudo systemctl daemon-reload`. Revise las comprobaciones transitorias activas antes de eliminar la copia de trabajo. Conserve o elimine el estado y los registros por separado, según las instrucciones de desinstalación de la CLI.

La dirección `site-preview` de Codex solo sirve archivos estáticos. Muestra la interfaz y el registro de cambios incluido, pero no dispone del backend `/api` para ver discos o iniciar pruebas. Para consultar datos reales, abra la dirección del servicio Python. Desde otro equipo, ejecute allí `ssh -L 8765:127.0.0.1:8765 user@nas-host` y abra `http://127.0.0.1:8765`.

El instalador `deploy/install.sh` comprueba el sistema, instala la aplicación en `/root/apps/hdd-health-check` y activa `hdd-health-web.service`. Consulte después el estado con `sudo systemctl status hdd-health-web.service`.

Antes de actualizar, haga una copia de seguridad de `/var/lib/hdd-health` junto con la versión correspondiente del script. La interfaz Web no cambia la política de migración del estado.

## Comportamiento y límites

- Las comprobaciones rápidas automáticas están desactivadas inicialmente. Al habilitarlas, se ejecuta una comprobación cada 6–168 horas. Si no hay ninguna comprobación programada anteriormente, la primera comienza poco después de habilitarlas. La programación solo incluye discos mecánicos e inicia el trabajo mediante una unidad transitoria de systemd.
- Las comprobaciones manuales se eligen por disco. En un SSD están disponibles la rápida, las autopruebas SMART corta y larga, la lectura completa de solo lectura y la evaluación completa. Los controles por lotes muestran la unión de módulos admitidos; los exclusivos de HDD omiten los SSD seleccionados. La herramienta puede activar SMART o iniciar autopruebas internas. Una parada segura conserva el progreso de superficie, pero no cancela una autoprueba interna.
- `--no-install` impide que el servicio Web apruebe la instalación de paquetes al iniciar tareas. Instale por separado las dependencias ausentes. El servicio solo acepta nombres de comprobación fijos y dispositivos enumerados en ese momento; no utiliza un intérprete de comandos para construir las órdenes.
- El estado privado permanece en `/var/lib/hdd-health` y los registros en `/var/log/disk-health`. `web-schedule.json`, `web-job.json`, los recibos terminados en `web-job-history/` y la lista de direcciones privadas con su interruptor en `web-access.json` se guardan allí con permisos restringidos. El navegador obtiene resultados e historial por JSON del mismo origen.
- El servicio instalado se vincula a todas las interfaces IPv4, pero solo acepta un Host que coincida con la IP y el puerto de destino. Comprueba Origin y exige una sesión con contraseña o una IP de origen admitida. Los archivos estáticos son públicos para que cargue el acceso. Solo una sesión administrativa que haya verificado recientemente la contraseña puede leer o editar la lista de IP privadas y su interruptor; entrar por IP solo concede acceso ordinario al panel. Al cerrar sesión, una cookie impide el acceso IP automático hasta volver a elegirlo. No hay TLS; quien observe el tráfico HTTP LAN puede ver la contraseña. Use una LAN de confianza o el túnel SSH y mantenga TCP 8765 cerrado a Internet. El comando manual `python3 src/web/server.py` sigue limitado a loopback salvo que se indiquen `--bind` y `--password-file`.
- Los controles están disponibles en los idiomas del proyecto. Los resúmenes detallados de comprobación y los registros de tareas en tiempo real proceden del comprobador Bash existente en chino y, por ahora, permanecen en chino en todos los idiomas de la interfaz.

## API

`GET /api/auth` informa del estado de acceso; `POST /api/auth/login`, `/api/auth/logout` y `/api/auth/ip-login` gestionan sesiones. `POST /api/auth/security-verify` comprueba la contraseña administrativa, rota la cookie de sesión y concede un permiso fijo de cinco minutos para Security Settings. `POST /api/auth/change-password` exige ese permiso y que coincidan la contraseña nueva y su confirmación; sustituye de forma atómica el archivo de contraseña propiedad de root e invalida las sesiones existentes.

`GET` y `POST /api/access` requieren el mismo permiso breve para leer o editar el interruptor y las direcciones IPv4 RFC 1918 o IPv6 locales únicas. `GET` y `POST /api/preferences` permiten a cualquier visitante autenticado leer y guardar la política de activar discos en reposo al entrar. `POST /api/disks/wake-on-visit` inicia esa operación en segundo plano. `GET /api/disks/<device>/smart` lee detalles SMART a petición sin activar un HDD en espera; `POST /api/disks/<device>/wake`, con autenticación, activa solo un disco mecánico enumerado.

`GET /api/snapshot` devuelve el estado estructurado del comprobador y `GET /api/status` la tarea activa con el tramo final del registro. `GET /api/jobs/history` devuelve resúmenes de tareas Web archivadas; `GET /api/jobs/history/<id>` muestra un tramo limitado del registro si todavía existe. Las tareas cuyos recibos ya se borraron no pueden reconstruirse con fiabilidad. `GET /api/history/<device>` devuelve hasta 30 filas SMART por compatibilidad; `GET /api/history/samples` muestra las muestras de todas las unidades enumeradas. `DELETE /api/history/samples/<device>/<index>`, con autenticación, borra una muestra y puede cambiar la base de comparación si era la última. `DELETE /api/jobs/history/<id>` borra un recibo archivado y su registro.

`POST /api/disks/<device>/sleep` solicita espera ATA solo para un HDD SATA enumerado y se rechaza durante una comprobación; la E/S del sistema puede despertarlo de nuevo. `GET` y `POST /api/schedule` gestionan el intervalo. `POST /api/jobs` inicia una comprobación fija en un dispositivo enumerado. `POST /api/jobs/assess` acepta `scope` con `sata`, `hdd`, `ssd`, `nvme` o `all`, y `module` con `quick`, `short`, `long`, `speed`, `surface`, `badblocks`, `iface` o `full`; inicia un lote en las unidades coincidentes. `POST /api/jobs/stop` pide una parada segura. Las rutas desconocidas devuelven 404. La salida `--json` del comprobador es la fuente de la puntuación; el servicio Web no la recalcula.

## Interfaz y acceso

Arriba aparecen Panel, Registro de cambios y Ajustes, en ese orden. Panel permanece activo en Discos, Atención, Tareas (incluido su historial) y Controles programados. Pulsarlo en esas páginas conserva la página actual; desde Ajustes o Registro de cambios vuelve a `/disks`. El logo superior izquierdo siempre enlaza a `/disks`. Las cuatro tarjetas abren `/disks`, `/attention`, `/tasks` y `/schedule`; la evaluación con un clic sigue en Discos. Registro de cambios abre la página independiente `/changelog`, que también admite acceso directo.

La marca HDD Health de la esquina superior izquierda enlaza con el panel de discos en `/disks`. La pestaña del navegador usa el icono del proyecto de `src/web/public/favicon.svg`, incluido en la compilación de producción. Un enlace de versión separado junto a la marca abre el historial de cambios. Las compilaciones sin etiqueta aparecen como `test-<sha>` (con `-dirty` si el árbol está modificado), y `/api/build` informa de la versión incorporada en la compilación. Las respuestas predeterminadas de instantánea y SMART solo envían números de serie ocultos; la instantánea pública también omite el ID interno del disco porque puede contener un número de serie; una solicitud autenticada separada obtiene el número completo únicamente tras una acción expresa del usuario. Se borra al ocultarlo o cerrar el detalle.

Ajustes ofrece idioma, ocho colores de acento y un interruptor de modo claro/oscuro, además de la política de reposo. El color y el modo se conservan por separado tras recargar la página. Una página separada de Security Settings guarda la lista de IP permitidas, su interruptor y el formulario de contraseña. Si no existe el permiso breve, solicita la contraseña administrativa y concede cinco minutos tras verificarla. Quien entre por IP puede usar los controles normales de discos y reposo, pero debe verificar la contraseña administrativa para abrir los ajustes protegidos. En ese plazo se introducen y confirman los 12–128 caracteres de la contraseña nueva sin repetir la anterior. El cambio invalida todas las sesiones. De forma predeterminada, los HDD en reposo permanecen así; opcionalmente se despiertan uno por uno al abrir la página. El detalle SMART oculta el número de serie hasta activar su control y vuelve a ocultarlo al cerrar.

La página principal permite elegir por separado el grupo de discos (SATA, HDD, SSD, NVMe o todos) y la prueba (rápida, SMART corta/larga, velocidad, superficie, badblocks, interfaz o completa). El servidor selecciona los discos enumerados y ejecuta la prueba elegida en segundo plano. Solo la evaluación completa puede producir una puntuación compuesta actual; las puntuaciones SSD/NVMe siguen reglas de HDD. La lista distingue SATA SSD y NVMe SSD según el medio y el transporte y obtiene la temperatura en segundo plano sin despertar HDD en reposo. Los detalles muestran el formato solo si el dispositivo lo informa; SATA o NVMe no permiten deducir que sea M.2. Los datos disponibles del enlace SATA o PCIe proceden de smartctl y Linux sysfs. Pulse las horas de uso para alternar con años, días y horas.

La tarjeta Atención filtra discos con avisos o errores. Los detalles muestran causas y descuentos; un resultado antiguo sin causa pide repetir la prueba. Tareas muestra la tarea activa y su registro detallado desplegable, además de un historial separado de las 30 tareas más recientes. Al terminar, detenerse o fallar, el recibo sale del panel activo y se guarda en web-job-history/; permanecen los resultados por disco y los registros del host. Los códigos 1 y 2 indican una prueba terminada con problemas.

La página principal suma la capacidad de los discos físicos y el uso de los sistemas de archivos montados, sin duplicar UUID. RAID y volúmenes sin montar pueden hacer que las cifras no sean comparables. SMART muestra las escrituras de SSD desde el contador NVMe estándar o estadísticas ATA con tamaño de sector conocido; no se infieren unidades de contadores del fabricante. La asignación de pools ZFS reconocidos también cuenta como uso. El control de capacidad alterna TB/TiB y un botón separado abre los detalles.

Tareas conserva la tarea activa y añade un historial separado con las 30 tareas Web más recientes terminadas, detenidas o fallidas. Puede mostrar la parte final del registro si aún existe. Los recibos nuevos se guardan en web-job-history/; los ya eliminados no pueden reconstruirse de forma fiable. Dashboard sigue activo arriba en Discos, Atención, Tareas y Controles programados.

La fila de disco muestra el modelo como título y la ruta `/dev/` aparte; el detalle también indica `/dev/`. Un botón específico abre los detalles. El servidor lanza un lote `<module> --rescan` y no acepta rutas de dispositivo arbitrarias del cliente. Solo el módulo `full` puede establecer una puntuación actual. La página `/changelog` muestra los cambios en Markdown. Las consultas de temperatura usan `smartctl -n standby` para no activar un HDD dormido; la opción de activación comprueba primero `-n standby` y luego obtiene atributos con `smartctl`.

## Evaluación y controles actuales de SSD

La evaluación completa de SSD/NVMe ejecuta una comprobación SMART rápida, autopruebas corta y larga y una lectura completa del disco. Omite el muestreo de velocidad; las lecturas lentas por sí solas no restan puntos de salud. Un lote completo sin anomalías obtiene 100 puntos; los hallazgos SMART o errores reales de lectura pueden reducir esta puntuación heurística. Si la selección incluye SSD, la interfaz solo ofrece comprobación rápida, autopruebas corta y larga, lectura completa y evaluación completa. Al pulsar la capacidad o los datos escritos se alternan unidades decimales y binarias. En los detalles SMART de un HDD en reposo hay un botón para activar solo ese disco.
