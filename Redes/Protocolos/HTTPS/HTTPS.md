---
tags:
  - Redes
  - Protocolos
  - HTTPS
  - TLS
  - Web
Descripción: "El Hypertext Transfer Protocol Secure (HTTPS) no es un protocolo nuevo: es HTTP transportado dentro de TLS. En la pila de red, TLS se sitúa entre TCP y la capa de aplicación, de…"
Fecha de actualización: 2026-07-14
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

El **Hypertext Transfer Protocol Secure (HTTPS)** no es un protocolo nuevo: es ==[[HTTP]] transportado dentro de **TLS**==. En la pila de red, `TLS` se sitúa **entre `TCP` y la capa de aplicación**, de forma transparente — la aplicación habla HTTP igual que siempre, pero todo el flujo viaja cifrado. Cambia el esquema (`https://`) y el puerto por defecto (**`TCP 443`** en lugar del 80).

HTTPS resuelve las tres carencias del HTTP en texto plano:
- ==**Confidencialidad**==: el tráfico va cifrado; un atacante en la ruta no puede leerlo.
- ==**Integridad**==: cualquier manipulación del tráfico se detecta (MAC / AEAD).
- ==**Autenticidad**==: el certificado del servidor prueba que hablas con quien crees, no con un impostor.

# TLS y SSL: el motor criptográfico

**Transport Layer Security (TLS)** y su predecesor **Secure Sockets Layer (SSL)** son protocolos criptográficos genéricos: sirven para HTTP, pero también para SMTP, IMAP, FTP, etc. ==SSL está **muerto**== (SSL 2.0 y 3.0 rotos y prohibidos); el término "SSL" sobrevive por inercia, pero lo que se usa hoy es TLS.

| Versión | Año | Estado 2026 |
| - | - | - |
| SSL 2.0 / 3.0 | 1995–96 | Roto ([[04 - POODLE y BEAST\|POODLE]], [[05 - Bleichenbacher y DROWN\|DROWN]]). Prohibido |
| TLS 1.0 / 1.1 | 1999–2006 | ==**Deprecados** (RFC 8996, 2021)==. No usar |
| TLS 1.2 | 2008 | Vigente y mayoritario. Seguro si se configura bien |
| TLS 1.3 | 2018 | Recomendado. Handshake simplificado, solo cifradores AEAD |

> [!info] Encryption-in-transit ≠ End-to-end
> TLS ofrece **cifrado en tránsito**: protege el dato entre cada par de saltos, pero cada servidor intermedio (el proxy, el balanceador, el WAF) ve el tráfico **en claro** al terminar TLS. No es lo mismo que el **cifrado extremo-a-extremo**, donde solo emisor y receptor finales pueden leer el contenido. Por eso un WAF puede inspeccionar peticiones HTTPS: el TLS termina en él.

# El handshake, a vista de pájaro

Antes de intercambiar datos HTTP, cliente y servidor ejecutan el **TLS handshake**, que persigue tres objetivos:

1. **Negociar** la versión de TLS y la *cipher suite* (algoritmos de cifrado, intercambio de claves y MAC).
2. **Autenticar** al servidor mediante su **certificado** (y opcionalmente al cliente con *mTLS*).
3. **Derivar** una clave de sesión simétrica compartida, usando criptografía asimétrica (RSA o, hoy, `ECDHE` para *forward secrecy*).

A partir de ahí, todo el HTTP viaja cifrado con esa clave simétrica. El detalle exacto del handshake —y los ataques que explotan sus pasos— se trata en [[02 - Handshake TLS 1.2 y 1.3]].

# Certificados y confianza (PKI)

La autenticidad se apoya en la **Public Key Infrastructure (PKI)**: el servidor presenta un **certificado X.509** firmado por una **Autoridad de Certificación (CA)** en la que el navegador confía. El navegador valida la ==cadena de confianza== hasta una CA raíz de su almacén, comprueba el dominio (`CN`/`SAN`), la vigencia y la revocación. Si algo falla, muestra la advertencia de certificado. Los fundamentos de X.509, CAs y cadena de confianza se detallan en [[01 - Infraestructura de Clave Pública (PKI)]].

# Qué protege HTTPS y qué no

HTTPS cifra la **ruta, cabeceras y cuerpo** de las peticiones. Pero ==deja expuesto cierto metadato==:
- El **dominio destino** se filtra por el `SNI` del handshake (aún en claro; `ECH`/Encrypted Client Hello lo empieza a resolver) y por las consultas `DNS`.
- La **IP destino** y el **tamaño/timing** del tráfico son observables → análisis de tráfico. Precisamente los ataques de compresión ([[06 - Ataques de compresión (CRIME y BREACH)|CRIME/BREACH]]) explotan que el *tamaño* del cifrado depende del contenido.

# Degradar HTTPS a HTTP

El eslabón débil clásico es la **primera conexión en claro**: si el usuario teclea `http://` o sigue un enlace no seguro, un atacante en la red puede mantenerlo en HTTP e interceptar todo — es el [[08 - SSL Stripping|SSL Stripping]]. La defensa es la cabecera **`Strict-Transport-Security` (HSTS)**, que instruye al navegador a usar siempre HTTPS para ese dominio, y la inclusión en la *HSTS preload list*.

# Ver también

- [[HTTP]] — el protocolo base que HTTPS envuelve.
- [[00 - Introducción a HTTPS y TLS]] — punto de entrada al módulo de ataques TLS (padding oracle, compresión, Heartbleed, downgrade…).
- [[11 - Detección, testeo y hardening de TLS]] — cómo auditar una configuración TLS en un pentest real.

## Referencias

- [RFC 8446 — TLS 1.3](https://www.rfc-editor.org/rfc/rfc8446)
- [RFC 8996 — Deprecating TLS 1.0 and TLS 1.1](https://www.rfc-editor.org/rfc/rfc8996)
- [MDN — An overview of HTTPS](https://developer.mozilla.org/en-US/docs/Web/Security/Transport_Layer_Security)
