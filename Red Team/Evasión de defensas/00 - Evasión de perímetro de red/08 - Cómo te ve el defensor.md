---
tags:
  - Evasion
  - Escaneo/Redes
  - Pentesting/Enumeracion
  - Tipo/Deteccion
Descripción: "La operación de perímetro vista desde el SOC — cómo se correlacionan los sensores en una narrativa y qué indicador tuyo cuesta más rotar"
Fecha de actualización: 2026-08-04
Nota previa: "[[07 - Low-and-slow y evasión de umbrales]]"
Nota siguiente: "[[09 - Arsenal de evasión de perímetro]]"
Area: "[[Evasión de perímetro.base|Evasión de perímetro]]"
---
---

No se evade lo que no se entiende. Esta nota es la vista **desde el otro lado**: qué ve el SOC cuando cruzas su perímetro, no sección por sección —eso está en las notas de cada técnica— sino **en conjunto**. La detección del escaneo en sí, con su telemetría de red y nube, la desarrolla [[08 - Detección de escaneos y evasión moderna|la nota de Nmap]]; aquí se ensambla el cuadro completo de una operación de perímetro.

# El defensor no ve paquetes, ve una narrativa

Un SOC maduro no reacciona a un paquete aislado: **correlaciona sensores** en un SIEM y construye una historia. Los sensores que registran tu paso por el perímetro, y que rara vez actúan solos:

| Sensor | Qué aporta a la narrativa |
| --- | --- |
| **Logs del firewall** | Denegaciones y permisos: el mapa de qué intentaste |
| **IDS/IPS** | Alertas por firma y por umbral ([[07 - Low-and-slow y evasión de umbrales\|umbral]]) |
| **NDR conductual** | La desviación de lo normal: fan-out, destinos nuevos |
| **NetFlow / VPC Flow Logs** | Metadatos de cada conexión, retenidos |
| **Proxy / SWG** | Cada destino de salida con URL, categoría y usuario |
| **Logs de DNS** | Volumen y entropía anómalos (túnel DNS) |
| **Threat intel** | Reputación de tus IPs y dominios |
| **Fingerprints TLS (JA4)** | Qué software habla, aunque vaya cifrado |

<mark style="background: #ADCCFFA6;">El poder del SOC no está en ningún sensor, sino en unirlos</mark>: «esta IP escaneó a las 02:14, intentó login a las 02:20 y abrió una sesión saliente a las 02:41». Tres eventos que por separado son ruido, juntos son un incidente. Y el hilo que los cose es casi siempre **el origen común** — por eso la [[06 - Rotación de origen e infraestructura sacrificable|rotación de origen]] no es un lujo: rompe la correlación que convierte eventos sueltos en un caso.

# La Pirámide del Dolor, aplicada a ti

El marco que ordena todo esto es la [[01 - Frameworks de threat intelligence y la Pyramid of Pain|Pirámide del Dolor]] de David Bianco, leída **desde el atacante**. Mide cuánto te duele que el defensor te detecte por cada tipo de indicador:

- **IPs y dominios** (base): te detectan por ahí y **rotas en minutos**. Poco dolor.
- **Artefactos de red/host y fingerprints** (`JA4`, User-Agent, perfil de C2): rotarlos cuesta más — hay que reconfigurar la herramienta.
- **TTPs y comportamiento** (cima): te detectan por *cómo operas* —el patrón de fan-out, el ritmo del beacon, la secuencia de acciones— y para evadirlo tendrías que **cambiar tu forma de trabajar**. Máximo dolor.

<mark style="background: #FF5582A6;">La conclusión que gobierna las siete notas de este bloque: mantén al defensor detectándote por lo barato de rotar, y no le regales nunca un indicador estable de la cima</mark>. Deformar el paquete ([[04 - Fragmentación y evasión a nivel IP y TCP|fragmentación]]) es pelear en la base y perder por atrición; el *blending* de comportamiento ([[05 - DPI, inspección TLS y blending de tráfico|fingerprint de navegador]], [[07 - Low-and-slow y evasión de umbrales|ritmo humano]]) es negarle la cima. Ahí está la diferencia entre evasión viva y muerta.

# Qué deja cada acción

| Tu acción | Rastro que deja | Dónde salta |
| --- | --- | --- |
| Escaneo | Fan-out a muchos puertos/hosts | IDS umbral + NDR + flow logs |
| Egress / C2 | Beacon periódico, JA4 no-navegador | NDR + proxy + JA4 |
| Túnel DNS/ICMP | Volumen y entropía anómalos | Logs DNS + [[15 - Detección y evasión de túneles\|detección de túneles]] |
| Rotación de origen | Sube el coste de correlación... | ...pero dominio/JA4/comportamiento aún te unen |
| Sonda a un señuelo | Un solo paquete = alerta de alta confianza | Honeypot / canary |

# La dimensión temporal: la evidencia te sobrevive

El error de encuadre más común es pensar en tiempo real. <mark style="background: #8000E1A6;">Aunque nadie mire en el momento, los logs se retienen</mark>: los VPC Flow Logs, el NetFlow y el SIEM guardan meses. Un escaneo *low-and-slow* que evadió la alerta en vivo sigue estando en los datos cuando el cliente investigue un incidente y mire atrás. La detección retrospectiva es real, y en la nube es el modo por defecto. La regla operativa: **asume análisis retrospectivo** — no te delata quien vigila ahora, sino quien correlaciona después.

> [!warning]+ Las trampas dan detección de alta confianza gratis
> Un **honeypot** o un **canary token** —un servicio o un puerto que no existe para ningún uso legítimo— convierte un solo paquete tuyo en una alerta sin falsos positivos: nadie legítimo lo toca, así que si algo lo toca, es un atacante. Barrer `-p-` a ciegas es la forma más rápida de pisar uno. La cara defensiva, en [[03 - Deception defensiva - honeypots, tiger traps y captura en vivo|deception defensiva]].

> [!important]+ Qué hacer con esto
> No se trata de ser invisible —no lo serás—, sino de **elegir el nivel de la pirámide en el que aceptas ser detectado** y minimizar los indicadores por encima. Antes de cada fase, pregúntate qué rastro deja y si ese rastro te ata por algo caro de cambiar. Y recuerda que en un ejercicio **anunciado** buena parte de esto se resuelve coordinando con el SOC, no escondiéndote de él ([[00 - El mindset del atacante persistente|mindset del atacante persistente]]).

> [!info]+ Fuentes
> [Pirámide del Dolor](https://detect-respond.blogspot.com/2013/03/the-pyramid-of-pain.html) — David J. Bianco (2013). Sensores y su colocación: [[01 - Sensores defensivos - tipos y colocación]]; cultura y límites del SOC: [[04 - Cultura del SOC, complacencia y vigilancia]] (Blue Team). Detección de escaneo con telemetría de red y nube: [[08 - Detección de escaneos y evasión moderna]] (Nmap). Marco de técnicas: MITRE ATT&CK [T1046](https://attack.mitre.org/techniques/T1046/), [T1071](https://attack.mitre.org/techniques/T1071/), [T1572](https://attack.mitre.org/techniques/T1572/).
