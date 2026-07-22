---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
  - Introduccion
Fecha de actualización: 2026-06-02
Nota previa:
Nota siguiente: "[[01 - WHOIS]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

<mark style="background: #ADCCFFA6;">El **reconocimiento web** (`web reconnaissance`) es la recopilación sistemática y metódica de información sobre un sitio o aplicación web objetivo</mark>. Es la fase preparatoria que precede a cualquier análisis o explotación: define **qué** vas a atacar antes de plantearte el **cómo**. En la metodología del pentest se encuadra dentro de la fase `Information Gathering`, y en bug bounty es —sin discusión— la actividad que más separa a un cazador mediocre de uno rentable: <mark style="background: #FF5582A6;">cada activo que el objetivo expuso por descuido y olvidó es un punto de entrada que el resto de cazadores aún no ha mirado</mark>.

![Diagrama del proceso de pentesting con la fase de Information Gathering dentro del ciclo](https://academy.hackthebox.com/storage/modules/144/PT-process.png)

El recon persigue cuatro objetivos:

- **Identificar activos** (`assets`): descubrir todos los componentes accesibles públicamente —páginas, subdominios, direcciones IP, tecnologías—. Construye el mapa de la presencia online del objetivo.
- **Descubrir información oculta**: localizar datos expuestos por descuido —archivos de backup, ficheros de configuración, documentación interna, credenciales filtradas en repositorios—. Estos hallazgos suelen ser puntos de entrada directos.
- **Analizar la superficie de ataque**: evaluar tecnologías, versiones, configuraciones y posibles vectores. <mark style="background: #FFB86CA6;">Cuanto mayor es la superficie expuesta, más probable es que exista un eslabón débil</mark>.
- **Reunir inteligencia**: información aprovechable para explotación posterior o ingeniería social —personal clave, direcciones de correo, patrones de nomenclatura de cuentas y hosts—.

La asimetría es la clave: el atacante usa esta información para **adaptar** su ataque a las debilidades concretas del objetivo y rodear las defensas; el defensor hace el mismo recon para **parchear** esas debilidades antes de que alguien las encuentre. <mark style="background: #8000E1A6;">Quien tiene el mapa más completo de la superficie de ataque juega con ventaja</mark>, sea cual sea el lado.

# Reconocimiento activo vs pasivo

El reconocimiento se divide en dos metodologías con un compromiso fundamental entre **profundidad de información** y **riesgo de detección**.

## Reconocimiento activo

<mark style="background: #ADCCFFA6;">En el reconocimiento activo interactúas directamente con los sistemas del objetivo para extraer información</mark>. Es más directo y suele dar una visión más completa de la infraestructura, pero <mark style="background: #FFB86CA6;">cada interacción deja rastro</mark>: genera tráfico que un `IDS`, un `WAF` o un equipo de *blue team* pueden registrar y correlacionar.

| Técnica | Descripción | Ejemplo | Herramientas | Riesgo de detección |
| - | - | - | - | - |
| `Port Scanning` | Identificar puertos y servicios abiertos | Escanear con `nmap` los puertos 80 (HTTP) y 443 (HTTPS) | `nmap`, `masscan`, `unicornscan` | Alto: la interacción directa puede disparar IDS y firewalls |
| `Vulnerability Scanning` | Probar vulnerabilidades conocidas (software obsoleto, *misconfigs*) | Lanzar Nessus contra una app buscando `SQLi` o `XSS` | Nessus, OpenVAS, `nikto` | Alto: los escáneres envían *payloads* de explotación detectables |
| `Network Mapping` | Mapear la topología de red y sus relaciones | `traceroute` para revelar saltos e infraestructura | `traceroute`, `nmap` | Medio-Alto: el tráfico inusual levanta sospechas |
| `Banner Grabbing` | Leer los *banners* de los servicios | Conectar al puerto 80 y leer el banner HTTP para identificar el servidor | `netcat`, `curl` | Bajo: interacción mínima, pero registrable |
| `OS Fingerprinting` | Identificar el sistema operativo | `nmap -O` para distinguir Windows/Linux | `nmap`, `xprobe2` | Bajo: alguna técnica avanzada es detectable |
| `Service Enumeration` | Determinar versiones exactas de servicios | `nmap -sV` para saber si corre Apache 2.4.50 o Nginx 1.18.0 | `nmap` | Bajo: registrable, pero rara vez alerta |
| `Web Spidering` | Rastrear el sitio para mapear páginas, directorios y archivos | Burp Spider / OWASP ZAP Spider mapeando la estructura | Burp Suite, OWASP ZAP, Scrapy | Bajo-Medio: detectable si el *crawler* no imita tráfico legítimo |

El `port scanning` y el `service enumeration` con `nmap` son la puerta de entrada clásica al recon activo de un host — el detalle operativo de esas técnicas vive en [[🔌 Puertos|el escaneo de puertos con Nmap]].

## Reconocimiento pasivo

<mark style="background: #ADCCFFA6;">El reconocimiento pasivo reúne información sin tocar el objetivo, analizando únicamente fuentes públicas</mark>. Consultas a terceros (motores de búsqueda, bases de datos `WHOIS`, registros DNS públicos, archivos web) que no generan tráfico hacia la infraestructura del objetivo.

| Técnica | Descripción | Ejemplo | Herramientas | Riesgo de detección |
| - | - | - | - | - |
| `Search Engine Queries` | Descubrir información indexada | Buscar `"[empresa] employees"` o *dorks* de archivos expuestos | Google, DuckDuckGo, Bing, Shodan | Muy bajo: actividad normal de internet |
| `WHOIS Lookups` | Recuperar datos de registro de dominio | `whois` para obtener registrante, contactos y *name servers* | `whois`, servicios web | Muy bajo: consultas legítimas |
| `DNS` | Analizar registros DNS (subdominios, servidores de correo) | `dig` para enumerar registros de un dominio | `dig`, `nslookup`, `host`, `dnsenum`, `fierce`, `dnsrecon` | Muy bajo: tráfico esencial de internet |
| `Web Archive Analysis` | Examinar instantáneas históricas del sitio | Wayback Machine para ver versiones antiguas y rutas desaparecidas | Wayback Machine | Muy bajo: actividad normal |
| `Social Media Analysis` | Recopilar datos de RRSS | LinkedIn para roles y objetivos de ingeniería social | LinkedIn, Twitter, herramientas OSINT | Muy bajo: perfiles públicos |
| `Code Repositories` | Buscar secretos en repos públicos | GitHub en busca de credenciales o lógica filtrada | GitHub, GitLab | Muy bajo: repos pensados para acceso público |

<mark style="background: #FFB8EBA6;">El recon pasivo es más sigiloso, pero produce información menos completa</mark>: se limita a lo que ya es público. El activo rellena los huecos a cambio de exponerte.

# El matiz: la frontera se difumina

En la práctica la separación activo/pasivo no es una pared, sino un gradiente. Consultar `crt.sh` por los certificados de un dominio es **pasivo** (preguntas a un tercero), pero **resolver** después esos subdominios y lanzarles peticiones HTTP ya es **activo**. El flujo real encadena ambos: empiezas pasivo para construir el inventario sin hacer ruido y escalas a activo solo cuando necesitas confirmar o profundizar.

> [!warning]+ Alcance y autorización
> El recon pasivo no toca el objetivo; el activo sí. En un engagement con alcance cerrado, lanzar un `port scan`, `subdomain bruteforcing` o `vulnerability scanning` contra un host **fuera de alcance** puede violar las reglas del contrato o la política del programa de bug bounty. Antes de pasar a técnicas activas, confirma que el activo está dentro del *scope*. La fase pasiva, en cambio, suele poder ejecutarse incluso sobre infraestructura de terceros sin tocar al cliente.

> [!info]+ Recon continuo en bug bounty
> En programas grandes la superficie de ataque cambia a diario: nuevos subdominios, despliegues, *staging* expuesto. Los cazadores serios automatizan el recon (`amass`, `subfinder`, `httpx`, `nuclei`) y lo ejecutan en bucle para detectar activos nuevos en cuanto aparecen —a menudo el bug está en el subdominio que se desplegó ayer y nadie revisó—. La automatización se trata en [[14 - Automatización del recon]].

# Cómo se organiza este tema

Este sub-tema recorre el recon web de lo más pasivo a lo más activo, y termina entrando en el **fuzzing** como forma avanzada de descubrimiento de contenido:

1. **Inteligencia de dominio** — [[01 - WHOIS]] (registro) y la familia DNS: [[02 - DNS - fundamentos]], [[03 - Enumeración DNS con dig]], [[04 - Transferencias de zona DNS]].
2. **Expansión de superficie** — [[05 - Enumeración de subdominios]], [[06 - Fuerza bruta de subdominios]], [[07 - Certificate Transparency logs]] y [[08 - Virtual Hosts]].
3. **Caracterización del objetivo** — [[09 - Fingerprinting web]], [[10 - Crawling web]] y [[11 - Spidering con Scrapy]].
4. **Fuentes externas** — [[12 - Search Engine Discovery]] y [[13 - Web Archives]].
5. **Fuzzing** — la evolución activa del recon: forzar al servidor a revelar directorios, parámetros, *vhosts* y endpoints de API que no enlaza en ninguna parte. Empieza en [[15 - Introducción al web fuzzing]].

La primera parada es el protocolo `WHOIS`: la vía más rápida para saber quién está detrás de un dominio y qué infraestructura lo sostiene.
