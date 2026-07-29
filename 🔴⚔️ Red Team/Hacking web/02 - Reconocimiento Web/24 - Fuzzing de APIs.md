---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Fuzzing
Descripción: "El API fuzzing es fuzzing adaptado a la estructura y los protocolos de las web APIs"
Fecha de actualización: 2026-06-02
Nota previa: "[[23 - APIs web e identificación de endpoints]]"
Nota siguiente: "[[25 - Cloud asset recon]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

<mark style="background: #ADCCFFA6;">El `API fuzzing` es fuzzing adaptado a la estructura y los protocolos de las web APIs</mark>. El principio es el mismo —enviar entradas inesperadas o inválidas— pero el objetivo no son directorios, sino endpoints, parámetros y formatos de datos. Cada test envía una petición ligeramente modificada: alterar valores de parámetros, cambiar cabeceras, reordenar parámetros o introducir tipos/formatos inesperados, buscando errores, *crashes* o comportamientos que delaten una vulnerabilidad.

# Tres tipos de API fuzzing

- **Parameter fuzzing**: probar valores en query params, cabeceras y cuerpo. Expone `SQLi`, `command injection`, `XSS` y *parameter tampering*.
- **Data format fuzzing**: manipular la estructura, contenido o codificación de los datos `JSON`/`XML`. <mark style="background: #FFB86CA6;">Revela errores de *parsing*, *buffer overflows* y mal manejo de caracteres especiales</mark> — en XML, la puerta a `XXE`.
- **Sequence fuzzing**: alterar el orden y el *timing* de peticiones encadenadas. Destapa `race conditions`, `IDOR`/`BOLA` y *bypasses* de autorización en la lógica y el estado de la API.

# Explorar la API

Muchas APIs publican documentación automática. Un endpoint `/docs` (Swagger UI) revela la especificación:

```text
GET    /                    Read Root
GET    /items/{item_id}     Read Item
DELETE /items/{item_id}     Delete Item
PUT    /items/{item_id}     Update Item
POST   /items/              Create Or Update Item
```

![Interfaz Swagger UI en /docs mostrando los endpoints documentados de la API](https://academy.hackthebox.com/storage/modules/280/apispec.png)

> [!important]+ Lo documentado no es todo
> La especificación lista los endpoints **públicos**, pero las APIs suelen tener endpoints <mark style="background: #FF5582A6;">ocultos o sin documentar</mark>: funciones internas, *security through obscurity* mal entendida, o features en desarrollo. Son los más interesantes, porque nadie pensó que alguien los encontraría — y rara vez tienen los mismos controles.

# Fuzzear endpoints ocultos

Con una `wordlist` fuzzeas rutas contra la API para descubrir lo no documentado. HTB usa un fuzzer a medida, pero `ffuf` hace lo mismo:

```shell-session
$ ffuf -u http://IP:PORT/FUZZ -w /usr/share/seclists/Discovery/Web-Content/api/api-endpoints.txt -mc all -fc 404
```

Salida típica:

```text
Found valid endpoints:
- /docs            (Swagger UI documentado)
- /cz...           (404 para casi todo, pero este responde → endpoint OCULTO)
Unusual status codes:
- 405: /items
```

El `/cz...` no aparecía en la documentación: un endpoint oculto. Validándolo con `curl` devuelve la flag.

> [!important]+ El truco del `405 Method Not Allowed`
> Fíjate en `405: /items`. <mark style="background: #FF5582A6;">Un `405` confirma que el endpoint **existe**, pero estás usando el método HTTP equivocado</mark>. La documentación decía `POST /items/`; un `GET /items` da `405`. Cuando veas un `405`, fuzzea también el **método** (`GET`/`POST`/`PUT`/`DELETE`/`PATCH`): a veces un método no previsto salta la autorización o expone funcionalidad. Con `ffuf` se fuzzea poniendo `FUZZ` en el propio método: `ffuf -u URL -X FUZZ -w methods.txt`.

# Del descubrimiento a la vulnerabilidad

Una vez tienes endpoints y parámetros, fuzzear sus **valores** expone las clases de bug propias de APIs, recogidas en el `OWASP API Security Top 10`:

- **`BOLA`** (Broken Object Level Authorization): manipular un `id` da acceso a objetos de otros usuarios — el [[23 - APIs web e identificación de endpoints|IDOR de las APIs]].
- **`BFLA`** (Broken Function Level Authorization): invocar funciones administrativas manipulando parámetros o el método.
- **`SSRF`**: inyectar URLs en parámetros para que el servidor haga peticiones a recursos internos.

> [!info]+ Herramientas de API fuzzing
> Más allá de `ffuf`: `kiterunner` usa `wordlists` construidas de especificaciones reales (rutas + método + content-type), mucho más certeras que una lista de rutas plana. `RESTler` (Microsoft) hace *stateful fuzzing* siguiendo las dependencias entre endpoints (sequence fuzzing automatizado). Para el trabajo manual de secuencias y reenvío, [[00 - Introducción a los proxies web|Burp/Caido]] siguen siendo el estándar. El tratamiento a fondo de estos ataques es el módulo dedicado de [[00 - Introducción a las API Attacks|API Attacks]].

---

Con esto cerramos el **recorrido clásico**: del **reconocimiento pasivo** ([[00 - Reconocimiento web|WHOIS, DNS, subdominios]]) al **descubrimiento activo por fuzzing** de directorios, parámetros, vhosts y APIs. <mark style="background: #8000E1A6;">El fuzzing no es un fin en sí mismo: es la fase que convierte un objetivo opaco en un mapa de endpoints y parámetros sobre el que aplicar las técnicas de explotación</mark> —inyección, autenticación, lógica— del resto del path.

Tres notas complementan el sub-tema con lo que el material clásico no cubre y la práctica actual exige: el [[25 - Cloud asset recon|recon de activos en la nube]], el [[26 - Escaneo dirigido con nuclei|escaneo dirigido con nuclei]] y la [[27 - Evasión en recon y fuzzing|evasión de WAF y rate-limits]] durante el descubrimiento.
