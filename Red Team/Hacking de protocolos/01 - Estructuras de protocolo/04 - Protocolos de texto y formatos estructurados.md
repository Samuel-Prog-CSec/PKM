---
tags:
  - Protocolos
  - Redes
  - Pentesting/Enumeracion
Descripción: "Delimitadores, fin de línea y formatos estructurados (MIME, JSON, XML) en protocolos de texto, y por qué la tolerancia de los parsers es la raíz de los parser differentials"
Fecha de actualización: 2026-08-03
Nota previa: "[[03 - Formatos binarios estructurados]]"
Nota siguiente: "[[05 - Codificación de binario en texto]]"
Area: "[[Estructuras de protocolo.base|Estructuras de protocolo]]"
---
---

Cuando lo que se transporta es fundamentalmente texto —correo, mensajería, noticias, la web— tiene sentido que el protocolo también lo sea: se depura con `telnet`, se lee sin herramientas y se extiende sin recompilar nada. El precio es que **delimitar deja de ser exacto y pasa a ser interpretativo**, y ahí nacen la mayoría de sus vulnerabilidades.

## Representar valores en texto

- **Enteros**: los dígitos tal cual. Sin límite de tamaño impuesto por la representación — lo que traslada el problema al parser: `atoi("99999999999999999999")` en C es comportamiento indefinido, y `strtol` satura a `LONG_MAX` sin que nadie mire `errno`. Un campo numérico de texto **siempre** hay que probarlo con un valor de 40 dígitos.
- **Decimales**: punto o coma según la locale, y ahí ya hay un fallo esperando. Además el binario no representa exactamente todos los decimales, así que comparar importes por igualdad es frágil.
- **Booleanos**: `true`/`false`, a veces con mayúsculas obligatorias, a veces `0`/`1`, a veces `yes`/`on`. La tolerancia varía entre implementaciones.
- **Fechas**: el desastre. Sin un formato universal, un cliente de correo tiene que aceptar RFC 5322, ISO 8601 y una docena de variantes regionales. Cada parser tolerante es una superficie.

## Delimitadores

Separar campos con un carácter. Habitualmente espacio en formatos legibles, pero no siempre: el protocolo financiero **FIX** delimita con `SOH` (ASCII 1), invisible en cualquier volcado de texto.

Y para terminar comandos, el fin de línea. Aquí está el problema clásico:

> [!warning]+ `CRLF` obligatorio, `LF` aceptado — y de ahí salen los ataques
> HTTP ([RFC 9112](https://datatracker.ietf.org/doc/html/rfc9112)) y SMTP ([RFC 5321](https://datatracker.ietf.org/doc/html/rfc5321)) especifican **`CR LF`** como terminador. Pero hubo tantas implementaciones que enviaban solo `LF` que casi todos los parsers acabaron aceptando ambos «por robustez».
>
> Esa tolerancia es exactamente el mecanismo de **[[06 - Introducción a HTTP Request Smuggling|request smuggling]]**: un proxy trata `LF` como fin de línea y el servidor de detrás exige `CRLF`, o al revés. Los dos ven peticiones distintas en el mismo flujo de bytes. Lo mismo, un nivel más simple, es la **[[01 - Introducción a CRLF Injection|inyección CRLF]]**: si un valor controlado por el usuario acaba en una cabecera sin filtrar `\r\n`, se inyectan cabeceras nuevas o se parte la respuesta ([[03 - HTTP Response Splitting]]).
>
> El principio de robustez de Postel («sé conservador en lo que envías, liberal en lo que aceptas») es, en seguridad, **una fuente sistemática de vulnerabilidades**: cada tolerancia añadida por un implementador es una discrepancia potencial con el siguiente componente de la cadena. Los RFC modernos lo dicen explícitamente ([RFC 9413](https://datatracker.ietf.org/doc/html/rfc9413)). La generalización del problema —dos parsers que ven cosas distintas en los mismos bytes— está en [[09 - Conversión de codificaciones y parser differentials]].

## MIME

Nació para adjuntos de correo ([RFC 2045](https://datatracker.ietf.org/doc/html/rfc2045) y siguientes) y acabó en HTTP, SIP y muchos más. Separa partes con una línea de frontera prefijada por `--`, y cierra repitiendo la frontera con `--` también al final:

```text
Content-Type: multipart/mixed; boundary=MSG_2934894829

--MSG_2934894829
Content-Type: text/plain

Hello World!
--MSG_2934894829
Content-Type: application/octet-stream
Content-Transfer-Encoding: base64

PGh0bWw+Cjxib2R5PgpIZWxsbyBXb3JsZCEKPC9ib2R5Pgo8L2h0bWw+Cg==
--MSG_2934894829--
```

Superficie de ataque: **la frontera la elige el emisor**. Si el contenido de una parte contiene la frontera, se parte donde no debe. Si el parser admite fronteras con caracteres especiales o vacías, o si difiere del siguiente componente en cómo maneja espacios finales, hay *parser differential*. Es lo que sostiene buena parte de los *bypass* de [[00 - Introducción a los File Upload Attacks|subida de ficheros]] y de filtrado de correo.

Los **MIME types** (`text/plain`, `application/octet-stream`) mapean contenido a manejador, y ahí el clásico es el **MIME sniffing**: el navegador ignora el `Content-Type` declarado y adivina por el contenido, convirtiendo un fichero «de texto» en HTML ejecutable. Se corta con `X-Content-Type-Options: nosniff`.

## JSON

Objetos entre llaves, pares clave-valor. Simple, y por eso está en todas partes.

```json
{ "index": 0, "str": "Hello World!", "arr": [ "A", "B" ] }
```

Riesgos que siguen vigentes:

- **`eval()`**. El pecado original. Hoy casi nadie parsea JSON con `eval`, pero sigue apareciendo en código antiguo y en implementaciones caseras — y ejecuta código en el contexto de la página ([[00 - Introducción a XSS|XSS]]).
- **Claves duplicadas**. `{"user":"admin","user":"guest"}` es JSON válido y **la especificación no dice cuál gana**. Python se queda con la última, algunas librerías Go con la primera. Si la autenticación mira un parser y la autorización otro, tienes un *bypass*.
- **Números grandes y precisión**. JavaScript pierde precisión por encima de 2⁵³; un ID de 19 dígitos deja de ser único.
- **Interpretación de tipos**. `{"user": {"$ne": null}}` es la base de la [[NoSQL Injection.base|inyección NoSQL]]: si el valor llega al motor como objeto en vez de como cadena, se convierte en operador de consulta.
- **Profundidad de anidamiento**. Sin cota, un JSON de 100.000 niveles agota la pila en parsers recursivos.

## XML

Elementos, atributos y texto, con reglas más estrictas que HTML — la intención declarada era simplificar los parsers y reducir fallos.

```xml
<value index="0">
    <str>Hello World!</str>
    <arr><value>A</value><value>B</value></arr>
</value>
```

No salió bien. XML es <mark style="background: #FFB86CA6;">el formato de texto con más superficie de ataque de todos</mark>, porque el estándar incluye funcionalidad que nadie necesita y casi nadie desactiva:

- **[[14 - Introducción a XXE|XXE]]** — entidades externas que leen ficheros locales o hacen peticiones de red desde el servidor.
- **Billion laughs** — entidades anidadas que expanden a gigabytes desde unos cientos de bytes. Es *data expansion* de manual ([[05 - Vulnerabilidades de agotamiento de recursos]]).
- **XSLT** — transformación con capacidad de ejecutar código ([[XSLT.base|XSLT]]).
- **XPath** — si la consulta se construye concatenando, [[XPath Injection.base|inyección]].
- **Namespaces y `xml:base`** — vías de confusión para filtros basados en nombre de elemento.

Cuando un protocolo binario propietario encapsula XML dentro, hereda **toda** esa superficie. Y como el analista está concentrado en el *framing* binario, es fácil que se le pase.

## Regla práctica

En cuanto identifiques un formato estructurado dentro de un protocolo, **deja de analizar el formato y ataca su parser**: la biblioteca de ataques ya existe y está en el vault. El trabajo original que queda es el *framing* que lo envuelve.

> [!info]+ Fuentes
> - [RFC 9112](https://datatracker.ietf.org/doc/html/rfc9112) (HTTP/1.1) y [RFC 5321](https://datatracker.ietf.org/doc/html/rfc5321) (SMTP) para el terminador `CRLF`.
> - [RFC 9413](https://datatracker.ietf.org/doc/html/rfc9413) — *Maintaining Robust Protocols*, la revisión moderna (y crítica) del principio de robustez.
> - [RFC 8259 §4](https://datatracker.ietf.org/doc/html/rfc8259#section-4) — comportamiento indefinido ante claves duplicadas en JSON.
> - Forshaw, *Attacking Network Protocols*, cap. 3, «Text Protocol Structures».
