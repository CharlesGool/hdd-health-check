---
name: project-changelog-es
description: Historial de cambios
metadata:
  version: "1.0.0"
  lang: "es"
---

# Historial de cambios

## Multilingüe

[简体中文](../CHANGELOG.md) | [English](../en/CHANGELOG.md) | **Español**

## Documentación

- Descripción general del proyecto: [README](README.md)

- Justificación del diseño: [DESIGN](DESIGN.md)

- Estado del proyecto: [LOG](LOG.md)
- Registros históricos: [HISTORY](HISTORY.md)
- Historial de cambios: [CHANGELOG](CHANGELOG.md)

- Avisos de terceros: [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md)

## Historial de cambios

### v4.1.0 — 2026-09-29

Esta versión actualiza la interfaz Web y los detalles de los discos. La compilación de prueba anterior se comprobó en un NAS Debian con 13 discos enumerados; la compilación formal se comprobará por separado antes de publicarla.

#### Añadido

- Las tarjetas de discos abren páginas de detalle completas con ruta de navegación, control para volver, comprobaciones por disco, atributos SMART y explicaciones. Los números de serie siguen ocultos hasta que una acción autenticada los muestra; solo entonces se permite copiarlos. Los detalles de SSD/NVMe muestran lecturas y escrituras del anfitrión cuando el dispositivo proporciona contadores con unidades conocidas.
- La interfaz Web sigue la referencia visual compartida en el inicio de sesión, Dashboard, páginas de funciones, Settings, Security y Changelog. Añade diseños adaptables, controles localizados, iconos y animaciones opcionales de navegación y cambio de tamaño.

#### Cambiado

- Changelog puede abrirse desde el inicio de sesión antes de autenticarse y muestra la versión de compilación correspondiente. Los controles del detalle de disco usan un indicador de pestaña medido, y la respuesta a copias repetidas reinicia el temporizador que la descarta.
- La unidad de servicio del NAS mantiene `/var/lib/hdd-health` en modo 700 tras reiniciarse. El instalador sigue conservando la aplicación, la unidad y la contraseña Web anteriores durante las actualizaciones.

#### Corregido

- Se corrigieron el ancho y la posición del subrayado activo de SMART y Checks con anchos reducidos y los niveles de zoom probados, incluido RTL. También se mejoraron la respuesta del detalle de disco, las explicaciones de contadores SMART y la limpieza de animaciones de navegación interrumpidas.

#### Problemas conocidos y validación

- El usuario informó de un problema en la animación al volver del detalle del disco y pidió aplazarlo. Siguen sin verificarse una evaluación completa en HDD reales, la animación en navegadores móviles reales y la recuperación del servicio tras reiniciar el anfitrión. La puntuación de salud sigue siendo heurística, no una probabilidad de fallo calibrada.
- La comprobación de tipos de Vue, la compilación de producción, las comprobaciones del proyecto y las traducciones, y las comprobaciones locales de diseño en Chromium pasaron para la compilación de prueba. La implantación de prueba en el NAS superó las comprobaciones autenticadas de versión y API de lista de discos, además de las comprobaciones en navegador de ambos subrayados; no se exploraron discos ni se cambió la contraseña ni se reinició el sistema.

### v4.0.0 — 2026-09-28

Esta versión mayor actualiza el controlador Web local, su modelo de seguridad y la disposición del código fuente. Se comprobó la compilación de prueba autenticada en un NAS Debian con 13 discos enumerados. Siguen sin verificarse una evaluación completa en HDD reales y la recuperación del servicio tras reiniciar el equipo.

#### Añadido

- Las evaluaciones completas SSD/NVMe ejecutan SMART rápido, autopruebas corta y larga y una exploración integral de solo lectura sin muestreo de velocidad para HDD. Un lote limpio y completo obtiene 100 puntos según la heurística existente; las lecturas lentas por sí solas no restan puntos, pero los errores reales de lectura y los hallazgos SMART sí pueden hacerlo. Los controles para lotes mixtos muestran la unión de comprobaciones admitidas y omiten los SSD en módulos exclusivos de HDD.
- El historial de tareas conserva ejecuciones Web terminadas, detenidas y fallidas por separado del resultado más reciente de cada disco y las tendencias SMART. El detalle puede poner en reposo un HDD SATA apto o activar individualmente uno dormido.
- Ajustes ofrece ocho colores de acento y modos claro/oscuro. La versión junto al nombre del proyecto abre Changelog, y `/api/build` comunica el mismo identificador incorporado. Los números de serie permanecen ocultos en las respuestas normales y solo se obtienen tras una acción autenticada para mostrarlos.

#### Cambiado

- Security Settings tiene una ruta independiente y exige una verificación de contraseña de administrador durante cinco minutos, impuesta por el servidor. La verificación renueva la sesión; durante ese período el cambio de contraseña requiere el nuevo valor y su confirmación e invalida todas las sesiones. La admisión por IP sin contraseña tiene un interruptor y solo acepta direcciones exactas RFC 1918 IPv4 o ULA IPv6. No permite leer ni modificar los ajustes de seguridad. Las peticiones que cambian datos exigen una cabecera del mismo origen; las cabeceras de reenvío del cliente no establecen la dirección de origen.
- El código fuente reside en `src/checker/` y `src/web/`, con archivos generados de la interfaz en `dist/web/`; se conservan el punto de entrada CLI de la raíz y la disposición instalada en el NAS. Los directorios de idiomas usan nombres BCP-47. La vista de discos se adapta al ancho disponible y las cuatro funciones del panel tienen páginas propias.

#### Corregido

- El estado de las tareas responde durante las autopruebas de todos los discos, muestra por separado los resultados SMART cortos y largos y conserva registros históricos de tareas. Se corrigen las bandas de temperatura NVMe y se evita descontar puntos solo por temperatura o variación de velocidad SSD. Las comprobaciones limpias con cobertura parcial ya no devuelven una advertencia solo por esa cobertura.
- El instalador Debian incluye ahora la cabecera requerida en la comprobación de salud autenticada y revierte los cambios si ocurre un error explícito después de iniciar la sustitución de archivos.

#### Validación

- Pasaron las pruebas Shell y Python, la comprobación de tipos Vue y la compilación de producción, los controles documentales y estructurales y las pruebas locales en navegador. El despliegue de prueba en NAS pasó las comprobaciones API autenticadas y de Security Settings en navegador, incluido el ocultamiento de series y una vista de 390 px sin desbordamiento horizontal. No se ejecutaron exploraciones de disco, cambios de contraseña ni reinicios durante la preparación de esta versión; la puntuación de salud no es una probabilidad calibrada de fallo.

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

### v2.3.0 — 2026-09-24

#### Changed

Esta versión incluye la integración v2.2 antes no etiquetada: resultados persistentes por disco, historial de contadores SMART, módulos interactivos y por lotes, exploraciones de superficie reanudables y de solo lectura, verificación de interfaz, tareas transitorias opcionales de systemd y análisis más seguro de estados como datos. No conserva la compatibilidad con la CLI ni el estado de v1: `-w/--wait` se ignora en vez de esperar; guarde el estado antes de actualizar y restaure el estado correspondiente al volver a un script anterior. La puntuación revisada siguiente solo tiene pruebas sintéticas, no en un HDD real.

#### Fixed

- Reconoce el primer registro de autoprueba SMART recién completada; los registros antiguos, incompletos o de otro tipo no cuentan como prueba nueva completada.
- Un lote completo marca la prueba SMART rápida, corta y larga, el muestreo de velocidad y la exploración de superficie terminada bajo un mismo identificador; repite SMART/ATA/CRC al final. Solo los resultados completos, válidos y del mismo lote permiten una puntuación global numérica. Reutilización, interrupción, caducidad, estado antiguo sin marcador y verificación posterior de interfaz dejan los registros anteriores como históricos/pendientes de revisión y el grado general parcial/desconocido; consultar un informe no actualiza la base de comparación rápida. La verificación de interfaz registra aparte si se resolvió el problema; no atribuye de nuevo errores antiguos ni convierte el lote anterior en actual. Un total ATA sin contador previo conserva un descuento de 5 puntos por riesgo no resuelto en revisiones y evaluaciones completas posteriores, también si el registro antiguo carece del campo de riesgo. Una subida resta 20 puntos; la estabilidad no es un nuevo error ni prueba una reparación, y la verificación de interfaz sola no atribuye los errores ATA antiguos a ella. Las lecturas lentas aisladas exigen revisar el rendimiento, no diagnostican sectores defectuosos; los fallos repetidos de lectura de superficie siguen restando 40 puntos. Son pesos heurísticos, no probabilidades de fallo.

### v1.0.0 — 2026-08-08

#### Added

- Comprobación inicial de salud de HDD de 12 dimensiones: datos de dispositivo e interfaz, capacidad SMART y evaluación global, atributos ATA o contadores de defectos/errores SAS, registros de errores y autopruebas, inicio de autopruebas cortas/largas, vida útil/carga, errores de E/S del kernel, detección de montajes y de solo lectura, medición opcional de rendimiento con `hdparm` de solo lectura y exploración con `badblocks`.
- Puntuación heurística de 0 a 100 y cuatro niveles con códigos de salida del proceso 0/1/2/3, detección automática del acceso directo a SMART, selección interactiva y por lotes de discos, y oferta de instalación mediante `apt` de `smartmontools` si faltaba.
- Los documentos completos de diseño y uso de v1.0.0 se conservan en la etiqueta Git `v1.0.0` (por ejemplo, `git show v1.0.0:DESIGN.md` y `git show v1.0.0:README.zh.md`); los comandos antiguos de v1 no son instrucciones actuales.
