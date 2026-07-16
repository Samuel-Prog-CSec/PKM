---
tags:
  - Web/Red-Team
  - Common-Applications
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Introducción y metodología]]"
Nota siguiente: "[[00 - Descubrimiento y enumeración de WordPress]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

Antes de atacar aplicaciones hay que **descubrirlas**. En un rango con cientos o miles de hosts, browsear IP a IP es inviable: la clave es escanear puertos web y luego **capturar pantallazos en masa** para triar la superficie de ataque de un vistazo.

# Descubrimiento con Nmap

Un primer barrido de puertos web comunes sobre el scope:

```shell-session
$ sudo nmap -p 80,443,8000,8080,8180,8888,10000 --open -oA web_discovery -iL scope_list
```

Y un escaneo de servicios (`-sV`) sobre los hosts interesantes revela **qué** aplicación corre en cada puerto:

```shell-session
$ sudo nmap --open -sV 10.129.201.50
...
8000/tcp  open  http   Splunkd httpd
8080/tcp  open  http   Indy httpd 17.3.33.2830 (Paessler PRTG bandwidth monitor)
8089/tcp  open  ssl/http  Splunkd httpd (free license; remote login disabled)
```

<mark style="background: #ADCCFFA6;">Los puertos ya delatan aplicaciones</mark>: `8000`/`8089` → Splunk, `8080` → PRTG o Tomcat, `8009` (AJP) → Tomcat, `8081` → GitLab. Guardar la salida XML (`-oA`) es imprescindible: es la entrada de las herramientas de screenshotting.

# Screenshotting masivo: EyeWitness y Aquatone

Ambas toman el XML de Nmap y generan un **informe HTML con capturas** de cada app, categorizándolas y a veces sugiriendo credenciales por defecto:

```shell-session
$ eyewitness --web -x web_discovery.xml -d inlanefreight_eyewitness
$ cat web_discovery.xml | ./aquatone -nmap
```

<mark style="background: #FFB86CA6;">Con 26 hosts ya ahorran tiempo; con 500 o 5.000 son imprescindibles</mark>. El informe agrupa "high value targets" primero y clusteriza páginas similares.

> [!info]+ Stack de recon web moderno (2026)
> EyeWitness/Aquatone siguen sirviendo, pero el flujo actual de bug bounty y red team es más rápido: <mark style="background: #ADCCFFA6;">`httpx`</mark> (probe masivo + detección de tecnología), <mark style="background: #ADCCFFA6;">`gowitness`</mark> (screenshots, hoy más usado que EyeWitness), <mark style="background: #ADCCFFA6;">`nuclei`</mark> (detección de tech y vulnerabilidades con plantillas), `katana` (crawling) y `whatweb`/`wappalyzer` para fingerprinting. Aquatone tiene un *fork* activo con mejoras. Un pipeline típico: `nmap`/`naabu` → `httpx` → `gowitness` + `nuclei -t http/technologies`.

# Pistas para priorizar

| Señal | Por qué importa |
| - | - |
| Vhosts `dev`/`qa`/`acc` | features sin probar, *debug mode*, menos hardening |
| Tomcat (`/manager`) | subir un `.war` = RCE |
| GitLab | repos públicos, registro abierto, secrets en commits |
| osTicket / ticketing | información sensible, ingeniería social |
| Splunk / PRTG | ejecución de scripts, datos sensibles |
| App custom | siempre testear — vulnerabilidades a medida |

> [!important]+ El escáner es input, no sustituto
> <mark style="background: #FF5582A6;">Todos estos escaneos son datos de entrada para el testing **manual**</mark>. Las vulnerabilidades más severas y únicas salen del análisis a mano, no del scanner. No empieces a atacar el primer host que veas: termina el descubrimiento, anota app + versión de cada objetivo, y ataca con criterio. La fase de enumeración se apoya en el módulo de [[00 - Reconocimiento Web|reconocimiento web]] (fuzzing de vhosts, directorios, parámetros).

Con el inventario de aplicaciones listo, empezamos por la más extendida de la web: [[00 - Descubrimiento y enumeración de WordPress|WordPress]].
