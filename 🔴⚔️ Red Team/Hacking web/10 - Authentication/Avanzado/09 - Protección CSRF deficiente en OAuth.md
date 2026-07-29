---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - OAuth
Descripción: "El parámetro state es opcional en OAuth pero crítico: es el token anti-CSRF del flujo"
Fecha de actualización: 2026-06-23
Nota previa: "[[08 - Robo de tokens de acceso OAuth]]"
Nota siguiente: "[[10 - Vulnerabilidades adicionales y prevención OAuth]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

El parámetro [[07 - Introducción a OAuth 2.0|`state`]] es opcional en OAuth pero crítico: es el token anti-[[01 - Fundamentos y defensas de CSRF|CSRF]] del flujo. <mark style="background: #ADCCFFA6;">Si falta o es predecible, el flujo OAuth es vulnerable a CSRF</mark>, y el ataque más directo es el **Login CSRF**: forzar a la víctima a iniciar sesión en la cuenta del **atacante**.

# El ataque: Login CSRF

Cuando no hay `state`, nada ata la autorización al usuario que la inició. El atacante mete a la víctima en su propia sesión:

1. El atacante obtiene un `authorization code` **para su propia cuenta** autenticándose en hubgit:

```http
POST /authorization/signin HTTP/1.1
Host: hubgit.htb

username=attacker&password=attacker&client_id=0e8f12335b0bf225&redirect_uri=%2Fclient%2Fcallback
```

2. Con ese código construye la URL del callback y se la entrega a la víctima (igual que un CSRF normal):

```text
http://hubgit.htb/client/callback?code=Z0FBQUFBQm1...
```

3. La víctima hace clic; su navegador completa el flujo y canjea el código del **atacante** por un access token. <mark style="background: #FFB86CA6;">La víctima queda logueada en la cuenta del atacante sin saberlo.</mark>

# Por qué importa un "Login CSRF"

Parece inofensivo —¿qué daño hay en loguear a alguien en *otra* cuenta?— pero el impacto puede ser severo:

- <mark style="background: #FFB86CA6;">**Robo de datos por confusión**</mark>: la víctima, creyendo que es su cuenta, introduce datos sensibles (tarjeta de pago, documentos, mensajes). Todo va a parar a la cuenta del atacante, que luego los lee.
- **Historial y actividad**: búsquedas, ubicaciones, archivos subidos quedan registrados en la cuenta del atacante.
- <mark style="background: #8000E1A6;">**Account linking takeover**</mark>: la variante grave. Si el flujo OAuth **vincula** una cuenta social a una cuenta existente del cliente, un CSRF puede atar la cuenta del **atacante** (en el IdP) a la cuenta de la **víctima** (en el cliente) → el atacante entra a la cuenta de la víctima con su propio login social. Esto es account takeover completo.

# Cómo protege el `state`

El `state` es un nonce impredecible que el cliente genera y guarda (normalmente en cookie) al iniciar el flujo, y verifica al recibir el callback. Si el atacante prepara el flujo con su `state`, no coincidirá con el de la cookie de la víctima → **mismatch** y rechazo:

```http
GET /client/callback?code=...&state=1337 HTTP/1.1
→ HTTP/1.1 500  "Invalid state"
```

> [!warning]+ Presente no basta: el state debe ser impredecible
> <mark style="background: #FF5582A6;">Como cualquier token CSRF, la seguridad del `state` depende de que no se pueda adivinar.</mark> Si es un valor fijo, secuencial o derivado de algo conocido, el atacante lo replica en su request y la protección cae. Al auditar: comprueba que el `state` (1) existe, (2) se valida server-side contra la sesión, y (3) tiene entropía real. Un `state=1`, `state=true` o ausente es hallazgo.

> [!info]+ Fuentes
> - [PortSwigger — Flawed CSRF protection in OAuth](https://portswigger.net/web-security/oauth#flawed-csrf-protection)
> - [RFC 6749 §10.12 — CSRF](https://datatracker.ietf.org/doc/html/rfc6749#section-10.12) · [OAuth Security BCP (RFC 9700)](https://datatracker.ietf.org/doc/html/rfc9700)
