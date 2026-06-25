---
tags:
  - Full-Stack
  - Backend
  - NodeJS
Fecha de actualización: 2026-06-22
Nota previa: "[[01-CRUD y filtros en MongoDB]]"
Nota siguiente: "[[01-package.json y el gestor de paquetes npm]]"
Area: "[[Node.js.base|Node.js]]"
---
---

<mark style="background: #ADCCFFA6;">Node.js es un entorno de ejecución de JavaScript del lado del servidor</mark> que permite desplegar y configurar aplicaciones de back-end con facilidad. Está pensado para el manejo de comunicaciones asíncronas, la entrada/salida y los protocolos de red, y se ha convertido en todo un ecosistema gracias al gestor de paquetes [[01-package.json y el gestor de paquetes npm|npm]].

# El motor V8 y el modelo de ejecución

Node.js se construye sobre el **motor V8 de Google** (el mismo de Chrome), que compila JavaScript a código máquina. Sobre V8, Node añade APIs para acceder al sistema de archivos, la red y otros recursos del servidor —cosas que el JavaScript del navegador no puede hacer—.

<mark style="background: #ADCCFFA6;">La arquitectura de Node está orientada a eventos: la ejecución del programa está determinada por los sucesos que ocurren en el sistema</mark> (una petición que llega, un fichero que termina de leerse…). Su modelo es **asíncrono y no bloqueante**: en lugar de esperar a que termine una operación de E/S, Node registra una función de *callback* y sigue atendiendo otros eventos.

<mark style="background: #FFB86CA6;">Esto le permite manejar miles de conexiones concurrentes con un solo hilo</mark>, lo que explica su rapidez y su escalabilidad en aplicaciones intensivas en E/S (APIs, tiempo real).

# Hola Mundo: de la consola a un servidor

En la consola de Node (comando `node`), un mensaje simple:

```javascript
console.log('Hola Mundo!');
```

Un servidor HTTP mínimo se construye con el módulo nativo `http`:

```javascript
var http = require('http');

const server = http.createServer(function (req, res) {
  res.writeHead(200, { 'content-type': 'text/plain' });
  res.end('Hola Mundo');
});
server.listen(8000);
```

Línea a línea: se importa el módulo `http`; `createServer` recibe una función con dos parámetros, la **petición** (`req`) y la **respuesta** (`res`); `res.writeHead(200, …)` escribe en la cabecera el **código de estado 200** y el tipo de contenido `text/plain`; `res.end('Hola Mundo')` envía la respuesta; y `server.listen(8000)` fija el **puerto** de escucha. Se ejecuta con `node holamundo.js` y se visita en `localhost:8000`.

> [!info]+ Por qué importa este patrón
> Este `req`/`res` y el `listen(puerto)` son exactamente lo que [[00-Express.js, framework y middleware|Express.js]] abstrae y amplía. Express no sustituye a Node: se ejecuta **sobre** él, simplificando el enrutamiento y el manejo de peticiones.

# Módulos

Los archivos Node tienen extensión `.js` y se ejecutan con `node archivo.js`. Para reutilizar código se usa el sistema de **módulos**:

```javascript
var modulo = require('modulo');   // CommonJS (sintaxis clásica de Node)
import modulo from 'modulo';      // ES6 (frameworks modernos, React…)
```

<mark style="background: #FFB8EBA6;">Hay módulos nativos incluidos en Node</mark> (como `http` o `fs`) que no requieren instalación; el resto se instalan con [[01-package.json y el gestor de paquetes npm|npm]] y se cargan igual.

# El event loop en una frase

<mark style="background: #FFB8EBA6;">Node ejecuta JavaScript en un único hilo, pero delega las operaciones de E/S al sistema y registra callbacks que se disparan cuando terminan.</mark> Ese bucle que atiende eventos y ejecuta callbacks es el **event loop**. No hay un hilo por conexión (como en los servidores tradicionales), sino un hilo que multiplexa miles de conexiones.

> [!warning]+ El reverso de la moneda
> Como hay un solo hilo, una operación **síncrona y pesada** (cálculo intensivo en CPU) **bloquea** todo el servidor: ningún otro evento se atiende hasta que termine. Node brilla en cargas de **E/S** (APIs, red, BBDD), no en cómputo intensivo.

# Casos de uso

Node destaca en: **APIs REST**, aplicaciones en **tiempo real** (chats y notificaciones con WebSockets), *microservicios* y herramientas de línea de comandos. Su modelo asíncrono y su ecosistema npm lo convierten en el back-end por defecto de la pila MERN.

> [!important]+ Para el examen
> Node.js = **entorno de ejecución de JavaScript del lado del servidor**, sobre el motor **V8**, con modelo **asíncrono, no bloqueante y orientado a eventos**. Permite usar JS fuera del navegador (acceso a red, ficheros…). El módulo `http` + `createServer(req, res)` + `listen(puerto)` forma un servidor básico. Importación clásica: `require()`.
