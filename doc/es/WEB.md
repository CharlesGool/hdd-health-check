---
name: web-es
description: Instalación, acceso e interfaz del controlador web local
metadata:
  version: "1.0.0"
  lang: "es"
---

# Guía web

## Multilingüe

[简体中文](../WEB.md) | [English](../en/WEB.md) | **Español**

## Alcance

Esta guía describe el controlador web local del código fuente actual, su instalación y formas de acceso. No garantiza que paquetes publicados antiguos incluyan todas las correcciones del código fuente actual.

## Compilación e instalación

Ejecute desde el directorio raíz del código fuente revisado:

```bash
cd src/web
npm ci
npm run check
cd ../..
sudo bash deploy/install.sh
```

La compilación requiere Node.js 22.12+ o 24+ y npm 10+. El servicio en ejecución requiere Python 3.10+, SMART y herramientas de dispositivos de bloque. El instalador solo admite Debian con systemd, instala las dependencias de ejecución faltantes, coloca la aplicación en `/root/apps/hdd-health-check`, la unidad en `/etc/systemd/system/hdd-health-web.service` y habilita un servicio protegido con contraseña en TCP 8765. El estado y los registros del host se conservan.

Acceda desde una LAN confiable a `http://<NAS-IP>:8765` e inicie sesión con `web-password` leído por el administrador desde el host. HTTP no cifra las credenciales; no exponga este puerto a Internet. También puede acceder al servicio mediante un túnel SSH. El servicio valida el Host destino y el Origin de mismo origen; no otorga acceso según cabeceras de reenvío arbitrarias.

Ejecución manual solo para desarrollo:

```bash
sudo python3 src/web/server.py --bind 127.0.0.1 --port 8765
```

Este modo solo escucha en loopback; si no se proporciona archivo de contraseña, usa modo de acceso local. Un enlace no loopback requiere `--password-file` apuntando a un archivo regular propiedad de root con permisos restringidos. La unidad LAN proporcionada por el instalador siempre pasa un archivo de contraseña.

## Páginas y permisos

| Página | Propósito |
| --- | --- |
| `/disks` | Panel de control, capacidad, tarjetas de disco y verificaciones por lotes |
| `/disks/<device>`, `/attention/<device>` | Detalle SMART, resultados de detección, visualización del número de serie y operaciones de encendido/apagado compatibles |
| `/attention` | Evidencia de anomalías y registros que requieren revisión |
| `/tasks` | Tareas actuales, recibos de completadas/detendidas/fallidas y registros disponibles |
| `/schedule` | Configuración programada de verificación rápida cada 6–168 horas |
| `/settings` | Idioma, modo claro/oscuro, ocho colores de tema, política de suspensión y acceso a seguridad |
| `/security` | Actualización de contraseña de administrador y control de acceso por IP |
| `/changelog` | Identificador de compilación y cambios oficiales, legible antes de iniciar sesión |

El inicio de sesión con contraseña establece una sesión. La API de seguridad requiere una verificación de contraseña de cinco minutos guardada por el servidor para esa sesión; modificar la contraseña invalida las sesiones existentes. El acceso por IP solo acepta direcciones IPv4 RFC 1918 exactas o `fc00::/7`, solo otorga permisos normales; acceder a la configuración de seguridad requiere revalidar la contraseña. Eliminar una dirección permitida revoca su acceso inmediatamente. El navegador limpia el registro de acceso por IP tras cerrar sesión o ser rechazado.

La navegación cambia de página inmediatamente. Las secciones de configuración solo hacen scroll hasta la tarjeta correspondiente; el acceso a seguridad valida por separado. Los números de serie privados están enmascarados por defecto; la operación de mostrar obtiene el texto original mediante una API de autenticación independiente; cambiar de pestaña o salir del detalle restaura el enmascaramiento. El idioma de la interfaz es uno de ocho; los registros de cambios de documentación están en chino simplificado/inglés/español, otros idiomas recurren al inglés.

## Verificaciones y límites de datos

Las solicitudes por lotes son seleccionadas por el servidor según el inventario de dispositivos y el alcance actuales, solo aceptan módulos fijos. Los SSD admiten verificación rápida, prueba corta, prueba larga, escaneo de superficie y evaluación completa; las selecciones mixtas omiten los SSD en verificaciones exclusivas de HDD. Las llamadas web añaden `--no-install`, no aprueban automáticamente la instalación de paquetes del sistema.

La configuración programada sigue guardándose y ejecutándose una vez habilitada; la actualización de instalación no la restablece. Detener el servicio web no equivale a detener verificaciones systemd independientes; solicite una parada segura desde la página o la CLI, que aún no cancela la autoverificación interna del disco.

El estado de salud crudo de SMART, la temperatura y los contadores no sustituyen la puntuación compuesta del lote. Los campos faltantes permanecen desconocidos; no se adivinan las unidades de contadores del fabricante. Los registros del host y los datos de tendencias pueden incluir identificadores de dispositivo; eliminar la última muestra SMART cambia la línea base de la próxima comparación.

## API

Excepto el estado de autenticación y las páginas estáticas, la API requiere acceso válido. En el modo con autenticación por contraseña, las solicitudes JSON que cambian estado también requieren `X-HDD-CSRF: 1`; las rutas de seguridad verifican adicionalmente permisos de contraseña recientes.

| Ruta | Función |
| --- | --- |
| `GET /api/auth`, `POST /api/auth/login`, `/ip-login`, `/logout` | Estado de acceso y sesiones |
| `POST /api/auth/security-verify`, `/change-password` | Verificación reciente y actualización de contraseña |
| `GET/POST /api/access` | Lista de IP protegida y interruptor |
| `GET /api/build`, `/api/changelog?lang=<lang>` | Versión incrustada en el artefacto y registros de cambios correspondientes |
| `GET /api/snapshot`, `/api/disks/<device>/smart`, `/serial` | Instantánea de disco, SMART y número de serie bajo demanda |
| `POST /api/disks/<device>/wake`, `/sleep`, `/api/disks/wake-on-visit` | Operaciones de encendido/apagado de un disco o al visitar |
| `GET/POST /api/preferences`, `/api/schedule` | Preferencias de suspensión y configuración programada |
| `POST /api/jobs`, `/api/jobs/assess`, `/api/jobs/stop` | Verificaciones, lote y parada segura |
| `GET /api/status`, `/api/jobs/history`, `/api/jobs/history/<id>` | Tareas actuales, recibos históricos y cola de registro acotada |
| `GET /api/history/<device>`, `/api/history/samples` | Datos de tendencias SMART |
| `DELETE /api/jobs/history/<id>`, `/api/history/samples/<device>/<index>` | Eliminar recibo/registro asociado o una muestra de tendencia |

`/api/jobs/assess` acepta alcance `sata,hdd,ssd,nvme,all` y módulos `quick,short,long,speed,surface,badblocks,iface,full`. No acepta comandos arbitrarios enviados por el navegador. Un código de retorno `1` o `2` indica que se completó pero se encontraron problemas, no un fallo al iniciar la tarea.

## Actualización y reversión

1. Primero termine o detenga las verificaciones y haga copia de seguridad del estado privado y los registros; verifique la versión actual y la unidad de servicio.
2. Tras actualizar y compilar el código fuente, vuelva a ejecutar el instalador. Conserva la contraseña, la aplicación antigua y la copia de unidad coincidente, intenta restaurar si el inicio falla; la instalación de paquetes no forma parte del alcance de reversión de archivos de aplicación.
3. Verifique el estado activo del servicio, el inicio de sesión con contraseña, `/api/build` y el inventario de discos. No use la visualización de páginas como sustituto de la evaluación completa de dispositivos.

Para revertir, primero detenga el servicio y las verificaciones independientes, restaure la aplicación, la unidad y la copia de estado coincidentes que deban revertirse, ejecute `sudo systemctl daemon-reload` y luego inicie el servicio. No elimine ni sobrescriba el directorio de estado a ciegas. Las actualizaciones reales en NAS y la recuperación tras reinicio aún requieren verificación en el host de destino.

## Verificación de desarrollo

Desde la raíz del código fuente ejecute `bash scripts/check.sh`. En `src/web/` ejecute `npm run check`, tras instalar Playwright Chromium ejecute `npm run test:ui`. Las pruebas de navegador usan un servicio de sesión aislado y dispositivos sintéticos; verifican versión, recurrencia de idioma, diseño responsivo, visualización de permisos, teclado y tacto simulado; no inician verificaciones reales.
