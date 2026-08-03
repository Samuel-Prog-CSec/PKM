---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
Descripción: "Las notas anteriores rompen la autenticación adivinando algo"
Fecha de actualización: 2026-06-23
Nota previa: "[[07 - Reset de contraseña vulnerable]]"
Nota siguiente: "[[09 - Bypass de autenticación - modificación de parámetros]]"
Area: "[[Authentication.base|Authentication]]"
---
---

Las notas anteriores rompen la autenticación adivinando algo. El bypass la **rodea**: <mark style="background: #ADCCFFA6;">accede al recurso protegido sin pasar por el login</mark>. La forma más directa es pedir el recurso protegido desde un contexto no autenticado y ver si la app lo entrega igualmente.

# Forced browsing

Si la app redirige a `/admin.php` tras el login pero **confía solo en la página de login** para proteger ese recurso, accederlo directamente lo sirve. El caso de libro es raro tal cual, pero su variante es muy común: el control existe pero **no detiene la ejecución**.

```php
if(!$_SESSION['active']) {
    header("Location: index.php");   // redirige... pero el script SIGUE ejecutando
}
// ...todo el HTML protegido se envía igualmente en el cuerpo
```

<mark style="background: #FF5582A6;">El servidor manda un `302` hacia el login, pero el cuerpo de esa respuesta **ya contiene la página de admin completa**.</mark> El navegador obedece la redirección y nunca te la muestra — pero los datos están ahí. Para verlos, interceptas la respuesta con [[02 - Interceptación de peticiones|Burp]] y cambias el estado:

```http
GET /admin.php HTTP/1.1            →   HTTP/1.1 302 Found        ⇒  cambiar a 200 OK
                                       Content-Length: 14465      ⇒  el cuerpo es la página de admin
```

Cambiar `302 Found` a `200 OK` en la respuesta interceptada hace que el navegador renderice el contenido protegido. La pista para detectarlo: <mark style="background: #FFB86CA6;">una redirección con un `Content-Length` grande</mark> — si el `302` "vacío" trae 14 KB de cuerpo, ahí hay datos filtrados.

La corrección es un `exit;` tras el `header()`:

```php
if(!$_SESSION['active']) {
    header("Location: index.php");
    exit;                            // ahora sí detiene la ejecución
}
```

# Dónde aparece en el mundo real

Más allá del lab, el acceso directo es endémico en:

- <mark style="background: #FFB8EBA6;">APIs y endpoints administrativos sin control</mark>: `/api/admin/users`, `/actuator/env` (Spring), `/admin` de paneles que asumen "nadie conoce la URL" (seguridad por oscuridad).
- **Rutas server-side rendered** que comprueban auth en la vista pero no en el endpoint de datos.
- **Recursos estáticos protegidos** solo por enlace oculto (reportes, exports en `/files/...`).
- El bypass de [[04 - Fuerza bruta de códigos 2FA y MFA|2FA por forced browsing]] es exactamente esta clase: acceder al recurso post-2FA antes de superar el segundo factor.

> [!warning]+ Redirección ≠ control de acceso
> El error de diseño raíz: tratar una **redirección** como si fuera un control de acceso. Una redirección es una sugerencia al navegador, no una barrera al servidor. <mark style="background: #8000E1A6;">El control de acceso debe denegar y **cortar** la entrega de datos en el servidor</mark>, no confiar en que el cliente siga el `Location`. Probar siempre: pedir el recurso directo, e interceptar la respuesta para ver qué viaja en el cuerpo de los `3xx`.

Esta clase se solapa con el control de **autorización** ([[06 - Introducción a IDOR|IDOR]]): aquí se salta el "¿estás logueado?"; en IDOR, el "¿puedes ver *este* recurso?". La siguiente nota ataca el otro bypass: confiar en un [[09 - Bypass de autenticación - modificación de parámetros|parámetro]].

> [!info]+ Fuentes
> - [OWASP WSTG — Testing for Bypassing Authentication Schema](https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/04-Authentication_Testing/04-Testing_for_Bypassing_Authentication_Schema)
> - [OWASP — Forced Browsing](https://owasp.org/www-community/attacks/Forced_browsing)
