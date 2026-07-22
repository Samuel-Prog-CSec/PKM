---
tags:
  - Web/Red-Team
  - XPath
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[04 - Exfiltración avanzada (schema walking)]]"
Nota siguiente: "[[06 - Evasión de filtros y WAF en XPath]]"
Area: "[[XPath Injection.base|XPath Injection]]"
---
---

Cuando la aplicación **no refleja** el resultado de la consulta —solo responde distinto según devuelva algo o nada— estamos en **blind XPath injection**. Se extrae el documento bit a bit usando un oráculo booleano, exactamente como en la [[01 - Introducción a Blind SQL Injection|blind SQLi]]. Y si ni siquiera hay diferencia visible en la respuesta, queda el tiempo.

# El oráculo booleano

El patrón: una acción responde distinto según la consulta tenga éxito. En un tablón de mensajes, un usuario válido devuelve `Message sent!` y uno inválido `User not found`. <mark style="background: #ADCCFFA6;">Esa diferencia observable es el oráculo</mark>. Se confirma la inyección forzando `true`:

```xpath
invalid' or '1'='1   →   /users/user[username='invalid' or '1'='1']
```

El usuario no existe, pero el `or '1'='1'` hace que la consulta devuelva datos → `Message sent!` → vulnerable.

# Exfiltrar el esquema (no conocemos los nombres de nodo)

A diferencia del caso in-band, en ciego no vemos el XML: primero reconstruimos su **estructura** con funciones XPath.

```xpath
# Longitud del nombre del nodo raíz (incrementar N hasta que dé true)
invalid' or string-length(name(/*[1]))=N and '1'='1

# Nombre carácter a carácter (iterar el char)
invalid' or substring(name(/*[1]),1,1)='u' and '1'='1     → root = "users"

# Nº de hijos de un nodo
invalid' or count(/users/*)=N and '1'='1
```

Direccionando cada hijo (`/users/*[1]`, `/users/*[2]`…) y repitiendo, se reconstruye todo el árbol (`users` → `user` → `username`, `password`, `desc`).

> [!important]+ Búsqueda binaria, no fuerza bruta lineal
> Comparar con `=` obliga a probar cada valor uno a uno. <mark style="background: #8000E1A6;">Usar `<`, `<=`, `>` convierte la extracción en búsqueda binaria</mark> (`string-length(...)>10`, `substring(...)>'m'`), reduciendo de ~N a ~log₂(N) peticiones por carácter. Es la misma optimización que en la [[05 - Optimización de la extracción|blind SQLi]].

# Exfiltrar los datos

Conocido el esquema, se apunta al dato concreto:

```xpath
# Longitud del valor
invalid' or string-length(/users/user[1]/username)=N and '1'='1

# Valor carácter a carácter
invalid' or substring(/users/user[1]/username,1,1)='a' and '1'='1     → "admin"
```

# Basada en tiempo (cuando no hay oráculo booleano)

Si la respuesta es **idéntica** devuelva o no datos, no hay oráculo... salvo el tiempo. <mark style="background: #FFB86CA6;">XPath no tiene función `sleep()`</mark>, así que se fuerza cómputo pesado: `count((//.)[count((//.))])` obliga al motor a iterar el documento de forma cuadrática/exponencial. Se encadena tras la condición a probar con `and`:

```xpath
invalid' or substring(/users/user[1]/username,1,1)='a' and count((//.)[count((//.))]) and '1'='1
```

Si `substring(...)='a'` es **verdadero**, el motor evalúa el `count` pesado y la respuesta tarda (p. ej. `477ms`); si es falso, corta en el `and` y responde al instante (`1ms`). <mark style="background: #FF5582A6;">El tiempo es el oráculo</mark>.

> [!warning]+ El time-based XPath es igual de frágil que en SQLi
> La latencia de red, el *rate limiting* y un WAF distorsionan las medidas. Repite cada medición y usa un umbral holgado (varios cientos de ms). En documentos XML pequeños el retardo puede ser insuficiente; funciona mejor cuanto mayor es el XML. Mismas cautelas que en la [[06 - Identificar SQLi basada en tiempo|SQLi temporal]].

> [!important]+ Automatiza siempre
> Iterar longitudes y caracteres a mano es inviable en un objetivo real. Un script (bucle sobre posición + charset, parseando la respuesta) es obligatorio; y [`XCat`](https://github.com/orf/xcat) hace todo esto —esquema, datos, e incluso *out-of-band* vía `doc()`— automáticamente → [[07 - Arsenal de herramientas XPath]].

Con la explotación cubierta, queda lo que de verdad diferencia a un profesional en 2026: explotar **a pesar de los filtros** → [[06 - Evasión de filtros y WAF en XPath]].
