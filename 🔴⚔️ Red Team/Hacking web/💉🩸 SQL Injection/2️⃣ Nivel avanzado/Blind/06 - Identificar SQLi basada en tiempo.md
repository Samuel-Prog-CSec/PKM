---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Enumeracion
Fecha de actualización: 2026-06-04
Nota previa: "[[05 - Optimización de la extracción]]"
Nota siguiente: "[[07 - Diseño del oráculo temporal]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

La SQLi `time-based` es el recurso cuando **no hay ninguna diferencia observable** en la respuesta: ni datos, ni errores, ni cambios de contenido. El oráculo se construye sobre el **tiempo de respuesta**: se fuerza al servidor a esperar si una condición es verdadera. Es más lenta que la [[02 - Identificar SQLi basada en booleanos|boolean]], pero funciona donde aquella no.

# El punto de inyección olvidado: las cabeceras

En el escenario, la web no tiene campos de entrada visibles. <mark style="background: #FF5582A6;">El error de novato es rendirse ahí; el profesional prueba las cabeceras HTTP</mark>. Cabeceras como `User-Agent`, `Referer`, `X-Forwarded-For` o `Host` se registran a menudo en la base de datos (analítica, logging) mediante consultas vulnerables. Las cabeceras personalizadas son aún mejores candidatas, porque están ahí por algo.

El payload de prueba en MSSQL:

```sql
';WAITFOR DELAY '0:0:10'--
```

<mark style="background: #ADCCFFA6;">`WAITFOR DELAY` bloquea la consulta el tiempo indicado</mark>. Inyectándolo en cada cabecera y midiendo el tiempo de respuesta, se descubre que el `User-Agent` tarda 10 segundos: ahí está la inyección.

# Confirmar que el retardo es nuestro

Un único retardo no basta —el servidor pudo ir lento por casualidad—. <mark style="background: #FFB8EBA6;">Se confirma enviando una petición sin el payload (o con delay 0) y verificando que responde rápido</mark>, y repitiendo con delays distintos (5 s, 10 s) para comprobar que el tiempo escala de forma proporcional. Solo entonces el retardo es atribuible a la inyección y no a la red.

# Payloads time-based por motor

La función de espera cambia según el DBMS —de nuevo, el [[01 - Detección de SQL Injection|fingerprinting]] decide cuál usar—:

| Motor | Payload |
| ----- | ------- |
| MSSQL | `WAITFOR DELAY '0:0:10'` |
| MySQL/MariaDB | `AND (SELECT SLEEP(10) FROM dual WHERE database() LIKE '%')` |
| PostgreSQL | `\|\| (SELECT 1 FROM PG_SLEEP(10))` |
| Oracle | `AND 1234=DBMS_PIPE.RECEIVE_MESSAGE('RaNdStR',10)` |

> [!warning]+
> La detección time-based es la más **fiable contra defensas que ocultan todo** (errores, contenido), pero también la más **frágil ante la latencia**: una red lenta, un VPN o el rate limiting generan falsos positivos. <mark style="background: #FFB86CA6;">Usa delays generosos (5-10 s) para que el retardo inyectado destaque claramente del ruido de red</mark>, y promedia varias mediciones. Es el precio de trabajar totalmente a ciegas.

> [!info]+
> Cuando incluso el tiempo es poco fiable (mucha latencia, WAF que corta conexiones largas), queda la [[09 - Exfiltración Out-of-Band por DNS|exfiltración out-of-band]]: forzar al servidor a hacer una petición DNS/HTTP a un dominio controlado. Es el último recurso de la blind SQLi.

> [!important]+
> Las cabeceras como vector recuerdan algo clave para 2026: <mark style="background: #8000E1A6;">la superficie de inyección no son solo los parámetros visibles</mark>. Herramientas como [[SQLMap.base|SQLMap]] requieren `--level=3` para probar cabeceras; a mano, hay que probarlas explícitamente marcándolas como punto de inyección. Muchos SQLi que sobreviven hoy están justo en estos puntos secundarios.

El concepto del oráculo es idéntico al boolean, solo cambia el indicador: en lugar de "¿cambió el contenido?", preguntamos "¿tardó más?". Lo formalizamos en [[07 - Diseño del oráculo temporal]].
