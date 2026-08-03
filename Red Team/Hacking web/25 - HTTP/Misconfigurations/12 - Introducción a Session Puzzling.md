---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Session-Puzzling
  - Tipo/Introduccion
Descripción: "Las sesiones dan contexto a un protocolo que no lo tiene"
Fecha de actualización: 2026-07-14
Nota previa: "[[11 - Detección, herramientas y prevención de Host Header Attacks]]"
Nota siguiente: "[[13 - Session IDs débiles]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

Las sesiones dan **contexto** a un protocolo que no lo tiene. Robar o corromper una sesión equivale a <mark style="background: #8000E1A6;">tomar la cuenta de la víctima</mark>, por eso los bugs de sesión son de alto impacto. El **Session Puzzling** es uno especialmente sutil: no roba la sesión, la **confunde**, aprovechando que la app maneja mal sus **variables de sesión**.

# HTTP es stateless; las sesiones lo arreglan

La [RFC 7230](https://www.rfc-editor.org/rfc/rfc7230) dice que <mark style="background: #ADCCFFA6;">cada petición HTTP se entiende **en aislamiento**</mark>, independiente de las demás. En una tienda online, "añadir al carrito" y "pagar" son peticiones separadas; lo que las cose es la **sesión**: un identificador (cookie) más las **variables de sesión** asociadas en el servidor. (`TCP`, en cambio, sí es stateful: su número de secuencia ata los paquetes.)

# Tokens stateful vs stateless

La diferencia es **dónde vive el estado**:

- **Stateful**: el servidor genera un token aleatorio y guarda **en su lado** el mapeo token→usuario. Cookie típica de PHP:
  ```http
  Set-Cookie: PHPSESSID=hvplcmsh88ja77r3dutanmn68u;
  ```
  El estado se almacena en `/var/lib/php/sessions/sess_<id>`:
  ```text
  Username|s:8:"testuser";Active|b:1;
  ```
- **Stateless**: el token **contiene** toda la info, protegida por una **firma** criptográfica. El caso canónico es el **`JWT`** (header con el algoritmo · body con los claims · firma). Los ataques a JWT (confusión de algoritmo, secreto débil…) se tratan a fondo en [[01 - Introducción a JWT|el bloque de JWT]] del módulo de autenticación.

# Qué es el Session Puzzling

<mark style="background: #ADCCFFA6;">Session puzzling = manejo incorrecto de variables de sesión, de forma que el estado de un flujo se **filtra** a otro</mark>. Lo acuñó Shay Chen (2011). El impacto depende de la app, pero suele ser <mark style="background: #FFB86CA6;">bypass de autenticación o account takeover</mark>. Tres causas raíz (el resto del bloque desarrolla cada una):

1. **Reutilizar** la misma variable de sesión en procesos distintos (login, registro, reset).
2. **Poblar prematuramente** una variable antes de completar la autenticación.
3. **Valores por defecto inseguros** de las variables.

# Ejemplo: valor por defecto inseguro

```php
session_start();
// login
if (check_password($_POST['username'], $_POST['password'])) {
    $_SESSION['user_id'] = get_user_id($_POST['username']);   // ← se puebla al autenticar
    header("Location: profile.php"); die();
}
// logout
if (isset($_POST['logout'])) {
    $_SESSION['user_id'] = 0;                          // ← no destruye la sesión, la pone a 0
}
```

`profile.php` confía en `$_SESSION['user_id']`. No puedes manipular la sesión directamente, así que parece seguro. El fallo: <mark style="background: #FF5582A6;">al hacer logout, la sesión **no se destruye**; `user_id` se pone a **0**</mark>. Si `0` es un ID **válido** —el del admin—, el ataque es trivial:

1. Login con tu cuenta → `user_id` = el tuyo.
2. Logout → `user_id = 0`.
3. Ir a `/profile.php` → <mark style="background: #FFB86CA6;">estás logueado como **admin**</mark> (user_id 0).

Es session puzzling por **valor por defecto inseguro**: el default de `user_id` coincide con una cuenta real.

> [!important] Por qué escapa a los escáneres
> El session puzzling vive en la **lógica de estado multi-paso**, no en un parámetro reflejado. Ninguna herramienta automática "ve" que una variable poblada en el flujo de registro se reutiliza en el de login. Se caza **razonando** sobre qué variable de sesión toca cada flujo y probando a **cruzarlos**: empezar un flujo, abandonarlo a medias, y entrar en otro que reutilice la misma variable. Es terreno de bug bounty de alto valor (bypass de 2FA, de reset, de login).

Esta familia complementa a los [[10 - Ataques a tokens de sesión|ataques a tokens de sesión]] del módulo de autenticación: allí se ataca el **token**; aquí, la **lógica** que gobierna las variables detrás de él. Las siguientes notas cubren [[13 - Session IDs débiles|IDs débiles]], [[14 - Variables de sesión compartidas - bypass de autenticación|variables compartidas]] y la [[15 - Población prematura de sesión|población prematura]].

## Referencias

- [Shay Chen — Session Puzzling / Session Variable Overloading (2011)](https://owasp.org/www-pdf-archive/Session_Puzzles.pdf)
- [PortSwigger — Authentication vulnerabilities](https://portswigger.net/web-security/authentication)
