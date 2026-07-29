---
tags:
  - Go
  - Go/Arsenal
  - Herramientas
Descripción: "La otra cara del arsenal: no las librerías para construir, sino las herramientas ya hechas"
Fecha de actualización: 2026-07-25
Nota previa: "[[00 - Arsenal de librerías Go ofensivas]]"
Nota siguiente: "[[02 - OPSEC del binario Go]]"
Area: "[[Arsenal y OPSEC.base|Arsenal y OPSEC]]"
---
---

La otra cara del arsenal: no las librerías para construir, sino las **herramientas ya hechas**. Y aquí hay un patrón difícil de ignorar — <mark style="background: #ADCCFFA6;">buena parte del tooling de pentest y bug bounty moderno está escrito en Go</mark>. No es casualidad: encaja con exactamente lo que este libro enseña.

## Por qué Go domina el tooling moderno

Tres propiedades de Go que lo hacen ideal para herramientas ofensivas:

- **Binario estático cross-platform**: `GOOS=windows go build` desde tu Linux te da un `.exe` sin dependencias. Distribuyes un único fichero que corre en cualquier caja — sin runtime de Python, sin DLLs.
- **Concurrencia barata**: goroutines + channels hacen trivial escanear miles de hosts o fuzzear miles de rutas en paralelo (el patrón de [[01 - Escáner TCP - de secuencial a concurrente]]). El recon a escala de bug bounty vive de esto.
- **Velocidad de C, ergonomía alta**: rápido para el trabajo pesado (parseo, red), pero cómodo de escribir y mantener.

## El arsenal por categoría

| Categoría | Herramientas (Go) | Uso |
| - | - | - |
| **Recon / subdominios** | `subfinder`, `amass`, `dnsx` | Enumeración pasiva y activa de subdominios y DNS |
| **Probing HTTP** | `httpx` | Sondear hosts vivos, tech-detection, títulos, códigos |
| **Crawling** | `katana` | Spidering moderno (headless, JS-aware) |
| **Port scanning** | `naabu` | Escáner de puertos rápido (SYN/CONNECT) |
| **Fuzzing web** | `ffuf`, `gobuster` | Descubrimiento de rutas, vhosts, parámetros |
| **Escaneo de vulns** | `nuclei` | Scanner por *templates* YAML — el estándar de facto en BB |
| **Pivoting / túneles** | `chisel`, `ligolo-ng` | Túneles y pivoting sobre redes restringidas |
| **OOB / interacción** | `interactsh` | Detección de vulnerabilidades *out-of-band* (SSRF, blind) |
| **C2 (Red Team)** | `sliver`, `merlin` | Frameworks C2 open-source, alternativa a Cobalt Strike |

<mark style="background: #FFB86CA6;">La suite de ProjectDiscovery</mark> (`subfinder`, `httpx`, `naabu`, `nuclei`, `katana`, `dnsx`) es, en la práctica, el *pipeline* de recon de bug bounty en 2026 — y toda ella es Go, encadenable por stdin/stdout precisamente por el diseño de binario único.

## Encaje con el PKM

Estas herramientas ya tienen (o tendrán) su tratamiento a fondo en el vault, donde toca:

- **`ffuf`** → [[00 - Introducción a ffuf]] (herramienta completa en Tools).
- **`naabu`** es a un port scan lo que este libro construye a mano; para el escaneo serio y sigiloso sigue mandando **`nmap`** → [[00 - Introducción a Nmap]]. `naabu` descubre rápido, `nmap -sV` confirma.
- **`ligolo-ng`** y **`chisel`** → el pivoting y *tunneling* a fondo es Pentesting (`007 - Pivoting y túneles`).

> [!important]+ Construir vs usar
> Este proyecto (Black Hat Go) enseña a **construir** tus propias herramientas. El día a día usa las de la tabla — pero saber cómo funcionan por dentro (por qué `naabu` acota la concurrencia, cómo `nuclei` estructura sus *templates*, qué hace `ligolo-ng` con las interfaces `TUN`) es lo que te deja <mark style="background: #8000E1A6;">extenderlas, depurarlas o escribir la pieza que ninguna cubre</mark>. Ahí es donde el conocimiento de Go ofensivo paga.

Herramientas construidas o usadas, todas comparten un problema final: el binario Go deja una huella characterística. Reducirla es OPSEC → [[02 - OPSEC del binario Go]].
