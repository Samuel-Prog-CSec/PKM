---
tags:
  - Web/Red-Team
  - Open-Redirect
  - Pentesting/Explotacion
  - Tipo/Introduccion
Descripción: "Un *open redirect* ocurre cuando una aplicación redirige el navegador a una URL controlada por el atacante, porque confía en un valor de entrada (normalmente un parámetro) sin…"
Fecha de actualización: 2026-07-27
Nota previa: ""
Nota siguiente: "[[01 - Bypasses de validación y chaining de Open Redirect]]"
Area: "[[Open Redirect.base|Open Redirect]]"
---
---

<mark style="background: #ADCCFFA6;">Un *open redirect* ocurre cuando una aplicación redirige el navegador a una URL controlada por el atacante</mark>, porque confía en un valor de entrada (normalmente un parámetro) sin validar que el destino sea propio. El ataque <mark style="background: #8000E1A6;">explota la confianza en el dominio legítimo</mark>: la víctima ve un enlace que empieza por `https://sitio-de-confianza.com/...`, hace clic, y acaba en el sitio del atacante sin notarlo.

Como solo redirige usuarios, <mark style="background: #FFB8EBA6;">en aislado se considera de impacto bajo</mark> — Google lo clasifica como *low* y OWASP lo retiró de su Top 10 de 2017. Pero es una de las <mark style="background: #FFB86CA6;">primitivas de *chaining* más rentables</mark>: alimenta el robo de tokens en OAuth (vía [[08 - Robo de tokens de acceso OAuth|redirect_uri]]), el phishing sobre un dominio de confianza, el bypass de filtros [[00 - Introducción a los ataques server-side|SSRF]] y de CSP, y la distribución de malware. Por eso conviene documentarlo aunque suela pagar poco suelto (ver [[04 - Mindset del cazador y encadenamiento de bugs|encadenamiento]]).

# Dónde vive: los tres vectores

Un open redirect nace de que el desarrollador confía en entrada del atacante para decidir el destino. Se materializa de tres formas:

**1. Parámetro de redirección (el más común).** Un parámetro lleva la URL de destino y el servidor responde con un `3xx` (`301`, `302`, `303`, `307`, `308`) y una cabecera `Location`:

```http
GET /login?redirect_to=https://www.gmail.com HTTP/1.1
Host: www.google.com
```

Si el sitio no valida que `redirect_to` apunte a un dominio propio, cambiarlo por `https://attacker.com` saca a la víctima fuera. <mark style="background: #FF5582A6;">Nombres a vigilar: `url`, `redirect`, `redirect_to`, `next`, `returnTo`, `return`, `checkout_url`, `continue`, `dest`, `r`, `u`</mark> — a veces de una sola letra o poco obvios, y varían de sitio a sitio.

**2. Meta refresh.** Una etiqueta HTML fuerza la recarga hacia una URL:

```html
<meta http-equiv="refresh" content="0; url=https://www.google.com/">
```

Explotable si el atacante controla el atributo `content` (o puede inyectar la etiqueta vía otra vulnerabilidad).

**3. Basado en DOM (`window.location`).** JavaScript redirige modificando la propiedad `location`:

```javascript
window.location = userInput;
window.location.href = userInput;
window.location.replace(userInput);
```

Requiere que el atacante controle ese valor — vía [[00 - Introducción a XSS|XSS]] o porque el sitio deja definir la URL de destino en el cliente. Es el *open redirect basado en DOM*, primo del DOM XSS.

# Tres casos reales

> [!example]+ Shopify Theme Install — $500 · [H1 #101962](https://hackerone.com/reports/101962)
> El parámetro `domain_name`, al final de la URL de *preview* de un tema, redirigía a la tienda del usuario añadiéndole `/admin`. Shopify **asumía** que siempre sería un dominio suyo y no lo validaba. `domain_name=attacker.com` redirigía a `http://attacker.com/admin`. *No todas las vulnerabilidades son complejas.*

> [!example]+ Shopify Login — $500 · [H1 #103772](https://hackerone.com/reports/103772)
> Aquí el atacante solo controlaba **parte** de la URL: `checkout_url` se **añadía** a un subdominio fijo de Shopify. Con `?checkout_url=.attacker.com`, el destino final era `http://mystore.myshopify.com.attacker.com/` — y como <mark style="background: #ADCCFFA6;">el DNS resuelve por la etiqueta más a la derecha</mark>, ese host pertenece a `attacker.com`, no a Shopify. **Lección**: con control parcial de una URL, caracteres especiales como `.` o `@` cambian su significado y el destino real.

> [!example]+ HackerOne Interstitial Redirect — $500 · [H1 #111968](https://hackerone.com/reports/111968)
> Las *interstitial pages* ("estás saliendo del sitio") mitigan el open redirect, pero HackerOne no las mostraba en enlaces que contuvieran `hackerone.com`, confiando en ellos. Mahmoud Jamal creó una cuenta Zendesk (`compayn.zendesk.com`), inyectó `<script>document.location.href="http://evil.com";</script>` en el tema, y un enlace `hackerone.com/zendesk_session?...&return_to=...redirect_to_account?state=compayn:/` — al contener `hackerone.com` saltaba sin interstitial y ejecutaba su JS. **Lección**: cada servicio de terceros que usa el objetivo (aquí Zendesk) es un vector nuevo; combina la confianza entre servicios con un redirect permitido.

# Cazarlo

En el [[03 - Metodología de caza - mapear y atacar la aplicación|mapeo de funcionalidad]], cualquier parámetro con una URL de destino es un *marker*: cambia el valor por un dominio externo (`https://example.com`, o mejor un *collaborator* tuyo) y observa si el `Location` de la respuesta o el `window.location` del cliente te sacan del dominio. Cuando el sitio **sí** valida el destino, empiezan los [[01 - Bypasses de validación y chaining de Open Redirect|bypasses]] — y el verdadero valor, que es encadenarlo con otra vulnerabilidad.
