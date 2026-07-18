---
tags:
  - Redes
  - Protocolos
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

El **protocolo de transferencia de archivos (FTP)** es uno de los protocolos más antiguos de Internet. El FTP se ejecuta dentro de la **capa de aplicación** de la pila de protocolos TCP/IP. 

Imaginemos que queremos subir archivos locales a un servidor y descargar otros archivos utilizando el protocolo FTP. En una **conexión FTP, se abren dos canales**. Primero, el ==cliente y el servidor establecen un canal de control a través del puerto `TCP 21`==. El cliente envía comandos al servidor y el servidor devuelve códigos de estado. Luego, ambos participantes de la comunicación pueden ==establecer el canal de datos a través del puerto `TCP 20`==. Este canal se utiliza exclusivamente para la transmisión de datos y el protocolo vigila los errores durante este proceso. Si se interrumpe una conexión durante la transmisión, el transporte se puede reanudar después de restablecer el contacto.

Se hace una distinción entre **FTP activo y pasivo**:
- En la **variante activa**, el cliente establece la conexión como se describe a través del puerto TCP 21 y, de esta manera, informa al servidor a través de qué puerto, del lado del cliente, puede transmitir las respuestas el servidor. Sin embargo, ==si un cortafuegos protege al cliente, el servidor no puede responder== porque todas las conexiones externas están bloqueadas. 
- Para este propósito, se ha desarrollado el **modo pasivo**. El ==servidor anuncia un puerto a través del cual el cliente puede establecer el canal de datos==. Como el cliente inicia la conexión en este método, el **cortafuegos no bloquea la transferencia**.

El FTP conoce diferentes **[comandos](https://www.smartfile.com/blog/the-ultimate-ftp-commands-list/) y códigos de estado**. El ==servidor responde en cada petición del cliente con un código de estado== que indica si el comando se implementó correctamente. Puede encontrar una lista de posibles códigos de estado [aquí](https://en.wikipedia.org/wiki/List_of_FTP_server_return_codes).

Por lo general, **necesitamos credenciales para usar FTP en un servidor**. Sin embargo, también ==existe la posibilidad de que un servidor ofrezca **FTP anónimo**==. Dado que existen riesgos de seguridad asociados a un servidor FTP público de este tipo, ==las opciones para los usuarios suelen ser limitadas==.


# Índice
- [[📂🔄 FTP]]
- [[📂🚀 TFTP]]
- 🗃️ **Servidores FTP**:
	- [[📂🖥️🌐 vsFTPd]]
	- [[⚠️⚙️ Ajustes peligrosos]]
- [[04 - FTP|Footprinting de FTP (ofensivo)]]