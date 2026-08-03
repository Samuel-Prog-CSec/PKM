---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - TLS
  - Tipo/Introduccion
Descripción: "Este módulo ataca la criptografía de transporte, no la lógica de la aplicación"
Fecha de actualización: 2026-07-14
Nota previa: ""
Nota siguiente: "[[01 - Infraestructura de Clave Pública (PKI)]]"
Area: "[[HTTPs-TLS.base|HTTPs/TLS]]"
---
---

Este módulo ataca la **criptografía de transporte**, no la lógica de la aplicación. El objetivo son los protocolos [[HTTPS]] y `TLS`/`SSL` que se supone que protegen la comunicación. <mark style="background: #ADCCFFA6;">TLS y su predecesor SSL son protocolos criptográficos que aportan confidencialidad, integridad y autenticidad al tráfico</mark> combinando cifrado simétrico, asimétrico y códigos de autenticación de mensaje (`MAC`).

Encontrar un fallo en un protocolo es **raro** comparado con encontrarlo en una aplicación concreta: HTTPS y TLS se diseñaron con seguridad en mente y se han revisado durante décadas. Pero cuando aparece, <mark style="background: #FFB86CA6;">el impacto es enorme porque afecta a un número gigantesco de servicios a la vez</mark>. La mayoría de estos fallos no son de **especificación** sino de **implementación**: una librería (típicamente OpenSSL) que no sigue el estándar al pie de la letra, o un servidor que mantiene activa una versión o un cifrador que ya se sabe roto.

> [!important] Lo que de verdad haces en un pentest moderno
> En 2026 rara vez *explotas* estos ataques de forma end-to-end: los servidores están parcheados y las versiones rotas, desactivadas. Lo que sí haces —y es un entregable habitual— es **detectar la mala configuración**: "el servidor admite TLS 1.0", "negocia cifradores `RC4`", "es vulnerable a un downgrade". Entender el ataque a bajo nivel es lo que te permite justificar por qué esa config es un hallazgo y no un `false positive`. Por eso el eje fuerte de este sub-tema es **detección + herramientas**, no la explotación teatral.

# Cifrado en tránsito, no extremo a extremo

TLS aplica **cifrado en tránsito** (`encryption-in-transit`): el dato se cifra antes de enviarse y se descifra al recibirse en **cada salto**. No es cifrado **extremo a extremo** (`end-to-end`). La diferencia es operativa y crítica:

- Con **e2e**, Alice cifra un correo y solo Bob puede descifrarlo; ningún servidor intermedio accede al contenido.
- Con **TLS**, Alice cifra hacia su servidor de correo, que <mark style="background: #FFB8EBA6;">lo descifra, lo vuelve a cifrar y lo reenvía</mark> al siguiente salto. Cada intermediario ve el mensaje en claro.

<mark style="background: #8000E1A6;">Esto explica que un WAF, un proxy inverso o un balanceador puedan inspeccionar tráfico HTTPS</mark>: el TLS **termina** en ellos. Y explica por qué muchos ataques de este módulo se plantean como *man-in-the-middle* en un salto concreto de la cadena. Los tipos de cifrado (at-rest, in-transit, e2e) se detallan en [[HTTPS]].

# Historial de versiones con lente de seguridad

La única razón por la que un pentester memoriza estas versiones es saber **cuáles están rotas y por qué** — cada versión muerta habilita un ataque de este módulo.

| Versión | Año | Por qué importa ofensivamente |
| - | - | - |
| SSL 1.0 | — | Nunca se publicó; fallos graves de diseño |
| SSL 2.0 | 1995 | Fallos de especificación; habilita [[05 - Bleichenbacher y DROWN\|DROWN]] |
| SSL 3.0 | 1996 | Rediseño, pero cripto obsoleta; habilita [[04 - POODLE y BEAST\|POODLE]] |
| TLS 1.0 | 1999 | Basado en SSL 3.0; vulnerable a `BEAST`. **Deprecado** |
| TLS 1.1 | 2006 | Mitiga MitM sobre 1.0, pero cripto anticuada. **Deprecado** |
| TLS 1.2 | 2008 | Vigente y mayoritario. Suites `AEAD`/`GCM` y SHA-256. La compresión TLS (opcional desde SSLv3, RFC 3749) habilita [[06 - Ataques de compresión (CRIME y BREACH)\|CRIME]] |
| TLS 1.3 | 2018 | Handshake simplificado, solo `AEAD`, sin `RSA` estático ni compresión. Cierra la mayoría de estos vectores |

<mark style="background: #FF5582A6;">TLS 1.0 y 1.1 están formalmente deprecados desde 2021 (RFC 8996)</mark>. Que un servidor los siga aceptando es, por sí solo, un hallazgo. TLS 1.3 elimina de raíz la compresión, el intercambio de claves `RSA` y los modos `CBC` problemáticos — es la razón por la que casi todos los ataques de aquí mueren si el servidor es *TLS 1.3-only*.

# Cómo se relaciona TLS con HTTPS

HTTPS es HTTP hablando sobre TLS. En la capa de aplicación es idéntico a [[HTTP]] (mismos métodos, cabeceras, códigos), pero <mark style="background: #FFB8EBA6;">todo el flujo va cifrado e íntegro</mark>, impidiendo *eavesdropping* y manipulación. HTTP usa `http://` y `TCP 80`; HTTPS usa `https://` y `TCP 443`. Todo lo cripto ocurre en la capa TLS, transparente para HTTP.

# Hoja de ruta del módulo

Los ataques se agrupan en tres familias, más las misconfiguraciones:

- **[[03 - Padding Oracle Attacks|Padding Oracle]]**: el servidor filtra si el `padding` de un texto cifrado `CBC` es correcto. Ese oráculo permite <mark style="background: #FFB86CA6;">descifrar un mensaje completo sin conocer la clave</mark>. Casos históricos: [[04 - POODLE y BEAST|POODLE]] y [[05 - Bleichenbacher y DROWN|Bleichenbacher/DROWN]].
- **[[06 - Ataques de compresión (CRIME y BREACH)|Compresión]]**: comprimir antes de cifrar filtra información por el **tamaño** del cifrado, recuperando secretos como cookies de sesión o tokens `CSRF`. Casos: `CRIME` y `BREACH`.
- **Misc. y misconfiguraciones**: [[07 - Heartbleed|Heartbleed]] (fuga de memoria en OpenSSL), [[08 - SSL Stripping|SSL Stripping]], [[10 - Downgrade Attacks|Downgrade]], y [[09 - Primitivas criptográficas inseguras|primitivas débiles]].

El módulo cierra con [[11 - Detección, testeo y hardening de TLS]], la nota operativa: cómo auditar todo lo anterior con herramientas reales y qué configuración considerar segura.

> [!info] Prerrequisitos conceptuales
> Antes de los ataques conviene tener claros dos cimientos: la [[01 - Infraestructura de Clave Pública (PKI)|PKI]] (certificados, CAs, cadena de confianza) y el [[02 - Handshake TLS 1.2 y 1.3|handshake]] (dónde y cómo se negocia la cripto). Casi todos los vectores atacan un paso concreto de esa negociación o un fallo en la validación del certificado.

## Referencias

- [RFC 8446 — TLS 1.3](https://www.rfc-editor.org/rfc/rfc8446)
- [RFC 8996 — Deprecating TLS 1.0/1.1](https://www.rfc-editor.org/rfc/rfc8996)
- HTB Academy — *HTTPs/TLS Attacks* (módulo base de estas notas)
