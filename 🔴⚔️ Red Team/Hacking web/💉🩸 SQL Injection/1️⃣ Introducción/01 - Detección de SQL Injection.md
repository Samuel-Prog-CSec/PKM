---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Enumeracion
Fecha de actualización: 2026-06-04
Nota previa: "[[00 - Introducción a SQL Injection]]"
Nota siguiente: "[[02 - Subvertir la lógica de consulta]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

En 2026 la SQL injection es escasa pero no extinta: el reto profesional ya no es explotarla en un laboratorio limpio, sino **detectarla** donde sobrevive entre defensas modernas. Esta nota sistematiza el descubrimiento —la parte que el material clásico da por supuesta— porque una detección rigurosa es lo que separa encontrar el bug de pasarlo por alto. HTB lo trata de pasada dentro de [[02 - Subvertir la lógica de consulta|subvertir la lógica]]; aquí lo elevamos a metodología.

# Identificar los puntos de inyección

<mark style="background: #ADCCFFA6;">Cualquier dato del cliente que termine en una consulta SQL es un punto de inyección potencial</mark>, no solo los campos de formulario. La superficie real incluye:

- Parámetros **GET** y **POST** (los clásicos).
- Claves y valores en cuerpos **JSON** y **XML** de APIs.
- **Cabeceras HTTP** reflejadas en consultas de logging o analítica: `User-Agent`, `Referer`, `X-Forwarded-For`.
- **Cookies** usadas en consultas de sesión o preferencias.
- Parámetros que alimentan `ORDER BY`, `LIMIT` o nombres de columna —los que [[Consultas y operadores SQL|sobreviven a prepared statements]].

> [!important]+
> No basta con probar el parámetro obvio. <mark style="background: #FF5582A6;">Muchos SQLi modernos viven en parámetros secundarios</mark> (un `sort=`, un `filter=`, un campo JSON anidado) que el desarrollador parametrizó mal porque "no parecían peligrosos". Mapea **todos** los puntos de entrada con un proxy ([[Interceptación solicitudes|Burp/caido]]) antes de fuzzear; el [[19 - Fuzzing de parámetros y valores|fuzzing de parámetros]] ayuda a descubrir los que la aplicación acepta pero no documenta.

# El contexto de inyección

Antes de explotar hay que saber **cómo** se inserta la entrada en la consulta. El contexto determina qué carácter rompe la query:

| Contexto | Consulta típica | Cómo romperlo |
| -------- | --------------- | ------------- |
| Numérico | `... WHERE id = 1` | Sin comillas: `1 AND 1=1` |
| String (comilla simple) | `... WHERE user = '$x'` | `'` |
| String (comilla doble) | `... WHERE user = "$x"` | `"` |
| Dentro de `LIKE` | `... LIKE '%$x%'` | `%' ` |
| Entre paréntesis | `... WHERE (id = $x)` | `)` o `')` |
| Identificador (`ORDER BY`) | `... ORDER BY $x` | número de columna; no necesita comillas |

# Señales de que un parámetro es vulnerable

- <mark style="background: #FFB86CA6;">Un error de sintaxis SQL o un error 500</mark> al inyectar `'` — la señal más directa.
- **Cambio de comportamiento** entre una condición verdadera y una falsa (aunque no haya error).
- Diferencias sutiles: número de filas devueltas, longitud de la respuesta, presencia/ausencia de un elemento.
- Un retardo en la respuesta cuando se inyecta una función de espera.

# Técnicas de detección, de más a menos evidente

## Basada en error

El primer test: enviar una comilla simple (`'`) y una doble (`"`). Si la respuesta cambia, da un error de base de datos o un 500, el parámetro es candidato. Confirmar enviando dos comillas (`''`), que deberían "reparar" la sintaxis y normalizar la respuesta.

## Diferencial booleano

Cuando no hay error visible, se compara el resultado de una condición verdadera frente a una falsa. Si difieren, hay inyección:

```sql
' AND '1'='1      -- verdadero: respuesta normal
' AND '1'='2      -- falso: respuesta distinta (sin resultados)
```

Para contexto numérico: `1 AND 1=1` vs `1 AND 1=2`. Una variante robusta usa operaciones que un WAF no reconoce como payload: `id=2-1` debería devolver lo mismo que `id=1`.

## Basada en tiempo

Si no hay reflexión ni error (caso ciego), se fuerza un retardo condicional. La sintaxis depende del motor —de ahí la importancia del `fingerprinting`:

```sql
' OR SLEEP(5)-- -            -- MySQL
'; WAITFOR DELAY '0:0:5'--   -- MSSQL
'; SELECT pg_sleep(5)--      -- PostgreSQL
```

> [!warning]+
> La detección por tiempo es la más fiable contra defensas que ocultan errores, pero también la más frágil: la latencia de red y el *rate limiting* generan falsos positivos/negativos. Repite la medición con varios valores de `SLEEP` (5 s, 0 s, 10 s) y comprueba que el retardo escala de forma proporcional antes de afirmar nada.

## Out-of-band (OOB)

Cuando ni la salida ni el tiempo son fiables, se fuerza al servidor a iniciar una conexión externa (DNS/HTTP) a un dominio controlado (Burp Collaborator, `interactsh`). Recibir esa petición confirma la ejecución. Es la última carta, pero la única que funciona en inyecciones totalmente ciegas tras un WAF.

# Fingerprinting del DBMS

Confirmada la inyección, identificar el motor decide toda la explotación posterior. Pistas: la sintaxis de comentario que funciona, las funciones de tiempo aceptadas, y consultas directas de versión:

```sql
SELECT VERSION();        -- MySQL / PostgreSQL
SELECT @@version;        -- MSSQL / MySQL
```

# Automatización: cuándo y con qué

- **[[SQLMap.base|SQLMap]]** sigue siendo el estándar. En reconocimiento, `--batch --level=1 --risk=1` para un primer barrido; subir `--level`/`--risk` solo si se sospecha y el primer paso no detecta nada.
- **`ghauri`** es una alternativa más rápida y con mejor evasión por defecto en blind boolean/time, útil cuando SQLMap se atasca.
- **`nuclei`** con plantillas de SQLi sirve para barridos masivos en bug bounty (detección, no explotación).
- **Burp Scanner / caido** detectan SQLi durante el *crawling* autenticado.

> [!important]+
> <mark style="background: #8000E1A6;">La detección manual sigue siendo imprescindible</mark>: las herramientas automáticas fallan ante contextos raros (JSON anidado, parámetros que requieren encoding doble, inyección de segundo orden) y generan ruido que dispara WAFs y *rate limits*. Detecta a mano, confirma el contexto, y solo entonces lanza la herramienta afinada al punto exacto.

Con un punto de inyección confirmado y el contexto claro, el primer uso práctico es alterar la consulta a nuestro favor: [[02 - Subvertir la lógica de consulta]].
