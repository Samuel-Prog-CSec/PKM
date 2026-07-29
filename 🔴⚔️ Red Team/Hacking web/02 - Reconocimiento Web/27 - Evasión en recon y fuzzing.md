---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
  - Fuzzing
Descripción: "El recon y el fuzzing a escala generan mucho tráfico, y eso choca de frente con las defensas perimetrales"
Fecha de actualización: 2026-06-13
Nota previa: "[[26 - Escaneo dirigido con nuclei]]"
Nota siguiente:
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

El recon y el fuzzing a escala generan **mucho** tráfico, y eso choca de frente con las defensas perimetrales: WAFs, *rate limiting* y baneo de IP. <mark style="background: #ADCCFFA6;">La evasión en esta fase no es de payload —eso pertenece a cada vulnerabilidad— sino de **volumen y huella**</mark>: cómo lanzar miles de peticiones sin que te corten ni te delaten. Esta nota reúne la doctrina que en el resto del sub-tema aparece como avisos sueltos ([[09 - Fingerprinting web|fingerprinting]], [[17 - Fuzzing de directorios y archivos|dirs]], [[18 - Fuzzing recursivo|recursivo]], [[26 - Escaneo dirigido con nuclei|nuclei]]).

# Primero, identificar la defensa

No se evade a ciegas. Antes de subir el ritmo, determina qué hay enfrente:

- **`wafw00f`** para confirmar y *fingerprintear* el WAF (parte del [[09 - Fingerprinting web|fingerprinting]]).
- **Lee las respuestas**: un `403`/`406` súbito = WAF; un `429 Too Many Requests` = rate-limit; un *captcha* o un *tarpitting* (respuestas que se ralentizan) = protección anti-automatización. <mark style="background: #FF5582A6;">Cada síntoma pide una contramedida distinta</mark>: el `429` se trata bajando ritmo o rotando IP; el `403` del WAF, cambiando la huella de la petición.

# Control de ritmo

La primera palanca, y la que más baneos evita, es **bajar y aleatorizar** el volumen:

| Herramienta | Limitar ritmo | Concurrencia | Jitter / delay |
| - | - | - | - |
| `ffuf` | `-rate 50` | `-t 10` | `-p 0.1-2.0` (delay aleatorio) |
| `feroxbuster` | `--rate-limit 50` | `-t 10` | `--rate-limit` + scan-limit |
| `nuclei` | `-rl 50` | `-c 10` | — |

<mark style="background: #FFB8EBA6;">El `jitter` (delay aleatorio entre peticiones) es clave</mark>: un patrón de peticiones perfectamente regular grita "bot". `ffuf -p 0.1-2.0` introduce una pausa variable que imita tráfico humano y diluye la firma temporal.

# Rotación: IP, User-Agent y cabeceras

Cuando el límite es **por IP**, hay que repartir el origen:

- **Rotación de IP real**: `fireprox` levanta un AWS API Gateway que rota la IP de origen en cada petición. <mark style="background: #FF5582A6;">Aviso</mark>: su propio README advierte que usarlo contra sistemas que no son tuyos "probablemente viola la AWS Acceptable Use Policy y puede llevar a la suspensión de tu cuenta AWS" — riesgo real a mitad de un engagement; además AWS publica sus rangos IP, así que un WAF serio bloquea el tráfico de API Gateway en bloque. `fireprox` está sin commits desde abril-2023; el sucesor multi-cloud es <mark style="background: #ADCCFFA6;">`OmniProx`</mark> (Azure/GCP/Cloudflare/Alibaba — no AWS). Alternativa: distribuir el escaneo con `axiom` entre varias VMs efímeras (ver [[14 - Automatización del recon|automatización]]); `--proxy` con una lista de proxies, o `Tor` (lento, último recurso).
- **`X-Forwarded-For` spoofing**: algunos rate-limits y controles de acceso confían en cabeceras de IP de cliente. Inyectar `X-Forwarded-For`/`X-Real-IP` con valores variables a veces salta el contador por IP sin cambiar de origen real. <mark style="background: #8000E1A6;">Barato de probar y sorprendentemente efectivo en backends mal configurados</mark>.
- **Rotación de `User-Agent`**: alternar UAs de navegadores reales reduce el bloqueo por firma.

# La huella de la herramienta

Las herramientas se delatan solas: <mark style="background: #FFB86CA6;">`ffuf` y `nuclei` envían un `User-Agent` por defecto reconocible</mark> (`Fuzz Faster U Fool`, `Nuclei - Open-source...`) que cualquier WAF tiene en su lista negra. Sobrescríbelo siempre con uno realista:

```shell-session
$ ffuf -u https://target.htb/FUZZ -w wordlist.txt -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -rate 30 -p 0.1-1.5
```

# Cuándo NO evadir

> [!warning]+ Las reglas del programa mandan sobre el sigilo
> En bug bounty, evadir el rate-limit puede **violar las normas del programa** y costarte la recompensa o el acceso. <mark style="background: #FF5582A6;">Muchos programas piden explícitamente respetar los límites y no usar escaneo agresivo</mark>. La evasión de volumen es para pentest autorizado con objetivo de cobertura, o cuando el programa lo permite. Si las reglas exigen prudencia, baja el ritmo y acepta que el recon tarde más — un baneo te deja sin objetivo, y saltarte las reglas, sin pago.

> [!info]+ Fuentes y herramientas
> - [wafw00f](https://github.com/EnableSecurity/wafw00f) · [fireprox](https://github.com/ustayready/fireprox) (AWS API Gateway; abandonado desde 2023) · [OmniProx](https://github.com/ZephrFish/OmniProx) (multi-cloud) · [axiom](https://github.com/pry0cc/axiom)
> - [ffuf wiki](https://github.com/ffuf/ffuf/wiki) (flags `-rate`/`-p`) · [nuclei rate limiting](https://docs.projectdiscovery.io/tools/nuclei/running#rate-limit)

Con la superficie mapeada, escaneada y la metodología de evasión clara, termina la fase de descubrimiento. El siguiente paso del path es **explotar** lo encontrado —[[00 - Introducción a SQL Injection|inyección]], [[00 - Introducción a XSS|XSS]], [[00 - Introducción a Command Injection|command injection]], autenticación y lógica— sobre el mapa de endpoints y parámetros que estas notas han construido.
