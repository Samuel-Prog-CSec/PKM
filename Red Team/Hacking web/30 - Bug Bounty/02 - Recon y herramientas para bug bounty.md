---
tags:
  - Web/Red-Team
  - Bug-Bounty
  - Pentesting/Enumeracion
Descripción: "El módulo original no cubre la parte que más determina el éxito en bug bounty: el recon"
Fecha de actualización: 2026-07-27
Nota previa: "[[01 - Reglas, legalidad y conducta]]"
Nota siguiente: "[[03 - Metodología de caza - mapear y atacar la aplicación]]"
Area: "[[Bug Bounty.base|Bug Bounty]]"
---
---

El módulo original no cubre la parte que más determina el éxito en bug bounty: el **recon**. En un scope amplio (`*.dominio.com`), <mark style="background: #FFB86CA6;">el que encuentra más superficie de ataque encuentra más bugs</mark>. La metodología de referencia es *The Bug Hunter's Methodology* (TBHM) de Jason Haddix: **descubrir activos → descubrir contenido → identificar vulnerabilidades**.

# El pipeline de recon

| Fase | Herramientas | Qué hace |
| - | - | - |
| Enum de subdominios | `subfinder`, `amass`, `assetfinder`, `chaos` | Descubre subdominios (pasivo) |
| Enum vía certificados | `crt.sh` (CT logs), `tlsx` | Subdominios y hosts internos que aparecen en los certificados — de las técnicas de recon más rentables (ver [[01 - Infraestructura de Clave Pública (PKI)|CT logs]]) |
| Resolución y sondeo | `dnsx`, `httpx` | Resuelve y filtra los vivos; tecnología, título, status |
| Puertos | `naabu` | Escaneo rápido de puertos |
| Descubrimiento de contenido | `ffuf`, `feroxbuster`, `katana`, `gau`, `waybackurls`, `waymore` | Directorios, endpoints y URLs históricas |
| Análisis de JS | `LinkFinder`, `getJS`, `nuclei` | Endpoints y secretos ocultos en JavaScript |
| Identificación de vulns | `nuclei`, Burp/Caido | Plantillas de CVE + testing manual |
| Triaje visual | `gowitness`, `aquatone` | Screenshots masivos para priorizar |

La mayoría del ecosistema moderno es de [**ProjectDiscovery**](https://github.com/projectdiscovery) (`subfinder`, `httpx`, `dnsx`, `naabu`, `katana`, `nuclei`) y de [**tomnomnom**](https://github.com/tomnomnom) (`waybackurls`, `assetfinder`, `gf`). Ojo con las guías antiguas: <mark style="background: #FFB8EBA6;">`aquatone` y `EyeWitness` están prácticamente **sin mantener**</mark> — para screenshots masivos usa `gowitness` (o los templates *headless* de `nuclei`).

# El one-liner que lo encadena

La fuerza está en encadenar herramientas por *stdin/stdout*:

```shell-session
$ subfinder -d target.com -silent | httpx -silent | nuclei -tags cve,exposure
```

Descubre subdominios → filtra los que responden → los pasa por las plantillas de `nuclei`. Variantes: añadir `katana`/`gau` para URLs, o `nuclei -t` con plantillas propias.

> [!important]+ El recon no sustituye el trabajo manual
> La automatización **expande la superficie**; los bugs que pagan bien salen del **testing manual** de la lógica de negocio con [[13 - Flujo profesional y alternativas modernas|Burp o Caido]]. `nuclei` encuentra CVEs conocidas (que suelen ser duplicados o *out-of-scope*); tú buscas lo que el escáner no ve: IDOR, fallos de autorización, *race conditions*, lógica rota. Registra **todo** el proceso — lo necesitarás para el PoC del [[05 - Escribir un buen reporte|reporte]].

> [!info]+ Frameworks de automatización
> Para no orquestar a mano, hay *frameworks* que encadenan todo el pipeline: [`reconftw`](https://github.com/six2dez/reconftw), [`reNgine`](https://github.com/yogeshojha/rengine) y [`Osmedeus`](https://github.com/j3ssie/osmedeus). Útiles para *continuous recon* (monitorizar un scope amplio en el tiempo y cazar activos nuevos en cuanto aparecen), pero conviene entender cada herramienta por separado antes de delegar en el framework.

El recon expande la superficie; ahora hay que convertirla en bugs. La metodología para mapear y atacar la aplicación de forma sistemática: [[03 - Metodología de caza - mapear y atacar la aplicación]].
