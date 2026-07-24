---
tags:
  - Web/Red-Team
  - ColdFusion
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-16
Nota previa: "[[01 - Vulnerabilidades web en thick clients]]"
Nota siguiente: "[[01 - Ataques a ColdFusion]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">Adobe ColdFusion es una plataforma de desarrollo web basada en Java</mark> (de 1995, hoy de Adobe) que usa el lenguaje **CFML** (`.cfm`, `.cfc`), con sintaxis de tags similar a HTML:

```html
<cfquery name="myQuery" datasource="myDataSource">
  SELECT * FROM myTable
</cfquery>
```

Es antiguo pero persiste en entornos empresariales y gubernamentales, y su historial de CVEs críticas (SQLi, XSS, path traversal, auth bypass, file upload) lo hace muy rentable.

# Puertos por defecto

| Puerto | Uso |
| - | - |
| 80 / 443 | HTTP / HTTPS |
| **8500** | comunicación por SSL (el delator típico) |
| 1935 | RPC (cliente-servidor) |
| 25 | SMTP (envío de email) |
| 5500 | Server Monitor (administración remota) |

# Enumeración

| Método | Señal |
| - | - |
| Extensiones | `.cfm` / `.cfc` en las URLs |
| Cabeceras HTTP | `Server: ColdFusion`, `X-Powered-By: ColdFusion` |
| Mensajes de error | referencias a tags/funciones CFML |
| Ficheros por defecto | `admin.cfm`, **`/CFIDE/administrator/index.cfm`** |

```shell-session
$ nmap -p- -sC -Pn 10.129.247.30 --open
8500/tcp  open  fmtp        # puerto SSL de ColdFusion
```

Navegando a `IP:8500` aparecen los directorios **`CFIDE`** y **`cfdocs`** en la raíz (indicador claro), y `/CFIDE/administrator/` carga el **login del ColdFusion 8 Administrator** → versión confirmada.

> [!info]+ Versión → CVE
> HTB lista CVEs de la época: **CVE-2020-24450** (command injection), **CVE-2020-24449** (lectura de ficheros), **CVE-2021-21087**, **CVE-2019-15909** (XSS). Pero el vector actual y más grave es <mark style="background: #FFB86CA6;">**CVE-2023-26360** (RCE no autenticada vía *access control bypass*, CWE-284; en CISA KEV)</mark> — la RCE por deserialización WDDX es otra CVE (`CVE-2023-26359`/`CVE-2023-29300`), ver [[01 - Ataques a ColdFusion]]. Herramientas: `nuclei -tags coldfusion`, `metasploit` (`auxiliary/scanner/http/coldfusion_version`).

A la explotación: [[01 - Ataques a ColdFusion]].
