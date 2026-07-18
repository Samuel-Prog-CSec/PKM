---
tags:
  - Redes
  - Protocolos
  - Linux
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">Los `r-services` (o *r-commands*) son la suite Berkeley de administración remota **anterior a SSH**</mark>: `rlogin`, `rsh` y `rexec`. Siguen apareciendo en sistemas Unix legacy y son <mark style="background: #FF5582A6;">intrínsecamente inseguros</mark>: no cifran nada y basan la confianza en la **IP/hostname del cliente**, no en credenciales robustas.

# Los comandos y sus puertos

| Servicio | Puerto | Función |
| --- | --- | --- |
| `rexec` | `TCP 512` | Ejecución remota de comandos (pide usuario/contraseña, en claro). |
| `rlogin` | `TCP 513` | Login remoto interactivo (tipo telnet). |
| `rsh` | `TCP 514` | Ejecuta un comando sin pedir contraseña **si hay relación de confianza**. |
| `rwho` / `rusers` | `UDP 513` / RPC | Listan usuarios conectados (info de enumeración). |

# El modelo de confianza (el fallo)

La autorización se define en dos ficheros:

- **`/etc/hosts.equiv`** (global): lista de hosts/usuarios **de confianza** para todo el sistema.
- **`~/.rhosts`** (por usuario): confianza a nivel de cuenta.

Una entrada como `+ +` o un host confiado significa que <mark style="background: #8000E1A6;">desde ese origen se entra **sin contraseña**</mark>. Como la confianza es por IP/hostname, falsificar el origen o comprometer un host confiado da acceso directo.

# Relevancia ofensiva

Si encuentras r-services, buscas relaciones de confianza abusables (`.rhosts`/`hosts.equiv` permisivos) para entrar sin credenciales, y sniffas el tráfico (va en claro). La enumeración y explotación se tratan en [[15 - Gestión remota Linux]]. En 2026 su sola presencia ya es un hallazgo: deberían estar deshabilitados en favor de [[SSH]].
