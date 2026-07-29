---
tags:
  - Bases-de-Datos
  - SQL
Descripción: "Oracle TNS (*Transparent Network Substrate*) es el protocolo de comunicación entre las bases de datos Oracle y sus clientes, parte de *Oracle Net Services*"
Fecha de actualización: 2026-07-18
Nota previa:
Nota siguiente:
Area: "[[Bases de Datos.base|Bases de Datos]]"
---
---

<mark style="background: #ADCCFFA6;">`Oracle TNS` (*Transparent Network Substrate*) es el protocolo de comunicación entre las bases de datos Oracle y sus clientes</mark>, parte de *Oracle Net Services*. Soporta varias pilas (históricamente `IPX/SPX`, hoy `TCP/IP`), cifrado incorporado, IPv6 y `SSL/TLS`. Es el estándar en entornos empresariales grandes (sanidad, finanzas, retail), lo que lo hace un objetivo de alto valor en pentest interno.

# Puerto y arquitectura

- **`TCP 1521`** — el *TNS Listener*, el proceso que recibe las conexiones y las enruta a la instancia correcta.
- El cliente no conecta "a la base" sino **al listener**, indicando a qué instancia quiere ir.

# SID vs Service Name

<mark style="background: #FFB8EBA6;">Para conectar necesitas identificar la instancia</mark>, y hay dos formas de nombrarla:

- **`SID`** (*System Identifier*) — el nombre de una instancia concreta en el host.
- **`Service Name`** — un alias lógico que puede mapear a una o varias instancias.

Sin un SID/Service Name válido no se puede iniciar sesión — por eso el primer paso ofensivo suele ser **adivinar el SID**.

# Ficheros de configuración

- **`tnsnames.ora`** (cliente) — mapea alias a `host:puerto:SID`.
- **`listener.ora`** (servidor) — configura el listener: instancias, puertos, y —crítico— si exige contraseña de administración del propio listener.

# Cuentas por defecto

Oracle arrastra cuentas de fábrica famosas: `scott/tiger`, `system/manager`, `sys/change_on_install`, `dbsnmp/dbsnmp`. Que sigan activas es un clásico.

# Relevancia ofensiva

Un listener Oracle expuesto permite adivinar el SID, probar credenciales por defecto, **extraer hashes de contraseñas** y **subir ficheros** (→ RCE). La enumeración y explotación (con `odat`, `sqlplus`) se tratan en [[13 - Oracle TNS|Footprinting de Oracle TNS]].
