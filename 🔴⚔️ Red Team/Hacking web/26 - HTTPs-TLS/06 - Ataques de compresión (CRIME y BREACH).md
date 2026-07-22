---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - TLS
Fecha de actualización: 2026-07-14
Nota previa: "[[05 - Bleichenbacher y DROWN]]"
Nota siguiente: "[[07 - Heartbleed]]"
Area: "[[HTTPs-TLS.base|HTTPs/TLS]]"
---
---

**CRIME** y **BREACH** explotan una verdad incómoda: <mark style="background: #ADCCFFA6;">comprimir **antes** de cifrar filtra información por el **tamaño** del texto cifrado</mark>. El cifrado oculta el contenido pero no la longitud, y la longitud tras comprimir depende de cuánta redundancia haya con datos que el atacante controla. Con eso se recuperan secretos —cookies de sesión, tokens `CSRF`— byte a byte.

# Dónde se aplica la compresión

La compresión reduce el tamaño de los datos para acelerar la transmisión. En web hay dos niveles:

- **Compresión HTTP** (capa de aplicación): comprime **solo el cuerpo** HTTP. Se anuncia con `Content-Encoding: gzip|deflate|compress`. Las cabeceras viajan sin comprimir. <mark style="background: #FFB8EBA6;">Burp descomprime la respuesta por defecto</mark> — para ver el cifrado real hay que desactivar esa opción.
- **Compresión TLS** (capa TLS): comprime **todo** el dato de aplicación, **incluidas las cabeceras**. Es transparente al servidor y a cualquier proxy (no la ves en Burp). Se negocia en el handshake (campo *Compression Methods* del `ClientHello`).

Ambas usan algoritmos tipo **`LZ77`**: mantienen un diccionario de cadenas recientes y sustituyen repeticiones por una **back-reference** `<puntero, longitud>`. Ejemplo: `I like HackTheBox's HackTheBox Academy` → `I like HackTheBox's <13,10> Academy`. La clave para los ataques es que LZ77 usa una <mark style="background: #ADCCFFA6;">**ventana deslizante**</mark>: si dos cadenas iguales están cerca, se comprimen juntas y el resultado es más pequeño.

# CRIME (2012): contra la compresión TLS

Como la compresión TLS abarca las cabeceras, CRIME puede robar la **cookie de sesión**. Requisitos: `man-in-the-middle` para medir el tamaño del cifrado, capacidad de **forzar peticiones** desde la víctima (JavaScript malicioso), y conocer el **nombre y longitud** de la cookie.

El truco: el atacante añade a la URL un parámetro con el **mismo nombre** que la cookie y va adivinando su valor carácter a carácter. Supongamos cookie `sess=abcdef`:

```http
GET /crime.html?sess=aXXXXX HTTP/1.1
Host: crime.local
Cookie: sess=abcdef
```

Si el primer carácter adivinado (`a`) **coincide** con el de la cookie, la cadena `sess=a` aparece dos veces cerca → LZ77 la comprime con una back-reference → <mark style="background: #8000E1A6;">el cifrado resulta **más pequeño**</mark>. El atacante lo nota y fija ese carácter. Repite:

```http
GET /crime.html?sess=aXXXXX  → cifrado más corto → 'a' correcto
GET /crime.html?sess=abXXXX  → cifrado más corto → 'b' correcto
GET /crime.html?sess=abcXXX  → ...
```

De izquierda a derecha, con muchas peticiones, filtra la cookie entera.

# BREACH (2013): contra la compresión HTTP

**BREACH** es la variante contra la compresión **HTTP**. Como esta solo comprime el **cuerpo**, no puede tocar cookies (van en cabeceras), pero sí <mark style="background: #FFB86CA6;">secretos reflejados en el cuerpo, típicamente [[01 - Fundamentos y defensas de CSRF|**tokens `CSRF`**]]</mark>. El mecanismo es idéntico al de CRIME, con una condición: la respuesta del servidor debe **reflejar** un valor controlado por el atacante en el cuerpo, ya que no puede usar la query string (no forma parte del body comprimido).

| | CRIME | BREACH |
| - | - | - |
| Comprime | TLS (todo, con cabeceras) | HTTP (solo cuerpo) |
| Objetivo | Cookie de sesión | Token CSRF / secretos en el body |
| Requisito | Nombre+longitud de la cookie | Un **reflejo** del input en la respuesta |
| Estado 2026 | **Muerto** | <mark style="background: #FF5582A6;">**Vivo**</mark> |

# Por qué CRIME murió y BREACH no

> [!success] CRIME: cerrado
> La compresión TLS se **desactivó en todos los navegadores** hacia 2012 y **TLS 1.3 la eliminó del protocolo**. Detección: `testssl.sh --crime`. En un pentest, verla activa es un hallazgo, pero es rarísimo.

> [!warning] BREACH: sigue siendo explotable
> La compresión HTTP (`gzip`) es **universal y no se puede apagar sin penalizar el rendimiento**, así que BREACH sigue vivo donde un secreto y un reflejo del atacante conviven en la misma respuesta comprimida. Variantes modernas que HTB no menciona:
> - **TIME (2013)**: BREACH por **timing**, sin necesidad de MitM.
> - **HEIST (2016, Black Hat)**: BREACH ejecutable **solo desde JavaScript** en el navegador (sin MitM), usando *Resource Timing* y el tamaño de la ventana TCP como oráculo de tamaño. Fue el que devolvió BREACH a la actualidad.

# Mitigación real y detección

La contramedida "de libro" (desactivar la compresión) es cara para HTTP. Lo que se hace hoy:

- **Enmascarar los secretos**: frameworks como Django y Rails aleatorizan el token CSRF en cada respuesta (XOR con un `pad` aleatorio), de modo que su forma comprimida varía y no hay señal de tamaño estable. Es la razón de que el token CSRF cambie en cada carga.
- **Separar** secretos del input reflejado, añadir **padding aleatorio** a las respuestas, y **rate limiting** para frenar los miles de peticiones que exige.

```shell-session
# ¿Compresión HTTP activa? (BREACH potencial, a confirmar con un reflejo)
$ testssl.sh --breach target.htb
# CRIME (compresión TLS)
$ testssl.sh --crime target.htb
```

En bug bounty, un candidato a BREACH es cualquier endpoint que **refleje** un parámetro y a la vez incluya un secreto en un cuerpo `gzip`-comprimido. Es un vector de nicho, pero real.

## Referencias

- [CRIME (Rizzo & Duong, 2012)](https://en.wikipedia.org/wiki/CRIME)
- [BREACH Attack](https://www.breachattack.com/)
- [HEIST (Black Hat 2016)](https://tom.vg/papers/heist_blackhat2016.pdf)
