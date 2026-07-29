---
tags:
  - Bases-de-Datos
  - SQL
Descripción: "Microsoft SQL Server (MSSQL) es el RDBMS de Microsoft, profundamente integrado con Windows y Active Directory"
Fecha de actualización: 2026-07-18
Nota previa:
Nota siguiente:
Area: "[[Bases de Datos.base|Bases de Datos]]"
---
---

<mark style="background: #ADCCFFA6;">`Microsoft SQL Server` (`MSSQL`) es el `RDBMS` de Microsoft</mark>, profundamente integrado con Windows y **Active Directory**. Esa integración es justo lo que lo convierte en un objetivo clave del pentest interno: comprometer un MSSQL a menudo es comprometer identidades del dominio.

# Protocolo y puertos

- Habla **`TDS`** (*Tabular Data Stream*).
- **`TCP 1433`** — instancia por defecto.
- **`UDP 1434`** — *SQL Server Browser*: resuelve el puerto de las **instancias con nombre** (que usan puertos dinámicos). Consultarlo enumera todas las instancias del host.

# Autenticación: el detalle que importa

<mark style="background: #FFB8EBA6;">MSSQL soporta dos modos</mark>:

- **Windows Authentication** (integrada): usa las identidades de Windows/AD (NTLM/Kerberos). El login `sa` puede estar deshabilitado y todo pasar por cuentas de dominio.
- **SQL Server Authentication**: usuarios internos del motor (el clásico `sa` + contraseña).

# Bases de datos del sistema

`master` (config del servidor), `model` (plantilla), `msdb` (SQL Agent, jobs), `tempdb` (temporal). Enumerarlas orienta sobre la configuración y los trabajos programados.

# Lo que lo hace peligroso

MSSQL trae funcionalidad que, mal gobernada, da ejecución de comandos y movimiento lateral:

- **`xp_cmdshell`** — ejecuta comandos del **SO** desde SQL. Deshabilitado por defecto, pero un `sysadmin` puede reactivarlo.
- **Linked servers** — enlaces a otros servidores SQL que permiten ejecutar consultas (y a veces comandos) **en cadena**, ideal para pivotar.
- **Procedimientos como `xp_dirtree`** — fuerzan al servicio a autenticarse contra una ruta UNC, filtrando su hash **NetNTLM**.

# Relevancia ofensiva

Un MSSQL accesible es potencialmente RCE (`xp_cmdshell`), captura de credenciales de dominio (`xp_dirtree` + relay) y pivoting (linked servers). La enumeración y explotación se tratan en [[12 - MSSQL|Footprinting de MSSQL]]. Las técnicas SQL genéricas se comparten con [[00 - Introducción a SQL Injection|SQL Injection]].
