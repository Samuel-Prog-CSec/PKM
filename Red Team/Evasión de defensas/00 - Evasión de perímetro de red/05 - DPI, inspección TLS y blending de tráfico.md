---
tags:
  - Evasion
  - Escaneo/Redes
  - Pentesting/Enumeracion
Descripción: "Cuando el perímetro mira el contenido y no el sobre — DPI, interceptación TLS y fingerprinting JA4/JARM, y cómo fundirse con lo legítimo"
Fecha de actualización: 2026-08-04
Nota previa: "[[04 - Fragmentación y evasión a nivel IP y TCP]]"
Nota siguiente: "[[06 - Rotación de origen e infraestructura sacrificable]]"
Area: "[[Evasión de perímetro.base|Evasión de perímetro]]"
---
---

Las notas anteriores tratan el perímetro que decide por **puerto y forma de paquete**. Este trata el que decide por **contenido**: el que abre el sobre, o que sin abrirlo reconoce quién lo escribió. Es el salto de la ACL al *deep packet inspection* y a la inspección TLS, y cambia por completo qué significa "salir por el 443".

# DPI: el puerto ya no dice qué protocolo va dentro

<mark style="background: #ADCCFFA6;">El *deep packet inspection* clasifica el tráfico por su contenido, no por su número de puerto</mark>. Un NGFW con **App-ID** (Palo Alto y equivalentes de Fortinet, Check Point, Zscaler) mira los primeros bytes de la sesión y decide si eso es HTTPS de verdad, `SSH`, `BitTorrent` o un túnel, aunque vaya por el 443. Consecuencias directas para el operador:

- Un túnel `SSH` o un SOCKS metido en el 443 se marca como **discrepancia protocolo-puerto** y salta. Salir por 443 ya no basta: tiene que **parecer** HTTPS.
- Los protocolos "no reconocidos" se bloquean por política en muchos despliegues (*deny unknown-tcp/udp*), así que un C2 con un protocolo propietario sobre un puerto alto no pasa.

<mark style="background: #FFB86CA6;">La defensa dejó de preguntar «¿por dónde vas?» y pregunta «¿qué eres?»</mark>. Por eso el canal de salida se elige por a qué protocolo legítimo puede imitar, tema de [[03 - Egress filtering - por dónde se sale|la nota anterior]].

# Inspección TLS: el 443 deja de ser opaco

La suposición de que el TLS te cubre es válida **solo hasta el punto donde alguien tiene la clave**. En una red corporativa madura, el **SWG** (Zscaler, Netskope, Palo Alto Prisma) actúa de *man-in-the-middle* legítimo: termina tu TLS, lee el claro, y vuelve a cifrar hacia el destino con su propio certificado. Funciona porque **el endpoint gestionado confía en la CA corporativa** que se le instaló.

Los límites de esta inspección son tu margen:

- **Solo muerde en endpoints gestionados**: la interceptación necesita la CA en el *trust store* del host. Desde una máquina no gestionada (un dispositivo que trajiste tú, un servidor comprometido sin la CA) el MITM del SWG **no valida** y la conexión falla o se hace en claro.
- **El *pinning* la rompe**: una app que fija su certificado rechaza el de la CA corporativa. Muchos despliegues **excluyen** categorías (banca, salud) de la inspección por eso y por privacidad → esas categorías son un hueco.
- **Es cara a escala**: descifrar todo el tráfico cuesta CPU, así que la inspección suele ser **selectiva**. Lo no inspeccionado sigue siendo opaco.

> [!warning]+ Gestionado vs no gestionado: la distinción que lo decide todo
> Un pentester operando desde su propia máquina detrás del SWG del cliente **no** sufre la interceptación (no tiene la CA), pero **sí** el App-ID y el fingerprinting de abajo. Un implante en un endpoint corporativo gestionado **sí** la sufre. Antes de diseñar el canal, sitúa desde dónde operas.

# Fingerprinting TLS sin descifrar: JA3, JA4, JARM

Aunque el perímetro **no** rompa el TLS, puede identificar **qué software** habla por él a partir del `ClientHello` en claro (versiones, cifrados, extensiones, curvas). Ese es el terreno donde muere la evasión perezosa:

- **JA3/JA3S** (Salesforce, 2017): hash del `ClientHello`/`ServerHello`. Fue el estándar, pero el orden aleatorio de extensiones de los navegadores (GREASE) lo hizo frágil.
- **JA4+** (FoxIO, 2023): la familia moderna —`JA4` (cliente TLS), `JA4S` (servidor), `JA4H` (HTTP), `JA4X` (certificado)—, diseñada para ser **estable** ordenando los campos. Es el fingerprint que hoy usan los SOC y los NGFW.
- **JARM** (Salesforce, 2020): fingerprint **activo del servidor** — manda diez `ClientHello` a medida y hashea las respuestas. Delata la pila TLS del **otro** extremo, y es como los defensores cazan **servidores de C2**: un Cobalt Strike o un Metasploit con TLS por defecto tiene un JARM conocido y publicado. Lo calcula [[06 - tlsx - inteligencia desde TLS|tlsx]].

<mark style="background: #FF5582A6;">El fingerprint por defecto de tu herramienta es una firma</mark>: la librería TLS estándar de Go, `python-requests` o un C2 sin tunear tienen JA3/JA4 catalogados en listas de bloqueo. Mandas un paquete perfectamente cifrado y aun así cantas por **cómo** lo cifras.

# Blending: parecerse a lo legítimo

La única evasión que queda contra todo lo anterior es **fundirse con el tráfico normal**, en las tres dimensiones a la vez:

- **Fingerprint de navegador real (uTLS)**: la librería `uTLS` (refraction-networking) construye un `ClientHello` idéntico al de Chrome o Firefox, de modo que tu <mark style="background: #8000E1A6;">JA3/JA4 pasa a ser el de un navegador cualquiera</mark>. Es la contramedida directa al fingerprinting de cliente y la base de muchos C2 y herramientas de evasión de censura.
- **SNI y *fronting***: el *domain fronting* clásico —SNI de un dominio de confianza, `Host` interno distinto, que la CDN enruta a tu backend— está **mayormente muerto** desde que AWS CloudFront (2018), Google y Cloudflare forzaron `SNI == Host`. Su sucesor emergente es **ECH** (*Encrypted Client Hello*): cifra el `ClientHello` entero, **incluida la SNI**, con una clave publicada por DNS. Donde el servidor lo soporta (Cloudflare lo ofrece), el DPI deja de ver a qué dominio vas — pero depende del lado servidor, no lo activas tú solo.
- **Fundirse con SaaS**: montar el C2 sobre un servicio permitido —`Slack`, `Teams`, GitHub, un bucket— convierte tu tráfico en tráfico que la organización ya autoriza y no puede bloquear sin romper el negocio (MITRE T1102, *Web Service*). Y ajustar el perfil (tamaños, cabeceras, ritmo) para que se parezca al SaaS real.

| Capa de inspección | Qué ve | Cómo te fundes |
| --- | --- | --- |
| **App-ID / DPI** | Que "eso" no es HTTPS real | Túnel que sí habla HTTPS/HTTP correcto |
| **Interceptación TLS** | El claro (solo si gestionado) | Operar sin la CA; categorías excluidas; *pinning* |
| **JA3/JA4 (cliente)** | Qué software cifra | `uTLS` con fingerprint de navegador |
| **JARM (tu servidor)** | Tu C2 por su pila TLS | Perfil TLS a medida, no el por defecto |
| **SNI en claro** | A qué dominio vas | ECH donde exista; dominio con reputación |

# Probarlo y verlo desde el otro lado

Para **ver** qué expone tu propio tráfico —qué SNI viaja en claro, qué JA4 emites, si un middlebox reescribe el certificado— se monta un MITM de laboratorio con [[00 - Introducción a mitmproxy|mitmproxy]] o [[00 - bettercap - suite de MITM|bettercap]] y se inspecciona el `ClientHello`. La detección de CDN/WAF que hay delante (para decidir si el *fronting* siquiera aplica) sale de [[03 - asnmap y cdncheck - superficie por ASN y detección de CDN|cdncheck]]. Los fundamentos del propio handshake, en [[02 - Handshake TLS 1.2 y 1.3|el handshake TLS]].

> [!info]+ Fuentes
> Fingerprinting: [JA4+](https://github.com/FoxIO-LLC/ja4) (FoxIO), [JA3](https://github.com/salesforce/ja3) y [JARM](https://github.com/salesforce/jarm) (Salesforce). Imitación de `ClientHello`: [uTLS](https://github.com/refraction-networking/utls). *Encrypted Client Hello*: [borrador de la TLS WG](https://datatracker.ietf.org/doc/draft-ietf-tls-esni/) y el [despliegue de Cloudflare](https://blog.cloudflare.com/encrypted-client-hello/). Clasificación por aplicación: [App-ID de Palo Alto](https://docs.paloaltonetworks.com/pan-os/11-1/pan-os-admin/app-id). Técnicas MITRE ATT&CK: [T1573](https://attack.mitre.org/techniques/T1573/) *Encrypted Channel*, [T1090.004](https://attack.mitre.org/techniques/T1090/004/) *Domain Fronting*, [T1102](https://attack.mitre.org/techniques/T1102/) *Web Service*. JARM en la práctica, con [[06 - tlsx - inteligencia desde TLS|tlsx]].
