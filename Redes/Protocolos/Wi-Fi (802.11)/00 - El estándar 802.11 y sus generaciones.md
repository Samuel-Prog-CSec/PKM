---
tags:
  - Redes
  - Protocolos
  - Wi-Fi/802.11
  - Tipo/Introduccion
Descripción: "Qué define IEEE 802.11, cómo se organiza en enmiendas y qué aporta cada generación Wi-Fi 1-7, con las enmiendas de seguridad que un pentester necesita reconocer"
Fecha de actualización: 2026-08-01
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">`IEEE 802.11` es la familia de estándares que define las capas física (`PHY`) y de control de acceso al medio (`MAC`) de las redes de área local inalámbricas</mark>. "Wi-Fi" no es el estándar: es la marca comercial de la **Wi-Fi Alliance**, el consorcio que certifica la interoperabilidad entre productos que implementan 802.11. Un dispositivo puede cumplir 802.11 y no estar certificado Wi-Fi, y la certificación añade requisitos propios —especialmente de seguridad— que el estándar IEEE deja como opcionales.

Esa distinción importa en un pentest: cuando un fabricante dice "compatible con Wi-Fi 6" está afirmando que pasó el programa de certificación de la Alliance, lo que **arrastra obligaciones de seguridad** (WPA3, `PMF`) que no vienen impuestas por el documento del IEEE.

# Cómo se organiza el estándar

802.11 no es un documento único que se reescribe: es un **documento base con enmiendas** (*amendments*) identificadas por letras. Cada enmienda añade capacidades y, cada varios años, el grupo de trabajo publica una **revisión consolidada** que las integra todas.

- La revisión vigente es **`IEEE Std 802.11-2024`**, publicada el **28 de abril de 2025** ([IEEE 802.11 Working Group](https://www.ieee802.org/11/)). Sustituye a la anterior, 802.11-2020.
- Las enmiendas posteriores a una revisión viven aparte hasta la siguiente consolidación. **`802.11be-2024`** (Wi-Fi 7) recibió la aprobación final del IEEE SA Standards Board en **septiembre de 2024** y se publicó el **22 de julio de 2025** ([IEEE SA](https://standards.ieee.org/ieee/802.11be/7516/)).

<mark style="background: #FFB8EBA6;">La consecuencia práctica es que "802.11" a secas casi nunca es lo que se está mirando</mark>: el comportamiento real de un despliegue depende de qué enmiendas implementa cada AP y cada cliente, y esa mezcla es desigual dentro de una misma red.

# Las generaciones Wi-Fi

En 2018 la Wi-Fi Alliance introdujo la numeración generacional para que el usuario no tuviera que descifrar sufijos. Sólo se numeraron las enmiendas de rendimiento, retroactivamente desde 802.11n.

| Enmienda | Marca | Año | Bandas | Ancho máx. | Modulación | Tasa PHY máx. |
| -------- | ----- | --- | ------ | ---------- | ---------- | ------------- |
| 802.11b | — | 1999 | 2,4 GHz | 22 MHz | CCK | 11 Mb/s |
| 802.11a | — | 1999 | 5 GHz | 20 MHz | OFDM 64-QAM | 54 Mb/s |
| 802.11g | — | 2003 | 2,4 GHz | 20 MHz | OFDM 64-QAM | 54 Mb/s |
| 802.11n | Wi-Fi 4 | 2009 | 2,4 + 5 GHz | 40 MHz | 64-QAM · MIMO 4×4 | 600 Mb/s |
| 802.11ac | Wi-Fi 5 | 2013 | 5 GHz | 160 MHz | 256-QAM · MU-MIMO (bajada) | ~6,9 Gb/s |
| 802.11ax | Wi-Fi 6 / 6E | 2021 | 2,4 + 5 (+ 6 GHz en 6E) | 160 MHz | 1024-QAM · OFDMA · MU-MIMO bidireccional | ~9,6 Gb/s |
| 802.11be | Wi-Fi 7 | 2024 | 2,4 + 5 + 6 GHz | 320 MHz | 4096-QAM · MLO · 16 flujos | ~46 Gb/s |

Tres saltos conceptuales explican casi toda la tabla:

- **MIMO** (802.11n) — varias antenas transmitiendo flujos espaciales simultáneos sobre el mismo canal. Multiplica el caudal sin ampliar el espectro.
- **OFDMA** (802.11ax) — el canal se reparte en unidades de recurso que sirven a varios clientes *dentro de la misma transmisión*. Wi-Fi 6 no es "más rápido" punto a punto tanto como **mucho más eficiente en entornos densos**.
- **MLO** (*Multi-Link Operation*, 802.11be) — un cliente se asocia simultáneamente por varias bandas y reparte o duplica el tráfico entre ellas. <mark style="background: #8000E1A6;">Esto rompe la premisa de que un cliente vive en un canal: bajo MLO, capturar una sola banda deja la sesión incompleta</mark>, y una captura pasiva "limpia" puede estar perdiendo la mitad de la conversación.

> [!info]+ Wi-Fi 8 (802.11bn)
> El grupo de tarea **TGbn** trabaja en *Ultra High Reliability* (UHR), la base de la futura Wi-Fi 8. El objetivo declarado no es más caudal pico sino **latencia y fiabilidad deterministas** (percentil 99, no media). Sigue en desarrollo, sin certificación comercial: cualquier producto que se anuncie hoy como "Wi-Fi 8" lo hace sobre borrador.

# Las enmiendas que importan en seguridad

Las generaciones venden caudal; el trabajo de un pentester depende de otras letras, que no aparecen en ninguna caja de producto.

| Enmienda | Año | Qué aporta | Por qué importa ofensivamente |
| -------- | --- | ---------- | ----------------------------- |
| **802.11i** | 2004 | `RSN`, WPA2, CCMP/AES, el *4-way handshake* | Define el intercambio que se captura para crackear WPA2 |
| **802.11r** | 2008 | *Fast BSS Transition* (roaming rápido) | Expone el `PMKID`, base del ataque sin clientes contra WPA2 |
| **802.11k** | 2008 | Informes de vecinos y de medida | Un cliente revela el mapa de APs que ve; útil en reconocimiento |
| **802.11v** | 2011 | *BSS Transition Management* | <mark style="background: #FF5582A6;">Permite empujar a un cliente fuera de un AP sin enviar una sola trama de desautenticación</mark> |
| **802.11w** | 2009 | `PMF` — protección de tramas de gestión | Es lo que rompe el ataque de deauth clásico |
| **802.11ad** | 2012 | `DMG` a 60 GHz (WiGig) | Introduce el tipo de trama *Extension* |
| **802.11ah** | 2016 | `S1G` sub-1 GHz (Wi-Fi HaLow) | IoT de largo alcance, fuera del alcance de una tarjeta común |
| **802.11bh** | 2024 | Identificación de clientes con MAC aleatorizada | Contramedida al *tracking*; publicada el 3 de junio de 2025 |

`802.11w` merece una lectura aparte. <mark style="background: #FFB86CA6;">Con `PMF` activo, las tramas de gestión post-asociación llevan un código de integridad, así que una trama de desautenticación forjada se descarta sin efecto</mark> — y con ella cae el ataque más enseñado del pentesting Wi-Fi. Desde el programa **Wi-Fi CERTIFIED 6** (2020) `PMF` es obligatorio para certificar, y **Wi-Fi 7 exige WPA3 o Enhanced Open más `PMF`** para operar en tasas 802.11be y funciones como MLO, además de *beacon protection* en AP y cliente ([Cisco Meraki · Wi-Fi 7 Technical Guide](https://documentation.meraki.com/Wireless/Design_and_Configure/Architecture_and_Best_Practices/Wi-Fi_7_(802.11be)_Technical_Guide)).

> [!warning]+ Lo que no protege PMF
> `PMF` cubre las tramas de gestión **después** de la asociación. Beacons y *probe requests* siguen en claro porque deben ser legibles por dispositivos que aún no se han asociado. Sobre ese hueco se construyen los ataques modernos: Schepers y Vanhoef demostraron que se puede forzar la desconexión falsificando un beacon con un ancho de canal inválido, lo que hace que el kernel de Linux abandone la red ([*On the Robustness of Wi-Fi Deauthentication Countermeasures*, WiSec 2022](https://papers.mathyvanhoef.com/wisec2022.pdf)). El vector sigue vivo en 2026: **`CVE-2025-71127`** describe beacons unicast usados como ataque dirigido contra estaciones asociadas en el kernel de Linux.

# Qué mirar en un engagement

La generación anunciada de un despliegue dice poco por sí sola; lo que fija la superficie de ataque es la combinación de enmiendas activas.

- **Un AP Wi-Fi 6 mal configurado puede tener `PMF` en modo opcional**, no requerido. Ese matiz decide si la deauth funciona o no, y no se ve en el modelo del equipo.
- **La red suele ser heterogénea.** Un SSID con clientes de 2015 conviviendo con clientes de 2025 obliga al AP a ofrecer modos de compatibilidad, y <mark style="background: #FF5582A6;">el eslabón más débil marca la seguridad efectiva del conjunto</mark>: un modo de transición WPA3/WPA2 acepta asociaciones WPA2 y, con ellas, todos los ataques de WPA2.
- **802.11v cambia el juego de la desconexión.** Donde `PMF` bloquea la deauth, una petición de transición BSS puede conseguir el mismo efecto por la vía legítima del protocolo: el AP le sugiere al cliente que se mueva y, si no lo hace antes de que expire el temporizador, lo desasocia ([Cisco · 802.11v BSS Transition](https://www.cisco.com/c/en/us/support/docs/wireless-mobility/wireless-lan-wlan/201015-802-11v-Basic-Service-Set-BSS-on-AireO.html)).

La forma concreta de esas tramas —qué campos lleva cada una y cuáles se pueden falsificar— se detalla en [[02 - Arquitectura 802.11 y la trama MAC]]. Dónde se emiten, con qué potencia y bajo qué límites legales, en [[01 - Bandas, canales y regulación del espectro]]. La contraparte ofensiva vive en [[00 - Metodología del pentest Wi-Fi]].
