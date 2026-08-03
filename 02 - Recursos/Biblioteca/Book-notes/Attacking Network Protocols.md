---
tags:
  - Biblioteca
  - Protocolos
  - Redes
Fecha de actualización: 2026-08-03
Autores:
  - James Forshaw
Editorial: No Starch Press
Año: 2018
ISBN: 978-1-59327-750-5
Portada: https://covers.openlibrary.org/b/isbn/9781593277505-L.jpg
PDF: "[[attackingnetworkprotocols.pdf]]"
Estado: Aceptada
Rating:
Area: "[[Librería.base|Librería]]"
---
---

# Attacking Network Protocols

![Portada de Attacking Network Protocols](https://covers.openlibrary.org/b/isbn/9781593277505-L.jpg)

**A Hacker's Guide to Capture, Analysis, and Exploitation** — prólogo de Katie Moussouris (fundadora de Luta Security, ex-responsable del programa de *bug bounty* de Microsoft).

## Sinopsis

Guía de James Forshaw (investigador de Google Project Zero, poseedor de la mayor recompensa jamás pagada por Microsoft — 100.000$ — y antiguo #1 del ranking público del MSRC) sobre cómo auditar la seguridad de un protocolo de red desde cero, sin depender de documentación oficial ni de herramientas ya construidas para ese protocolo concreto. Forshaw es también el creador de `Canape`, la herramienta de análisis de protocolos que usa como hilo conductor en varios capítulos.

Arranca por la base — captura de tráfico de aplicación con `Wireshark` y desarrollo de proxies/interceptores a medida — y escala en dificultad hacia el análisis estático y dinámico de la estructura del protocolo (formatos binarios, texto plano, TLV, serialización tipo `ASN.1`) y la ingeniería inversa de la propia aplicación que lo implementa cuando no queda otra que leer el binario.

La segunda mitad se centra en encontrar y explotar vulnerabilidades: modelado de amenazas específico para protocolos de red, las causas raíz más habituales (corrupción de memoria, *bypass* de autenticación, denegación de servicio) y cómo automatizar su descubrimiento con *fuzzing* dirigido y depuración. Cierra con un apéndice-*toolkit* de herramientas de análisis de protocolos.

Publicado en 2018: `Canape` lleva años sin mantenimiento activo y algunas referencias de *tooling* han quedado desfasadas (`Wireshark`, `Scapy` y `mitmproxy` siguen siendo el estándar actual para la captura/manipulación descrita en los primeros capítulos), pero la metodología de análisis y explotación de protocolos —el grueso real del libro— sigue vigente como referencia.

## Qué cubre el libro

- Fundamentos de *networking* aplicados a la perspectiva de un atacante (capas, sockets, tráfico cliente-servidor).
- Captura de tráfico de aplicación con `Wireshark` y desarrollo de proxies/interceptores propios.
- Estructuras comunes de protocolos de red: formatos binarios, texto plano, TLV y serialización tipo `ASN.1`.
- Análisis estático y dinámico del protocolo, incluida ingeniería inversa de la aplicación que lo implementa.
- Criptografía aplicada a protocolos: dónde se implementa mal y cómo detectarlo.
- Modelado de amenazas y causas raíz de vulnerabilidades: corrupción de memoria, *bypass* de autenticación, denegación de servicio.
- *Fuzzing* dirigido y depuración para automatizar el descubrimiento de vulnerabilidades.
- Apéndice con un *toolkit* completo de herramientas de análisis de protocolos de red.

## Enlace

[[attackingnetworkprotocols.pdf|Abrir PDF]]

## Dónde vive en el PKM

El libro se ingirió al vault el **2026-08-03** como el área **[[Hacking de protocolos.base|Red Team/Hacking de protocolos]]** (49 notas en 6 sub-temas), modernizando el contenido a 2026 y señalando explícitamente lo desfasado. Correspondencia capítulo → sub-tema:

| Capítulos | Sub-tema |
| - | - |
| 1, 2, 5 | [[Análisis de protocolos.base\|00 - Metodología de análisis]] — modelo de tres capas, captura pasiva/activa, proxies no-HTTP, disectores Lua |
| 3 | [[Estructuras de protocolo.base\|01 - Estructuras de protocolo]] — enteros, TLV, longitud variable, ASN.1, codificaciones |
| 4 | [[MITM de red.base\|02 - MITM a nivel de red]] — routing/NAT, ARP, DHCP, DNS **+ IPv6/mitm6 (net-new)** |
| 6 | [[Reversing de protocolos.base\|03 - Reversing de la implementación]] — ABI, localizar el código de red, Frida, código gestionado |
| 9 | [[Causas raíz de vulnerabilidades.base\|04 - Causas raíz de vulnerabilidades]] — 10 notas, **+ use-after-free (net-new)** |
| 10 | [[Fuzzing y explotación.base\|05 - Fuzzing y explotación]] — fuzzing, triaje, explotación, **+ mitigaciones 2026 (net-new)** |
| 7 | **No duplicado**: la criptografía y TLS ya estaban en [[HTTPs-TLS.base\|26 - HTTPs-TLS]] (12 notas); se enriqueció en vez de rehacerse |
| 8 | Distribuido entre [[07 - Modificar el protocolo en vuelo]] (replay) y las notas de proxy TLS |

## Qué ha envejecido mal (verificado 2026-08-03)

- **`Canape` y `Canape Core`**, la herramienta del propio autor sobre la que están construidos **todos** los ejemplos prácticos, lleva **sin mantenimiento desde 2017**. Sustituto: [[mitmproxy.base|mitmproxy]] 12.2.3 con modos `raw_tcp`/`raw_udp`.
- **`IDA Pro Free Edition 5`** (cap. 6) era x86-32, sin decompilador y sin uso comercial. Hoy la recomendación se invierte: [[Ghidra.base|Ghidra]] 12.1.2 es libre, decompila todas las arquitecturas y **permite uso comercial**.
- **`PEiD`** (detección de constantes criptográficas) está muerto desde 2011 → `Detect It Easy` + `capa`.
- **`Sulley`** (fuzzing) → `boofuzz`. **`Mallory`** y **Microsoft Message Analyzer** → retirados.
- **`JD-GUI`** para Java → `CFR`, `Vineflower`, `jadx`.
- **`iptables`** sigue funcionando pero es `iptables-nft`: la sintaxis nativa es **`nftables`**.
- **El cap. 10 cubre DEP, ASLR y canarios** (estado de ~2010). Faltan CFI/CFG/XFG, **Intel CET** (shadow stack e IBT), **ARM PAC/BTI/MTE** y RELRO — todo en [[08 - Mitigaciones modernas y cómo se saltan]].
- **`Ettercap` NO está muerto**, en contra de lo que suele afirmarse: v0.8.4.1 de abril de 2026. El flujo del cap. 4 sigue siendo válido, aunque `bettercap` es hoy más cómodo.

Lo que **no** ha envejecido, y es el grueso: la metodología de análisis, la taxonomía de estructuras de protocolo del cap. 3 y el catálogo de causas raíz del cap. 9. Siguen siendo la mejor referencia que existe sobre el tema — **CVE-2026-55200** en `libssh2` (campo de longitud sin cota superior, CVSS 9,2) es exactamente el patrón que describe el capítulo 3, ocho años después.

## Huecos que el libro no cubre y se añadieron

- **IPv6 completo**: no se menciona en todo el libro, y `mitm6` es hoy el vector MITM más rentable en redes Windows.
- **Frida** e instrumentación dinámica — no existía como estándar en 2018 y resuelve en veinte líneas lo que el cap. 6 tarda un capítulo en plantear.
- **Kaitai Struct** para especificar formatos binarios de forma declarativa.
- **Use-after-free y confusión de tipos**, hoy más frecuentes que el desbordamiento clásico.
- **Fuzzing guiado por cobertura y con conciencia de estado** (AFL++, AFLNet, `libdesock`) y **sanitizers**, que en 2018 existían pero no eran práctica estándar en pentest.

## Notas propias

