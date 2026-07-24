---
tags:
  - Web/Red-Team
  - NoSQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[05 - Extracción de datos ciega y automatización]]"
Nota siguiente: "[[07 - Evasión de filtros y WAF en NoSQL]]"
Area: "[[NoSQL Injection.base|NoSQL Injection]]"
---
---

La **Server-Side JavaScript Injection (SSJI)** es un tipo de inyección **único de NoSQL**: cuando el servidor evalúa JavaScript controlado por el atacante mediante el operador `$where`. Escala de "leer datos" a "ejecutar lógica JS arbitraria sobre cada documento".

# El operador `$where` = JavaScript en el servidor

`$where` recibe una expresión JavaScript que MongoDB evalúa por cada documento. Si la entrada del usuario se concatena en esa cadena, hay inyección de código:

```javascript
db.users.find({$where: 'this.username == "' + req.body['username'] + '" && this.password == "' + req.body['password'] + '"'})
```

# Bypass de autenticación con JavaScript

Con `$where: 'this.username == "<user>" && this.password == "<pass>"'`, se inyecta en `username` una expresión que hace toda la condición verdadera:

```javascript
username = " || true || ""=="
// → this.username == "" || true || ""=="" && this.password == "..."
```

<mark style="background: #ADCCFFA6;">Es JavaScript puro: `true ||` cortocircuita y la expresión entera es `true`</mark>, así que la consulta casa el primer documento y autenticamos. Se puede verificar en la consola del navegador antes de enviarlo.

# Extracción ciega con `match()`

Como se ejecuta JS, disponemos de los métodos de string. `this.username.match()` reproduce el `$regex` anclado de la [[05 - Extracción de datos ciega y automatización|extracción ciega]]:

```javascript
" || (this.username.match('^.*')) || ""=="     // confirma que hay username
" || (this.username.match('^H.*')) || ""=="    // ¿empieza por H? → sí
```

Carácter a carácter se vuelca el `username` (u otro campo).

# Automatización

El mismo bucle-oráculo de la nota anterior, cambiando solo el `payload` al formato SSJI:

```python
def payload(prefix):
    # se envía en el campo username
    return '" || (this.username.match("^' + prefix + '")) || ""=="'

# en oracle(): data = {"username": payload(prefix), "password": "x"}
# y el resto del bucle posición × charset es idéntico
```

> [!success]+ Optimización con búsqueda binaria
> Como `$where` ejecuta JS, el oráculo puede comparar valores ASCII con `charCodeAt()`: `this.username.startsWith("HTB{") && this.username.charCodeAt(i) > mid`. Aplicando **búsqueda binaria** sobre el charset imprimible (32-127), la extracción de un `username` baja de <mark style="background: #FFB86CA6;">~1678 peticiones (2m40s) a solo 286 (24s)</mark> — la misma optimización O(log₂N) que conviene aplicar también a la [[05 - Extracción de datos ciega y automatización|blind extraction con `$regex`]], imprescindible al exfiltrar datos grandes.

> [!warning]+ Alcance real de la SSJI en 2026 (no es RCE)
> Un error común es esperar RCE de un `$where`. <mark style="background: #FFB86CA6;">El JavaScript de `$where` corre en un *sandbox*</mark>: sin `require`, sin `fs`, sin APIs de Node — solo puede leer los campos del documento (`this.*`) y usar JS básico. Da bypass de lógica y extracción de datos, **no** ejecución de comandos. Además, <mark style="background: #FF5582A6;">el JS server-side está desaconsejado y a menudo deshabilitado</mark> en despliegues modernos (`security.javascriptEnabled`), y `$where` es lento. Sigue vivo en apps legacy y en `mapReduce`/`$accumulator`/`$function` de agregación, que también evalúan JS.

> [!info]+ Relación con otras inyecciones de código
> La SSJI es a MongoDB lo que la [[00 - Motores de plantillas e introducción a SSTI|SSTI]] es a los motores de plantillas: entrada del usuario evaluada como código en el servidor. La diferencia es el sandbox — la SSTI suele escalar a RCE, la SSJI de `$where` no.

Con la explotación cubierta, lo que marca la diferencia ante defensas: la [[07 - Evasión de filtros y WAF en NoSQL|evasión de filtros]].
