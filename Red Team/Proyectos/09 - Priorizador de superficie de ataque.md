---
tags:
  - Proyectos
  - Go
  - Web/Red-Team
  - Recon
  - Tipo/Proyecto
Descripción: "Consume la salida de tu recon y la prioriza por frescura y anomalía, para atacar la fatiga de alertas y encontrar lo que el defensor aún no ha endurecido"
Fecha de actualización: 2026-08-04
Nota previa: "[[08 - Escáner de seguridad de servidores MCP]]"
Nota siguiente: "[[10 - Cazador de SSRF moderno]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 4
Esfuerzo: 3-4 semanas
---
---

**Nombre propuesto**: `fresheye`

Una pasada de recon sobre un programa de *bug bounty* serio escupe miles de líneas: subdominios, IPs, puertos, tecnologías, certificados. Mirarlas todas es inviable, y volver a mirarlas dos semanas después para ver qué ha cambiado es un ejercicio de fuerza de voluntad que casi nadie hace. Ahí está el problema, porque <mark style="background: #FFB86CA6;">lo que paga en bug bounty no es el activo que lleva un año expuesto —ese ya lo miró todo el mundo— sino el que apareció ayer, antes de que el defensor lo endurezca</mark>. En 2025, entre el 73 % y el 74 % de las organizaciones atribuyeron algún incidente a un activo de cara a internet que no sabían que tenían.

# El problema que resuelve

Las herramientas de descubrimiento son excelentes y están saturadas: `amass`, `subfinder`, `httpx`, `nuclei` resuelven de sobra el *"¿qué hay ahí fuera?"*. Ninguna resuelve el <mark style="background: #ADCCFFA6;">*"¿qué de todo esto merece mi atención ahora mismo?"*</mark>. El resultado es un fichero de 4.000 líneas y ningún criterio para priorizar más allá del instinto, que no escala ni se transmite a un compañero.

`fresheye` no añade otra fuente de descubrimiento al montón. Añade la capa que falta encima: la que <mark style="background: #8000E1A6;">convierte el volcado de recon en una lista corta de "mira esto primero"</mark>.

# Alcance del proyecto

Consume la salida del pipeline de recon que ya usas y construye un **modelo temporal** de la superficie. Tres capas:

- **Ingesta y baseline.** Normaliza y deduplica la salida heterogénea de las herramientas en un modelo único de activo (host, puerto, servicio, tecnología, certificado, `CNAME`), y le pone a cada uno marca de *primera vez visto* y *última vez visto*. Ese registro temporal es lo que ninguna herramienta de descubrimiento guarda.
- **Diff entre pasadas.** Qué apareció, qué cambió (un puerto nuevo, una tecnología que subió —o bajó— de versión, un certificado reemitido, un `CNAME` que ahora apunta a otro sitio) y qué desapareció. El ciclo es el de cualquier monitorización seria: establecer baseline, detectar cambios contra él, enriquecer, y re-baselinar para que el estado nuevo sea la referencia.
- **Puntuación por frescura y anomalía.** Frescura es lo recién aparecido. Anomalía es lo que se sale del patrón de la **propia** superficie, calibrado contra la población observada —el mismo principio que usa el detector de señuelos (05): un umbral fijo no significa nada, la señal solo existe frente a la normalidad del objetivo—.

Señales de anomalía que suben la prioridad:

| Señal | Por qué merece mirarse antes |
| --- | --- |
| Puerto de gestión (22, 3389, 5985) donde el patrón es 443 | Superficie de administración expuesta que rompe la norma del resto de activos |
| Certificado de una CA distinta de la corporativa habitual | *Shadow IT*, un activo montado fuera del proceso, o infraestructura de un tercero |
| `CNAME` colgante hacia un recurso sin reclamar | Candidato directo a *subdomain takeover* |
| Tecnología obsoleta o en fin de vida | Superficie con CVEs conocidas donde el defensor no ha llegado |
| Subdominio que rompe el patrón onomástico (`dev-`, `staging-`, un panel) | Entornos de pre-producción, típicamente menos endurecidos |
| Activo en un ASN o *cloud* distinto del habitual | Posible subsidiaria, adquisición reciente o proveedor fuera del inventario |

# Funcionalidades principales

| Funcionalidad | Detalle |
| --- | --- |
| Modelo de activo con historia | Cada activo recuerda cuándo se vio por primera y última vez; la frescura es una propiedad, no una conjetura |
| Ingesta agnóstica de herramienta | Consume JSON de `httpx`/`nuclei`, listas de `amass`/`subfinder` y feeds de CT; no obliga a cambiar de pipeline |
| Diff con clasificación de cambio | Distingue "activo nuevo" de "activo que mutó" de "activo que se cayó" — cada uno pide una acción distinta |
| Scoring calibrado y explicado | La prioridad se justifica señal a señal; el operador ve por qué algo subió, y puede discrepar |
| Filtro de alcance de primera clase | Cruza contra el scope declarado y no prioriza lo que no se puede tocar |
| Exportación a cola de trabajo | La lista corta sale en un formato que alimenta el siguiente paso (fuzzing, nuclei dirigido, revisión manual) |

# Qué existe ya y dónde se queda corto

El **Attack Surface Management** comercial (CyCognito, Censys ASM, Recorded Future y compañía) hace exactamente este ciclo —baseline, detección de cambios, enriquecimiento, priorización— y lo hace bien. Pero es <mark style="background: #FF5582A6;">producto SaaS, caro y opaco, y está diseñado para el defensor que vigila su propia superficie</mark>, no para el pentester o el bug hunter que trabaja la superficie de un objetivo autorizado. Para ese perfil no hay equivalente: una herramienta CLI, local y offline, que corra sobre su propio pipeline sin mandar la superficie del cliente a un tercero.

Hay además una diferencia de criterio, no solo de empaquetado. El ASM prioriza por *explotabilidad* y *actividad de amenaza* genéricas; <mark style="background: #FFB8EBA6;">`fresheye` prioriza por frescura y por anomalía respecto al patrón propio</mark>, que es la señal que de verdad busca el cazador y la que se pierde en el ruido de una lista plana.

# Cosas a tener en cuenta

> [!warning]+ Monitorización continua es disciplina de alcance
> Un baseline que se alimenta de CT logs arrastra subdominios que no son tuyos para tocar: un `*.acme.com` que resuelve al CDN, el subdominio de una subsidiaria fuera del programa, la infraestructura de un proveedor. <mark style="background: #FF5582A6;">Priorizar un activo fuera de alcance es invitar al operador a salirse del scope</mark>. El filtro contra el alcance declarado —el del proyecto 00— no es opcional: es lo que separa esta herramienta de un generador de tentaciones.

- **Los CT logs mienten sobre la vida del activo.** Un certificado aparece en el log antes de que el servicio esté en pie, y a veces se emite para algo que nunca llega a existir. <mark style="background: #FFB8EBA6;">Frescura de certificado no es igual a activo vivo</mark>; la aparición en CT es una pista que hay que verificar, no un hallazgo.
- **La frescura es relativa a cuándo empezaste a mirar**, no a cuándo nació el activo. Un subdominio de hace cinco años que ves por primera vez hoy es "nuevo" para ti y viejo para el mundo. La herramienta debe declarar ese sesgo y no venderlo como recién nacido.
- **Sin calibración, la anomalía es ruido.** Una organización cuya superficie entera vive en un *cloud* poco común convierte esa señal en falso positivo constante. Las señales solo significan algo medidas contra la distribución del propio objetivo.
- **No re-escanea.** El sondeo activo es trabajo de las herramientas de descubrimiento; `fresheye` solo consume lo que ellas producen. Esa separación es la que mantiene el sigilo: la capa de decisión no genera tráfico.

# Fuera de alcance

No descubre ni escanea nada por su cuenta: orquesta y prioriza sobre la salida de otros. No es un SaaS ni guarda estado en la nube —el modelo temporal vive en un fichero local por objetivo, con la misma custodia que el resto de artefactos del engagement—. Y no explota: termina en la lista corta priorizada.

# Criterio de terminado

Cuando, dados dos *snapshots* de recon del mismo objetivo separados en el tiempo, produce la lista de lo que apareció y cambió con el `CNAME` colgante y el puerto de gestión anómalo en cabeza y la razón de cada puntuación a la vista; y cuando un activo que cae fuera del alcance declarado queda filtrado en lugar de priorizado.

# Conexiones en el vault

Las fuentes que consume están en [[07 - Certificate Transparency logs]], [[05 - Enumeración de subdominios]], [[25 - Cloud asset recon]] y la [[14 - Automatización del recon]] que produce el volcado que hay que priorizar; la detección que dispara después, en [[26 - Escaneo dirigido con nuclei]]. La señal estrella —el `CNAME` colgante— lleva directa a [[00 - Fundamentos de Subdomain Takeover]]. El filtro de alcance es el [[00 - Guardián de alcance para engagements]], y la lógica de puntuar por anomalía calibrada contra la población es la misma del [[05 - Detector de señuelos defensivos en Active Directory]].

> [!info]+ Fuentes
> - Vectra AI, [*Attack surface monitoring — continuous change detection*](https://www.vectra.ai/topics/attack-surface-monitoring) — el ciclo baseline → cambio → enriquecer → re-baseline (consultado 2026-08-04).
> - CyCognito, [*Attack Surface Management 2026 Guide*](https://www.cycognito.com/learn/attack-surface-management/) — proceso, señales de descubrimiento pasivo y el dato de incidentes por activos no gestionados.
> - Laurie, Langley & Kasper, [RFC 6962 — *Certificate Transparency*](https://www.rfc-editor.org/rfc/rfc6962) — cómo y cuándo aparece un certificado en el log, y por qué eso precede (o no) al activo.
