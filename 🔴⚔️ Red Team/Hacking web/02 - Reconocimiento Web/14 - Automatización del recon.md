---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
Fecha de actualización: 2026-06-02
Nota previa: "[[13 - Web Archives]]"
Nota siguiente: "[[15 - Introducción al web fuzzing]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

El recon manual funciona, pero es lento y propenso a errores. <mark style="background: #ADCCFFA6;">Automatizar el reconocimiento encadena las técnicas vistas en un flujo reproducible que las ejecuta a escala</mark>, dejándote a ti el análisis y la decisión.

# Por qué automatizar

- **Eficiencia**: las herramientas hacen las tareas repetitivas mucho más rápido que tú.
- **Escala**: aplicas el recon a cientos de objetivos o dominios de una vez.
- **Consistencia**: siguen reglas fijas, con resultados reproducibles y menos error humano.
- **Cobertura**: programadas para cubrir DNS, subdominios, crawling, *port scanning* y más en una sola pasada.
- **Integración**: muchos frameworks encadenan con otras herramientas, creando un flujo continuo de recon → análisis de vulnerabilidades → explotación.

# Frameworks de recon

| Framework | Enfoque |
| - | - |
| `FinalRecon` | Python modular: SSL, WHOIS, cabeceras, crawling, DNS, subdominios, directorios, Wayback |
| `Recon-ng` | Framework modular potente, estilo Metasploit, con módulos para cada tarea |
| `theHarvester` | Correos, subdominios, hosts, empleados y banners desde fuentes públicas |
| `SpiderFoot` | Automatización OSINT que integra decenas de fuentes de datos |
| `OSINT Framework` | Colección de herramientas y recursos OSINT por categoría |

# `FinalRecon`

Es un "todo en uno" en Python con módulos activables por flags. Cubre cabeceras, WHOIS, info de certificado SSL, crawling (incluye links en JS y Wayback), enumeración DNS (40+ tipos de registro, incl. `DMARC`), subdominios (vía `crt.sh`, CertSpotter, VirusTotal, Shodan…) y enumeración de directorios.

```shell-session
$ git clone https://github.com/thewhiteh4t/FinalRecon.git
$ cd FinalRecon && pip3 install -r requirements.txt
$ chmod +x ./finalrecon.py
```

Los módulos se activan con flags, combinables, o `--full` para todo:

| Flag | Módulo |
| - | - |
| `--headers` | Información de cabeceras |
| `--sslinfo` | Certificado SSL |
| `--whois` | WHOIS |
| `--crawl` | Crawling del objetivo |
| `--dns` | Enumeración DNS |
| `--sub` | Subdominios |
| `--dir` | Búsqueda de directorios |
| `--wayback` | URLs de Wayback |
| `--ps` | Port scan rápido |
| `--full` | Recon completo |

```shell-session
$ ./finalrecon.py --headers --whois --url http://inlanefreight.com

[+] Target : http://inlanefreight.com
[+] IP Address : 134.209.24.248
[!] Headers :
Server : Apache/2.4.41 (Ubuntu)
[!] Whois Lookup :
   Registrar: Amazon Registrar, Inc.
   Name Server: NS-1303.AWSDNS-34.ORG
[...]
```

Reconoces aquí, encadenadas, técnicas de notas anteriores: [[01 - WHOIS|WHOIS]], [[09 - Fingerprinting web|cabeceras]], [[05 - Enumeración de subdominios|subdominios]] y [[13 - Web Archives|Wayback]].

> [!info]+ El stack de automatización moderno
> En bug bounty actual conviven dos enfoques:
> - **Pipeline de herramientas atómicas** (ProjectDiscovery): `subfinder | dnsx | httpx | nuclei`, encadenadas con `anew` (acumula solo lo nuevo) y `notify` (alerta a Slack/Discord). Modular y combinable a tu gusto.
> - **Frameworks orquestadores todo-en-uno**: `reconFTW`, `Osmedeus`, `reNgine` automatizan el flujo completo —subdominios, resolución, fingerprinting, fuzzing, *nuclei*— en un comando, ideales para recon continuo y monitorización de superficie.
> Para escala masiva, `axiom` distribuye el trabajo entre múltiples VMs efímeras —su uso para evadir *rate-limits* está en [[27 - Evasión en recon y fuzzing]]—.
> El escaneo dirigido con `nuclei` se detalla en [[26 - Escaneo dirigido con nuclei]], y el recon de activos en la nube en [[25 - Cloud asset recon]].

> [!warning]+ La automatización da amplitud, no profundidad
> <mark style="background: #8000E1A6;">Las herramientas encuentran lo evidente a gran escala; los bugs jugosos suelen requerir análisis manual</mark>. No confíes ciegamente en la salida automatizada: genera falsos positivos, pierde lógica de negocio y no entiende el contexto. Úsala para acotar la superficie y priorizar, luego profundiza a mano sobre lo prometedor.

Hasta aquí el reconocimiento "clásico": mapear lo que el objetivo expone. El siguiente nivel es **forzar** al servidor a revelar lo que **no** enlaza —directorios, parámetros, vhosts y endpoints ocultos— mediante fuzzing. Es la evolución natural del recon activo, y arranca en [[15 - Introducción al web fuzzing]].
