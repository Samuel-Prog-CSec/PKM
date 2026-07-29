---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - CSRF
Descripción: "Las dos últimas familias de bypass atacan el token cuando es débil, y el formato del cuerpo cuando la aplicación espera JSON y cree que eso la protege"
Fecha de actualización: 2026-06-08
Nota previa: "[[05 - Bypass de SameSite y defensas de cabecera]]"
Nota siguiente: "[[07 - Herramientas para CSRF y CORS]]"
Area: "[[CSRF.base|CSRF]]"
---
---

Las dos últimas familias de bypass atacan el [[01 - Fundamentos y defensas de CSRF|token]] cuando es débil, y el formato del cuerpo cuando la aplicación espera JSON y cree que eso la protege.

# Tokens CSRF débiles

Un token solo protege si es impredecible **y** está correctamente atado a la sesión. Fallar cualquiera de las dos cosas lo rompe.

## Token no atado a la sesión

<mark style="background: #FF5582A6;">Si el backend valida que el token sea "uno válido" pero no que pertenezca a la sesión que envía la petición, el atacante usa el suyo propio</mark>: pide un token válido desde su cuenta y lo incrusta en la petición cross-site dirigida a la víctima. El backend lo acepta porque es un token válido, sin notar que se generó para otra sesión. Detéctalo así: captura dos peticiones de dos sesiones distintas e intercambia sus tokens; si ambas se aceptan, el token no está atado a la sesión.

## Token predecible

Si el token no es realmente aleatorio, se adivina. El caso de libro es un token que resulta ser un [Unix timestamp](https://www.unixtimestamp.com/) del momento de generación. <mark style="background: #FFB8EBA6;">Recoge varios tokens seguidos; si crecen de forma monótona o coinciden con la hora, son predecibles</mark>. No puedes leer el token para reintentar: aunque la cookie viajara, la [[02 - Same-Origin Policy y CORS|Same-Origin Policy]] bloquea leer la respuesta cross-origin sin una CORS misconfig. El ataque es a ciegas —se hardcodea el valor estimado en un formulario auto-enviado y se ajusta por intento— y por eso solo es viable si el token es predecible:

```html
<form method="GET" action="https://vulnerablesite.htb/profile.php">
  <input type="hidden" name="promote" value="htb-stdnt" />
  <input type="hidden" name="csrf" value="1692981700" />
</form>
<script>document.forms[0].submit();</script>
```

El reto es acertar el instante exacto en que la víctima accedió por última vez al endpoint que genera el token. Reduce la probabilidad de éxito, pero un token predecible sigue siendo explotable.

El timestamp es solo el caso más obvio. Otros patrones de token débil que conviene probar al recoger varias muestras: un **hash de un dato conocido** (`MD5`/`SHA1` del username, el user-id o la hora — compáralo con el hash de esos valores), un **contador incremental** (cada token es el anterior +N, a veces envuelto en `base64`/`hex`), o **entropía insuficiente** (token corto o de charset limitado que cabe en un espacio brute-forceable). <mark style="background: #FF5582A6;">La detección es siempre la misma: recoge un puñado de tokens, decodifícalos (`base64`, `hex`), mide longitud y charset, y busca estructura o correlación con datos conocidos</mark>. Un token verdaderamente aleatorio no muestra ninguna.

# CSRF con cuerpo JSON

Muchas APIs modernas esperan el cuerpo del `POST` en formato JSON. Esto **parece** proteger contra CSRF, porque un formulario HTML no puede enviar `Content-Type: application/json` de forma nativa. Hay dos formas de saltárselo.

## Vía CORS

Si la aplicación tiene una [[03 - CORS Misconfigurations|CORS misconfiguration]] que permite especificar el `Content-Type`, basta enviar el JSON desde JavaScript con la cabecera correcta. Requiere la misconfig adicional, pero entonces es trivial.

## Vía `enctype=text/plain`

Sin CORS, el truco está en que un formulario HTML **sí** puede fijar tres `Content-Type` con el atributo `enctype`: `application/x-www-form-urlencoded`, `multipart/form-data` y `text/plain`. <mark style="background: #8000E1A6;">Si la aplicación no valida el `Content-Type` y solo mira si el cuerpo es JSON válido, podemos forjar JSON con un formulario `text/plain`</mark>:

```html
<form method="POST" action="https://vulnerablesite.htb/profile.php" enctype="text/plain">
  <input type="hidden" name='{"promote": "htb-stdnt", "dummykey' value='": "dummyvalue"}' />
</form>
<script>document.forms[0].submit();</script>
```

Esto produce el siguiente cuerpo, que es JSON válido:

```http
POST /profile.php HTTP/1.1
Content-Type: text/plain

{"promote": "htb-stdnt", "dummykey=": "dummyvalue"}
```

> [!important]+ El truco de la dummy key
> Un formulario `text/plain` inserta un `=` entre el `name` y el `value` de cada campo. Si metiéramos todo el JSON en `name`, ese `=` aparecería en mitad de nuestra estructura y la rompería. La solución es partir el JSON entre `name` y `value` de modo que el `=` caiga dentro de una **clave basura** (`dummykey=`) que el backend ignora, dejando intactos los datos reales (`promote`). Es la pieza que hace explotable un endpoint JSON que solo se fía de la sintaxis del cuerpo.

> [!warning]+ Cuándo NO funciona
> Si la aplicación valida estrictamente `Content-Type: application/json` y rechaza cualquier otro, este vector muere — el formulario no puede producir esa cabecera. La validación del `Content-Type` es, de hecho, la mitigación correcta contra el CSRF en JSON.

Con esto cerramos las técnicas de explotación CSRF. El instrumental para detectarlas y automatizarlas a escala se recoge en [[07 - Herramientas para CSRF y CORS]].

> [!info]+ Fuentes de referencia
> - [PortSwigger — CSRF tokens y validación](https://portswigger.net/web-security/csrf)
> - [PayloadsAllTheThings — CSRF (JSON, text/plain)](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/CSRF%20Injection/README.md)
