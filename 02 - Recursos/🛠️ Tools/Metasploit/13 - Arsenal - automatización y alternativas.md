---
tags:
  - Pentesting/Explotacion
  - Pentesting/Post-Explotacion
  - Metasploit
  - Tipo/Arsenal
Descripción: "Cierre del sub-tema: cómo automatizar Metasploit y —igual de importante— cuándo cambiarlo por otra herramienta"
Fecha de actualización: 2026-07-18
Nota previa: "[[12 - Detección y evasión]]"
Nota siguiente: 
Area: "[[Metasploit.base|Metasploit]]"
---
---

Cierre del sub-tema: cómo **automatizar** Metasploit y —igual de importante— **cuándo cambiarlo** por otra herramienta. Un pentester senior no usa MSF para todo; lo integra en un arsenal más amplio y sabe reconocer cuándo no es la opción correcta.

# Automatizar Metasploit

| Vía | Uso |
| --- | --- |
| **Resource scripts** (`.rc`) | Comandos en secuencia: `msfconsole -r auto.rc` o `resource auto.rc` |
| **One-liner** (`-x`) | Todo en la línea de comandos, ideal para un handler rápido |
| **`AutoRunScript`** | Ejecuta un módulo post **al recibir** cada sesión (migrar, enumerar) |
| **msf-RPC** (`msfrpcd`) | Control programático desde Python ([pymetasploit3](https://github.com/DanMcInerney/pymetasploit3)) |

```shell-session
# Handler completo en un one-liner
$ msfconsole -q -x "use exploit/multi/handler; \
    set PAYLOAD windows/x64/meterpreter/reverse_https; \
    set LHOST tun0; set LPORT 443; exploit -j"

# Migrar automáticamente al recibir la sesión (estabilidad + sigilo)
msf6 > set AutoRunScript "post/windows/manage/migrate"
```

<mark style="background: #FFB8EBA6;">Los resource scripts son la base de un flujo repetible</mark>: montar el handler, cargar plugins y fijar variables globales al arrancar, sin teclear nada. Se apoyan en el [[01 - MSFconsole|arranque de msfconsole]].

# Integración con el resto del arsenal

MSF no trabaja solo: [[06 - Guardar y explotar resultados|Nmap]] (`db_nmap`/`db_import`), [[Nessus.base|Nessus]]/OpenVAS (plugins), y las tablas de la [[06 - Bases de datos y workspaces|base de datos]] alimentan y consumen datos del framework.

# Cuándo NO usar Metasploit

<mark style="background: #FF5582A6;">La razón nº1 para no usar MSF es la [[12 - Detección y evasión|detección]]</mark>: frente a EDR maduro, Meterpreter cae. Otras: cuando necesitas OPSEC de alto nivel (red team sigiloso), cuando el objetivo es Active Directory puro (Impacket/NetExec son más quirúrgicos), o cuando quieres un implant a medida.

# C2 alternativos modernos

Cuando el engagement pasa de "una shell" a operación sostenida y sigilosa:

| C2 | Notas |
| --- | --- |
| [Sliver](https://github.com/BishopFox/sliver) | <mark style="background: #8000E1A6;">El estándar **open-source** actual</mark> (BishopFox), en Go: mTLS/HTTP(S)/DNS, implants multiplataforma, mucho menos fichado que Meterpreter |
| [Havoc](https://github.com/HavocFramework/Havoc) | C2 moderno con GUI y buen soporte de evasión |
| [Mythic](https://github.com/its-a-feature/Mythic) | Framework modular, dockerizado, multi-agente |
| Cobalt Strike | Comercial, referencia del red team (y muy vigilado por lo mismo) |
| [Empire](https://github.com/BC-SECURITY/Empire) / Starkiller | C2 PowerShell/Python con GUI |

# Complementos que no son C2

Para ataque a Windows/AD, a menudo más precisos que MSF:

| Herramienta | Uso |
| --- | --- |
| [Impacket](https://github.com/fortra/impacket) | `psexec.py`, `wmiexec.py`, `secretsdump.py` — ejecución y volcado de credenciales sin MSF |
| [NetExec](https://github.com/Pennyw0rth/NetExec) (nxc) | Sucesor de CrackMapExec: barrido masivo de credenciales/servicios |
| [pwncat](https://github.com/calebstewart/pwncat) | Listener con post-explotación (ver [[12 - Arsenal de herramientas|Shells & Payloads]]) |

> [!success]+ Criterio de elección (2026)
> - **Lab / CTF / host sin defensas** → Metasploit, rápido y completo.
> - **Enumeración y explotación de servicios** → MSF `auxiliary` + exploits, o Nmap NSE.
> - **Post-explotación con EDR** → shellcode de [[11 - MSFvenom|msfvenom]] en un loader, o implant de **Sliver**.
> - **Active Directory / lateral movement** → **Impacket** + **NetExec**, MSF como apoyo.
> - **Red team sigiloso** → C2 dedicado (Sliver/Havoc/Cobalt Strike), MSF solo como handler.

MSF sigue siendo la navaja suiza para aprender y para gran parte del pentest, pero <mark style="background: #FFB86CA6;">reconocer sus límites y combinarlo con el arsenal adecuado es lo que distingue al profesional</mark>. Este toolkit enlaza con el [[12 - Arsenal de herramientas|arsenal de Shells & Payloads]] y con el [[18 - Arsenal de footprinting|de footprinting]].
