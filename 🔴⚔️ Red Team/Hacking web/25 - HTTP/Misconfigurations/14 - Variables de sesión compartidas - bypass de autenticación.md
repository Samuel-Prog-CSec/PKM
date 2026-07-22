---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Session-Puzzling
Fecha de actualización: 2026-07-14
Nota previa: "[[13 - Session IDs débiles]]"
Nota siguiente: "[[15 - Población prematura de sesión]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

El session puzzling por excelencia: <mark style="background: #ADCCFFA6;">una misma variable de sesión se usa en **dos flujos distintos**</mark>, y escribirla desde el flujo "débil" engaña al flujo "fuerte". Detectarlo se parece a cazar un bug de **lógica de negocio**: hay que mapear **dónde** se escriben y leen las variables de sesión y buscar el cruce peligroso.

# Identificación: mapear el flujo multi-paso

La app tiene login y un **reset de contraseña en 3 pasos**: (1) usuario → (2) pregunta de seguridad → (3) nueva contraseña. Pista clave: <mark style="background: #ADCCFFA6;">en el paso 2 la petición **no** reenvía el username, pero el backend sabe de qué usuario hablamos</mark> → esa información se guarda en **variables de sesión** entre pasos. Se confirma quitando la cookie de sesión: te redirige al login (sesión nueva, sin el contexto).

Sabemos entonces que el flujo de reset **puebla** una variable de sesión con el usuario. La pregunta es cómo abusarlo.

# Explotación

**Intento 1 (falla, pero educa)**: saltar la pregunta de seguridad. Mando `admin` a `/reset_1.php` (guarda `admin` en sesión) y accedo directo a `/reset_3.php` para fijar la contraseña sin responder la pregunta. El servidor detecta que no completé la fase 2 y redirige. No cuela — hay control de fase.

**Intento 2 (funciona)**: ¿y si el reset y el **login** usan **la misma** variable de sesión para el usuario? Entonces poblarla desde el reset pasa el control de autenticación:

1. *Forgot Password?* → introduce username `admin` (esto ejecuta `reset_1.php`).
2. Accede directo a `/profile.php`.
3. <mark style="background: #FFB86CA6;">Estás logueado como **admin**</mark>, sin contraseña ni pregunta de seguridad.

# La raíz en el código

```php
// reset_1.php — el flujo de reset escribe la variable...
if (isset($_POST['Submit'])) {
    $_SESSION['Username'] = $_POST['Username'];   // ← controlable por el atacante
    header("Location: reset_2.php"); exit;
}
```

```php
// profile.php — ...y la autenticación LEE la misma variable
if (!isset($_SESSION['Username'])) {              // ← solo comprueba que EXISTE
    header("Location: login.php"); exit;
}
```

El control de acceso solo comprueba que `$_SESSION['Username']` **esté puesta**, sin verificar que se puso por un **login exitoso**. El flujo de reset la puebla con el usuario que yo diga → <mark style="background: #8000E1A6;">el reset se convierte en un login sin credenciales</mark>.

> [!important] La metodología, generalizada
> Busca **toda** función que **escriba** una variable de sesión (registro, reset, cambio de email, selección de perfil, primer paso de 2FA…) y toda función que **lea** una variable para tomar decisiones de acceso. El bug aparece cuando <mark style="background: #FF5582A6;">una escritura poco protegida alimenta una lectura de alta confianza</mark>. Es razonamiento de lógica de negocio: ningún escáner lo detecta.

> [!warning] El patrón moderno más jugoso: bypass de 2FA
> El mismo fallo es la causa de muchos **bypass de 2FA** en bug bounty: el paso 1 (usuario+contraseña) puebla `$_SESSION['user_id']` **antes** de validar el segundo factor, y la página post-login confía en `user_id` sin comprobar el flag de "2FA superado". Variantes: registro que fija `session.email` y login que confía en él → account takeover; flujo OAuth a medias que deja la sesión medio-autenticada. Siempre que veas un flujo multi-paso, **crúzalo** con otro.

La prevención (namespaces de sesión por flujo, un flag `authenticated` que solo ponga el login) se detalla en [[17 - Detección, herramientas y prevención de Session Puzzling]]. La siguiente variante ataca el **momento** en que se puebla la variable: la [[15 - Población prematura de sesión|población prematura]].

## Referencias

- [PortSwigger — Business logic vulnerabilities](https://portswigger.net/web-security/logic-flaws)
- [OWASP WSTG — Testing for Session Puzzling](https://owasp.org/www-project-web-security-testing-guide/)
