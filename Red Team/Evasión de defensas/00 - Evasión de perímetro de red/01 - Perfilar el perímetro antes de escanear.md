---
tags:
  - Evasion
  - Escaneo/Redes
  - Pentesting/Enumeracion
Descripción: "Averiguar qué dispositivo tienes delante antes de mandar el primer paquete ruidoso — y hacerlo con el tráfico que menos cuesta"
Fecha de actualización: 2026-08-04
Nota previa: "[[00 - El perímetro moderno - firewall, NGFW, IDS-IPS, NDR y WAF]]"
Nota siguiente: "[[02 - Descubrir la política de filtrado]]"
Area: "[[Evasión de perímetro.base|Evasión de perímetro]]"
---
---

El error de secuencia más caro del reconocimiento es **escanear primero y descubrir después que había un IPS**. Para entonces ya te ha bloqueado, ya estás en su log y ya has quemado la IP. <mark style="background: #ADCCFFA6;">Perfilar el perímetro es la fase que va antes del escaneo y que decide cómo se hace el escaneo</mark>.

# Paso 0 — todo lo que se pueda saber sin tocar

Antes de generar un solo paquete, la información pasiva ya responde media pregunta:

| Fuente | Qué te dice del perímetro |
| --- | --- |
| [[00 - Smap - escaneo pasivo con datos de Shodan\|Smap]] / [[07 - uncover - recon pasivo vía motores de búsqueda\|uncover]] | Qué puertos ve Shodan. Si ve pocos, hay filtrado. |
| [[03 - asnmap y cdncheck - superficie por ASN y detección de CDN\|cdncheck]] | Si hay CDN/WAF delante y de quién. |
| [[06 - tlsx - inteligencia desde TLS\|tlsx]] (JARM) | Agrupa hosts por pila TLS: delata balanceadores y terminadores. |
| Registros MX, SPF, DMARC | Proveedor de correo → a menudo el mismo proveedor del filtrado. |
| Ofertas de empleo, LinkedIn, repositorios | «Buscamos ingeniero con experiencia en Palo Alto y CrowdStrike» es inteligencia de primer nivel. |
| Certificate Transparency | Nombres tipo `vpn.`, `fw.`, `proxy.`, `waf.` — ver [[07 - Certificate Transparency logs]]. |

<mark style="background: #8000E1A6;">Una oferta de empleo del cliente nombrando su fabricante de firewall vale más que tres horas de sondeo</mark>, y no genera ni un paquete. Es OSINT, no hacking, y es donde hay que empezar.

# Paso 1 — identificar la capa web (barato y seguro)

Si el objetivo es web, lo primero que hay que saber es si hay WAF, porque cambia toda la fase siguiente:

```shell-session
$ wafw00f https://objetivo.com
$ curl -sI https://objetivo.com | grep -iE 'server|cf-ray|x-akamai|x-sucuri|x-cdn'
$ echo objetivo.com | httpx -silent -cdn -title -sc
```

`wafw00f` identifica el producto mandando peticiones benignas y comparando la respuesta contra una base de firmas. Es **poco intrusivo** y muy informativo: saber que enfrente hay Cloudflare, Akamai o AWS WAF determina qué evasión tiene sentido intentar y cuál es perder el tiempo ([[27 - Evasión en recon y fuzzing]]).

Las cabeceras también hablan solas: `cf-ray` es Cloudflare, `x-akamai-*` es Akamai, `x-sucuri-id` es Sucuri.

# Paso 2 — leer el camino

```shell-session
$ sudo nmap --traceroute -sS -p 443 objetivo.com
$ sudo tcptraceroute objetivo.com 443
$ sudo nping --tcp -p 443 --ttl 5 -c 1 objetivo.com
```

Lo que buscas en la traza:

- **Dónde muere.** El último salto que responde suele ser el filtro (o el router inmediatamente anterior).
- **Cuántos saltos hay detrás.** Si el objetivo es el salto siguiente al filtro, el [[00 - Firewalking - mapear ACLs con TTL|firewalking]] no va a funcionar (no hay quien expire el TTL).
- **Nombres inversos de los saltos.** Los PTR de los routers a menudo llevan el nombre del operador, la ciudad y a veces el modelo.
- **Saltos que cambian entre ejecuciones.** Indica ECMP o balanceo: el conteo de saltos deja de ser fiable.

# Paso 3 — distinguir *drop* de *reject*

Es la señal más barata y más informativa de todas, y sale de un escaneo mínimo:

| Respuesta | Qué significa |
| --- | --- |
| `RST` | Puerto cerrado, **o** firewall configurado para rechazar. |
| **Silencio** | *Drop* silencioso: hay filtrado deliberado. |
| `ICMP Port/Host/Net Unreachable` | Filtrado que se identifica. |
| **`ICMP Administratively Prohibited` (tipo 3, código 13)** | <mark style="background: #FF5582A6;">Confirmación explícita: hay una ACL y te la está diciendo</mark>. |

Un perímetro que hace *drop* silencioso en todo es un perímetro cuidado; uno que devuelve `administratively prohibited` te está regalando el mapa. Detalle en [[02 - Escaneo de puertos y hosts]].

# Paso 4 — inferir si hay IPS (con cuidado)

Los IDS/IPS son pasivos: **no se detectan directamente, se infieren por su reacción**. La técnica clásica sigue siendo válida y hay que ejecutarla con criterio:

1. Coge **dos** orígenes distintos: uno **sacrificable** y otro que quieras conservar.
2. Desde el sacrificable, provoca deliberadamente: un escaneo agresivo y corto de un puerto, o una firma conocida y benigna.
3. Comprueba desde el **otro** origen si el objetivo sigue accesible.

<mark style="background: #FFB86CA6;">Si el origen sacrificable pierde el acceso y el otro no, hay IPS y bloquea por IP</mark>. Ya sabes que toca ser silencioso, y lo has averiguado quemando la IP que estabas dispuesto a quemar.

> [!warning]+ Esto es deliberadamente ruidoso: acuérdalo antes
> Provocar a un IPS genera una alerta real en el SOC del cliente. En un engagement **anunciado** no pasa nada. En un ejercicio de red team no anunciado, es exactamente lo contrario de lo que quieres, y puede activar la respuesta a incidentes y terminar el ejercicio. Coordínalo con el contacto y déjalo por escrito ([[03 - Coordinación de operadores y deconflicting]]).

## La otra vía: pedirlo

En un pentest normal (no un red team ciego), **la vía más eficiente para perfilar el perímetro es preguntar**. Un pentester profesional pide en la reunión de arranque: qué hay desplegado, si hay IPS en modo bloqueo, si se ha añadido tu IP a una lista blanca, y a quién avisar si te cortan.

<mark style="background: #8000E1A6;">No es hacer trampa: es no gastar el presupuesto del cliente en averiguar por sondeo algo que él ya sabe</mark>. El sigilo se compra cuando el sigilo es el objetivo del ejercicio ([[12 - Niveles de evasividad y testing dirigido por amenazas (TLPT)]]).

# La decisión que sale de todo esto

```
¿Hay WAF/CDN?          → busca el origen real; no aporrees el WAF
¿IPS en bloqueo?       → low-and-slow, orígenes rotados, nada de -A ni scripts vuln
¿Solo firewall estático? → tienes margen; el sondeo de flags aún dice cosas
¿Drop silencioso total? → perímetro cuidado; asume que también hay logging serio
¿Dual-stack?           → prueba IPv6, casi siempre está peor filtrado
```

> [!important]+ Regístralo, no solo lo uses
> El perfil del perímetro **es contenido del informe**, no solo insumo para tu siguiente comando. «El perímetro rechaza con `administratively prohibited`, revelando la existencia y ubicación de las ACLs» es un hallazgo de configuración menor pero real, y demuestra al cliente que entendiste su arquitectura ([[Documentación y reporting.base|reporting]]).

> [!info]+ Fuentes
> Técnicas de sondeo en [[07 - Evasión de firewalls, IDS e IPS]] y [[01 - Implementaciones vivas del firewalking]]; detección de WAF con `wafw00f` en [[27 - Evasión en recon y fuzzing]] y [[09 - Fingerprinting web]]; recon pasivo en [[08 - Detección de escaneos y evasión moderna]].
