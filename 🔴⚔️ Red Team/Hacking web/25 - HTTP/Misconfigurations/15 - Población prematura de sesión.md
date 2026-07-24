---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Session-Puzzling
Fecha de actualización: 2026-07-14
Nota previa: "[[14 - Variables de sesión compartidas - bypass de autenticación]]"
Nota siguiente: "[[16 - Variables de sesión compartidas - account takeover]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

La segunda variante de session puzzling: la **población prematura**. <mark style="background: #ADCCFFA6;">El servidor escribe datos en la sesión **antes** de que un proceso termine o de conocer su resultado</mark> — en concreto, marca la sesión como autenticada **antes** de comprobar la contraseña. Si la limpieza posterior se puede evitar, hay bypass de autenticación.

# Identificación: la sesión se puebla incluso al fallar

La app (sin reset esta vez) redirige un **login fallido** a `/login.php?failed=1`, y el mensaje de error **muestra el username** que enviaste. Detalle clave: <mark style="background: #FFB8EBA6;">ese redirect es una **petición separada** que no lleva el username en ningún parámetro</mark> — luego el servidor lo guardó en la sesión. Se confirma pidiendo `/login.php?failed=1` **sin** cookie de sesión válida: el mensaje cambia y ya no muestra el usuario. Conclusión: **la sesión se puebla también en un login fallido**.

# Explotación: descartar el redirect

Si la sesión queda poblada tras fallar y no se limpia, deberíamos poder entrar. Pero acceder a `/profile.php` tras el fallo redirige al login… porque <mark style="background: #FF5582A6;">el servidor solo limpia la sesión cuando se procesa la petición a `/login.php?failed=1`</mark>. Ahí está la grieta: **ese paso lo controla el cliente**.

El ataque:
1. Intento un login **inválido** para `admin` (usuario correcto, contraseña cualquiera).
2. **Descarto** (drop) el redirect a `/login.php?failed=1` — así la limpieza (`session_destroy`) **nunca se ejecuta**.
3. Uso esa cookie de sesión para acceder a `/profile.php` → <mark style="background: #FFB86CA6;">entro como **admin**</mark>.

> [!example] La técnica "drop the redirect" en Burp
> Con *Intercept* activo, envías el login inválido y, cuando el navegador va a seguir el `302` hacia `/login.php?failed=1`, **descartas** esa petición (botón *Drop*). La sesión se quedó "autenticada" del paso previo y la limpieza no llegó a correr. Es un patrón reutilizable: **cuando la seguridad depende de una petición de seguimiento (un redirect, un callback), descártala y observa qué estado queda a medias**.

# La raíz en el código

```php
if (isset($_POST['Submit'])) {
    $_SESSION['Username'] = $_POST['Username'];
    $_SESSION['Active']   = true;              // ← marcada activa ANTES de validar
    if (login($_POST['Username'], $_POST['Password'])) {
        header("Location: profile.php"); exit;
    } else {
        header("Location: login.php?failed=1"); exit;   // limpieza SOLO si se sigue esto
    }
}
if (isset($_GET['failed'])) {
    session_destroy(); session_start();        // ← depende de que el cliente pida ?failed=1
}
```

`Active = true` se pone **antes** de `login()`. La única limpieza vive en una rama que exige una **segunda petición** del cliente — descártala y la sesión queda autenticada con credenciales inválidas.

> [!important] Es un fallo **fail-open**, no una race condition
> El patrón: la sesión se marca autenticada **antes** de comprobar las credenciales, y la única limpieza se delega a un paso (el redirect) que el atacante gobierna. No es un `TOCTOU` (no hay carrera temporal que ganar): es un estado de autenticación **poblado prematuramente** que **no falla de forma segura**. La regla inviolable: <mark style="background: #FF5582A6;">**nunca** establezcas estado de autenticación antes de la verificación completa</mark>, y no dependas de una petición de seguimiento para deshacerlo. El mismo error habilita bypass de 2FA (marcar `authenticated` antes del segundo factor) y fallos de "remember me".

La tercera variante escala esto de bypass a [[16 - Variables de sesión compartidas - account takeover|account takeover]]; la prevención completa, en [[17 - Detección, herramientas y prevención de Session Puzzling]]. La manipulación fina de peticiones (interceptar, dropear, reordenar) se apoya en los [[00 - Introducción a los proxies web|proxies web]] como Burp o Caido.

## Referencias

- [OWASP WSTG — Testing for Bypassing Authentication Schema](https://owasp.org/www-project-web-security-testing-guide/)
- [PortSwigger — Flawed multi-step processes](https://portswigger.net/web-security/logic-flaws/examples)
