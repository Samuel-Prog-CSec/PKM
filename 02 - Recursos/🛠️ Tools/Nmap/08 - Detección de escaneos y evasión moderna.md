---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
Fecha de actualización: 2026-07-18
Nota previa: "[[07 - Evasión de firewalls, IDS e IPS]]"
Nota siguiente: "[[09 - Arsenal de herramientas de escaneo]]"
Area: "[[Nmap.base|Nmap]]"
---
---

Las técnicas de evasión de [[07 - Evasión de firewalls, IDS e IPS]] son de la era del IDS de firma simple. En un entorno de 2026 —con IDS que reensamblan, análisis de flujo en la nube y detección por comportamiento— la mayoría ya no cuela sola. Esta nota cubre **cómo se detecta un escaneo hoy** y **qué OPSEC funciona de verdad**. Es el estándar de calidad CPTS: salir a un pentest real sabiendo que enfrente hay telemetría que HTB ignora.

> [!info]+ El marco defensivo: MITRE ATT&CK T1046
> El escaneo de puertos es *Network Service Discovery* ([T1046](https://attack.mitre.org/techniques/T1046/)) en ATT&CK. Los *blue teams* construyen sus detecciones sobre esta técnica, así que pensar en esos términos ayuda a anticipar qué buscan.

# Cómo se detecta un escaneo hoy

## IDS/IPS de red por umbral y firma

`Snort`, `Suricata` y `Zeek` no buscan un paquete "malo", sino el **patrón**: <mark style="background: #ADCCFFA6;">un origen que toca muchos puertos o muchos hosts en poco tiempo</mark>. El preprocesador de *portscan* de **Snort** (`sfPortscan`), las reglas por umbral (`threshold`/`detection_filter`) de **Suricata** y el *scan detection* de **Zeek** (vía su framework de *notices*) disparan por umbral de conexiones fallidas/nuevas por ventana temporal. Un `-sS` a los top-1000 es un caso de libro. En AWS, Suricata/Zeek se despliegan sobre *VPC Traffic Mirroring* para inspeccionar el tráfico este-oeste a escala (AWS, [*Work with open-source tools for traffic mirroring*](https://docs.aws.amazon.com/vpc/latest/mirroring/tm-example-open-source.html)).

## Análisis de flujo (la nube te ve sin IDS)

No hace falta un IDS clásico: la nube detecta escaneos desde los **logs de flujo** (VPC Flow Logs). Pero conviene no confundir dos hallazgos de **AWS GuardDuty** (AWS, [*GuardDuty EC2 finding types*](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-ec2.html)):

- `Recon:EC2/Portscan` se dispara cuando **una instancia EC2 monitorizada escanea hacia fuera** — señal de que **esa** instancia ya está comprometida (post-explotación), **no** el atacante externo escaneando un target alojado en AWS.
- `Recon:EC2/PortProbeUnprotectedPort` es el que aplica al escaneo **externo**: un puerto expuesto sondeado **desde una IP ya catalogada como maliciosa** en la *threat intel* de AWS. <mark style="background: #FFB8EBA6;">No dispara para los puertos 80 y 443</mark>, y **exige que tu IP figure como *known scanner/malicious*** — no salta por puro volumen.

<mark style="background: #8000E1A6;">Consecuencia práctica: un pentester con una IP limpia escaneando un target en AWS probablemente no dispara ningún hallazgo EC2 de GuardDuty</mark>, sea cual sea el puerto — el riesgo real llega si operas desde una instancia ya comprometida o desde una IP con mala reputación. Azure Defender y GCP tienen equivalentes basados en logs de flujo.

## Detección por comportamiento / IA

Aquí es donde la evasión clásica muere. Plataformas como **Darktrace** o **Vectra AI** modelan el comportamiento "normal" de cada host y marcan la desviación, no una firma. <mark style="background: #FF5582A6;">Fragmentación, decoys y `--badsum` no engañan a un motor heurístico/ML</mark> porque lo que detectan es el *patrón de conexión anómalo*, no la forma del paquete (appsecvenue, [*Mastering Nmap Part 2*, 2025](https://medium.com/@appsecvenue/mastering-nmap-part-2-advanced-scans-firewall-evasion-for-bug-bounty-hunters-e005dcaf21a7)).

## Host y trampas

- **EDR** en el endpoint correlaciona conexiones salientes/entrantes anómalas.
- **Honeypots y canary tokens**: un servicio señuelo o un puerto-trampa. <mark style="background: #FFB86CA6;">Un solo paquete a un canario = alerta de alta confianza</mark>, porque nadie legítimo lo toca. Barrer `-p-` a ciegas es la forma más rápida de pisar uno.
- **Tarpits / SYN cookies / rate-limiting**: ralentizan o falsean respuestas para envenenar tus resultados.

# Evasión y OPSEC que sí funcionan en 2026

## 1. Recon pasivo primero (no toques el objetivo)

La mejor evasión es **no escanear**. Antes de mandar un paquete: `Shodan`, `Censys`, `ZoomEye` y los *Certificate Transparency logs* ya tienen mapeados puertos, servicios, versiones y certificados de casi cualquier IP pública. <mark style="background: #8000E1A6;">Buena parte del "escaneo" moderno es OSINT: llegas al escaneo activo sabiendo ya qué buscar</mark>, reduciendo el ruido a lo mínimo. Herramientas en [[09 - Arsenal de herramientas de escaneo]].

## 2. Low-and-slow

Contra detección por umbral, bajar por debajo del umbral funciona: `-T0`/`-T1`, `--scan-delay`, `--max-rate` muy bajo, pocos puertos por pasada y repartir en horas o días (secybr, [*Evasion Tactics for Scanning Targets*](https://secybr.com/posts/evasion-tactics-for-scanning-targets/)). El coste es tiempo — no siempre viable con plazos ajustados, pero es lo único que evade un IDS por umbral bien afinado.

## 3. Parecer tráfico legítimo (*blending*)

- `--source-port 443`/`53` para imitar respuestas de servicios de confianza.
- Escanear **solo puertos comunes** en vez de barridos completos (el sondeo de 80/443, además, queda fuera del finding de GuardDuty).
- Escanear **en horario laboral**, cuando tu tráfico se pierde entre el legítimo.
- Salir desde **rangos con buena reputación** (cloud conocido) en vez de una IP residencial sospechosa.
- Cambiar el *user-agent* de los scripts HTTP: `--script-args http.useragent="Mozilla/5.0..."` para no cantar en un WAF (appsecvenue, 2025).

## 4. Distribuir el origen

Repartir el escaneo entre varias IPs/VPS o *egress* cloud rotado sube el umbral que el defensor necesita para correlacionar. El *spoofing* de origen (`-S`, decoys) mayormente lo filtran los ISP, pero el *source spoofing* controlado tiene usos ofensivos concretos (TierZero Security, [*SYN spoof scan*, 2025](https://tierzerosecurity.co.nz/2025/01/08/syn-spoof-scan.html)).

## 5. Evitar lo que grita

En fase sigilosa, **nada** de `-A`, `-O`, `--version-all` ni scripts NSE `vuln`/`brute`/`exploit`: son las firmas más ruidosas de Nmap. Enumeración de versión mínima y confirmación manual (ver [[03 - Enumeración de servicios y versiones]]).

> [!warning]+ Asume que te pueden ver y bloquear
> La OPSEC de infraestructura es parte del ataque: usa VPS **sacrificables**, no reutilices IPs entre clientes, y da por hecho que un IPS puede cortarte y tu ISP recibir una queja ([[07 - Evasión de firewalls, IDS e IPS#Detectar el IDS/IPS|rotación de VPS]]). En bug bounty, un escaneo agresivo puede además violar las reglas del programa.

# Regla práctica

El sigilo real en 2026 no viene de un flag mágico de Nmap, sino de **hacer menos y parecer normal**: recon pasivo → objetivos concretos → bajo volumen → puertos/orígenes que se confunden con lo legítimo. La fragmentación y los decoys son historia contra defensas serias.

> [!info]+ Fuentes
> - AWS — [GuardDuty EC2 finding types](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_finding-types-ec2.html) y [Traffic Mirroring con Suricata/Zeek](https://docs.aws.amazon.com/vpc/latest/mirroring/tm-example-open-source.html).
> - MITRE ATT&CK — [T1046 Network Service Discovery](https://attack.mitre.org/techniques/T1046/).
> - appsecvenue — [Mastering Nmap Part 2 (2025)](https://medium.com/@appsecvenue/mastering-nmap-part-2-advanced-scans-firewall-evasion-for-bug-bounty-hunters-e005dcaf21a7); secybr — [Evasion Tactics](https://secybr.com/posts/evasion-tactics-for-scanning-targets/); TierZero Security — [SYN spoof scan (2025)](https://tierzerosecurity.co.nz/2025/01/08/syn-spoof-scan.html).
