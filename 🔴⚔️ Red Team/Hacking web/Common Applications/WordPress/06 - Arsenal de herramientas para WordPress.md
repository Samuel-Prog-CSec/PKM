---
tags:
  - Web/Red-Team
  - WordPress
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-17
Nota previa: "[[05 - Detección y evasión en WordPress]]"
Nota siguiente: "[[07 - Hardening de WordPress]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Set de herramientas actuales para atacar WordPress, organizado por **propósito**. Ninguna sustituye a las demás: el flujo real combina detección sigilosa, correlación de CVEs y explotación manual.

| Herramienta | Tipo | Mejor para |
| - | - | - |
| `wpscan` | Enumeración + vuln mapping | Inventario autoritativo y fuerza bruta xmlrpc |
| `nuclei` | Detección de CVEs | Detección masiva de fallos conocidos |
| `wpprobe` | Enumeración de plugins | Enum sigilosa que evade el brute-force |
| `wafw00f` | Fingerprint de WAF | Saber qué defensa hay delante |
| CMSeeK / WPintel | Recon | Primer *fingerprint* rápido / manual |
| `waybackurls`,`gau` | Recon pasivo | Rutas y versiones olvidadas |
| Burp / Caido | Explotación manual | *Tampering* de REST/xmlrpc + logging |
| Metasploit | Explotación | RCE automatizado con credenciales |

# Detección y enumeración

## `wpscan`

El estándar. Mantenido por **Automattic/Jetpack** desde 2021, con API v4 y una base de 60.000+ vulnerabilidades ([wpscan.com](https://wpscan.com/)). Enumera versión, plugins, temas y usuarios, y fuerza credenciales.

```shell-session
$ wpscan --url https://target --enumerate vp,vt,u --api-token <TOKEN>
$ wpscan --url https://target --passwords rockyou.txt --usernames admin --password-attack xmlrpc -t 20
```

Flags de `--enumerate`: `vp` (plugins vulnerables), `ap` (todos los plugins), `vt`/`at` (temas), `u` (usuarios), `cb`/`dbe` (backups de config).

> [!important]+ El API token y su límite real
> Sin `--api-token`, WPScan detecta versiones pero **no correlaciona vulnerabilidades**. El token es gratis registrándote en [wpscan.com/register](https://wpscan.com/register). Ojo al límite actual: <mark style="background: #FF5582A6;">la capa gratuita da 25 peticiones/día</mark>, no 50 — el "50/día" que circula es un valor retirado de un blog de 2023 ([pricing actual](https://wpscan.com/pricing/)). Se consume **una petición por cada** versión, plugin y tema consultados, así que agota rápido: reserva el token para objetivos priorizados. La antigua marca *WPVulnDB* está retirada.

## `nuclei`

El motor de plantillas de ProjectDiscovery para detección de CVEs conocidas a escala:

```shell-session
$ nuclei -u https://target -tags wordpress          # ~1.261 plantillas del repo oficial
$ nuclei -u https://target -tags wordpress,kev       # solo CVEs explotadas in-the-wild
$ nuclei -u https://target -t nuclei-wordfence-cve/  # 75k+ plantillas auto-generadas de Wordfence
```

<mark style="background: #ADCCFFA6;">El set [`topscoder/nuclei-wordfence-cve`](https://github.com/topscoder/nuclei-wordfence-cve) da 75.000+ plantillas</mark> derivadas de la inteligencia de Wordfence — cobertura muy superior al repo base para plugins.

## `wpprobe` — el enumerador sigiloso (2025)

La herramienta moderna que cambia el juego en la enumeración de plugins. Escrita en Go por [Chocapikk](https://github.com/Chocapikk/wpprobe), <mark style="background: #FFB86CA6;">infiere plugins abusando de la REST API</mark> (`?rest_route=/`): compara las rutas expuestas contra una base de firmas de **5.000+ plugins**, sin fuerza bruta de rutas. Ya viene empaquetada en Kali.

```shell-session
$ wpprobe update-db
$ wpprobe scan -u https://target --mode stealthy    # stealthy | bruteforce | hybrid
```

Mapea los hallazgos a CVEs de Wordfence+WPScan y exporta CSV/JSON, sin API key. Su ventaja: <mark style="background: #8000E1A6;">evade la detección de brute-force</mark> porque no sondea rutas a ciegas — encaja con lo visto en [[05 - Detección y evasión en WordPress]].

> [!warning]+ Gotcha de `wpprobe`
> Cambios recientes en la API de Wordfence dejaron el `update-db` roto en versiones antiguas de `wpprobe`. Actualiza el binario antes de fiarte de su base de firmas de plugins.

# Recon pasivo

`wafw00f https://target` identifica el WAF de borde. Para expandir superficie sin tocar el objetivo, minar archivos históricos:

```shell-session
$ waybackurls target.com | grep -E 'wp-content/plugins/[^/]+' | sort -u
$ gau target.com | grep '?ver='
```

Revelan **plugins retirados pero aún en disco** y versiones antiguas (`?ver=`) que delatan software sin parchear. `CMSeeK` da un *fingerprint* CMS de primera pasada y la extensión de navegador `WPintel` hace recon manual mientras navegas.

# Explotación

**Burp / Caido** para el trabajo manual: *tampering* de peticiones REST y xmlrpc, montar los *header spoof* tipo WooCommerce ([[03 - Explotación de plugins vulnerables]]), y registro de todo para el reporte. **Metasploit** automatiza el RCE con credenciales válidas (`wp_admin_shell_upload`, [[04 - RCE como administrador en WordPress]]).

> [!info]+ Reparto por propósito
> **Detección** → `nuclei`, `wpprobe`, `wpscan`. **Explotación** → Burp/Caido + PoCs, Metasploit. **Recon y registro** → `WPintel`, `CMSeeK`, `waybackurls`/`gau`. Encadenar los tres es lo que distingue un escaneo de un pentest.

Cerramos el sub-tema con la cara defensiva — saber endurecer un WordPress es saber qué buscar para romperlo: [[07 - Hardening de WordPress]].
