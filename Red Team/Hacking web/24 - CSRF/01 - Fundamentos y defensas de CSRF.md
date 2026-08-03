---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - CSRF
  - Tipo/Defensa
Descripción: "El Cross-Site Request Forgery (CSRF) fuerza al navegador de la víctima a realizar, sin que ella lo sepa, acciones en una aplicación donde está autenticada"
Fecha de actualización: 2026-06-08
Nota previa: "[[00 - Primitivas y entorno de explotación]]"
Nota siguiente: "[[02 - Same-Origin Policy y CORS]]"
Area: "[[CSRF.base|CSRF]]"
---
---

<mark style="background: #ADCCFFA6;">El `Cross-Site Request Forgery` (CSRF) fuerza al navegador de la víctima a realizar, sin que ella lo sepa, acciones en una aplicación donde está autenticada</mark>. El payload vive en un sitio controlado por el atacante y lanza una petición *cross-origin* contra la aplicación vulnerable; el navegador adjunta automáticamente las cookies de sesión de la víctima, autenticando la petición. <mark style="background: #8000E1A6;">El atacante nunca ve la sesión ni roba la cookie: abusa de que el navegador la envía solo</mark>.

> [!example]+ Caso real — Badoo Full Account Takeover · $852 · [H1 #127703](https://hackerone.com/reports/127703)
> Badoo protegía las peticiones con un token `rt` por usuario (que CORS impedía leer del JSON)… pero Mahmoud Jamal vio que el `rt` **se reflejaba dentro de un fichero JavaScript** (`chrome-service-worker.js`). CORS no restringe cargar JS remoto con `<script src>`, así que una página maliciosa cargaba ese fichero, parseaba el `rt` y disparaba el endpoint de vincular-cuenta-Google → **secuestro de cuenta**. **Lección**: si el token CSRF aparece en cualquier otro sitio (JSON, ficheros JS), sigue cavando — revisa **todos** los recursos que carga la página.

# Anatomía de un ataque

El escenario canónico: la víctima es administradora de `https://vulnerablesite.htb` y tiene sesión iniciada. El atacante controla una cuenta sin privilegios y quiere promocionarla. La aplicación promociona usuarios con una petición a `/promote?user=<nombre>` y **no** está protegida contra CSRF.

El atacante aloja en `https://exploitserver.htb` un payload que dispara esa petición. Cuando la víctima visita el sitio del atacante, su navegador ejecuta el JavaScript, que emite la petición cross-origin a `https://vulnerablesite.htb/promote?user=attacker` **con las cookies de la víctima**. La aplicación, viendo una petición autenticada de una administradora, promociona la cuenta del atacante.

```html
<form method="POST" action="https://vulnerablesite.htb/promote">
  <input type="hidden" name="user" value="attacker" />
</form>
<script>document.forms[0].submit();</script>
```

<mark style="background: #FFB86CA6;">El requisito es que la víctima visite voluntariamente el payload</mark> (ingeniería social, un comentario con un enlace, una web comprometida). Por eso el CSRF se paga menos que un XSS: depende de la entrega. Generar el PoC se puede automatizar con el [CSRF PoC Generator](https://csrf-poc-generator.vercel.app/) o con el generador integrado de Burp Suite Pro.

# Detección: ¿es explotable este endpoint?

Antes de escribir un exploit, confirma que el endpoint reúne las condiciones. <mark style="background: #FF5582A6;">Un endpoint es candidato a CSRF cuando se cumplen las cuatro</mark>:

1. **Acción sensible**: cambia estado (promocionar, cambiar contraseña/email, transferir, borrar). Las peticiones de solo lectura no interesan.
2. **Depende solo de cookies**: la sesión se mantiene por cookie y la petición no exige ningún secreto que el atacante no pueda predecir (un token, una cabecera custom).
3. **Sin token CSRF válido o mal validado**: no hay token, o el backend no lo verifica, o no está atado a la sesión de la víctima (ver abajo).
4. **La cookie se envía cross-site**: `SameSite=None`, o `Lax`/ausente con un método que el navegador sí envía (un `GET` que cambia estado, por ejemplo).

> [!important]+ La prueba rápida en Burp
> Repite la petición state-changing eliminando el token CSRF (o con uno inválido) y borrando la cabecera `Referer`/`Origin`. Si la aplicación **sigue aceptándola**, no hay protección efectiva. Si la rechaza, toca analizar **cuál** de las defensas actúa y si es sorteable —el resto de este sub-tema.

# Defensas contra CSRF

## Tokens CSRF

<mark style="background: #ADCCFFA6;">Un token CSRF es un valor único, aleatorio e impredecible que debe acompañar a toda petición que cambie estado</mark>, normalmente como campo oculto en el formulario. El backend lo verifica antes de ejecutar la acción. Como el atacante no puede adivinar el valor, no puede construir una petición cross-site que la aplicación acepte. Para ser efectivo, el token debe ser **impredecible**, estar **correctamente verificado** en el backend, **atado a la sesión** del usuario y **no viajar en una cookie** (si va en cookie, el navegador lo adjunta solo y la protección se desmorona). Es la defensa primaria recomendada. Frameworks como Django o Rails además **enmascaran** el token en cada respuesta (XOR con un valor aleatorio), de modo que su forma cambia en cada carga: así no se filtra por un canal lateral de compresión — ver [[06 - Ataques de compresión (CRIME y BREACH)|BREACH]].

## Validación de cabeceras: `Origin` y `Referer`

El navegador añade la cabecera [`Origin`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Origin) a las peticiones cross-origin, y el atacante **no puede falsificarla** desde JavaScript. La aplicación puede leerla y rechazar peticiones que no provengan de su propio origen. Lo mismo aplica a [`Referer`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referer). Es una defensa de refuerzo: <mark style="background: #FFB8EBA6;">su talón de Aquiles es una comprobación mal implementada</mark> (buscar una subcadena en lugar de validar el origen exacto), que veremos cómo sortear.

## Cookies `SameSite`

El atributo [`SameSite`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite) controla si la cookie se envía en peticiones cross-site:

| Valor | Comportamiento |
| - | - |
| `None` | Se envía con todas las peticiones cross-site (exige `Secure` → solo HTTPS) |
| `Lax` | Solo en navegaciones top-level con método seguro (clic en enlace, `GET` de barra). **No** se envía en subrecursos (`img`, `iframe`, `fetch`/XHR) aunque usen `GET`, **ni** en peticiones top-level con método no seguro (`POST`) |
| `Strict` | Nunca se envía en peticiones cross-site |

<mark style="background: #FFB86CA6;">Los navegadores basados en **Chromium** (Chrome, Edge, Opera) aplican `Lax` por defecto</mark> si no se fija el atributo. Esto neutraliza por sí solo la mayoría de CSRF basados en `POST`, dejando vivos sobre todo los `GET` state-changing. <mark style="background: #FF5582A6;">Firefox y Safari **no** comparten ese default</mark> (usan sus propios mecanismos anti-tracking — ETP/ITP): contra usuarios de esos navegadores, un CSRF `POST` "de libro" puede seguir vivo sin ningún bypass, así que pruébalo antes de asumir que hace falta CORS/XSS. Aun así, el CSRF clásico ha perdido mucho terreno y la explotación real suele pasar por combinarlo con CORS o XSS.

> [!warning]+ La ventana "Lax+POST" de Chrome
> Chrome aplica una excepción poco conocida: una cookie recién creada con `SameSite=Lax` (o sin atributo) **sí** se envía en peticiones `POST` top-level durante los **primeros 2 minutos** de vida. Pensada para compatibilidad con flujos de login `POST`, abre una ventana real para CSRF `POST` si consigues que la víctima inicie sesión justo antes de disparar el payload. Firefox y Safari no implementan esta excepción, así que el comportamiento depende del navegador.

La recomendación defensiva es **tokens CSRF como medida primaria**, con `SameSite` y validación de cabeceras como capas de *defense-in-depth*. Para entender cómo se rompen esas capas —y por qué CORS es la pieza central— primero hay que dominar la [[02 - Same-Origin Policy y CORS|Same-Origin Policy y CORS]].

> [!info]+ Fuentes de referencia
> - [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
> - [PortSwigger — CSRF](https://portswigger.net/web-security/csrf) y [SameSite cookies](https://portswigger.net/web-security/csrf/bypassing-samesite-restrictions)
> - [MDN — SameSite cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite)
