---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - TLS
  - Tipo/Deteccion
Descripción: "Esta es la nota operativa del módulo: en un pentest real casi nunca explotas los ataques anteriores; auditas la configuración y reportas lo que la habilita"
Fecha de actualización: 2026-07-14
Nota previa: "[[10 - Downgrade Attacks]]"
Nota siguiente: ""
Area: "[[HTTPs-TLS.base|HTTPs/TLS]]"
---
---

Esta es la nota operativa del módulo: <mark style="background: #ADCCFFA6;">en un pentest real casi nunca explotas los ataques anteriores; **auditas la configuración** y reportas lo que la habilita</mark>. Una config TLS mala no solo arriesga al servidor, sino a **todos** los clientes que se conectan a él. El objetivo es un veredicto rápido, reproducible y con severidad justificada.

# Arsenal de herramientas

HTB solo enseña `testssl.sh`. Este es el conjunto que se usa de verdad, según el escenario:

| Herramienta | Tipo | Cuándo usarla |
| - | - | - |
| **testssl.sh** | Bash, exhaustiva | Auditoría profunda de **un** host: protocolos, ciphers, cert, vulns con nombre y grado SSL Labs |
| **sslscan** | C, rápida | Enumeración veloz de protocolos/ciphers en consola |
| **sslyze** | Python, scriptable | Automatización/CI, salida **JSON**, escanear **muchos** hosts en paralelo |
| **nmap** `ssl-*` | NSE | Dentro de un escaneo general (`ssl-enum-ciphers`, `ssl-cert`, `ssl-heartbleed`, `ssl-dh-params`) |
| **tlsx** (ProjectDiscovery) | Go, masiva | **Recon a escala** en bug bounty: SAN, versiones, JARM; encadena con `subfinder`/`httpx` |
| **Qualys SSL Labs** | Web | Grado autoritativo A+…F (solo objetivos **públicos**) |

```shell-session
# testssl.sh — auditoría completa con salida para el informe
$ testssl.sh --jsonfile out.json https://target.htb

# sslscan — vistazo rápido de protocolos y ciphers
$ sslscan target.htb

# sslyze — JSON, ideal para pipelines y muchos hosts
$ sslyze --json_out out.json target.htb:443

# nmap — dentro del escaneo de red
$ nmap -p443 --script ssl-enum-ciphers,ssl-cert target.htb

# tlsx — recon masivo: saca SAN de miles de hosts (subdominios ocultos)
$ subfinder -d target.com -silent | tlsx -san -resp-only -silent
```

> [!info] tlsx y JARM para recon ofensivo
> `tlsx` no es solo para auditar: extraer los `subjectAltName` de todo un rango revela <mark style="background: #FFB86CA6;">subdominios y hostnames internos</mark> que no salen por fuerza bruta de DNS (complementa los [[01 - Infraestructura de Clave Pública (PKI)|CT logs]]). El fingerprint **JARM** identifica el stack TLS del servidor (útil para agrupar infraestructura o detectar C2). Es de las técnicas de recon más rentables en bug bounty.

# Interpretar la salida de testssl.sh

La herramienta agrupa exactamente los ataques de este módulo. Lo que buscas:

```text
SSLv2 / SSLv3         not offered (OK)          ← si "offered" → DROWN / POODLE
TLS 1 / TLS 1.1       offered (deprecated)      ← hallazgo: versiones muertas
NULL / EXPORT / LOW   not offered (OK)          ← si offered → FREAK, cifradores rotos
Triple DES            offered                   ← SWEET32
Forward Secrecy (AEAD) offered (OK)             ← bien: ECDHE + GCM

Heartbleed / ROBOT / CRIME / POODLE   not vulnerable (OK)

Overall Grade  B
Grade cap reasons: TLS 1.1 offered · TLS 1.0 offered · HSTS not offered
```

<mark style="background: #FF5582A6;">El **grado** y sus "cap reasons" son oro para el informe</mark>: traducen la config a severidad. Un grado B por soportar TLS 1.0/1.1 y no tener [[08 - SSL Stripping|HSTS]] son típicamente hallazgos *low*; un grado F (SSLv3, RC4, cert inválido) escala la severidad. La sección de certificado te da `CN`/`SAN`, algoritmo de firma, tamaño de clave y validez — todo lo que revisas en [[01 - Infraestructura de Clave Pública (PKI)|PKI]].

# Gestión de claves (base de todo)

Antes de la config TLS, los principios NIST de manejo de claves que también se auditan:

- <mark style="background: #ADCCFFA6;">Una clave, **un solo propósito**</mark> (cifrado, firma o autenticación) — limita el impacto de un compromiso.
- **Cryptoperiods**: las claves expiran y se rotan; una clave comprometida se reemplaza de inmediato.
- Generación **fuerte**, nunca almacenada en claro, **separada** del dato que protege, **sin** claves hardcodeadas, y **sin** cripto casera (solo algoritmos estándar).

# Hardening: la configuración correcta

**Versiones** — solo TLS 1.2 y 1.3; SSL 2.0/3.0 jamás:

```text
# Apache (ssl.conf)
SSLProtocol -all +TLSv1.2 +TLSv1.3
# Nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

**Cipher suites** — ni `NULL` ni `EXPORT`; preferir PFS (`ECDHE`/`DHE`, todos los de 1.3) y `GCM` sobre `CBC`:

```text
# Nginx — baseline moderno con forward secrecy y AEAD
ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers on;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

> [!success] No inventes la config: genérala
> La referencia de la industria es el <mark style="background: #FF5582A6;">**Mozilla SSL Configuration Generator**</mark>: produce configs listas para Apache/Nginx/HAProxy en tres perfiles (**Modern** = solo TLS 1.3; **Intermediate** = 1.2+1.3, el recomendado general; **Old** = compatibilidad con clientes antiguos). En el informe, recomienda el perfil *Intermediate* de Mozilla y añade OCSP stapling y HSTS. Para el veredicto, apóyate en **Qualys SSL Labs** y en NIST SP 800-52r2.

> [!warning] Automatización y bug bounty
> Para muchos objetivos, integra `sslyze --json` o `testssl.sh --jsonfile` en el pipeline, o usa plantillas `nuclei` de la categoría `ssl` (`tls-version`, `weak-cipher-suites`, `expired-ssl`, `deprecated-tls`) para triage masivo antes de la revisión manual:
> ```shell-session
> $ nuclei -tags ssl,tls -u https://target.htb
> ```

Con esto se cierra el módulo: has visto los ataques ([[03 - Padding Oracle Attacks|padding oracle]], [[06 - Ataques de compresión (CRIME y BREACH)|compresión]], [[07 - Heartbleed|Heartbleed]], [[10 - Downgrade Attacks|downgrade]]) y ahora sabes **detectarlos, puntuarlos y corregirlos** con herramientas actuales.

## Referencias

- [testssl.sh](https://testssl.sh/) · [sslyze](https://github.com/nabla-c0d3/sslyze) · [sslscan](https://github.com/rbsec/sslscan) · [tlsx](https://github.com/projectdiscovery/tlsx)
- [Mozilla SSL Config Generator](https://ssl-config.mozilla.org/) · [Qualys SSL Labs](https://www.ssllabs.com/ssltest/)
- [NIST SP 800-52r2 — Guidelines for TLS](https://csrc.nist.gov/pubs/sp/800/52/r2/final)
