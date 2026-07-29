---
tags:
  - Redes
  - Protocolos
  - Windows
Descripción: "RDP (*Remote Desktop Protocol*) es el protocolo de Microsoft para acceso remoto gráfico a escritorios Windows"
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">`RDP` (*Remote Desktop Protocol*) es el protocolo de Microsoft para acceso remoto **gráfico** a escritorios Windows</mark>. Escucha en **`TCP/3389`** y transmite pantalla, teclado y ratón entre cliente y servidor sobre un canal cifrado (TLS).

# Seguridad

- **`NLA`** (*Network Level Authentication*): exige autenticar **antes** de crear la sesión, mitigando parte de los ataques. Su presencia/ausencia se enumera.
- El nivel de cifrado y el certificado se pueden auditar (`rdp-sec-check`, scripts NSE).

# Vulnerabilidades históricas

<mark style="background: #FFB86CA6;">RDP arrastra fallos críticos y *wormables*</mark>:

- **BlueKeep** (`CVE-2019-0708`) — RCE preauth en versiones antiguas, gusaneable (como WannaCry).
- **DejaBlue** (`CVE-2019-1181/1182`) — familia relacionada.

# Relevancia ofensiva

RDP es objetivo de enumeración (NLA, dominio/hostname vía `rdp-ntlm-info`), fuerza bruta de credenciales y explotación de CVEs sin parchear. Con credenciales válidas da un escritorio completo. La enumeración se trata junto a WinRM y WMI en [[16 - Gestión remota Windows]].
