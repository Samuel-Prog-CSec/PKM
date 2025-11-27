---
tags:
Fecha de actualización: 2025-10-10
Nota previa: "[[Subdominios y host virtual]]"
Nota siguiente:
Area: "[[Fuzzing web]]"
---
---

# Gobuster
[[Herramientas#Gobuster|Gobuster]] ofrece varias opciones de filtrado según el módulo que se esté ejecutando, para ayudar a centrarse en respuestas específicas y agilizar el análisis. Hay una pequeña salvedad: las opciones `-s` y `-b` <mark style="background: #FFB86CA6;">solo están disponibles en el modo de fuzzing `dir`.</mark>

| Bandera            | Descripción                                                                                          | Ejemplo de escenario                                                           |
| ------------------ | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `-s`(incluir)      | **Incluir únicamente respuestas con los códigos de estado especificados** (separados por comas).     | Si buscamos redirecciones, filtramos los códigos `301,302,307`                 |
| `-b`(excluir)      | **Excluir las respuestas con los códigos de estado especificados** (separados por comas).            | El servidor devuelve muchos errores 404. Excluirlos con `-b 404`               |
| `--exclude-length` | **Excluir respuestas con longitudes de contenido específicas** (separadas por comas, admite rangos). | No interesan las respuestas de 0 o 404 bytes, así que `--exclude-length 0,404` |

```shell-session
# Find directories with status codes 200 or 301, but exclude responses with a size of 0 (empty responses)

$ gobuster dir -u http://example.com/ -w wordlist.txt -s 200,301 --exclude-length 0
```

---

# FFUF
[[Herramientas#FFUF|FFUF]] ofrece un sistema de filtrado altamente personalizable, que permite un control preciso sobre la salida mostrada. Esto permite examinar de manera eficiente cantidades potencialmente grandes de datos y centrarse en los hallazgos más relevantes. <mark style="background: #FFB8EBA6;">Las opciones de filtrado se clasifican en varios tipos</mark>, cada uno de los cuales cumple un propósito específico al refinar sus resultados.

| Bandera                                           | Descripción                                                                                                                                                                                                                                                                                                                                                | Ejemplo de escenario                                                                                                                                              |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-mc`(código de coincidencia)                     | Incluya únicamente respuestas que coincidan con los códigos de estado especificados. Puede proporcionar un solo código, varios códigos separados por comas o rangos de códigos separados por guiones (por ejemplo, `200,204,301`, `400-499`). El comportamiento predeterminado es hacer coincidir los códigos 200-299, 301, 302, 307, 401, 403, 405 y 500. | Después del fuzzing, notas muchas redirecciones 302 (encontradas), pero lo que más te interesa son las respuestas 200 (aceptables). Uso `-mc 200` para aislarlos. |
| `-fc`(código de filtro)                           | Excluya las respuestas que coincidan con los códigos de estado especificados, utilizando el mismo formato que `-mc`. Esto es útil para eliminar códigos de error comunes como 404 No encontrado.                                                                                                                                                           | Un escaneo devuelve muchos errores 404. Uso `-fc 404` para eliminarlos de la salida.                                                                              |
| `-fs`(tamaño del filtro)                          | Excluya respuestas con un tamaño específico o un rango de tamaños. Puede especificar tamaños o rangos individuales utilizando guiones (por ejemplo, `-fs 0` para respuestas vacías, `-fs 100-200` para respuestas entre 100 y 200 bytes).                                                                                                                  | Sospechas que las respuestas interesantes serán mayores a 1 KB. Uso `-fs 0-1023` para filtrar respuestas más pequeñas.                                            |
| `-ms`(tamaño de coincidencia)                     | Incluya solo respuestas que coincidan con un tamaño específico o un rango de tamaños, utilizando el mismo formato que `-fs`.                                                                                                                                                                                                                               | Estás buscando un archivo de respaldo que sepas que tiene exactamente 3456 bytes de tamaño. Uso `-ms 3456` para encontrarlo.                                      |
| `-fw`(filtrar el número de palabras en respuesta) | Excluya las respuestas que contengan la cantidad especificada de palabras en la respuesta.                                                                                                                                                                                                                                                                 | Estás filtrando una cantidad específica de palabras de las respuestas. Uso `-fw 219` para filtrar las respuestas que contienen esa cantidad de palabras.          |
| `-mw`(coincide con el recuento de palabras)       | Incluya únicamente respuestas que tengan la cantidad especificada de palabras en el cuerpo de la respuesta.                                                                                                                                                                                                                                                | Estás buscando mensajes de error breves y específicos. Uso `-mw 5-10` para filtrar respuestas con 5 a 10 palabras.                                                |
| `-fl`(línea de filtro)                            | Excluya respuestas con un número específico de líneas o un rango de líneas. Por ejemplo, `-fl 5` filtrará las respuestas con 5 líneas.                                                                                                                                                                                                                     | Notas un patrón de mensajes de error de 10 líneas. Uso `-fl 10` para filtrarlos.                                                                                  |
| `-ml`(recuento de líneas coincidentes)            | Incluya solo respuestas que tengan la cantidad especificada de líneas en el cuerpo de la respuesta.                                                                                                                                                                                                                                                        | Estás buscando respuestas con un formato específico, como 20 líneas. Uso `-ml 20` para aislarlos.                                                                 |
| `-mt`(hora del partido)                           | Incluya solo respuestas que cumplan con una condición específica de tiempo hasta el primer byte (TTFB). Esto es útil para identificar respuestas que son inusualmente lentas o rápidas, lo que potencialmente indica un comportamiento interesante.                                                                                                        | La aplicación responde lentamente al procesar ciertas entradas. Uso `-mt >500` para encontrar respuestas con un TTFB superior a 500 milisegundos.                 |

Puedes combinar varios filtros. Por ejemplo:
```shell-session
# Find directories with status code 200, based on the amount of words, and a response size greater than 500 bytes
$ ffuf -u http://example.com/FUZZ -w wordlist.txt -mc 200 -fw 427 -ms >500

# Filter out responses with status codes 404, 401, and 302
$ ffuf -u http://example.com/FUZZ -w wordlist.txt -fc 404,401,302

# Find backup files with the .bak extension and size between 10KB and 100KB
$ ffuf -u http://example.com/FUZZ.bak -w wordlist.txt -fs 0-10239 -ms 10240-102400

# Discover endpoints that take longer than 500ms to respond
$ ffuf -u http://example.com/FUZZ -w wordlist.txt -mt >500
```

---

# wenum
[[Herramientas#wfuzz/wenum|wenum]] ofrece un <mark style="background: #ADCCFFA6;">sistema de filtrado robusto para ayudar a gestionar y refinar la gran cantidad de datos</mark> generados durante el fuzzing. Puede filtrar según códigos de estado, tamaño de respuesta/número de caracteres, número de palabras, número de líneas e incluso expresiones regulares.

|Bandera|Descripción|Ejemplo de escenario|
|---|---|---|
|`--hc`(ocultar código)|Excluya las respuestas que coincidan con los códigos de estado especificados.|Después del fuzzing, el servidor devolvió muchos 400 errores de solicitud incorrecta. Uso `--hc 400` para ocultarlos y centrarse en otras respuestas.|
|`--sc`(mostrar código)|Incluya únicamente respuestas que coincidan con los códigos de estado especificados.|Sólo te interesan las solicitudes exitosas (200 OK). Uso `--sc 200` para filtrar los resultados en consecuencia.|
|`--hl`(ocultar longitud)|Excluya respuestas con la longitud de contenido especificada (en líneas).|El servidor devuelve mensajes de error detallados con muchas líneas. Uso `--hl` con un alto valor para ocultarlos y centrarse en respuestas más cortas.|
|`--sl`(mostrar longitud)|Incluya únicamente respuestas con la longitud de contenido especificada (en líneas).|Sospecha que una respuesta específica con un recuento de líneas conocido está relacionada con una vulnerabilidad. Uso `--sl` para localizarlo.|
|`--hw`(ocultar palabra)|Excluya respuestas con el número especificado de palabras.|El servidor incluye frases comunes en muchas respuestas. Uso `--hw` para filtrar las respuestas con esos recuentos de palabras.|
|`--sw`(mostrar palabra)|Incluya únicamente respuestas con el número especificado de palabras.|Estás buscando mensajes de error cortos. Uso `--sw` con un valor bajo para encontrarlos.|
|`--hs`(ocultar tamaño)|Excluya respuestas con el tamaño de respuesta especificado (en bytes o caracteres).|El servidor envía archivos grandes para solicitudes válidas. Uso `--hs` para filtrar estas respuestas grandes y centrarse en las más pequeñas.|
|`--ss`(mostrar tamaño)|Incluya únicamente respuestas con el tamaño de respuesta especificado (en bytes o caracteres).|Estás buscando un tamaño de archivo específico. Uso `--ss` para encontrarlo.|
|`--hr`(ocultar expresión regular)|Excluir respuestas cuyo cuerpo coincida con la expresión regular especificada.|Filtre las respuestas que contengan el mensaje "Error interno del servidor". Uso `--hr "Internal Server Error"`.|
|`--sr`(mostrar expresión regular)|Incluya únicamente respuestas cuyo cuerpo coincida con la expresión regular especificada.|Filtrar las respuestas que contienen la cadena "admin" usando `--sr "admin"`.|
|`--filter`/`--hard-filter`|Filtro de propósito general para mostrar/ocultar respuestas o evitar su posprocesamiento utilizando una expresión regular.|`--filter "Login"` mostrará solo respuestas que contengan "Iniciar sesión", mientras `--hard-filter "Login"` los ocultará e impedirá que cualquier complemento los procese.|

Puedes combinar varios filtros. Por ejemplo:
```shell-session
# Show only successful requests and redirects:
$ wenum -w wordlist.txt --sc 200,301,302 -u https://example.com/FUZZ

# Hide responses with common error codes:
$ wenu -w wordlist.txt --hc 404,400,500 -u https://example.com/FUZZ

# Show only short error messages (responses with 5-10 words):
$ wenum -w wordlist.txt --sw 5-10 -u https://example.com/FUZZ

$ wenum -w wordlist.txt --hs 10000 -u https://example.com/FUZZ

# Filter for responses containing specific information:
$ wenum -w wordlist.txt --sr "admin\|password" -u https://example.com/FUZZ
```

---

# Feroxbuster
[[Herramientas#FeroxBuster|Feroxbuster]] está diseñado para ser <mark style="background: #ADCCFFA6;">potente y flexible</mark>, lo que le permite <mark style="background: #FFB8EBA6;">ajustar los resultados que recibe durante un escaneo</mark>. Ofrece una variedad de filtros que operan tanto a nivel de solicitud como de respuesta.

|Bandera|Descripción|Ejemplo de escenario|
|---|---|---|
|`--dont-scan`(Solicitud)|Excluir URL o patrones específicos del escaneo (incluso si se encuentran en enlaces durante la recursión).|Ya sabes el `/uploads` El directorio contiene solo imágenes, por lo que puedes excluirlo usando `--dont-scan /uploads`.|
|`-S`, `--filter-size`|Excluir respuestas según su tamaño (en bytes). Puede especificar tamaños individuales o rangos separados por comas.|Has notado muchas páginas de error de 1KB. Uso `-S 1024` para excluirlos.|
|`-X`, `--filter-regex`|Excluya respuestas cuyo cuerpo o encabezados coincidan con la expresión regular especificada.|Filtre páginas con un mensaje de error específico usando `-X "Access Denied"`.|
|`-W`, `--filter-words`|Excluya respuestas con un recuento de palabras específico o un rango de recuentos de palabras.|Elimine las respuestas con muy pocas palabras (por ejemplo, mensajes de error) usando `-W 0-10`.|
|`-N`, `--filter-lines`|Excluya respuestas con un recuento de líneas específico o un rango de recuentos de líneas.|Filtre páginas largas y detalladas con `-N 50-`.|
|`-C`, `--filter-status`|Excluir respuestas basadas en códigos de estado HTTP específicos. Esto funciona como una lista de negación.|Suprima códigos de error comunes como 404 y 500 usando `-C 404,500`.|
|`--filter-similar-to`|Excluya respuestas que sean similares a una página web determinada.|Elimine páginas duplicadas o casi duplicadas según una página de referencia usando `--filter-similar-to error.html`.|
|`-s`, `--status-codes`|Incluya únicamente respuestas con los códigos de estado especificados. Esto funciona como una lista de permisos (predeterminado: todos).|Concéntrese en las respuestas exitosas utilizando `-s 200,204,301,302`.|

Puedes combinar varios filtros. Por ejemplo:
```shell-session
# Find directories with status code 200, excluding responses larger than 10KB or containing the word "error"

$ feroxbuster --url http://example.com -w wordlist.txt -s 200 -S 10240 -X "error" 
```