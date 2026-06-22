---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-04
Nota previa:
Nota siguiente: "[[01 - Interpretación de la salida de SQLMap]]"
Area: "[[SQLMap.base|SQLMap]]"
---
---

<mark style="background: #ADCCFFA6;">`SQLMap` es la herramienta estándar para automatizar la detección y explotación de [[00 - Introducción a SQL Injection|SQL injection]]</mark>. Es software libre escrito en Python, desarrollado desde 2006 y mantenido activamente. Donde la explotación manual se vuelve tediosa —enumerar una base entera carácter a carácter en una inyección a ciegas—, SQLMap brilla; pero conviene dominarla *después* de entender la SQLi manual, porque su salida y sus decisiones solo tienen sentido con esa base.

# Qué hace

Más allá de detectar la inyección, SQLMap cubre toda la cadena: huella del DBMS, enumeración, volcado de datos, acceso al sistema de ficheros, ejecución de comandos del SO y evasión de protecciones mediante *tamper scripts*. Soporta **todas** las técnicas de SQLi conocidas, seleccionables con `--technique` (por defecto `BEUSTQ`):

| Letra | Técnica | Payload ejemplo |
| ----- | ------- | --------------- |
| `B` | Boolean-based blind | `AND 1=1` |
| `E` | Error-based | `AND GTID_SUBSET(@@version,0)` |
| `U` | UNION query-based | `UNION ALL SELECT 1,@@version,3` |
| `S` | Stacked queries | `; DROP TABLE users` |
| `T` | Time-based blind | `AND 1=IF(2>1,SLEEP(5),0)` |
| `Q` | Inline queries | `SELECT (SELECT @@version) FROM ...` |

También soporta **out-of-band** por exfiltración DNS. <mark style="background: #FFB8EBA6;">La boolean-based es la más común; la UNION y la error-based, las más rápidas; la time-based, la más lenta (un retardo por bit)</mark>. Cada técnica es la automatización de lo que se hace a mano en las notas de [[01 - Introducción a Blind SQL Injection|Blind]] y [[06 - SQL Injection basada en errores|error-based]].

# DBMS soportados

Tiene el soporte más amplio de cualquier herramienta de SQLi: MySQL/MariaDB, PostgreSQL, Microsoft SQL Server, Oracle, SQLite, IBM DB2, Firebird, y decenas más (CockroachDB, Redshift, Vertica, etc.). En la práctica de web pentesting, los cuatro primeros cubren casi todo.

# Instalación

> [!warning]+
> SQLMap evoluciona rápido y la versión de los repositorios del sistema (`apt install sqlmap`) suele estar **desactualizada**. <mark style="background: #FF5582A6;">En 2026, instala desde el origen para tener las últimas técnicas y *tamper scripts*</mark>:
> ```shell-session
> $ pipx install sqlmap          # aislado, recomendado
> $ git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git
> ```
> Viene preinstalado en Pwnbox, Kali y la mayoría de distros de seguridad. Se ejecuta con `sqlmap` o `python sqlmap.py`.

> [!info]+
> **Alternativa moderna**: [`ghauri`](https://github.com/r0oth3x49/ghauri) reimplementa la detección y extracción con mejor rendimiento y evasión por defecto en blind boolean/time; útil cuando SQLMap se atasca o es demasiado ruidoso. SQLMap sigue siendo el más completo, pero tener `ghauri` como segunda opción es buena práctica.

# Primer escaneo

El uso más simple apunta a una URL con un parámetro `GET`. El switch `--batch` responde automáticamente todas las preguntas con la opción por defecto (clave para automatizar):

```shell-session
$ sqlmap -u "http://www.example.com/vuln.php?id=1" --batch
```

SQLMap prueba conexión, detecta WAF/IPS, comprueba que el parámetro es dinámico, lanza una heurística que adivina el DBMS y, si hay inyección, reporta los puntos vulnerables con sus payloads:

```text
Parameter: id (GET)
    Type: boolean-based blind
    Payload: id=1 AND 8814=8814
    Type: error-based
    Payload: id=1 AND (SELECT 7744 FROM(SELECT COUNT(*),CONCAT(...,FLOOR(RAND(0)*2))x ...)a)
    Type: time-based blind
    Payload: id=1 AND (SELECT 3669 FROM (SELECT(SLEEP(5)))TIxJ)
    Type: UNION query
    Payload: id=1 UNION ALL SELECT NULL,NULL,CONCAT(...)-- -
[INFO] the back-end DBMS is MySQL
```

<mark style="background: #8000E1A6;">Que SQLMap encuentre varios tipos a la vez es lo normal</mark>: cada uno tiene ventajas (UNION para volcar rápido, boolean para fiabilidad, time como último recurso).

> [!warning]+
> El disclaimer legal no es decorativo: <mark style="background: #FFB86CA6;">usar SQLMap contra objetivos sin autorización es ilegal</mark>. En bug bounty, además, lanzar SQLMap a ciegas con `--level`/`--risk` altos puede violar las reglas del programa (ruido, riesgo de `DROP`/escritura) y tumbar servicios. Acota siempre el ataque al punto ya confirmado a mano.

El siguiente paso es saber leer lo que SQLMap reporta: [[01 - Interpretación de la salida de SQLMap]].
