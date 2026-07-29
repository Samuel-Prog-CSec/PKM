---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Descripción: "SQLMap escupe muchísima información durante un escaneo"
Fecha de actualización: 2026-06-04
Nota previa: "[[00 - Introducción a SQLMap]]"
Nota siguiente: "[[02 - SQLMap sobre peticiones HTTP]]"
Area: "[[SQLMap.base|SQLMap]]"
---
---

SQLMap escupe muchísima información durante un escaneo. Leerla no es opcional: <mark style="background: #ADCCFFA6;">los mensajes de log guían el proceso y revelan exactamente qué tipo de inyección está explotando</mark>, dato imprescindible para el reporte y para reproducir el ataque a mano si hace falta. Conviene reconocer los mensajes por la fase del escaneo en que aparecen.

# Fase 1 — Validación del objetivo

- **`target URL content is stable`**: no hay diferencias notables entre respuestas idénticas. <mark style="background: #FFB8EBA6;">La estabilidad facilita detectar los cambios que provoca una inyección</mark>; si el contenido es inestable, SQLMap aplica filtros de "ruido" para comparar igualmente.
- **`parameter 'id' appears to be dynamic`**: cambiar el valor altera la respuesta, señal de que el parámetro llega a la base de datos. Un parámetro **estático** probablemente no se procesa y no es buen candidato.

# Fase 2 — Heurística

- **`heuristic (basic) test shows that parameter 'id' might be injectable (possible DBMS: 'MySQL')`**: enviando un valor deliberadamente inválido (`?id=1",)..).))'`) se provocó un error de base de datos. <mark style="background: #FFB86CA6;">No es prueba de SQLi, solo un indicio</mark> que la detección posterior confirmará, y una pista del motor.
- **`heuristic (XSS) test shows that parameter 'id' might be vulnerable to XSS`**: SQLMap hace de paso una comprobación rápida de XSS. Un extra útil en escaneos masivos, sobre todo si no hay SQLi.

# Fase 3 — Confirmación y ajuste

- **`it looks like the back-end DBMS is 'MySQL'. Do you want to skip test payloads specific for other DBMSes?`**: si el motor está claro, acotar a sus payloads acelera el escaneo.
- **`do you want to include all tests for 'MySQL' extending provided level (1) and risk (1)?`**: ofrece lanzar **todos** los payloads de ese DBMS más allá del [[03 - Tuning del ataque|level/risk]] indicados.
- **`reflective value(s) found and filtering out`**: parte del payload aparece reflejada en la respuesta (ruido); SQLMap lo filtra antes de comparar.
- **`parameter 'id' appears to be ... injectable (with --string="luther")`**: <mark style="background: #FF5582A6;">hallazgo fuerte</mark>. SQLMap detectó una cadena constante (`luther`) que distingue respuestas `TRUE` de `FALSE`, lo que hace la detección boolean fiable y descarta falsos positivos.

# Fase 4 — Detección por técnica

- **`time-based comparison requires a larger statistical model`**: SQLMap recoge tiempos de respuesta normales para distinguir estadísticamente un retardo deliberado, incluso en redes con latencia.
- **`automatically extending ranges for UNION query injection`** y **`'ORDER BY' technique appears to be usable`**: la detección UNION es cara en peticiones; si otra técnica ya apareció, SQLMap amplía el rango, y usa `ORDER BY` (sondeo incremental) para hallar el número de columnas rápido.

# Fase 5 — Resultado

- **`parameter 'id' is vulnerable. Do you want to keep testing the others?`**: <mark style="background: #FFB86CA6;">el mensaje clave: el parámetro es explotable</mark>. Normalmente basta un punto de inyección; en una auditoría exhaustiva conviene seguir para reportarlos todos.
- **`sqlmap identified the following injection point(s)...`**: lista cada punto con tipo, título y payload. <mark style="background: #8000E1A6;">SQLMap solo lista lo que ha probado explotable</mark>, no meras sospechas.

# Session files: la caché que ahorra tiempo

- **`fetched data logged to text files under '~/.local/share/sqlmap/output/<host>'`** (ruta por defecto desde 2020; en instalaciones legacy era `~/.sqlmap/output/`): aquí SQLMap guarda logs, sesión y datos.

> [!important]+
> Esos *session files* son una caché: <mark style="background: #FF5582A6;">en ejecuciones posteriores contra el mismo objetivo, SQLMap reutiliza lo aprendido y reduce drásticamente las peticiones</mark>. Si cambias algo en el objetivo o quieres re-detectar desde cero, usa `--flush-session`. Para depurar lo que envía realmente, `-v 3` (o más) muestra los payloads completos —indispensable al ajustar evasión de WAF—.

Con la salida bajo control, el caso real rara vez es una URL `GET` simple: lo habitual es replicar una petición HTTP completa capturada con el proxy, [[02 - SQLMap sobre peticiones HTTP]].
