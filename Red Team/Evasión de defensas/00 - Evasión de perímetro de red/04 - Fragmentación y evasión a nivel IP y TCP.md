---
tags:
  - Evasion
  - Escaneo/Redes
  - Pentesting/Enumeracion
Descripción: "La caja de herramientas clásica de deformación de paquete, por qué funcionaba, por qué murió y qué queda vivo como diagnóstico"
Fecha de actualización: 2026-08-04
Nota previa: "[[03 - Egress filtering - por dónde se sale]]"
Nota siguiente: "[[05 - DPI, inspección TLS y blending de tráfico]]"
Area: "[[Evasión de perímetro.base|Evasión de perímetro]]"
---
---

Esta es la caja de herramientas que **todo el material antiguo llama "evasión de firewalls"**: fragmentar, meter *decoys*, falsear el origen, romper el checksum. La nota [[00 - El perímetro moderno - firewall, NGFW, IDS-IPS, NDR y WAF|de introducción]] ya adelantó el veredicto —casi todo está muerto—; esta explica **por qué funcionaba, por qué murió y qué queda**, porque entender el mecanismo es lo que te deja usar estas técnicas como **diagnóstico** en vez de creerte que evaden algo.

# Por qué funcionaba: inserción y evasión

La base teórica es un paper de 1998, Ptacek & Newsham, *Insertion, Evasion, and Denial of Service* — sigue siendo la lectura canónica. La idea: <mark style="background: #ADCCFFA6;">un IDS pasivo tiene que **reconstruir** el flujo que verá el host destino, pero no es el host, así que puede reconstruirlo distinto</mark>. Esa discrepancia se explota de dos formas:

- **Inserción**: haces que el IDS acepte un paquete que el host **rechazará**. El IDS "ve" bytes que el destino nunca procesa, y su reensamblado se desalinea del real.
- **Evasión**: al revés, haces que el host acepte algo que el IDS **descarta**. La firma vive en los bytes que el IDS tiró.

Las palancas para crear esa ambigüedad son la **fragmentación** (¿qué fragmento gana si dos se solapan?), el **TTL** (un paquete que expira entre el IDS y el host: el IDS lo ve, el host no) y el **checksum** (¿verifica el IDS lo que el host sí verifica?). Toda la "evasión clásica" es una variación de esto.

# Fragmentación IP: `-f` y `--mtu`

<mark style="background: #FFB86CA6;">Trocear el paquete para que ninguna pieza contenga la firma completa</mark>. `nmap -f` fragmenta en trozos de 8 bytes; `--mtu` fija el tamaño. El mecanismo y los flags están en [[07 - Evasión de firewalls, IDS e IPS|la nota de Nmap]].

Por qué murió, con nombre técnico: los IDS modernos hacen **reensamblado con conciencia del destino** (*target-based reassembly*). En **Suricata** el motor `defrag` y `stream` aplican una `host-os-policy` por rango de IPs: le dices que tal host es Linux, tal otro Windows, y reensambla los solapamientos **exactamente como lo haría ese sistema**. **Snort** hace lo mismo con `frag3` y sus políticas (`first`, `last`, `bsd`, `linux`, `windows`…). Cuando el IDS reensambla igual que el host, <mark style="background: #8000E1A6;">la ambigüedad que hacía posible la evasión desaparece</mark>. Y por delante, cualquier **firewall con estado** reensambla el datagrama antes de decidir, así que la firma vuelve a estar entera cuando se inspecciona.

> [!warning]+ La fragmentación puede empeorar tu OPSEC
> Un stream fragmentado en trozos de 8 bytes **no es tráfico normal**: es una anomalía en sí misma. Reglas de Suricata como las de la categoría `stream-events` disparan por *fragmentos solapados* o *tiny fragments*. Fragmentar hoy no te oculta: te **señala** ([[08 - Detección de escaneos y evasión moderna|detección moderna]]).

# Decoys y source spoofing: `-D` y `-S`

Los *decoys* (`-D`) mezclan tu escaneo con orígenes falsificados para diluir cuál es el real; `-S` falsea el origen por completo. Ambos chocan con dos muros:

- **Anti-spoofing de red** (BCP38 / RFC 2827, uRPF): los operadores serios descartan en el borde los paquetes cuyo origen no corresponde a la red de la que salen. Tus paquetes con IP falsificada **no llegan** desde una red bien configurada.
- **No ves las respuestas**: con `-S` puro, las respuestas van a la IP falsa, no a ti (por eso el *idle scan* necesitaba un "zombi" con IP ID predecible, hoy casi extinto). Con `-D`, **uno de los orígenes sigues siendo tú**, y el análisis de flujo o de comportamiento correlaciona igual: los *decoys* no ocultan el patrón de conexión del origen real, solo el paquete individual.

<mark style="background: #FF5582A6;">Contra un NDR que modela comportamiento, veinte orígenes falsos escaneando en sincronía perfecta son *más* sospechosos que uno solo</mark>.

# `--badsum`: el que sobrevive como diagnóstico

`nmap --badsum` envía paquetes con el checksum TCP/UDP **deliberadamente inválido**. Una pila de red real los descarta sin responder. Un middlebox de inspección que no valida el checksum puede, en cambio, responder o dejar rastro. Por eso <mark style="background: #ADCCFFA6;">una respuesta a `--badsum` prueba que hay un inspector en el camino</mark>, no un host real. No evade nada: **identifica** al perímetro. Es el ejemplo perfecto de la reconversión de toda esta caja: de arma a instrumento de medida.

# Qué queda vivo

| Técnica | Mecanismo | Estado 2026 | Uso residual |
| --- | --- | --- | --- |
| Fragmentación (`-f`, `--mtu`) | Firma partida entre fragmentos | Muerta contra lo que reensambla | Ninguno; empeora OPSEC |
| Decoys (`-D`) | Diluir el origen real | Muerta: anti-spoofing + correlación | Ninguno serio |
| Source spoof (`-S`) | Ocultar el origen | Muerta salvo idle scan (extinto) | Casos muy concretos de *SYN spoof* |
| `--badsum` | Checksum inválido | **Vivo como diagnóstico** | Detectar inspector en el camino |
| `--data-length` | Cambiar el tamaño/firma del paquete | Marginal | Despistar firmas de longitud fija |
| `--source-port 53/443` | Regla perezosa que confía en el "retorno" | **Vivo de verdad** | Atravesar firewalls mal escritos ([[02 - Descubrir la política de filtrado\|política de filtrado]]) |
| Juegos de TTL | Paquete que expira entre IDS y host | Muy nicho | Fingerprinting de topología |

<mark style="background: #8000E1A6;">Lo único de esta lista que sigue **evadiendo** es el puerto de origen de confianza</mark>, y no por deformar el paquete sino por explotar una regla mal escrita. El resto se ha reconvertido en instrumentos para saber qué tienes delante.

# Cómo se ejecuta hoy

Para las pruebas de flags y fragmentación en un escaneo, los flags de [[07 - Evasión de firewalls, IDS e IPS|Nmap]], las sondas de [[02 - Evasión de firewalls y detección con sx|sx]] y el modo de evasión de [[05 - Evasión de firewalls e IDS con masscan|masscan]] cubren el 90 % de los casos. Cuando necesitas **control total del paquete** —solapamientos a medida, secuencias de flags no estándar, campos manipulados uno a uno— la herramienta es [[🔨📦 Scapy|Scapy]], que construye la trama byte a byte. `fragroute`/`fragrouter`, la referencia clásica del paper de Ptacek, está archivada y sin mantenimiento; su función la hace hoy Scapy o `nping`.

> [!important]+ El encuadre correcto
> Trata este capítulo como **caja de diagnóstico**, no de evasión. Su valor en 2026 es responder «¿qué clase de dispositivo tengo delante?» —con estado o sin él, reensambla o no, verifica checksum o no— para decidir la estrategia real, que es la de las notas siguientes: [[05 - DPI, inspección TLS y blending de tráfico|blending]], [[06 - Rotación de origen e infraestructura sacrificable|rotación de origen]] y [[07 - Low-and-slow y evasión de umbrales|low-and-slow]].

> [!info]+ Fuentes
> Base teórica: Ptacek & Newsham, [*Insertion, Evasion, and Denial of Service: Eluding Network Intrusion Detection*](https://insecure.org/stf/secnet_ids/secnet_ids.html) (1998, mirror en insecure.org). Reensamblado consciente del destino: [documentación de Suricata](https://docs.suricata.io/en/latest/configuration/suricata-yaml.html) (`defrag` / `stream` host-os-policy) y el preprocesador `frag3` de [Snort](https://www.snort.org/). Consideraciones de seguridad de la fragmentación: [RFC 1858](https://www.rfc-editor.org/rfc/rfc1858); TCP moderno: [RFC 9293](https://www.rfc-editor.org/rfc/rfc9293). Anti-spoofing: [BCP38 / RFC 2827](https://www.rfc-editor.org/rfc/rfc2827). Los flags concretos, en [[07 - Evasión de firewalls, IDS e IPS]].
