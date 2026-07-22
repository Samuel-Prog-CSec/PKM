---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - HTTP/Request-Smuggling
Fecha de actualización: 2026-07-14
Nota previa: "[[11 - Explotación de Request Smuggling]]"
Nota siguiente: "[[13 - Introducción a HTTP2]]"
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

Cierre del bloque de smuggling: el **arsenal** que automatiza la matriz de desyncs y ofuscaciones, y la **prevención** (que, spoiler, pasa por HTTP/2 extremo a extremo).

# Arsenal

| Herramienta | Tipo | Uso |
| - | - | - |
| **HTTP Request Smuggler** | Extensión Burp (PortSwigger) | Detección por timing, *convert to chunked*, *Smuggle attack* vía Turbo Intruder — **el estándar** |
| **smuggler.py** (defparam) | CLI Python | Detección masiva de CL.TE/TE.CL/TE.TE sobre listas |
| **Turbo Intruder** | Extensión Burp | Envío a alta velocidad y scripts de ataque custom (timing preciso) |
| **h2csmuggler** | CLI | HTTP/2 cleartext (`h2c`) smuggling |
| **Burp Scanner** | — | Detecta smuggling automáticamente |

## HTTP Request Smuggler (el de HTB)

Se instala desde el **BApp Store**. Tres funciones clave:

- **Convert to chunked**: convierte un cuerpo normal a chunked, calculando los tamaños en hex por ti (evita errores de conteo):
  ```http
  Content-Length: 28
  Transfer-Encoding: chunked

  11
  param1=HelloWorld
  0
  ```
- **Smuggle probe**: detección **por timing**, segura (no daña a otros usuarios) — es la forma correcta de confirmar una desync en producción.
- **Smuggle attack (CL.TE / TE.CL)**: abre **Turbo Intruder** con un script donde editas el `prefix` (la petición smuggled, p. ej. `GET /admin.php`). Ataca ~1/seg; analizas las **longitudes de respuesta** en la tabla: si una petición "víctima" devuelve una longitud distinta (la del recurso smuggled) en vez del index, la desync funcionó.

```shell-session
# smuggler.py — barrido de detección
$ python3 smuggler.py -u https://target.htb/
# h2csmuggler — probar upgrade a HTTP/2 cleartext
$ python3 h2csmuggler.py -x https://target.htb/ https://target.htb/admin
```

# Prevención

<mark style="background: #FF5582A6;">Prevenir smuggling es difícil porque el bug vive en el **software** (servidor/proxy), no en la aplicación</mark> — el desarrollador de la app a menudo no puede hacer nada. Recomendaciones a nivel de despliegue:

- **Mantener actualizados** servidor web y proxy inverso (los CVEs de smuggling se parchean constantemente).
- **Cerrar la conexión TCP** ante **cualquier** excepción o error de parseo — así un prefijo huérfano no envenena la siguiente petición.
- **Parchear los bugs client-side** aunque parezcan inexplotables: el smuggling los weaponiza.
- <mark style="background: #FF5582A6;">**Usar HTTP/2 extremo a extremo** y **desactivar** versiones inferiores</mark>. Es la prevención de fondo:

> [!success] Por qué HTTP/2 e2e mata el smuggling
> El smuggling nace de la **ambigüedad de longitud** de HTTP/1.1 (`CL` vs `TE`). [[13 - Introducción a HTTP2|HTTP/2]] <mark style="background: #ADCCFFA6;">lleva la longitud en su **framing binario**: no hay dos formas de declararla, así que no hay discrepancia posible</mark>. <mark style="background: #8000E1A6;">Si **toda** la cadena (cliente→proxy→servidor) habla HTTP/2, el smuggling desaparece</mark>. El problema —y el siguiente bloque— es que muchos despliegues hablan HTTP/2 delante pero **reescriben a HTTP/1.1** por detrás, reintroduciendo la ambigüedad: el [[14 - HTTP2 Downgrading|HTTP/2 downgrading]].

> [!info] Defensa adicional en el front-end
> Un front-end robusto debería **normalizar o rechazar** peticiones ambiguas: descartar las que traen `CL` **y** `TE`, las que tienen un `TE` ofuscado, o cabeceras malformadas — en vez de reenviarlas "tal cual" al back-end. Muchos WAFs/CDN modernos ya lo hacen; verificarlo es parte de la auditoría.

Con esto cierra el bloque de Request Smuggling clásico (HTTP/1.1). El último bloque del módulo lleva el ataque a [[13 - Introducción a HTTP2|HTTP/2]] y su downgrade.

## Referencias

- [HTTP Request Smuggler (Burp)](https://github.com/PortSwigger/http-request-smuggler) · [smuggler.py](https://github.com/defparam/smuggler)
- [PortSwigger — Preventing request smuggling](https://portswigger.net/web-security/request-smuggling#how-to-prevent-http-request-smuggling-vulnerabilities)
