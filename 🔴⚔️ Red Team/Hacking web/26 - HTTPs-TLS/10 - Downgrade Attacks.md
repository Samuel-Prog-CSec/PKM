---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - TLS
Fecha de actualización: 2026-07-14
Nota previa: "[[09 - Primitivas criptográficas inseguras]]"
Nota siguiente: "[[11 - Detección, testeo y hardening de TLS]]"
Area: "[[HTTPs-TLS.base|HTTPs/TLS]]"
---
---

Un **downgrade attack** no rompe TLS: <mark style="background: #ADCCFFA6;">fuerza a la víctima a usar una configuración **insegura** —una versión antigua o un cipher suite débil— para romperla en un segundo paso</mark>. Es el eslabón que arma casi todos los demás ataques del módulo: [[04 - POODLE y BEAST|POODLE]], [[09 - Primitivas criptográficas inseguras|FREAK y Logjam]] y [[05 - Bleichenbacher y DROWN|DROWN]] empiezan todos con un downgrade.

# Por qué es posible

Los servidores soportan **varias versiones** de TLS por compatibilidad, para que clientes antiguos que no hablan la última versión puedan conectar. <mark style="background: #FFB86CA6;">Un `man-in-the-middle` abusa de esa flexibilidad para forzar incluso a clientes modernos a caer a una versión vieja</mark>. Mientras exista una versión débil soportada, existe un objetivo al que degradar.

# Cipher Suite Rollback (SSL 2.0)

En **SSL 2.0**, la lista de cipher suites del handshake <mark style="background: #FFB8EBA6;">**no** está protegida por un MAC</mark>. Un MitM intercepta el `ClientHello` y altera la lista para que solo queden suites débiles (p. ej. solo `export`), reenvía el handshake, y la conexión se establece con un suite roto que el atacante puede romper.

> [!success] Cómo lo cerró SSL 3.0 y TLS
> Desde SSL 3.0, la lista de cipher suites se incluye en el **MAC del mensaje `Finished`** del handshake. Cualquier manipulación del MitM se detecta antes de concluir → `alert` y handshake fallido. Por eso el cipher suite rollback "puro" solo afecta a SSL 2.0.

# TLS Downgrade por fallback

El downgrade moderno no altera la lista: **sabotea el handshake**. El MitM interfiere y **descarta paquetes** hasta provocar un fallo de handshake. Ante fallos repetidos con TLS 1.2, algunos clientes/navegadores <mark style="background: #FFB8EBA6;">**reintentan con una versión inferior**</mark> (TLS 1.1, luego 1.0…) asumiendo que el servidor es viejo. El atacante repite el sabotaje hasta que el cliente ofrece la versión vulnerable que busca.

```mermaid
sequenceDiagram
    participant C as Cliente
    participant A as Atacante (MitM)
    participant S as Servidor
    C->>A: ClientHello (TLS 1.2)
    A--xS: (descarta el handshake)
    Note over C: Handshake falla → el cliente reintenta
    C->>A: ClientHello (TLS 1.1)  ← fallback inseguro
    A->>S: reenvía; se establece TLS 1.1
    Note over A: Ahora ataca la versión débil (POODLE, BEAST...)
```

# La defensa que HTB no cuenta: TLS_FALLBACK_SCSV

El talón de Aquiles del fallback es que el reintento con versión inferior no está autenticado. La mitigación (RFC 7507) es el <mark style="background: #ADCCFFA6;">**`TLS_FALLBACK_SCSV`**</mark>: un "cipher suite" señalizador que el cliente incluye **cuando reintenta** con una versión menor a la que soporta. Si el servidor lo ve pero **es capaz** de hablar una versión más alta, deduce que hay un downgrade forzado y **aborta** la conexión. Fue la respuesta directa a POODLE: mata el "baile de fallback" del que dependía.

> [!info] TLS 1.3: protección anti-downgrade en el propio handshake
> Un servidor que soporta TLS 1.3 pero negocia 1.2 inserta un **valor centinela** en `ServerHello.random` (`44 4F 57 4E 47 52 44 01` = `DOWNGRD\x01`). Un cliente TLS 1.3 que lo ve sabe que le han degradado y aborta. Es redundante con `TLS_FALLBACK_SCSV`, a propósito.

# Estado 2026 y prevención

- Los navegadores **eliminaron el fallback inseguro** hacia 2015: Chrome y Firefox ya **no** reintentan con SSLv3/TLS 1.0 ante un fallo. El downgrade por fallback clásico está muerto **en navegadores**.
- Sigue importando en clientes **no-navegador**: librerías, APIs, clientes móviles e IoT que aún implementan version fallback manual.
- **ALPACA (2021)** es un primo moderno: no degrada la versión, sino que confunde **servicios distintos** que comparten certificado (redirigir el TLS de una web a un FTPS/IMAPS) para inyectar contenido. Recordatorio de que reutilizar certificados entre servicios es peligroso.

> [!warning] Lo que reportas
> La causa raíz es siempre la misma: <mark style="background: #FF5582A6;">**soportar versiones/suites obsoletos**</mark>. La prevención definitiva es eliminarlos y quedarse en **TLS 1.2 (bien configurado) + TLS 1.3**. Comprobaciones:
> ```shell-session
> # ¿Soporta TLS_FALLBACK_SCSV? ¿Qué versiones acepta?
> $ testssl.sh --protocols --tls-fallback target.htb
> $ openssl s_client -connect target.htb:443 -fallback_scsv -tls1
> ```
> El fallo `inappropriate fallback` de OpenSSL confirma que el servidor rechaza el downgrade. La auditoría completa, en [[11 - Detección, testeo y hardening de TLS]].

## Referencias

- [RFC 7507 — TLS Fallback SCSV](https://www.rfc-editor.org/rfc/rfc7507)
- [ALPACA Attack (2021)](https://alpaca-attack.com/)
