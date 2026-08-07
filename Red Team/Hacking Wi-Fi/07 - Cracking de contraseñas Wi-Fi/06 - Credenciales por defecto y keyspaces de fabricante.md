---
tags:
  - Wi-Fi/WPA
  - Seguridad/Contraseñas
  - Pentesting/Enumeracion
Descripción: "Identificar al fabricante correctamente con los tres registros del IEEE y atacar el keyspace acotado que genera su firmware en vez de un diccionario ciego"
Fecha de actualización: 2026-08-04
Nota previa: "[[05 - Wordlists dirigidas a redes Wi-Fi]]"
Nota siguiente: "[[07 - Precomputación de PMK y su vigencia real]]"
Area: "[[Cracking Wi-Fi.base|Cracking Wi-Fi]]"
---
---

Una contraseña de fábrica parece fuerte —`sleeksalamander113` tiene 18 caracteres— pero <mark style="background: #ADCCFFA6;">no se genera al azar, sino con una plantilla</mark>. Si se conoce la plantilla, el espacio de búsqueda cae de 10¹⁵ a unos pocos millones, y el ataque pasa de imposible a instantáneo.

# Identificar al fabricante sin equivocarse

El BSSID de un AP es casi siempre su MAC real (a diferencia de los clientes, que hoy la aleatorizan). Sus primeros bytes identifican al titular del bloque en el registro del IEEE.

> [!warning]+ `grep` sobre `oui.txt` sólo cubre un tercio del problema
> El IEEE mantiene **tres registros** con longitudes de prefijo distintas, y buscar únicamente en el de 24 bits produce falsos negativos silenciosos:
>
> | Registro | Prefijo | Direcciones | Fichero |
> | -------- | ------- | ----------- | ------- |
> | **MA-L** | 24 bits | ~16,7 M | [`oui/oui.txt`](https://standards-oui.ieee.org/oui/oui.txt) |
> | **MA-M** | 28 bits | ~1 M | [`oui28/mam.txt`](https://standards-oui.ieee.org/oui28/mam.txt) |
> | **MA-S** | 36 bits | 4.096 | [`oui36/oui36.txt`](https://standards-oui.ieee.org/oui36/oui36.txt) |
>
> <mark style="background: #FF5582A6;">Con un bloque MA-M o MA-S, los 24 primeros bits **no identifican al fabricante**</mark>: pertenecen al bloque padre que el IEEE reparte entre varias empresas. La búsqueda correcta es por prefijo más largo primero. Los fabricantes pequeños —y muchos de IoT— compran MA-S precisamente por precio.

```shell-session
$ grep -i "^107BEF" /var/lib/ieee-data/oui.txt
107BEF     (base 16)		Zyxel Communications Corporation
```

El paquete `ieee-data` de Debian trae **los tres registros** en `/var/lib/ieee-data/` (`oui`, `mam`, `oui36`, más `iab`), así que la búsqueda por prefijo largo se puede hacer sin conexión. La consulta correcta prueba del prefijo más largo al más corto:

```shell-session
$ MAC=107BEF08A3B4
$ grep -i "^${MAC:0:9}" /var/lib/ieee-data/oui36.txt \
  || grep -i "^${MAC:0:7}" /var/lib/ieee-data/mam.txt \
  || grep -i "^${MAC:0:6}" /var/lib/ieee-data/oui.txt
```

> [!warning]+ Los datos locales caducan
> `/var/lib/ieee-data/` se refresca con **`update-ieee-data`** —no `update-oui`, que es el nombre antiguo—, y sólo descarga si la copia tiene más de cinco días (`-f` lo fuerza). Debian instala un `cron.monthly`, pero en una caja de ataque recién montada o sin salida a internet los ficheros pueden ser los del paquete. <mark style="background: #FF5582A6;">Si un AP reciente "no tiene fabricante", el problema suele ser la copia local, no el AP</mark>.

`hcxhashtool` resuelve esto sin salir del flujo, y trabaja directamente sobre el fichero de hashes:

```shell-session
$ hcxhashtool -i hash.hc22000 --info-vendor-ap=stdout
$ hcxhashtool -i hash.hc22000 --oui-ap=107bef -o zyxel.hc22000
```

# Del fabricante al keyspace

Conocido el fabricante y el modelo —que sale de `hcxpcapngtool -D`, ver [[05 - Wordlists dirigidas a redes Wi-Fi]]—, el objetivo es la **plantilla de generación** de su firmware.

El caso canónico es Netgear: `{adjetivo}{sustantivo}{3 dígitos}`, que produce `sleeksalamander113` o `abandonedelephant556`. El espacio es `|adjetivos| × |sustantivos| × 1000`: con listas de unos pocos cientos de palabras cada una, salen entre **10⁷ y 10⁸ candidatas** — segundos o minutos de GPU, frente a los 81 años del espacio libre de 8 caracteres calculado en [[04 - Anatomía de una contraseña Wi-Fi]].

<mark style="background: #8000E1A6;">Es el mismo tipo de victoria que el número de teléfono</mark>: no se ataca la contraseña, se ataca el generador.

Otras plantillas habituales que conviene reconocer sobre la marcha:

| Patrón observado | Familia típica |
| ---------------- | -------------- |
| 8-10 dígitos decimales | Routers de operador (INFINITUM, VodafoneNet, INEA) |
| 8 hex en mayúsculas | Derivado de la MAC o del número de serie |
| Palabra + 4 dígitos | Firmware genérico de ODM |
| Fecha completa `DDMMYYYY` | Configurado a mano, no de fábrica |

# La herramienta que sustituye a diez repositorios

HTB enumera media docena de generadores sueltos de GitHub. <mark style="background: #FFB86CA6;">`hcxpsktool` cubre la mayoría de esos keyspaces de forma nativa</mark>, alimentándose del propio fichero de hashes —de donde saca ESSID y MAC— y documentando el tamaño de cada lista:

| Opción | Familia cubierta | Tamaño |
| ------ | ---------------- | ------ |
| `--netgear` | NETGEAR, ORBI, NTGR_VMB, ARLO_VMB, FoxtelHub | — |
| `--spectrum` | MySpectrumWiFi, SpectrumSetup, MyCharterWiFi | > 3,3 GB |
| `--digit10` | INFINITUM, ALHN, INEA, VodafoneNet, VIVACOM | > 1 GB |
| `--phome` | PEGATRON / Vantiva (CBCI, HOME, SPSETUP) | > 2,9 GB |
| `--alticeoptimum` | MyAltice, MyOptimum | > 6,3 GB |
| `--ee` / `--eeupper` | EE, BrightBox, EE-Hub | > 1,4 / 4,0 GB |
| `--tenda`, `--asus` | Tenda/NOVA/BrosTrend, ASUS RT-AC | — |
| `--wpskeys`, `--weakpass`, `--eudate` | Claves WPS, débiles genéricas, fechas europeas | — |

```shell-session
$ hcxpsktool -c hash.hc22000 --netgear --weakpass | sort -u > candidatas.txt
$ hcxpsktool -c hash.hc22000 --maconly                    # sólo lo derivado de la MAC del AP
$ hashcat -m 22000 hash.hc22000 candidatas.txt
```

`--maconly` es el arranque más barato que existe: unos miles de candidatas derivadas del BSSID, que resuelven un porcentaje real de routers domésticos en menos de un segundo.

> [!info]+ Estado de los generadores externos (verificado 2026-08-04)
> De los que enlaza HTB: `RealEnder/imeigen` sigue vivo (mayo 2026); `redsquirrel7/Netgear-Password-Constructinator` está en 2022 y `LivingInSyn/netgear_hashcat_wordlist` en 2021 —siguen sirviendo, porque las plantillas de firmware no cambian—; `sheimo/Wifi-WPA-Keyspace-List` (2017) y `datagoboom/twcracker` (2017) están abandonados; `ahmdrz/wifi-password-generator` lleva **desde 2016** sin tocarse.

# La vía WPS y el aviso de repositorio huérfano

Si el AP tiene WPS activo, el PIN por defecto suele derivarse del BSSID, y recuperarlo entrega la PSK directamente sin crackear nada. Todo el desarrollo está en [[06 - Algoritmos de generación de PIN]] y [[03 - Fuerza bruta online del PIN]].

> [!warning]+ `wpspin` y `OneShot` de `drygdryg` han desaparecido de GitHub
> Los módulos 312 y 305 enlazan `github.com/drygdryg/wpspin` y `drygdryg/OneShot`. <mark style="background: #FF5582A6;">Ambos devuelven **404**</mark> (verificado el 2026-08-04). El fork mantenido de OneShot es [`fulvius31/OneShot`](https://github.com/fulvius31/OneShot), con actividad en junio de 2026.
>
> Un nombre de repositorio huérfano que aparece en cursos y tutoriales es un **objetivo de suplantación**: cualquiera puede registrar la cuenta abandonada y publicar código bajo la URL que miles de guías siguen enlazando. Instalar herramientas de credenciales desde un enlace que devuelve 404 hoy y algo mañana es exactamente el vector que se quiere evitar. La generación de PIN también la cubre `hcxpsktool --wpskeys` sin depender de terceros.

# Qué significa encontrarlo

Una PSK de fábrica sin cambiar no es sólo "contraseña débil". Implica que <mark style="background: #FFB8EBA6;">el equipo se instaló y nadie volvió a tocarlo</mark>, lo que en un informe se traduce en dos hallazgos independientes: la credencial recuperable y la ausencia de proceso de puesta en servicio. El segundo suele tener más recorrido con el cliente que el primero, porque afecta a todo el parque y no a un dispositivo.
