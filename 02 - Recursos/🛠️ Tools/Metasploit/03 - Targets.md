---
tags:
  - Pentesting/Explotacion
  - Metasploit
Descripción: "Un target es la variante concreta del objetivo para la que un exploit está preparado: una versión de sistema operativo, un *service pack*, un idioma, una arquitectura o incluso…"
Fecha de actualización: 2026-07-18
Nota previa: "[[02 - Módulos]]"
Nota siguiente: "[[04 - Payloads en Metasploit]]"
Area: "[[Metasploit.base|Metasploit]]"
---
---

<mark style="background: #ADCCFFA6;">Un `target` es la variante concreta del objetivo para la que un exploit está preparado</mark>: una versión de sistema operativo, un *service pack*, un idioma, una arquitectura o incluso una versión específica del software vulnerable. Un mismo exploit puede traer varios targets porque **los detalles de bajo nivel cambian entre versiones**.

# Ver y fijar el target

```shell-session
msf6 exploit(...) > show targets

Exploit targets:
   Id  Name
   --  ----
   0   Automatic
   1   Windows 7 SP1
   2   Windows Server 2008 R2
   3   Windows Server 2016

msf6 exploit(...) > set TARGET 1
```

Por defecto suele venir seleccionado el target `0 – Automatic`, que intenta **detectar** la versión del objetivo y elegir la variante correcta.

# Automatic vs. manual

<mark style="background: #FFB8EBA6;">El target automático es cómodo pero no infalible</mark>: si el fingerprinting de MSF se equivoca (por un banner alterado, una configuración atípica o un WAF de por medio), elige mal. Fijar el target **manualmente** cuando ya conoces la versión exacta del objetivo es más fiable.

# Por qué el target correcto es crítico

Muchos exploits de memoria dependen de **offsets, direcciones y cadenas ROP** que son específicos de cada build:

- <mark style="background: #FFB86CA6;">Un target equivocado no solo hace que el exploit falle: puede **corromper la memoria y tumbar el servicio o el host**</mark> (un `BSOD` en Windows, por ejemplo).
- El idioma del SO importa: los offsets de una edición en inglés y una en otro idioma pueden diferir.
- El target también condiciona qué **arquitectura de payload** es compatible (`x86` vs `x64`) — enlaza con la elección de [[04 - Payloads en Metasploit|payload]].

> [!warning]+ Target incorrecto = posible DoS
> En un objetivo de producción, un `set TARGET` mal elegido en un exploit de corrupción de memoria puede dejar el sistema caído. Cuando dudes de la versión, **enuméra primero** y confirma el build exacto antes de disparar.

# Fingerprinting para elegir el target

La elección del target se apoya en la [[00 - Principios y metodología de enumeración|enumeración]] previa. En Windows, el build exacto (`systeminfo`, versión de SMB, banner del servicio) determina qué target aplica — la metodología está en [[06 - Shells en Windows|fingerprinting de Windows]]. En servicios de red, la versión del software vulnerable (por su banner o respuesta) es la que manda.

```shell-session
# ejemplo de flujo: enumerar versión → elegir target coherente
msf6 > use auxiliary/scanner/smb/smb_version
msf6 auxiliary(...) > set RHOSTS 10.10.10.40
msf6 auxiliary(...) > run          # revela "Windows Server 2008 R2"
msf6 > use exploit/windows/smb/ms17_010_eternalblue
msf6 exploit(...) > set TARGET 2   # coherente con lo enumerado
```

<mark style="background: #8000E1A6;">La disciplina es siempre la misma: enumerar → confirmar versión → elegir target → elegir payload compatible</mark>. Saltarse el primer paso y confiar ciegamente en `Automatic` es la causa nº1 de exploits que "no funcionan" o que crashean el objetivo.

Con el módulo, su target y el objetivo claros, falta la pieza que nos entrega el acceso: el [[04 - Payloads en Metasploit|payload]].
