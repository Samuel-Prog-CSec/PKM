---
tags:
  - Redes
  - Protocolos
  - Windows
Fecha de actualización: 2026-07-18
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">`SMB` (*Server Message Block*) es un protocolo cliente-servidor que regula el acceso a ficheros, directorios y otros recursos de red</mark> (impresoras, interfaces compartidas) y también sirve para el intercambio de información entre procesos (IPC). Es el pilar del compartido de ficheros en Windows y, vía **Samba**, en Linux/Unix.

# Historia y dialectos

Apareció con LAN Manager y OS/2, y su área principal ha sido siempre Windows, que lo mantiene **retrocompatible** (equipos nuevos hablan con viejos). Los dialectos importan mucho por seguridad:

| Versión | Aparece en | Nota de seguridad |
| --- | --- | --- |
| **SMB 1.0 / CIFS** | Windows antiguos | <mark style="background: #FF5582A6;">Peligroso, obsoleto</mark>. Vector de `EternalBlue`/WannaCry (MS17-010). **Debe desactivarse.** |
| **SMB 2.0/2.1** | Vista/Server 2008 (2.1 en 7/Server 2008 R2) | Rediseño eficiente, menos comandos. |
| **SMB 3.x** | Windows 8 / Server 2012+ | Cifrado end-to-end, firma obligatoria opcional, mejor rendimiento. |

# Puertos: NetBIOS vs SMB directo

<mark style="background: #FFB8EBA6;">Distinguir 139 de 445 es clave al enumerar</mark>:

- **`UDP 137/138`** — NetBIOS name service y datagram.
- **`TCP 139`** — SMB **sobre NetBIOS** (legacy).
- **`TCP 445`** — SMB **directo sobre TCP/IP** (el moderno). Es el que verás casi siempre.

# Conceptos que usarás al atacar

- **Recursos compartidos (*shares*)**: carpetas expuestas (`C$`, `ADMIN$`, `IPC$`, y los del admin). Los `$` son administrativos/ocultos.
- **`IPC$`**: share especial para comunicación entre procesos vía **named pipes** — la puerta de las *null sessions* y de la enumeración con `rpcclient`.
- **Workgroup vs Dominio**: en workgroup la autenticación es local a cada host; en dominio la centraliza Active Directory (NTLM/Kerberos).
- **Samba**: la implementación libre de SMB para Linux/Unix; su config vive en `/etc/samba/smb.conf` y sus malas opciones (`guest ok`, `browseable`, `writable`) son un clásico de findings.

# Relevancia ofensiva

SMB es uno de los servicios más rentables de una red interna: <mark style="background: #8000E1A6;">un recurso mal configurado da lectura/escritura de ficheros, y `IPC$` permite enumerar usuarios, grupos y políticas sin credenciales</mark> (null session). La enumeración y explotación —`smbclient`, `rpcclient`, RID cycling, `enum4linux-ng`, `smbmap`, `netexec`— se trata en [[05 - SMB|Footprinting de SMB]]. Recuerda que **Azure File Storage habla SMB**, así que esto aplica también a recursos cloud (ver [[02 - Recursos cloud]]).
