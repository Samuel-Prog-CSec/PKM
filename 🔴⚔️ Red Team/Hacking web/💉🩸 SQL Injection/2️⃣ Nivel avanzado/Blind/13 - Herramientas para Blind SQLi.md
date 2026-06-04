---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa: "[[12 - MSSQL lectura de archivos]]"
Nota siguiente: "[[14 - Defensa contra Blind SQL Injection]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

Escribir el [[03 - Diseño del oráculo booleano|oráculo]] y los [[05 - Optimización de la extracción|algoritmos de extracción]] a mano es imprescindible para entender la blind SQLi y para los casos raros, pero en el día a día se automatiza. Las herramientas implementan exactamente lo que hemos construido —oráculo, bisección, multithreading— pero gestionando reintentos, sesión y evasión.

# SQLMap contra blind

[[SQLMap.base|SQLMap]] detecta y explota blind SQLi (boolean y time) en MSSQL igual que en MySQL. El flujo es el de siempre, apuntando al endpoint vulnerable:

```shell-session
$ sqlmap -u "http://host/api/check-username.php?u=maria" --batch
$ sqlmap -u "http://host/api/check-username.php?u=maria" --batch --dbs
$ sqlmap -u "..." -D amdonuts --tables
$ sqlmap -u "..." -D amdonuts -T users --dump
```

<mark style="background: #ADCCFFA6;">SQLMap detecta automáticamente que es boolean-based y elige el algoritmo de extracción</mark>. El detalle completo de opciones está en el módulo dedicado: [[00 - Introducción a SQLMap|SQLMap]]. Lo relevante para blind:

- <mark style="background: #FFB8EBA6;">`--threads` es clave</mark>: la blind es lenta y por defecto SQLMap va en un solo hilo. Subirlo acelera mucho en boolean (en time-based, con cuidado, como vimos en el [[07 - Diseño del oráculo temporal|oráculo temporal]]).
- `--technique=B` o `T` fuerza solo boolean o solo time si la detección automática falla.
- `--no-cast`/`--hex` resuelven problemas de extracción de datos con caracteres especiales.
- Para inyección en cabeceras (como el `User-Agent` del ejemplo time-based) hace falta `--level=3`.

> [!warning]+
> SQLMap avisa de algo importante en time-based: <mark style="background: #FF5582A6;">"no estreses la conexión durante payloads time-based"</mark>. Demasiada concurrencia o una red inestable corrompen las mediciones de tiempo y, por tanto, los datos extraídos. Ajusta `--threads` y `--time-sec` al objetivo.

# `ghauri`: la alternativa

[`ghauri`](https://github.com/r0oth3x49/ghauri) está especializado en blind boolean/time, con lógica de detección y extracción propia que a menudo es **más rápida y evade mejor** que SQLMap en estos casos. Cuando SQLMap se atasca con una blind (falsos positivos, WAF, contexto raro), `ghauri` suele ser el siguiente intento antes de volver al script manual.

> [!info]+
> Para los ataques MSSQL-específicos ([[10 - MSSQL ejecución de comandos con xp_cmdshell|xp_cmdshell]], [[11 - MSSQL robo de hashes NetNTLM|NetNTLM]]), una vez confirmada la inyección con la herramienta suele ser más limpio cambiar a `--sql-shell` de SQLMap o a [[00 - Introducción a MSSQL|impacket-mssqlclient]] para ejecutar las consultas manualmente, en lugar de depender de la automatización completa.

> [!important]+
> La regla que recorre todo el módulo: <mark style="background: #8000E1A6;">la herramienta es el acelerador, no el sustituto del conocimiento</mark>. SQLMap falla ante endpoints de API con cuerpos complejos, oráculos no estándar (una señal que no sea contenido ni tiempo) o evasión a medida. Saber construir el oráculo a mano es lo que permite explotar cuando la herramienta no puede.

Para cerrar, la perspectiva defensiva: cómo se previene todo lo anterior, con énfasis en las particularidades de MSSQL: [[14 - Defensa contra Blind SQL Injection]].
