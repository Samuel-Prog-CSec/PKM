---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - TLS
Descripción: "Los ataques anteriores atacaban el padding de la criptografía simétrica (CBC)"
Fecha de actualización: 2026-07-14
Nota previa: "[[04 - POODLE y BEAST]]"
Nota siguiente: "[[06 - Ataques de compresión (CRIME y BREACH)]]"
Area: "[[HTTPs-TLS.base|HTTPs/TLS]]"
---
---

Los ataques anteriores atacaban el padding de la criptografía **simétrica** (`CBC`). **Bleichenbacher** y **DROWN** atacan el padding de la **asimétrica**: el esquema `PKCS#1 v1.5` usado con `RSA`. Son padding oracles también, pero contra el intercambio de claves — y su premio es <mark style="background: #FFB86CA6;">la clave de sesión completa, lo que descifra **toda** la comunicación</mark>.

# Ataque de Bleichenbacher

`RSA` con `PKCS#1 v1.5` añade **padding aleatorio** antes de cifrar para que el cifrado sea no-determinista (el mismo plaintext produce cifrados distintos). El ataque, publicado por Daniel Bleichenbacher en **1998**, funciona así: el atacante envía numerosos textos cifrados **adaptados**; el servidor los descifra y comprueba si el padding `PKCS#1` es conforme. <mark style="background: #ADCCFFA6;">Si el servidor filtra si el padding fue válido o no, el atacante deduce información del plaintext original</mark>, y repitiendo el proceso lo reconstruye entero.

En TLS 1.2 solo aplica si:
1. Se negoció un cipher suite con <mark style="background: #FFB8EBA6;">**intercambio de claves `RSA`**</mark> (no `ECDHE`/`DHE`).
2. El servidor **filtra** la validez del padding, por un error verboso o por un **canal lateral de timing**.

Cumplido esto, se filtra el `premaster secret` → la clave de sesión → descifrado total.

# Ataque DROWN

**DROWN** (*Decrypting RSA with Obsolete and Weakened eNcryption*, 2016) es un Bleichenbacher que explota **SSL 2.0**. El atacante intercepta muchas conexiones y ejecuta el Bleichenbacher contra un servidor SSL 2.0, que usa <mark style="background: #FFB8EBA6;">cifradores `export` deliberadamente débiles</mark> (herencia de las regulaciones de exportación de EE.UU. de los 90). El hardware moderno rompe esa cripto sin esfuerzo, y bugs de OpenSSL viejo lo aceleran.

> [!important] El giro cross-protocol de DROWN
> Lo peligroso de DROWN es que el servidor SSL 2.0 vulnerable **no tiene por qué ser el mismo** que quieres atacar: basta con que **comparta la clave/certificado RSA**. Un servidor de correo con SSL 2.0 activo puede servir para descifrar el tráfico TLS moderno de la web que reutiliza esa clave. En 2016, <mark style="background: #FFB86CA6;">~33% de los servidores HTTPS eran vulnerables</mark>. La variante *Special DROWN* (CVE-2016-0703) con OpenSSL buggy era aún más rápida.

# Herramientas: del oráculo al descifrado

HTB usa la colección **TLS-Breaker**. El flujo: detectar → obtener el `premaster secret` → descifrar en Wireshark.

```shell-session
# Detectar sobre un pcap (o -connect host:443)
$ java -jar apps/bleichenbacher-1.0.1.jar -pcap ./capture.pcap
# ... "Found a behavior difference" → Vulnerable:true

# Ejecutar el ataque para extraer el premaster secret (padded)
$ java -jar apps/bleichenbacher-1.0.1.jar -pcap ./capture.pcap -executeAttack
# ... "Solution found!" → premaster secret con padding
```

Se quita el padding hasta la versión TLS (`0303` = TLS 1.2) y, con el `Random` del `ClientHello` (copiado desde Wireshark), se crea un keyfile para descifrar la captura:

```text
PMS_CLIENT_RANDOM <client_random> <premaster_secret>
```

En Wireshark: `Edit → Preferences → Protocols → TLS → (Pre)-Master-Secret log filename`. A partir de ahí, el HTTP cifrado se ve en claro.

# La historia que HTB no cuenta: el oráculo que nunca muere

Bleichenbacher es de **1998** y sin embargo sigue apareciendo. Es el enriquecimiento más importante de esta nota para bug bounty:

- **ROBOT (2017)** — *Return Of Bleichenbacher's Oracle Threat*. Böck, Somorovsky y Young demostraron que <mark style="background: #8000E1A6;">el ataque seguía explotable **19 años después**</mark> en productos de F5, Citrix, Cisco, y en sitios de la talla de `facebook.com` y `paypal.com`. La causa: implementaciones que aún ofrecían intercambio RSA y filtraban el padding con diferencias sutiles.
- **Marvin Attack (2023)** — Hubert Kario (Red Hat) mostró que <mark style="background: #FF5582A6;">**decenas** de librerías criptográficas todavía tienen oráculos de Bleichenbacher **por timing**</mark>, incluso las que creían haberlo parcheado. La mitigación clásica (respuesta constante) es endiabladamente difícil de implementar sin fugas de tiempo.

> [!success] La mitigación definitiva: matar el intercambio RSA
> El denominador común es el **key exchange RSA con `PKCS#1 v1.5`**. La cura de fondo:
> - **TLS 1.3 lo elimina por completo** — no hay RSA key exchange, solo `ECDHE`. Un servidor *TLS 1.3-only* es inmune a Bleichenbacher, ROBOT, DROWN y Marvin de un plumazo.
> - En TLS 1.2, **preferir `ECDHE`** y desactivar los suites `TLS_RSA_*`.
> - **Desactivar SSL 2.0** en todos los servicios que compartan clave (DROWN).
>
> Detección rápida en pentest — `testssl.sh` marca `DROWN` y `ROBOT` directamente:
> ```shell-session
> $ testssl.sh --drown --robot target.htb
> ```

## Referencias

- [ROBOT Attack (2017)](https://robotattack.org/)
- [The Marvin Attack (2023)](https://people.redhat.com/~hkario/marvin/)
- [DROWN Attack (2016)](https://drownattack.com/)
