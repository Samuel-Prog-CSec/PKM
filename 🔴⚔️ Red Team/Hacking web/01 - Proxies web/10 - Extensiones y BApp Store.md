---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Proxies
Fecha de actualización: 2026-06-23
Nota previa: "[[09 - Escáner de vulnerabilidades - Burp y ZAP Scanner]]"
Nota siguiente: "[[11 - OPSEC y evasión de detección]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

<mark style="background: #ADCCFFA6;">Lo que de verdad hace a Burp imbatible es su ecosistema de extensiones.</mark> El **BApp Store** (Burp) y el **Marketplace** (ZAP) añaden capacidades que el core no trae: descubrir parámetros ocultos, atacar tokens, automatizar IDOR, encontrar clases enteras de vulnerabilidades. Conocer las imprescindibles separa al que "usa Burp" del que lo exprime.

# BApp Store

`Extensions > BApp Store`, ordenable por `Popularity`. Instalas con un clic (algunas requieren `Jython`/`Jruby` o son Pro-only):

![BApp Store de Burp con extensiones ordenables por popularidad; Active Scan++ destacado.](https://academy.hackthebox.com/storage/modules/110/burp_bapp_store.png)

# Las extensiones que importan (bug bounty 2026)

| Extensión | Para qué | Tema del PKM |
| - | - | - |
| <mark style="background: #FFB86CA6;">**Param Miner**</mark> | Descubre parámetros y cabeceras ocultos (cache poisoning, mass assignment) | [[09 - Bypass de autenticación - modificación de parámetros\|param tampering]] |
| <mark style="background: #FFB86CA6;">**Turbo Intruder**</mark> | Fuzzing rapidísimo y scriptable; *single-packet attack* HTTP/2 | [[05 - Defensas y evasión\|race conditions]] |
| **Autorize** | Reenvía cada petición con sesión de menor privilegio → detecta IDOR/bypass automáticamente | [[13 - Herramientas para IDOR\|authz testing]] |
| **JWT Editor** | Editar, firmar y atacar JWT en Repeater/Intruder | [[06 - Herramientas JWT y prevención\|JWT]] |
| **Active Scan++** | Extiende el scanner con checks adicionales | [[09 - Escáner de vulnerabilidades - Burp y ZAP Scanner\|scanner]] |
| **Backslash Powered Scanner** | Descubre clases de vulnerabilidad **desconocidas** por comportamiento | — |
| **Collaborator Everywhere** | Inyecta payloads OOB en todo el tráfico (SSRF/blind) | [[04 - Blind SSRF\|OOB]] |
| **Hackvertor** | Transformaciones/encoding por etiquetas dentro de la petición | [[06 - Codificación y decodificación\|encoding]] |
| **Retire.js** · **Software Vulnerability Scanner** | Detecta librerías JS y componentes vulnerables | — |
| **InQL** | Auditoría de GraphQL | [[00 - Introducción a las API Attacks\|APIs]] |

> [!important]+ Bambdas: el scripting moderno de Burp
> Desde 2023 Burp incluye **Bambdas**: snippets de Java que filtran el proxy/historial, definen reglas de Match & Replace dinámicas o resaltan peticiones según lógica propia, sin escribir una extensión completa. <mark style="background: #8000E1A6;">Es la forma actual de personalizar Burp</mark> para un objetivo concreto (p. ej. resaltar toda petición con un parámetro `redirect` para cazar [[08 - Robo de tokens de acceso OAuth\|open redirects]]).

# ZAP Marketplace

`Manage Add-ons > Marketplace`. Add-ons en estado `Release` (estable) o `Beta/Alpha`. Útiles: el **Ajax Spider**, y wordlists como **FuzzDB** que enriquecen el [[08 - Fuzzing web - Burp Intruder y ZAP Fuzzer|fuzzer]] (`fuzzdb > attack > os-cmd-execution` para command injection). ZAP, al ser open-source, recibe muchas de las features que en Burp son de pago.

> [!info]+ Fuentes
> - [BApp Store](https://portswigger.net/bappstore) · [ZAP Marketplace](https://www.zaproxy.org/addons/) · [Bambdas](https://portswigger.net/burp/documentation/desktop/bambdas)
