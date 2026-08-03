---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Enumeracion
Descripción: "La tercera vía para confirmar qué consultas ejecuta la aplicación —y para depurar payloads mientras se desarrolla el exploit— es leer los logs del propio motor"
Fecha de actualización: 2026-06-04
Nota previa: "[[03 - Live-debugging de aplicaciones Java]]"
Nota siguiente: "[[05 - Bypass de caracteres comunes]]"
Area: "[[SQLi Avanzado.base|SQLi Avanzado]]"
---
---

La tercera vía para confirmar qué consultas ejecuta la aplicación —y para depurar payloads mientras se desarrolla el exploit— es leer los logs del propio motor. En un assessment [[00 - Introducción a PostgreSQL|white-box]] con acceso al servidor, <mark style="background: #ADCCFFA6;">los logs SQL muestran la consulta exacta que llega al motor</mark>, sin ambigüedad de decompilación.

# Habilitar el logging en PostgreSQL

Se edita `postgresql.conf` (normalmente en `/etc/postgresql/<versión>/main/`; si no, `find / -name postgresql.conf`):

```ini
logging_collector = on          # activa el proceso de logging
log_statement = 'all'           # registra TODAS las sentencias (SELECT, INSERT, ...)
log_directory = 'pg_log'        # dónde se guardan
log_filename = 'postgresql-%Y-%m-%d.log'
```

Tras guardar, reiniciar el servicio y observar el log casi en tiempo real:

```shell-session
$ sudo systemctl restart postgresql
$ sudo tail -f /var/lib/postgresql/<ver>/main/pg_log/postgresql-2023-02-14.log   # 'pg_log' es relativo al data directory
```

# Leer el log: parametrizado vs concatenado

La salida revela cómo se ejecuta cada consulta:

```text
LOG:  execute <unnamed>: SELECT * FROM users WHERE username = $1
DETAIL:  parameters: $1 = 'bmdyy'
```

> [!important]+
> <mark style="background: #8000E1A6;">Esta es la prueba definitiva de si una consulta es vulnerable</mark>: si el log muestra `WHERE username = $1` con el valor en una línea `parameters:` aparte, es **parametrizada y segura** —la entrada nunca toca la estructura—. Si en cambio el valor aparece **incrustado** dentro de la query (`WHERE email = 'maria'`), está **concatenada y es vulnerable**. Los logs eliminan la duda que deja el código decompilado.

# Qué buscar, más allá de parametrizado vs concatenado

Con `log_statement = 'all'` el log se llena rápido; durante una auditoría importan unas señales concretas:

- **Errores de sintaxis**: una línea `ERROR: syntax error at or near ...` revela **dónde** rompe tu payload y suele incluir la query completa con tu inyección incrustada —oro para ajustar el exploit—.
- **La query tras tu petición**: envía un valor único (`zzq3x`) y búscalo en el log (`grep zzq3x`) para ver en qué consulta(s) acaba tu parámetro, incluidas las de [[07 - SQL Injection de segundo orden|segundo orden]] que se disparan en una petición posterior.
- **Consultas inesperadas**: un solo parámetro puede generar varias queries (joins, validaciones, logging); alguna secundaria puede ser la vulnerable.
- **Duración**: con `log_min_duration_statement = 0` se registra el tiempo de cada query, útil para confirmar un [[06 - Identificar SQLi basada en tiempo|retardo time-based]] desde el lado del servidor.

> [!info]+
> `log_statement = 'all'` también sirve para **depurar el exploit**: al enviar un payload, ves exactamente cómo queda la query tras los filtros y concatenaciones de la aplicación. Es invaluable al construir un [[05 - Bypass de caracteres comunes|bypass de filtros]] o una [[07 - SQL Injection de segundo orden|inyección de segundo orden]], donde el payload se transforma entre la entrada y la ejecución.

> [!warning]+
> En un pentest real, leer los logs del motor requiere **acceso al servidor de base de datos** —se tiene en un white-box, o tras una primera explotación—. No es una técnica de caja negra. Pero cuando se dispone de ella, convierte el desarrollo del exploit de adivinanza en observación directa. El equivalente en otros motores: en [[🐬 MySQL|MySQL]], `SET GLOBAL general_log='ON'` (+ `general_log_file`); en [[00 - Introducción a MSSQL|MSSQL]], *SQL Server Profiler* o *Extended Events*. <mark style="background: #FFB86CA6;">El log captura datos en claro (credenciales, PII) y penaliza el rendimiento: en producción es caro y, si lo activas durante un engagement, desactívalo y límpialo al terminar.</mark>

Con las técnicas de localización white-box cubiertas (estática, dinámica y por logs), empieza la explotación de las vulnerabilidades encontradas. La primera, la SQLi de `/find-user` protegida por un filtro de caracteres: [[05 - Bypass de caracteres comunes]].
