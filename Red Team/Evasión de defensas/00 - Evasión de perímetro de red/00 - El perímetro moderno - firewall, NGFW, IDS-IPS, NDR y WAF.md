---
tags:
  - Evasion
  - Escaneo/Redes
  - Pentesting/Enumeracion
  - Tipo/Introduccion
Descripción: "Qué hay realmente entre tú y el objetivo en 2026, qué ve cada capa y por qué la evasión clásica dejó de funcionar"
Fecha de actualización: 2026-08-04
Nota previa:
Nota siguiente: "[[01 - Perfilar el perímetro antes de escanear]]"
Area: "[[Evasión de perímetro.base|Evasión de perímetro]]"
---
---

El resto de esta área trata la evasión **del endpoint**: EDR, hooks, callbacks de kernel, ETW. Este bloque trata lo que hay **antes**: el conjunto de dispositivos y servicios que inspeccionan el tráfico entre tu máquina y el objetivo. Son dos problemas distintos con contramedidas distintas, y el orden en un ataque real es este primero.

<mark style="background: #ADCCFFA6;">La mayoría del material de evasión de red que circula describe un mundo de 1999</mark>: un filtro de paquetes sin estado al que se le cuelan fragmentos y *decoys*. Ese dispositivo prácticamente no existe ya en un perímetro corporativo. Esta nota fija qué hay de verdad.

# Las capas y qué ve cada una

| Capa | Qué decide | Qué **no** ve |
| --- | --- | --- |
| **Filtro de paquetes sin estado** | Permitir/denegar por IP, puerto, protocolo | Nada del contenido ni de la sesión |
| **Firewall con estado** | Lo anterior + si el paquete pertenece a una sesión válida | El contenido de la aplicación |
| **NGFW** | Lo anterior + aplicación (L7), usuario, categoría de URL, IPS integrado | Lo cifrado (salvo que rompa TLS) |
| **IDS** | Alerta sobre firmas y anomalías; **pasivo** | Nada, no bloquea |
| **IPS** | Igual que el IDS pero **corta** | — |
| **NDR** | Modela el comportamiento normal y marca la desviación | — |
| **WAF** | Contenido HTTP/S: payloads, cabeceras, ritmo, reputación | Lo que no sea tráfico web |
| **Proxy / SWG** | Todo lo que sale: URL, categoría, tipo de fichero | El tráfico que no pase por él |
| **CDN / anti-DDoS** | Absorbe y filtra antes de llegar al origen | — |
| **Flow logs cloud** | Metadatos de cada conexión, retenidos | El contenido |

## Firewall con estado: el que mató media técnica clásica

<mark style="background: #8000E1A6;">Es el cambio que invalida más literatura</mark>. Un firewall con estado mantiene una tabla de sesiones y descarta cualquier segmento que no encaje en una:

- Un `ACK` suelto, un `FIN` suelto, un paquete `NULL` o `Xmas` → **no pertenecen a ninguna sesión → se tiran antes de mirar la ACL de puertos**.
- Los fragmentos IP se **reensamblan** antes de decidir, así que fragmentar no oculta nada.
- Las combinaciones ilegales de flags se descartan por inválidas.

Por eso las técnicas de [[07 - Evasión de firewalls, IDS e IPS|evasión clásica de Nmap]] y los escaneos de flags de [[02 - Evasión de firewalls y detección con sx|sx]] son hoy herramientas de **diagnóstico** —sirven para saber qué clase de dispositivo tienes delante— y no de evasión.

## IDS/IPS: de firma a comportamiento

`Snort`, `Suricata` y `Zeek` ya no buscan solo el paquete "malo": buscan el **patrón**. Un origen que toca muchos puertos o muchos hosts en poco tiempo dispara por umbral, sin importar la forma de los paquetes.

Y por encima está el **NDR** (Darktrace, Vectra, ExtraHop y similares), que <mark style="background: #FFB86CA6;">modela lo que es normal en esa red y marca lo que se desvía</mark>. Contra un motor así, deformar el paquete no sirve de nada: lo que detecta es que un host esté hablando con doscientos destinos con los que nunca habló.

## La nube ve sin desplegar nada

Un objetivo en AWS/Azure/GCP genera **logs de flujo** de cada conexión por defecto. No hace falta un IDS: los metadatos ya están ahí, retenidos y consultables después del hecho. Es una diferencia importante respecto a un IDS clásico — <mark style="background: #FF5582A6;">aunque nadie mire en el momento, la evidencia queda</mark> y aparece cuando el cliente investigue.

El matiz de AWS GuardDuty ya está desarrollado en [[08 - Detección de escaneos y evasión moderna]]: el hallazgo de sondeo externo **exige que tu IP figure como escáner conocido**, lo que convierte la reputación de tu infraestructura en un activo operativo ([[06 - Rotación de origen e infraestructura sacrificable]]).

# Qué funciona y qué no, resumido

| Técnica | Estado en 2026 |
| --- | --- |
| Fragmentación (`-f`, `--mtu`) | <mark style="background: #FF5582A6;">Muerta</mark> contra cualquier cosa que reensamble |
| Decoys (`-D`) | Muerta: los ISP filtran el origen falsificado |
| `--badsum` | Solo como **diagnóstico**: distingue un stack real de un inspector |
| FIN / NULL / Xmas | Diagnóstico contra filtros sin estado; **dispara el IDS al instante** |
| Idle scan (`-sI`) | Casi imposible: requiere un host con IP ID predecible |
| Source port de confianza (53, 443) | **Sigue funcionando** en firewalls con reglas perezosas |
| IPv6 en redes dual-stack | **Funciona muy bien** — el filtrado IPv6 suele ir por detrás |
| Low-and-slow | **Funciona**, es lo único que evade un umbral bien puesto |
| Blending con tráfico legítimo | **Funciona** |
| Rotación de origen | **Funciona** y sube mucho el coste de correlación |
| Recon pasivo | **Funciona siempre**: no hay tráfico que detectar |

<mark style="background: #ADCCFFA6;">El patrón es claro: lo que va de **deformar el paquete** está muerto; lo que va de **mandar menos y parecerse a lo normal** sigue vivo</mark>. La razón de fondo es que las defensas pasaron de inspeccionar forma a inspeccionar comportamiento, y el comportamiento solo se disimula comportándose de otra manera.

# Cómo se recorre este bloque

1. **[[01 - Perfilar el perímetro antes de escanear]]** — averiguar qué tienes delante antes de decidir nada.
2. **[[02 - Descubrir la política de filtrado]]** — qué deja pasar y hacia dónde.
3. **[[03 - Egress filtering - por dónde se sale]]** — el lado que casi nadie prueba y el que decide si tu C2 y tus túneles van a funcionar.
4. **[[04 - Fragmentación y evasión a nivel IP y TCP]]** — la caja de herramientas clásica: qué queda vivo y por qué.
5. **[[05 - DPI, inspección TLS y blending de tráfico]]** — cuando el perímetro abre el TLS.
6. **[[06 - Rotación de origen e infraestructura sacrificable]]** — OPSEC de la infraestructura desde la que operas.
7. **[[07 - Low-and-slow y evasión de umbrales]]** — la única técnica que sigue derrotando a un IDS bien afinado.
8. **[[08 - Cómo te ve el defensor]]** — la vista desde el otro lado.
9. **[[09 - Arsenal de evasión de perímetro]]** — el set de herramientas actual.

> [!important]+ Esto no sustituye a la evasión de endpoint
> Atravesar el perímetro te deja **delante** del EDR, no detrás de él. Los dos problemas se resuelven con técnicas y herramientas distintas, y la cadena de ataque necesita las dos: perímetro para llegar, [[00 - Anatomía de un EDR|endpoint]] para ejecutar y persistir.

> [!warning]+ Lo legal manda sobre lo técnico
> Todo lo de este bloque se hace **dentro de un scope autorizado por escrito**. Sondear el perímetro de una organización sin autorización encaja en el **art. 197 bis CP** (acceso o mantenimiento en sistemas ajenos vulnerando medidas de seguridad), y la evasión de controles agrava la lectura, porque acredita intención. En bug bounty, muchos programas prohíben explícitamente las técnicas de evasión ([[01 - Reglas, legalidad y conducta]]). Y hay un matiz de encargo: si el cliente contrata un test **no evasivo**, evadir sin permiso rompe el contrato aunque técnicamente puedas ([[12 - Niveles de evasividad y testing dirigido por amenazas (TLPT)]]).

> [!info]+ Fuentes
> Base defensiva en [[08 - Detección de escaneos y evasión moderna]] (Suricata/Zeek, flow logs, GuardDuty) y MITRE ATT&CK [T1046](https://attack.mitre.org/techniques/T1046/) · *Network Service Discovery*. Las herramientas concretas y sus flags viven en sus notas de [[Tools.base|Tools]]; aquí solo se aplican.
