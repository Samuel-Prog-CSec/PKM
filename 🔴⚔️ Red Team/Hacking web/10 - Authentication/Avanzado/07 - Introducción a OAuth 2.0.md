---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - OAuth
  - Tipo/Introduccion
Descripción: "OAuth 2.0 es un estándar de autorización delegada: permite que una app acceda a tus recursos en otro servicio sin que le des tu contraseña"
Fecha de actualización: 2026-06-23
Nota previa: "[[06 - Herramientas JWT y prevención]]"
Nota siguiente: "[[08 - Robo de tokens de acceso OAuth]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

<mark style="background: #ADCCFFA6;">`OAuth 2.0` es un estándar de **autorización delegada**: permite que una app acceda a tus recursos en otro servicio sin que le des tu contraseña.</mark> Es el motor del "Login with Google/GitHub". Entender su flujo —y dónde viaja cada parámetro— es requisito para atacarlo: los fallos están en la validación de esos parámetros.

# Las cuatro entidades

| Entidad | Rol |
| - | - |
| `Resource Owner` | El usuario, dueño de los datos (John) |
| `Client` | La app que pide acceso a los datos (`academy.htb`) |
| `Authorization Server` | Autentica al usuario y emite tokens (`hubgit.htb`) |
| `Resource Server` | Aloja los recursos (a menudo, el mismo que el authz server) |

El caso típico: John quiere entrar en `academy.htb` con su cuenta de `hubgit.htb`. Pulsa "Login with hubgit", se autentica en hubgit, consiente, y academy obtiene acceso a su perfil **sin ver su contraseña**.

![Flujo OAuth: el cliente pide autorización al dueño del recurso, recibe un grant, lo presenta al authorization server, obtiene un access token y con él accede al resource server.](https://academy.hackthebox.com/storage/modules/259/Diagram3.png)

# Authorization Code Grant (el flujo seguro)

El grant más común y robusto. Siete pasos, y cada parámetro importa:

**1 · Authorization Request** — el cliente manda al usuario al authz server:

```http
GET /auth?client_id=1337&redirect_uri=http://academy.htb/callback&response_type=code&scope=user&state=a45c12e87d4522 HTTP/1.1
Host: hubgit.htb
```

- `client_id`: identifica al cliente.
- <mark style="background: #FF5582A6;">`redirect_uri`</mark>: a dónde se devuelve al usuario tras autorizar. **El parámetro más atacable** ([[08 - Robo de tokens de acceso OAuth|robo de tokens]]).
- `response_type=code`: pide un código (no un token directo).
- `scope`: qué recursos pide.
- <mark style="background: #FF5582A6;">`state`</mark>: nonce anti-CSRF que ata la request al callback ([[09 - Protección CSRF deficiente en OAuth|CSRF]]).

**2 · Autenticación** — el usuario se loguea en hubgit y consiente.

**3 · Authorization Code** — hubgit redirige al `redirect_uri` con el código:

```http
GET /callback?code=ptsmyq2zxyvv23bl&state=a45c12e87d4522 HTTP/1.1
Host: academy.htb
```

**4 · Access Token Request** — el cliente cambia el código por un token (server-to-server, **fuera del navegador**):

```http
POST /token HTTP/1.1
Host: hubgit.htb

client_id=1337&client_secret=SECRET&redirect_uri=http://academy.htb/callback&grant_type=authorization_code&code=ptsmyq2zxyvv23bl
```

El `client_secret` autentica al cliente — el usuario nunca lo ve. <mark style="background: #8000E1A6;">Que el intercambio código→token ocurra en el backend es lo que hace seguro a este grant</mark>: el token nunca pasa por el navegador de la víctima.

**5-7 · Token y recurso** — hubgit devuelve el `access_token`, y el cliente lo usa como `Bearer` para pedir los datos:

```http
GET /user_info HTTP/1.1
Host: hubgit.htb
Authorization: Bearer RsT5OjbzRn430zqMLgV3Ia
```

# Implicit Grant (el inseguro, en retirada)

Versión corta: se salta el intercambio de código y el authz server devuelve el **token directamente en el fragmento de URL** (`response_type=token`):

```http
GET /callback#access_token=RsT5OjbzRn430zqMLgV3Ia&token_type=Bearer&expires_in=3600&state=... HTTP/1.1
```

<mark style="background: #FFB86CA6;">El problema: el token queda expuesto en el navegador</mark> (historial, `Referer`, JS), por eso es menos seguro. Se diseñó para SPAs que no podían guardar el código de forma segura.

> [!warning]+ OAuth 2.1 elimina el implicit grant
> El borrador de [OAuth 2.1](https://oauth.net/2.1/) **retira el implicit grant** por inseguro: las SPAs deben usar ahora *authorization code grant con PKCE*. Si encuentras `response_type=token` en producción, ya es una bandera: implementación antigua y con el token expuesto en el cliente. <mark style="background: #FFB86CA6;">`PKCE` (`code_challenge`/`code_verifier`) ya no es solo cosa de SPAs: OAuth 2.1 lo exige en **todos** los flujos de authorization code</mark>, también los clientes confidenciales server-side. Un authz server que acepta el flujo **sin** `code_challenge` (PKCE downgrade) es un hallazgo válido en 2025.

El resto del sub-tema explota los dos parámetros críticos de este flujo: el [[08 - Robo de tokens de acceso OAuth|`redirect_uri`]] y el [[09 - Protección CSRF deficiente en OAuth|`state`]].

> [!info]+ Fuentes
> - [RFC 6749 — OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc6749) · [oauth.net/2.1](https://oauth.net/2.1/) · [PKCE (RFC 7636)](https://datatracker.ietf.org/doc/html/rfc7636)
> - [PortSwigger — OAuth 2.0 authentication vulnerabilities](https://portswigger.net/web-security/oauth)
