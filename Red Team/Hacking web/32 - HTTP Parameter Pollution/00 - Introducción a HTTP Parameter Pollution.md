---
tags:
  - Web/Red-Team
  - HPP
  - Pentesting/Explotacion
  - Tipo/Introduccion
Descripción: "La *HTTP Parameter Pollution* (HPP) consiste en manipular cómo una aplicación trata los parámetros que recibe, inyectando parámetros extra —normalmente duplicando uno existente—…"
Fecha de actualización: 2026-07-27
Nota previa: ""
Nota siguiente: "[[01 - Parsing por stack, WAF bypass y defensa de HPP]]"
Area: "[[HTTP Parameter Pollution.base|HTTP Parameter Pollution]]"
---
---

<mark style="background: #ADCCFFA6;">La *HTTP Parameter Pollution* (HPP) consiste en manipular cómo una aplicación trata los parámetros que recibe</mark>, inyectando parámetros extra —normalmente duplicando uno existente— que el backend procesa de forma inesperada. El resultado depende de **qué hace el servidor** con esos parámetros y **cuál** de los duplicados elige, algo invisible desde fuera; por eso encontrar HPP es sobre todo experimentación. Se da en dos planos: *server-side* y *client-side*.

# Server-side HPP

El servidor ejecuta código sobre los parámetros, invisible para ti: ves lo que envías y lo que vuelve, no el código intermedio. <mark style="background: #FFB86CA6;">Si el backend confía en un parámetro que puedes duplicar, alteras el resultado de su lógica</mark>.

Ejemplo clásico — un banco que transfiere con parámetros de URL:

```http
GET /transfer?from=12345&to=67890&amount=5000 HTTP/1.1
```

Añadiendo un segundo `from` de una cuenta ajena:

```http
GET /transfer?from=12345&to=67890&amount=5000&from=ABCDEF HTTP/1.1
```

...si el banco **valida** con el primer `from` pero **ejecuta** con el último, transfieres desde una cuenta que no es tuya. <mark style="background: #FFB8EBA6;">Cada tecnología resuelve los parámetros duplicados distinto</mark> (unas toman el primero, otras el último, otras los concatenan) — la tabla completa por stack está en la [[01 - Parsing por stack, WAF bypass y defensa de HPP|nota siguiente]].

No se limita a parámetros con nombre. Cuando el backend mete valores en un **array posicional**, un parámetro extra desplaza las posiciones. En este Ruby (deliberadamente malo) del libro:

```ruby
user.account = 12345
def prepare_transfer(params)      # params = [67890, 5000] desde la URL
  params << user.account          # params = [67890, 5000, 12345]
  transfer_money(params)
end
def transfer_money(params)
  to     = params[0]
  amount = params[1]
  from   = params[2]              # espera user.account (12345)
  transfer(to, amount, from)
end
```

Normalmente `?to=67890&amount=5000` llena `params = [67890, 5000]` → tras el append queda `[67890, 5000, 12345]`, y `params[2]` es la cuenta del usuario (`12345`) — correcto. Pero al **inyectar un `from`** (`?to=67890&amount=5000&from=ABCDEF`), el framework llena `params = [67890, 5000, ABCDEF]` → tras el append `[67890, 5000, ABCDEF, 12345]`, y ahora `from = params[2]` toma `ABCDEF` (del atacante). <mark style="background: #8000E1A6;">El parámetro inyectado desplaza las posiciones que el código creía fijas.</mark>

# Client-side HPP

Aquí se inyectan parámetros en una URL para afectar al **navegador de la víctima**, no al servidor. El truco típico es codificar un `&` como `%26` para colar un parámetro dentro de una URL que el sitio **genera** a partir de tu entrada:

```text
http://host/page.php?par=123%26action=edit
```

Si `par` se refleja dentro de un `href` construido por el servidor, el `%26` se decodifica como `&` y añade un `action=edit` no previsto al enlace resultante. Depende de cómo el sitio construya y escape esa URL (`htmlspecialchars` convertiría el `&` en `&amp;`, por ejemplo).

# Tres casos reales

> [!example]+ HackerOne Social Sharing Buttons — $500 · [H1 #105953](https://hackerone.com/reports/105953)
> Los botones de "compartir" generaban el enlace social a partir de la URL del post. Añadiendo `&u=https://vk.com/durov` a la URL del blog, el enlace de Facebook (que toma el **último** `u`) apuntaba a `vk.com` en lugar de a HackerOne. Igual con `&text=` para el tweet.

> [!example]+ Twitter Unsubscribe — $700 · [blog.mert.ninja](https://blog.mert.ninja/twitter-hpp-vulnerability/)
> El enlace de baja llevaba `uid` + una firma `sig`. Cambiar `uid` por el de otro usuario fallaba (la firma ya no cuadraba). Mert Tasci añadió un **segundo** `uid`: Twitter validaba la firma con el primero pero daba de baja al segundo. **Lección**: la persistencia paga — casi todos habrían abandonado tras el primer fallo.

> [!example]+ Twitter Web Intents — undisclosed
> Los 4 tipos de *intent* (follow, like, retweet, tweet) eran vulnerables. Con dos `screen_name`, Twitter mostraba el perfil correcto pero la acción se ejecutaba sobre el **segundo**. Un HPP suele ser síntoma de un fallo **sistémico**: si aparece en un sitio, revisa toda la plataforma.

# Cazarlo

HPP pide experimentación: no ves el código, solo infieres. <mark style="background: #FF5582A6;">Los mejores sitios donde probar: enlaces que generan contenido para otro servicio (share buttons, callbacks), URLs construidas a partir de tu entrada, y parámetros con IDs o valores tipo entero</mark> — piensa en HPP al testear sustitución de parámetros ([[06 - Introducción a IDOR|IDOR]]). Duplica el parámetro sospechoso y observa qué copia usa el backend. El *cómo* técnico —tabla de parsing por stack, bypass de WAF y defensa— en la [[01 - Parsing por stack, WAF bypass y defensa de HPP|nota siguiente]].
