---
tags:
  - Redes
  - Protocolos
  - Introduccion
  - Tipo/Introduccion
Descripción: "Un protocolo de red es el contrato que fija cómo dos máquinas intercambian datos: qué bytes se envían, en qué orden, qué significa cada campo y qué se hace cuando algo falla"
Fecha de actualización: 2026-07-29
Area: "[[Protocolos de red.base|Protocolos de red]]"
---
---

<mark style="background: #ADCCFFA6;">Un protocolo de red es el contrato que fija cómo dos máquinas intercambian datos: qué bytes se envían, en qué orden, qué significa cada campo y qué se hace cuando algo falla</mark>. Sin ese acuerdo previo dos equipos pueden estar perfectamente conectados a nivel eléctrico y no entenderse en absoluto.

Esta nota es la puerta de entrada al sub-tema: agrupa las fichas de "cómo funciona" cada protocolo. La contraparte ofensiva —cómo enumerarlo y atacarlo— vive en [[00 - Principios y metodología de enumeración|Footprinting]], y cada ficha de aquí enlaza con su nota de enumeración correspondiente.

# Por qué importa el modelo de capas

Los protocolos se apilan: cada capa resuelve un problema y delega el resto en la de abajo. <mark style="background: #8000E1A6;">Eso significa que un fallo de seguridad en una capa baja compromete todo lo que viaja encima, por muy bien diseñado que esté</mark> — es exactamente lo que explota un ataque de red clásico: si controlas la resolución de nombres (DNS) o el enrutado (ARP/BGP), da igual lo robusto que sea el protocolo de aplicación que corre por encima.

| Capa | Función | Protocolos de este sub-tema |
| - | - | - |
| Aplicación | Semántica del servicio | [[📂🔄 FTP\|FTP]], [[HTTP]], [[SMTP]], [[DNS]], [[SNMP]], [[📂🔗 SMB\|SMB]] |
| Presentación / Sesión | Cifrado, codificación, sesiones | [[HTTPS]], [[SSH]] |
| Transporte | Entrega fiable o no fiable, puertos | TCP / UDP |
| Red | Direccionamiento y enrutado | IP, ICMP |
| Enlace y física | Trama y medio | Ethernet, Wi-Fi |

La distinción **TCP vs UDP** es la que más consecuencias prácticas tiene. TCP establece conexión, garantiza orden y reintenta; UDP dispara y se olvida. Por eso [[📂🚀 TFTP\|TFTP]] (UDP) no puede ofrecer las garantías de [[📂🔄 FTP\|FTP]] (TCP), y por eso un escaneo UDP es lento y ruidoso mientras que uno TCP obtiene respuesta inmediata.

# El patrón que se repite en casi todos

Al estudiar las fichas siguientes aparece una y otra vez la misma historia: <mark style="background: #FFB8EBA6;">el protocolo se diseñó en una época en la que la red interna se consideraba de confianza</mark>. FTP, SMTP, SNMPv1/v2c, Telnet o los [[R-services]] transmiten **credenciales en claro** porque nacieron antes de que interceptar tráfico fuera trivial. Las versiones seguras (FTPS, SMTPS, SNMPv3, SSH) son parches posteriores, y en 2026 <mark style="background: #FF5582A6;">seguir encontrando la versión insegura en producción es habitual — y es un hallazgo reportable por sí mismo</mark>.

El segundo patrón es la **autenticación anónima o por defecto**: FTP anónimo, `null sessions` en SMB, comunidades `public`/`private` en SNMP, exports sin restricción en NFS. Ver [[⚠️⚙️ Ajustes peligrosos]] para el caso concreto de FTP.

# Fichas por protocolo

| Protocolo | Puerto(s) | Transporte | Nota |
| - | - | - | - |
| FTP / TFTP | 21, 20 · 69 | TCP · UDP | [[📂🔄 FTP]] · [[📂🚀 TFTP]] |
| SMB | 445 (139) | TCP | [[📂🔗 SMB]] |
| NFS | 2049 | TCP/UDP | [[NFS]] |
| DNS | 53 | UDP (TCP en zonas) | [[DNS]] |
| SMTP | 25, 465, 587 | TCP | [[SMTP]] |
| IMAP / POP3 | 143, 993 · 110, 995 | TCP | [[IMAP-POP3]] |
| SNMP | 161, 162 | UDP | [[SNMP]] |
| IPMI | 623 | UDP | [[IPMI]] |
| SSH | 22 | TCP | [[SSH]] |
| Rsync | 873 | TCP | [[Rsync]] |
| R-services | 512, 513, 514 | TCP | [[R-services]] |
| RDP | 3389 | TCP/UDP | [[RDP]] |
| WinRM | 5985, 5986 | TCP | [[WinRM]] |
| WMI | 135 + dinámico | TCP | [[WMI]] |
| HTTP / HTTPS | 80 · 443 | TCP | [[HTTP]] · [[HTTPS]] |

> [!important]+ Los puertos son una convención, no una garantía
> La tabla recoge los puertos **registrados** por IANA, que es lo que asume por defecto la detección de servicios. Un administrador puede mover cualquier servicio a cualquier puerto, y en un pentest real es frecuente: SSH en el 2222, RDP en el 33890. Por eso la identificación fiable no es "puerto 22 → SSH" sino la huella del servicio (`nmap -sV`, banner grabbing). Confiar en el número de puerto produce *false negatives* silenciosos.

> [!info]+ Fuente para los números de puerto
> Registro oficial de IANA, *Service Name and Transport Protocol Port Number Registry* — [iana.org](https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml). Es la referencia primaria; las listas que circulan en blogs suelen arrastrar errores.
