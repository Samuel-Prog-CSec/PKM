---
tags:
  - Pentesting/Explotacion
  - Pentesting/Post-Explotacion
  - Metasploit
Fecha de actualización: 2026-07-18
Nota previa: "[[07 - Plugins y Mixins]]"
Nota siguiente: "[[09 - Meterpreter]]"
Area: "[[Metasploit.base|Metasploit]]"
---
---

Cuando un exploit tiene éxito, la conexión resultante es una `session`. Cuando algo corre en segundo plano (un handler, un servidor), es un `job`. Gestionar ambos es lo que permite trabajar con varios objetivos a la vez sin perder el hilo.

# Sesiones: las conexiones vivas

```shell-session
msf6 > sessions              # o 'sessions -l': lista las sesiones abiertas
msf6 > sessions -i 1         # interactuar con la sesión 1
meterpreter > background     # (o Ctrl+Z) vuelve a msfconsole sin cerrarla
msf6 > sessions -k 1         # matar la sesión 1
msf6 > sessions -K           # matar TODAS
```

<mark style="background: #FFB8EBA6;">`background` es clave</mark>: deja la sesión viva mientras vuelves a la consola para lanzar otro módulo. `sessions -i` la retoma cuando quieras.

# Upgrade de shell a Meterpreter

Una de las utilidades más prácticas: si tienes una shell "tonta" (de un `shell/...` o de un exploit externo capturado con `multi/handler`), MSF la **eleva** a Meterpreter automáticamente:

```shell-session
msf6 > sessions -u 1         # upgrade de la sesión 1 (shell → meterpreter)
```

<mark style="background: #8000E1A6;">Es el equivalente en MSF al [[08 - Shells interactivas - upgrade a TTY|upgrade a TTY]]</mark> que hacíamos a mano en Shells & Payloads — aquí lo automatiza el framework, dándote además todas las capacidades de [[09 - Meterpreter|Meterpreter]].

# Comandos sobre múltiples sesiones

En un engagement con varias máquinas comprometidas:

```shell-session
msf6 > sessions -C "whoami"        # ejecuta un comando en TODAS las sesiones
msf6 > sessions -c "ipconfig" -i 3 # comando en una sesión concreta
```

# Jobs: lo que corre en segundo plano

Un `job` es un módulo ejecutándose en background — típicamente un **handler** esperando conexiones, o un servidor (SMB, HTTP) sirviendo un payload:

```shell-session
msf6 > exploit -j            # lanza el módulo como job (no bloquea la consola)
msf6 > jobs                  # o 'jobs -l': lista los jobs activos
msf6 > jobs -k 0             # matar el job 0
msf6 > jobs -K               # matar todos
```

<mark style="background: #FFB86CA6;">Un `multi/handler` lanzado con `exploit -j` queda escuchando en background</mark> mientras entregas el payload por otra vía — el patrón habitual para recibir shells de payloads generados con [[11 - MSFvenom|MSFvenom]].

> [!important]+ Persistencia del handler
> Si cierras msfconsole, los jobs mueren y pierdes las conexiones entrantes. Para handlers que deban sobrevivir, usa un [[01 - MSFconsole|resource script]] que los relance, o `exploit -j -z` (no interactúa automáticamente con la sesión al recibirla).

# Pivoting a través de una sesión

Las sesiones no solo dan acceso a un host: son la **puerta a su red interna**. Metasploit puede enrutar tráfico de otros módulos a través de una sesión comprometida:

```shell-session
meterpreter > run autoroute -s 172.16.5.0/24    # añade ruta por esta sesión
msf6 > use auxiliary/server/socks_proxy          # SOCKS para el resto de tools
```

<mark style="background: #FF5582A6;">Esto convierte un único host comprometido en un trampolín hacia segmentos que no eran alcanzables</mark> — el detalle completo pertenece al futuro módulo de *Pivoting, Tunneling & Port Forwarding*.

El agente que hace posible casi todo esto —upgrade, pivoting, post-explotación— es [[09 - Meterpreter|Meterpreter]].
