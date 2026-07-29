---
tags:
  - Web/Red-Team
  - XPath
  - Pentesting/Explotacion
Descripción: "Más allá del bypass de login, la XPath injection permite volcar el documento XML entero, igual que una SQLi UNION-based extrae tablas completas"
Fecha de actualización: 2026-07-16
Nota previa: "[[02 - Bypass de autenticación con XPath]]"
Nota siguiente: "[[04 - Exfiltración avanzada (schema walking)]]"
Area: "[[XPath Injection.base|XPath Injection]]"
---
---

Más allá del bypass de login, la XPath injection permite **volcar el documento XML entero**, igual que una [[05 - Inyección UNION|SQLi UNION-based]] extrae tablas completas. La técnica base explota dos puntos a la vez: el predicado de búsqueda y —la clave— el **campo de salida** de la consulta.

# Escenario: un buscador sobre XML

Un índice de calles envía dos parámetros GET: `q` con el término de búsqueda y `f` con el campo a mostrar (`fullstreetname` o `streetname`). La aplicación devuelve las calles que contienen la subcadena. De su comportamiento deducimos la consulta:

```xpath
/a/b/c[contains(d/text(), 'BAR')]/fullstreetname
```

> [!info]+ La profundidad del esquema es desconocida
> `/a/b/c` es una suposición: en caja negra no conocemos la ruta real ni la profundidad del XML. Aquí no importa porque vamos a volcar todo de golpe; cuando la salida está restringida, sí hay que descubrir el esquema paso a paso → [[04 - Exfiltración avanzada (schema walking)]].

# Confirmar la inyección

La entrada `q` cae **dentro** de `contains(d/text(), 'INPUT')`, así que para romper el contexto cerramos el literal y el paréntesis de la función con `')` y reabrimos con `(`:

```xpath
q = ') or ('1'='1
→  /a/b/c[contains(d/text(), '') or ('1'='1')]
```

<mark style="background: #ADCCFFA6;">El predicado pasa a ser universalmente `true`</mark> y la aplicación devuelve todas las calles: inyección confirmada.

# Volcar el documento con la unión `|`

El detalle que lo hace potente: el parámetro de **salida** `f` también se concatena en la ruta y es inyectable. Anexamos una segunda consulta con el operador unión `|` —el `UNION SELECT` de XPath— que selecciona todos los nodos texto del documento:

```http
GET /index.php?q=')+and+('1'='2&f=fullstreetname+|+//text() HTTP/1.1
Host: xpath-exfil.htb
```

La consulta resultante:

```xpath
/a/b/c[contains(d/text(), '') and ('1'='2')]/fullstreetname | //text()
```

La primera mitad no devuelve nada (`'1'='2'` es falso, anula el resultado legítimo), pero <mark style="background: #FFB86CA6;">`| //text()` devuelve **todos los nodos texto** del documento</mark> — exfiltración completa en una sola petición.

> [!success]+
> Cuando la respuesta pasa de listar calles a escupir el contenido íntegro del XML (usuarios, hashes, config…), la unión ha funcionado. `//text()` es el volcado total; si quieres solo una rama, apunta la ruta (`//users//text()`).

# Alternativa: trepar al nodo raíz

Si solo controlamos `q` y no el campo de salida, forzamos la ruta a subir hasta la raíz con `..` y volcamos desde ahí:

```xpath
/a/b/c[contains(d/text(), '') or ('1'='1')]/../../..//text()
```

> [!important]+
> Dos ideas portables a cualquier XPath injection: <mark style="background: #8000E1A6;">el operador `|` injerta una segunda consulta arbitraria</mark>, y `//text()` (o `//*`) vuelca todo. La dificultad real aparece cuando la aplicación **no refleja** el resultado —sin campo de salida inyectable o con la salida filtrada—: ahí toca reconstruir el documento nodo a nodo. Esa es la [[04 - Exfiltración avanzada (schema walking)|exfiltración avanzada]], y su versión sin salida visible es la [[05 - XPath ciega y basada en tiempo|explotación ciega]].
