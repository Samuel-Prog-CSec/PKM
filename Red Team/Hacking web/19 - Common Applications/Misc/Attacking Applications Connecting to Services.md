---
tags:
  - Web/Red-Team
  - Common-Applications
  - Pentesting/Explotacion
Descripción: "Las aplicaciones que se conectan a servicios (bases de datos, LDAP, APIs) llevan connection strings con credenciales"
Fecha de actualización: 2026-07-16
Nota previa: "[[Web Mass Assignment Vulnerabilities]]"
Nota siguiente: "[[Other Notable Applications]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Las aplicaciones que se conectan a servicios (bases de datos, LDAP, APIs) llevan **connection strings** con credenciales. Si el binario es accesible, <mark style="background: #FFB86CA6;">se pueden extraer esas credenciales por ingeniería inversa</mark> y reutilizarlas para moverse lateralmente o escalar. Es primo directo del análisis de [[00 - Ataque a thick clients|thick clients]].

# ELF (Linux): GDB / PEDA

Un binario `octopus_checker` que "verifica" instancias de base de datos claramente abre una conexión SQL. Con **GDB + PEDA** se desensambla `main`, se localiza la llamada a `SQLDriverConnect` y se pone un breakpoint:

```shell-session
$ gdb ./octopus_checker
gdb-peda$ set disassembly-flavor intel
gdb-peda$ disas main            # buscar la call a SQLDriverConnect@plt
gdb-peda$ b *0x5555555551b0     # breakpoint en esa dirección
gdb-peda$ run
```

Al pararse, <mark style="background: #FF5582A6;">el registro `RDX` contiene la connection string con las credenciales</mark>:

```text
RDX: "DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost,1401;UID=username;PWD=password;"
```

> [!warning]+ Endianness
> En el desensamblado los trozos de la cadena pueden aparecer **desordenados y con los bytes invertidos** (endianness). Por eso es más fiable poner el breakpoint y leer el **registro en runtime**, donde la cadena ya está montada, que reconstruirla a mano desde el `.data`.

# DLL .NET (Windows): dnSpy

Un `MultimasterAPI.dll` resulta ser un **.NET assembly** (`Get-FileMetaData` muestra el framework). Con **dnSpy** se lee el código fuente directamente; inspeccionando el controlador (`MultimasterAPI.Controllers → ColleagueController`) aparece la <mark style="background: #8000E1A6;">connection string con la contraseña</mark>.

# Reutilización

Las credenciales extraídas casi nunca sirven solo para su servicio: probar **password spraying** y reutilización contra otros servicios de la misma red (SMB, RDP, WinRM, otras BD). Un `PWD=password` de una connection string puede ser la contraseña de un usuario de dominio.

> [!info]+ Herramientas
> `gdb`+`PEDA`/`gef` (ELF), `dnSpy`/`ILSpy` (.NET), `strings` para un primer barrido rápido, `Get-FileMetaData` para identificar el runtime. La idea transversal con [[01 - Vulnerabilidades web en thick clients|thick clients]]: cualquier secreto embebido en un binario accesible está comprometido.

El módulo no puede cubrir cada aplicación; la metodología es lo que transfiere: [[Other Notable Applications]].
