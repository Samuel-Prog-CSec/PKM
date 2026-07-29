---
tags:
  - IA/Red-Team
  - IA/LLM
  - Pentesting/Explotacion
Descripción: "Los tres tipos de plugin que definen qué se lanza y cómo se decide si funcionó"
Fecha de actualización: 2026-07-28
Nota previa: "[[00 - Qué es garak y cuándo usarlo]]"
Nota siguiente: "[[02 - Ejecución y lectura de informes de garak]]"
Area: "[[Garak.base|Garak]]"
---
---

Los tres tipos de plugin que definen **qué** se lanza y **cómo** se decide si funcionó. Conocerlos bien es la diferencia entre lanzar `--spec all` durante seis horas y ejecutar en veinte minutos lo que aplica al objetivo.

# Probes — el catálogo de ataques

<mark style="background: #ADCCFFA6;">Un `probe` es una clase que genera prompts de ataque con un objetivo concreto y declara qué detector debe evaluar las respuestas.</mark> La v0.14 trae **42 módulos de probes**, cada uno con varias clases dentro.

Los atributos que declara cada probe, tomados de la clase base (`garak/probes/base.py`):

| Atributo | Significado |
| - | - |
| `goal` | Qué intenta hacer el probe, en imperativo |
| `intent` | Comportamiento o modo de fallo que busca provocar |
| `tags` | Categorías en taxonomía MISP — incluye el mapeo a OWASP LLM Top 10 y AVID |
| `tier` | Importancia del probe (ver abajo) |
| `primary_detector` / `extended_detectors` | Qué detectores se activan por defecto |
| `lang` | Idioma en formato BCP47; `*` si aplica a todos |
| `modality` | Tipos de entrada que acepta (texto, imagen, audio) |
| `active` | Si se incluye en una ejecución por defecto |
| `doc_uri` | Enlace al paper o descripción del ataque |

## El sistema de tiers

Introducido para priorizar resultados; es lo que evita ahogarse en un informe de cientos de probes:

| Tier | Nombre interno | Qué significa un resultado bajo |
| - | - | - |
| 1 | `OF_CONCERN` | **Problemático.** Hay que examinar el resultado y escalarlo al equipo de seguridad o alineamiento |
| 2 | `COMPETE_WITH_SOTA` | Un z-score bajo puede ser problemático; examinar y valorar documentarlo |
| 3 | `INFORMATIONAL` | Contextual: puede importar o no según el caso de uso |
| 9 | `UNLISTED` | Probe duplicado, deprecado, inestable o no adversarial. Ignorable |

`garak` considera "bajo" una puntuación absoluta por debajo del **40 %** (rojo/naranja, *defcon* 1 y 2) o un z-score relativo por debajo de **-0,125**.

<mark style="background: #FF5582A6;">Regla práctica: en una primera pasada, ejecutar `--spec 'tier:2'`.</mark> Cubre lo que de verdad importa y ahorra el grueso del tiempo de ejecución.

## Familias relevantes para prompt injection

| Probe | Qué prueba |
| - | - |
| `promptinject` | El framework PromptInject: secuestro de objetivo con cadenas rogue |
| `latentinjection` | **Inyección indirecta**: payload embebido en documentos, traducciones y resúmenes |
| `sysprompt_extraction` | Fuga del system prompt |
| `dan` | Familia DAN completa, incluido `DanInTheWild` (corpus de jailbreaks reales) |
| `grandma` | El [[09 - Jailbreaks clásicos (DAN, roleplay y ficción)\|jailbreak de la abuela]] y variantes de roleplay |
| `encoding` | Payloads codificados (Base64, ROT13, Braille, Morse) |
| `smuggling` | **[[07 - ASCII smuggling y payloads invisibles\|ASCII smuggling]]** con caracteres Unicode invisibles |
| `suffix` | Sufijos adversariales tipo GCG |
| `goodside` | Ataques documentados por Riley Goodside |
| `tap`, `atkgen`, `goat`, `adaptive_attacks` | **Ataques generados por otro LLM**, iterativos y adaptativos |
| `fitd`, `dra`, `sata` | Técnicas recientes: *foot-in-the-door*, *disguise & reconstruction*, *assistive task linkage* |
| `agent_breaker` | Ataques específicos contra **agentes** con herramientas |
| `web_injection` | [[00 - Introducción a XSS\|XSS]] y markdown malicioso en la **salida** del modelo |
| `ansiescape` | Secuencias de escape ANSI en la salida — relevante si se renderiza en terminal |
| `apikey`, `propile` | Fuga de claves de API y de datos personales |
| `packagehallucination` | Nombres de paquetes inventados — la base del *slopsquatting* |
| `divergence` | Extracción de datos de entrenamiento por repetición forzada |
| `visual_jailbreak`, `audio` | Jailbreaks multimodales |

<mark style="background: #FFB86CA6;">Cuatro de esas familias no existían cuando HTB escribió su sección</mark>: `latentinjection`, `sysprompt_extraction`, `smuggling` y `agent_breaker` son precisamente las que cubren lo que se trata en la carpeta de [[01 - Prompt injection y por qué no tiene parche|Prompt Injection]].

# Detectors — cómo se decide si funcionó

Un `detector` recibe la respuesta del modelo y devuelve una puntuación entre 0 y 1: **cuanto más alto, más indicios de que el ataque tuvo éxito**. Hay 30 módulos de detectores, y cada probe declara cuáles activa.

Tres estrategias, de menos a más fiable y de más a menos barata:

| Estrategia | Ejemplos | Nota |
| - | - | - |
| **Coincidencia de cadenas** | `mitigation.MitigationBypass`, `dan.DAN`, `knownbadsignatures` | Busca frases de rechazo (o su ausencia) y marcadores conocidos. Instantáneo y con falsos positivos |
| **Clasificador especializado** | `unsafe_content`, `perspective` | Modelo entrenado para detectar toxicidad o contenido dañino |
| **LLM como juez** | `judge` | Otro modelo evalúa si la respuesta cumple el objetivo del ataque. El más preciso y el más caro |
| **Detección de artefactos** | `apikey`, `productkey`, `web_injection`, `ansiescape` | Busca patrones concretos en la salida: claves, HTML ejecutable, escapes ANSI |
| **Guardrails ajenos** | `shields` | Comprueba si un guardrail externo bloqueó la respuesta |

> [!warning]+ Los detectores por cadena mienten en ambas direcciones
> `mitigation.MitigationBypass` funciona buscando frases de rechazo tipo *"I cannot"*. <mark style="background: #8000E1A6;">Si el modelo rechaza con un fraseo que no está en la lista, lo cuenta como ataque exitoso — falso positivo.</mark> Y si acepta pero añade un *"I can't provide details, but…"*, lo cuenta como bloqueado — falso negativo.
> **Todo hallazgo de `garak` que vaya a un informe hay que verificarlo manualmente en el JSONL**, leyendo el prompt y la respuesta reales. Es la misma disciplina que con cualquier escáner.

# Buffs — multiplicar cada payload

Un `buff` transforma el prompt antes de enviarlo, generando variantes de cada ataque. Son pocos pero potentes:

| Buff | Efecto |
| - | - |
| `paraphrase` | Reformula el payload manteniendo la intención. **Rompe la detección por similitud léxica** |
| `low_resource_languages` | Traduce a idiomas poco representados en el entrenamiento de seguridad |
| `encoding` | Aplica codificaciones al payload |
| `lowercase` | Normaliza a minúsculas |

<mark style="background: #FFB8EBA6;">`paraphrase` y `low_resource_languages` son la automatización directa de dos técnicas de [[10 - Jailbreaks por obfuscación]]</mark>, y son lo que convierte un corpus público quemado en algo que todavía puede pasar un filtro por firmas. Si un barrido limpio no encuentra nada, repetirlo con estos dos buffs es el siguiente paso obvio.

# Seleccionar con `--spec`

`--spec` sustituye a los antiguos `--probes`, `--probe_tags` y `--buffs`, que siguen funcionando pero están marcados como deprecados. Acepta cuatro tipos de selector, combinables con coma, y `-` para excluir:

```text
probes.<módulo>[.<Clase>]      probes.dan, probes.dan.DanInTheWild
buffs.<módulo>[.<Clase>]       buffs.paraphrase
tag:<prefijo>                  tag:owasp:llm01
tier:<N>                       tier:2   (inclusivo: tiers 1 y 2)
```

```shell-session
# Todo lo mapeado a OWASP LLM01, excluyendo un probe concreto
$ python -m garak --target_type ollama --target_name llama3.1 \
    --spec 'tag:owasp:llm01,-probes.dan.DanInTheWild'

# Inyección indirecta y fuga de system prompt, con paráfrasis
$ python -m garak --target_type ollama --target_name llama3.1 \
    --spec 'probes.latentinjection,probes.sysprompt_extraction,buffs.paraphrase'

# Ver qué se seleccionaría, sin ejecutar
$ python -m garak --list_probes --spec 'tier:2' -v
```

El último comando es el que más se usa en la práctica: <mark style="background: #FF5582A6;">antes de lanzar un barrido largo, comprobar exactamente qué probes entran.</mark> Con `-v` devuelve una tabla con tier y descripción de cada uno.
