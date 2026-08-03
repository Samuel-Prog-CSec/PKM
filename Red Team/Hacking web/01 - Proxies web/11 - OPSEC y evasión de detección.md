---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Proxies
  - Tipo/Deteccion
Descripción: "Un proxy es ruidoso por defecto. Tu tráfico de Burp/ZAP deja huellas que los WAF y los SOC fingerprintean y bloquean, aunque falsees lo obvio"
Fecha de actualización: 2026-06-23
Nota previa: "[[10 - Extensiones y BApp Store]]"
Nota siguiente: "[[12 - Proxying de apps móviles]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

Un proxy es ruidoso por defecto. <mark style="background: #ADCCFFA6;">Tu tráfico de Burp/ZAP deja huellas que los WAF y los SOC fingerprintean y bloquean</mark>, aunque falsees lo obvio. En bug bounty importa no tumbar el servicio ni inundar el SOC del programa; en un red team con detección activa, que te identifiquen como "herramienta de pentest" quema el engagement. Esta nota cubre **cómo te delata el proxy** y **cómo operar sin que salte la alarma** — el eje de detección y evasión aplicado a tu propia actividad.

# Cómo te delata el proxy

## Cabeceras de herramienta
El `User-Agent` por defecto del navegador de Burp, o el de `curl`/`python-requests` cuando [[07 - Proxying de herramientas|proxyficas herramientas]], grita "automatización". Más sutil: <mark style="background: #FFB8EBA6;">el **orden y el casing** de las cabeceras, y la ausencia de las que un navegador real siempre manda</mark> (`Sec-Fetch-*`, `Accept-Language`, `sec-ch-ua`). Un WAF compara tu juego de cabeceras con el de un Chrome real y nota la diferencia.

## La huella TLS: JA3 / JA4 — la frontera dura
El golpe que casi nadie ve venir: <mark style="background: #FF5582A6;">falsear el `User-Agent` **no cambia tu huella TLS**.</mark> En el [[02 - Handshake TLS 1.2 y 1.3|`ClientHello` del handshake]], tu librería TLS expone su lista de cipher suites, extensiones y curvas en un orden característico. Eso se hashea en una firma:

- **`JA3`** (Salesforce): el estándar veterano, aún muy desplegado. Hashea los campos del `ClientHello`.
- **`JA4`** (FoxIO/John Althouse): el sucesor, más robusto — resiste la **randomización del orden de extensiones** que los navegadores modernos introdujeron para romper JA3.

<mark style="background: #FFB86CA6;">Cloudflare (Bot Management Enterprise), Akamai, DataDome y HUMAN Security (ex-PerimeterX) usan JA3/JA4 para detectar un stack TLS de Burp o Python **al principio del handshake, antes de ver un solo byte de la petición**.</mark> Por eso un UA y unas cabeceras perfectas no bastan: si tu JA3 dice "esto no es Chrome", te marcan igual. Es el motivo nº1 por el que un scraper/scanner "bien camuflado" sigue recibiendo `403`.

## Ruido del scanner y de Collaborator
- El [[09 - Escáner de vulnerabilidades - Burp y ZAP Scanner|active scan]] dispara ráfagas de payloads, rutas de fuzzing y *canary markers* — una firma DAST inconfundible en los logs.
- El dominio de **Burp Collaborator** (`*.oastify.com`) es conocido; algunos WAF bloquean o alertan sobre interacciones OOB hacia dominios de pentest.

# Cómo operar sigiloso

## Normalizar cabeceras
Clona las cabeceras exactas de un navegador real (orden incluido) con [[04 - Modificación automática (Match and Replace)|Match & Replace]] global: UA realista, `Accept-Language`, `Sec-Fetch-*`. Es el primer paso, necesario pero **insuficiente** por sí solo.

## Romper el fingerprint TLS
Aquí está el trabajo de verdad. Para que tu JA3/JA4 parezca el de un navegador:

| Herramienta | Qué hace |
| - | - |
| <mark style="background: #FFB86CA6;">**Burp Awesome TLS**</mark> ([sleeyax](https://github.com/sleeyax/burp-awesome-tls)) | Extensión que secuestra el stack TLS de Burp y suplanta el JA3 de cualquier navegador — evade Cloudflare/Akamai/DataDome desde dentro de Burp |
| **curl-impersonate** ([repo](https://github.com/lwthiker/curl-impersonate)) / **curl_cffi** | `curl` recompilado que imita el TLS de Chrome/Firefox; ideal para scripts |
| **tls-client** ([bogdanfinn](https://github.com/bogdanfinn/tls-client)) · **uTLS** | Clientes Go que controlan el `ClientHello` (JA3, orden de cabeceras, HTTP/2) |

<mark style="background: #8000E1A6;">La regla: si el objetivo está tras Cloudflare/Akamai y recibes `403` pese a un UA perfecto, sospecha del JA3 y enruta por uno de estos.</mark>

## Ritmo, IP y alcance
- **Throttling y jitter**: baja la velocidad del scanner/[[08 - Fuzzing web - Burp Intruder y ZAP Fuzzer|Intruder]] (resource pools), evita `-t` alto. El sigilo lento gana al barrido agresivo — misma lógica que en [[05 - Defensas y evasión|el brute forcing]].
- **Rotación de IP**: un *upstream SOCKS* o cadena de proxies reparte el origen; `fireprox` para rotar (con el [[05 - Defensas y evasión|caveat de AWS]]). Útil cuando el control es por IP.
- **OOB propio**: usa `interactsh` self-hosted o un dominio tuyo en vez de `oastify.com` para los callbacks.
- **Scope disciplinado**: excluye `/logout` y endpoints destructivos del [[09 - Escáner de vulnerabilidades - Burp y ZAP Scanner|scope]]; **nunca** lances un active scan contra producción sin autorización — es ruidoso y potencialmente dañino.

> [!warning]+ Lado defensa: lo que ve el SOC
> Saber qué te detecta es saber qué evitar. El Blue Team caza la actividad de proxy por: <mark style="background: #FFB86CA6;">JA3/JA4 anómalo, UA de herramienta, ráfagas de peticiones con payloads, secuencias de rutas de fuzzing, e interacciones OOB hacia dominios conocidos.</mark> En un engagement con detección, cada uno de esos es una bandera; en bug bounty, lo que importa es no degradar el servicio ni saturar su monitorización.

> [!info]+ Fuentes
> - [Cloudflare — JA3/JA4 fingerprint](https://developers.cloudflare.com/bots/additional-configurations/ja3-ja4-fingerprint/) · [JA4+ (FoxIO)](https://github.com/FoxIO-LLC/ja4)
> - [Burp Awesome TLS](https://github.com/sleeyax/burp-awesome-tls) · [curl-impersonate](https://github.com/lwthiker/curl-impersonate) · [tls-client](https://github.com/bogdanfinn/tls-client)
