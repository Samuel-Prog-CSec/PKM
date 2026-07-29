---
tags:
  - Web/Red-Team
  - Common-Applications
  - Pentesting/Explotacion
Descripción: "Ninguna lista cubre todas las aplicaciones"
Fecha de actualización: 2026-07-16
Nota previa: "[[Attacking Applications Connecting to Services]]"
Nota siguiente: "[[Endurecimiento de aplicaciones]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Ninguna lista cubre todas las aplicaciones. <mark style="background: #8000E1A6;">Lo importante es la **metodología**, que transfiere a cualquier app nueva</mark>: filtrar el ruido de los escaneos (un EyeWitness de 500 páginas esconde joyas) y buscar credenciales por defecto, repos abiertos, o funcionalidad abusable — como el Nexus Repository OSS de la introducción del módulo.

# Honorable mentions (con su vector)

| Aplicación | Abuso |
| - | - |
| **Axis2** | Como [[01 - Ataques a Tomcat\|Tomcat]] (a menudo montado sobre él); default creds → subir un web shell en un **`.aar`**. Módulo de Metasploit disponible. |
| **WebSphere** | Con default `system:manager` en la consola admin → desplegar un **WAR** → RCE. |
| **WebLogic** | App server Java EE, ~190 CVEs; muchas **RCE no autenticadas** por **deserialización Java** (2007-2021+). |
| **Zabbix** | SQLi, auth bypass, stored XSS, *LDAP password disclosure*, y **RCE vía API**. Box HTB **Zipper**. |
| **Nagios** | RCE, privesc a root, SQLi, XSS. Probar default `nagiosadmin:PASSW0RD` y fingerprint de versión. |
| **Elasticsearch** | CVEs varias (p. ej. CVE-2015-1427 Groovy RCE), instancias sin auth. Box HTB **Haystack**. |
| **vCenter** | Weak creds + **CVE-2021-22005** (subida OVA **no autenticada** → RCE); a menudo corre como `SYSTEM` o incluso domain admin → JuicyPotato para el resto. |
| **DotNetNuke** | Auth bypass, directory traversal, stored XSS, file upload bypass, arbitrary file download. |
| **Wikis / Intranets** | MediaWiki, SharePoint, intranets custom — su **buscador** suele filtrar credenciales en documentos. |

# El mindset

> [!important]+ Cómo abordar una app desconocida
> 1. **Identifícala y versiónala** (`nuclei`, `whatweb`, metadatos, cabeceras).
> 2. **Credenciales por defecto** — casi siempre el primer intento.
> 3. **Busca la CVE** (`searchsploit`, `nuclei -tags <app>`, NVD).
> 4. Si no hay CVE, <mark style="background: #FFB86CA6;">abusa de la funcionalidad legítima</mark>: consola de scripts, subida de plugins/plantillas, tareas, o conexión a servicios ([[Attacking Applications Connecting to Services|extraer connection strings]]).

> [!info]+ Adiciones modernas (post-2021)
> A la lista de HTB (de 2021) hay que sumar los objetivos calientes de hoy: <mark style="background: #FFB86CA6;">**Atlassian Confluence** (OGNL RCE, CVE-2022-26134 no auth), **Grafana** (LFI, CVE-2021-43798), **ManageEngine** (múltiples RCE), y los appliances de acceso (Ivanti, Citrix, Fortinet)</mark> — todos vectores de red team y bug bounty actuales que siguen la misma lógica: versión → CVE o funcionalidad.

Para cerrar el módulo, la cara defensiva: [[Endurecimiento de aplicaciones]].
