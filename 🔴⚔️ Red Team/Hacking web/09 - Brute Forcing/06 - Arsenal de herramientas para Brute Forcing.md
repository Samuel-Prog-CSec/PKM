---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Brute-Forcing
Fecha de actualización: 2026-06-23
Nota previa: "[[05 - Defensas y evasión]]"
Nota siguiente:
Area: "[[Brute Forcing.base|Brute Forcing]]"
---
El instrumental del brute force ordenado por función. La regla de oro: <mark style="background: #ADCCFFA6;">Hydra/Medusa para protocolos de red; Burp/ffuf para web</mark>. Lo demás es soporte (generar wordlists, rotar IP, crackear hashes capturados).

# Cracking de logins online

| Herramienta | Qué aporta |
| - | - |
| **Hydra** ([thc-hydra](https://github.com/vanhauser-thc/thc-hydra)) | El más versátil en protocolos: SSH, FTP, RDP, SMTP, BBDD + web. Ver [[02 - Hydra]] |
| **Medusa** ([jmk-foofus](https://github.com/jmk-foofus/medusa)) | Multi-host (`-H`) y estable en paralelo. `-e ns` para vacías/iguales. Ver [[03 - Medusa y alternativas modernas]] |
| **ffuf** ([ffuf](https://github.com/ffuf/ffuf)) | El mejor para formularios web: control total de petición, `clusterbomb`/`pitchfork`, filtros |
| **patator** ([lanjelot](https://github.com/lanjelot/patator)) | El más flexible: pre-petición para scrapear tokens CSRF, condiciones complejas, módulos a medida |
| **ncrack** ([nmap](https://github.com/nmap/ncrack)) | Cracking de red a escala (RDP, SSH); integra con la salida de Nmap |
| **crowbar** ([galkan](https://github.com/galkan/crowbar)) | OpenVPN, RDP y SSH con autenticación por clave |
| **OpenBullet 2** ([repo](https://github.com/openbullet/OpenBullet2)) | La suite de facto de **credential stuffing**: combos de brechas + proxies residenciales + granjas de CAPTCHA |

<mark style="background: #FFB86CA6;">`patator` es la respuesta cuando Hydra/ffuf no llegan</mark>: su capacidad de hacer una petición previa, extraer un token de la respuesta y reinyectarlo resuelve los formularios con `CSRF` rotativo que tumban a los demás.

# Burp Suite: el estándar de web

| Módulo | Uso |
| - | - |
| **Intruder** | Brute force de formularios; *Cluster bomb* (user×pass), *Pitchfork* (alineado) |
| **Intruder + recursive grep** | Extrae el token `CSRF` de cada respuesta y lo reinyecta — resuelve formularios protegidos |
| **Turbo Intruder** ([repo](https://github.com/PortSwigger/turbo-intruder)) | Miles de peticiones/seg; *single-packet attack* HTTP/2 para [[05 - Defensas y evasión|race conditions]] anti-lockout |
| **IP-Rotate** ([repo](https://github.com/PortSwigger/IP-Rotate)) | Extensión que rota la IP de origen vía AWS API Gateway desde Burp |

# Enumeración de usuarios y OSINT

| Herramienta | Qué aporta |
| - | - |
| **username-anarchy** ([repo](https://github.com/urbanadventurer/username-anarchy)) | Permutaciones de usuario a partir de nombre y apellido |
| **linkedin2username** ([repo](https://github.com/initstring/linkedin2username)) | Empleados de LinkedIn → usuarios con el esquema corporativo |
| **CeWL** ([repo](https://github.com/digininja/CeWL)) | Rastrea la web objetivo y cosecha su vocabulario (y correos con `-e`) |
| **Kerbrute** ([repo](https://github.com/ropnop/kerbrute)) | Enum y spraying de usuarios contra Active Directory (Kerberos), sin disparar lockouts ruidosos |

# Password spraying contra Microsoft 365 / Entra / AD

El spraying real contra organizaciones hoy va casi siempre contra portales cloud de Microsoft (OWA, O365, Entra ID). Ecosistema dedicado y mantenido:

| Herramienta | Qué aporta |
| - | - |
| <mark style="background: #FFB86CA6;">**TREVORspray**</mark> ([repo](https://github.com/blacklanternsecurity/TREVORspray)) | El más completo: rotación de IP por SSH, detección de MFA/lockout/usuario-válido por cuenta, resume automático |
| **MSOLSpray** ([repo](https://github.com/dafthack/MSOLSpray)) | Clásico Azure/O365: reporta cred válida, MFA, tenant inexistente o cuenta bloqueada |
| **Spray365** ([repo](https://github.com/MarkoH17/Spray365)) | Spraying en dos pasos que evade Smart Lockout y conditional access |
| **entraspray** ([repo](https://github.com/dunderhay/entraspray)) | Sucesor moderno enfocado a Entra ID |
| <mark style="background: #FF5582A6;">**MFASweep**</mark> ([repo](https://github.com/dafthack/MFASweep)) | No es spray: comprueba a qué servicios MS entran unas creds **sin MFA** (el MFA suele estar mal aplicado por servicio) |

# Generación de wordlists

| Herramienta | Qué aporta |
| - | - |
| **psudohash** ([repo](https://github.com/t3l3machus/psudohash)) | Sustituto moderno de CUPP: mutaciones realistas dirigidas a una persona |
| **Mentalist** ([repo](https://github.com/sc0tfree/mentalist)) | GUI por grafos; exporta wordlist o reglas de `hashcat` |
| **pydictor** ([repo](https://github.com/LandGrey/pydictor)) | Generador configurable con plugins e ingeniería social |
| **crunch** | Genera por charset/longitud/patrón (máscaras) |
| **hashcat `--stdout`** | Aplica reglas (`best64`, `OneRuleToRuleThemAll`) para mutar una base. Ver [[01 - Tipos de ataque - diccionario, híbrido y máscara]] |
| **CUPP** ([repo](https://github.com/Mebus/cupp)) | El clásico OSINT-driven; útil pero ruidoso |

# Evasión y rotación de IP

| Herramienta | Qué aporta |
| - | - |
| **fireprox** ([repo](https://github.com/ustayready/fireprox)) | Endpoint AWS API Gateway que rota la IP en cada petición — ojo a la [[05 - Defensas y evasión\|política de AWS]] |
| **OmniProx** ([repo](https://github.com/ZephrFish/OmniProx)) | Reemplazo multi-cloud de fireprox (AWS/Azure/GCP/Cloudflare) |
| **requests-ip-rotator** ([repo](https://github.com/Ge0rg3/requests-ip-rotator)) | La misma rotación desde un script Python `requests` |

# Crackeo offline (hashes capturados)

Cuando obtienes hashes (volcado de BBDD vía [[02 - Subvertir la lógica de consulta|SQLi]], `/etc/shadow`, NetNTLM), el ataque pasa a offline y multiplica la velocidad:

| Herramienta | Qué aporta |
| - | - |
| **hashcat** ([repo](https://github.com/hashcat/hashcat)) | El cracker GPU de referencia: diccionario, reglas, máscara, híbrido |
| **John the Ripper** ([repo](https://github.com/openwall/john)) | Jumbo: cientos de formatos, modo `--rules` y `--single` |

<mark style="background: #FFB86CA6;">Caso web de alto valor: crackear el secreto de un `JWT` HS256 capturado</mark> — `hashcat -m 16500 jwt.txt jwt.secrets.list`. Con la clave recuperada forjas tokens arbitrarios (escalada a admin). Solo aplica a algoritmos simétricos; lo desarrolla [[03 - Ataque al secreto de firma JWT]].

# Flujo de referencia

```text
Enum usuarios (username-anarchy / Kerbrute / CeWL)
   → inferir esquema → wordlist dirigida (psudohash / hashcat rules)
   → filtrar a la política
   → ATAQUE: ffuf/Burp Intruder (web) · Hydra/Medusa/ncrack (red)
       └─ ¿protegido? → fireprox (rotar IP) · Turbo Intruder (race/HTTP2) · patator (token)
   → ¿hashes capturados? → hashcat/John (offline)
```

> [!info]+ Fuentes y repos
> - Online: [Hydra](https://github.com/vanhauser-thc/thc-hydra) · [Medusa](https://github.com/jmk-foofus/medusa) · [ffuf](https://github.com/ffuf/ffuf) · [patator](https://github.com/lanjelot/patator) · [ncrack](https://github.com/nmap/ncrack)
> - Burp: [Turbo Intruder](https://github.com/PortSwigger/turbo-intruder) · [IP-Rotate](https://github.com/PortSwigger/IP-Rotate)
> - Wordlists/OSINT: [psudohash](https://github.com/t3l3machus/psudohash) · [Mentalist](https://github.com/sc0tfree/mentalist) · [pydictor](https://github.com/LandGrey/pydictor) · [CeWL](https://github.com/digininja/CeWL) · [Kerbrute](https://github.com/ropnop/kerbrute)
> - Spraying cloud: [TREVORspray](https://github.com/blacklanternsecurity/TREVORspray) · [MSOLSpray](https://github.com/dafthack/MSOLSpray) · [Spray365](https://github.com/MarkoH17/Spray365) · [MFASweep](https://github.com/dafthack/MFASweep)
> - Evasión: [fireprox](https://github.com/ustayready/fireprox) · [OmniProx](https://github.com/ZephrFish/OmniProx) · [requests-ip-rotator](https://github.com/Ge0rg3/requests-ip-rotator) · stuffing: [OpenBullet 2](https://github.com/openbullet/OpenBullet2)
> - Offline: [hashcat](https://github.com/hashcat/hashcat) · [John the Ripper](https://github.com/openwall/john)
