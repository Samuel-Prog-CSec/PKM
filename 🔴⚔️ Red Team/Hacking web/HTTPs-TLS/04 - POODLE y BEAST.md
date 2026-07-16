---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - TLS
Fecha de actualización: 2026-07-14
Nota previa: "[[03 - Padding Oracle Attacks]]"
Nota siguiente: "[[05 - Bleichenbacher y DROWN]]"
Area: "[[HTTPs-TLS.base|HTTPs/TLS]]"
---
---

**POODLE** (*Padding Oracle On Downgraded Legacy Encryption*) y **BEAST** (*Browser Exploit Against SSL/TLS*) son dos [[03 - Padding Oracle Attacks|padding oracles]] concretos contra el modo `CBC` en **SSL 3.0** y **TLS 1.0**. Ambos permiten a un `man-in-the-middle` <mark style="background: #FFB86CA6;">descifrar tráfico y robar datos confidenciales como credenciales o cookies de sesión</mark>, pero requieren interceptar el tráfico y forzar al cliente a emitir peticiones concretas (típicamente con JavaScript en el navegador de la víctima).

# El padding de SSL 3.0, la raíz del fallo

El esquema de padding de SSL 3.0 es débil por diseño:

- El **último byte** indica la longitud del padding (sin contarse a sí mismo).
- El **resto** de bytes de padding pueden tener **cualquier valor**.

```text
Bloque de 8 bytes · plaintext DE AD BE EF (4 bytes) → 4 de padding
   DE AD BE EF 00 00 00 03
                └──┬──┘  └─ longitud (3, sin contar el byte de longitud)
              bytes arbitrarios (no se validan)
```

<mark style="background: #FFB86CA6;">Que esos bytes no se validen es exactamente lo que POODLE explota</mark>: el servidor solo comprueba el byte de longitud, no el contenido del padding.

# POODLE (2014): rompió SSL 3.0 por completo

El atacante fuerza a la víctima a enviar una petición cuyo último bloque es **todo padding** — así conoce su último byte (es el tamaño). Intercepta el cifrado y manipula ese bloque:

- Si el cambio altera la longitud de padding percibida → el servidor calcula mal el `MAC` → **error de MAC**.
- Si el padding sigue siendo válido → **sin error de MAC**.

Ese error/no-error es el oráculo: igual que en el padding oracle de libro, <mark style="background: #FFB8EBA6;">filtra un byte del resultado intermedio de CBC</mark> y, byte a byte, descifra el bloque. La "downgrade" del nombre es clave: aunque el servidor soporte TLS moderno, el atacante **fuerza la caída a SSL 3.0** manipulando el handshake (ver [[10 - Downgrade Attacks|Downgrade Attacks]]).

> [!info] POODLE también golpeó a TLS (CVE-2014-8730)
> Poco después se descubrió que ciertas implementaciones (F5, A10) **no validaban** los bytes de padding ni siquiera en TLS 1.0–1.2, haciéndolas vulnerables a POODLE aunque SSL 3.0 estuviese desactivado. Moraleja: POODLE no es solo "un problema de SSLv3", es un problema de **implementación** de la validación de padding.

# BEAST (2011): el IV predecible de TLS 1.0

BEAST explota que en TLS 1.0 el **IV** de cada registro CBC es el último bloque cifrado del registro anterior — **predecible** por el atacante. Con un plaintext parcialmente conocido, el atacante inyecta caracteres para que <mark style="background: #FFB8EBA6;">en cada bloque solo quede **un byte** desconocido</mark> y lo fuerza por fuerza bruta (256 intentos), no el bloque entero.

<mark style="background: #FF5582A6;">En la práctica BEAST es difícil</mark>: necesita ejecutar en el navegador de la víctima y **saltarse la Same-Origin Policy** para inyectar el plaintext elegido, lo que exige un ataque adicional. Su riesgo real siempre fue menor que el de POODLE.

# Comparativa

| | POODLE | BEAST |
| - | - | - |
| Año | 2014 | 2011 |
| Objetivo | SSL 3.0 (y TLS con CVE-2014-8730) | TLS 1.0 (CBC) |
| Causa | Padding no validado + oráculo de MAC | IV CBC predecible |
| Requisito extra | Forzar downgrade a SSLv3 | Bypass de Same-Origin Policy |
| Practicidad | Alta (rompió SSLv3) | Baja / teórica |

# Detección y herramientas

El material de HTB usa **TLS-Breaker** (colección de exploits TLS en Java) para probar POODLE:

```shell-session
$ java -jar apps/poodle-1.0.1.jar -connect target.htb:443
# ... Vulnerability status: VULNERABILITY_POSSIBLE   → soporta SSLv3, explotable
# ... Vulnerability status: NOT_VULNERABLE           → rechaza el handshake SSLv3
```

En un pentest real, sin embargo, <mark style="background: #FF5582A6;">no lanzas el exploit: **detectas la configuración**</mark>. La forma profesional y rápida es con `testssl.sh` / `sslscan` / `nmap`, que marcan directamente si el servidor admite SSLv3 o TLS 1.0 con CBC (ver [[11 - Detección, testeo y hardening de TLS]]):

```shell-session
$ testssl.sh --poodle --beast target.htb
$ nmap --script ssl-enum-ciphers -p 443 target.htb   # lista versiones y ciphers
```

> [!success] Estado en 2026 y prevención
> POODLE y BEAST son **históricos**: SSL 3.0 está desactivado en todas partes y los navegadores mitigaron BEAST con *1/n-1 record splitting*; TLS 1.1 introdujo IVs explícitos para cerrarlo. El hallazgo moderno no es "explotable por POODLE" sino <mark style="background: #FF5582A6;">"el servidor todavía acepta SSLv3 / TLS 1.0"</mark>, un incumplimiento de baseline que se reporta y se corrige desactivando esas versiones:
> ```text
> # Apache
> SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
> ```
> Curiosidad: tras BEAST se recomendó `RC4` como mitigación… y `RC4` resultó también roto ([[09 - Primitivas criptográficas inseguras|ver primitivas inseguras]]). Nunca hay atajos en cripto.

## Referencias

- [Google — This POODLE bites (2014)](https://www.openssl.org/~bodo/ssl-poodle.pdf)
- [Duong & Rizzo — BEAST](https://vnhacker.blogspot.com/2011/09/beast.html)
- [TLS-Breaker (GitHub)](https://github.com/tls-attacker/TLS-Breaker)
