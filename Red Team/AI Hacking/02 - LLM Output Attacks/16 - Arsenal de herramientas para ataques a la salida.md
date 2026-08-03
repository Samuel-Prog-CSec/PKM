---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting
  - Tipo/Arsenal
Descripción: "La particularidad de este módulo es que el arsenal es en su mayoría el del pentesting web clásico"
Fecha de actualización: 2026-07-28
Nota previa: "[[15 - Detección y evasión en ataques a la salida]]"
Nota siguiente: 
Area: "[[LLM Output Attacks.base|LLM Output Attacks]]"
---
---

> [!info]+ Nota añadida al temario
> Eje 3 del vault. HTB no dedica sección de herramientas a este módulo. El arsenal general de red teaming de IA está en [[13 - Arsenal de herramientas para red teaming de IA]] y el de prompt injection en [[15 - Arsenal de herramientas para prompt injection]]; aquí, lo específico de atacar la **salida**.

<mark style="background: #ADCCFFA6;">La particularidad de este módulo es que el arsenal es en su mayoría el del pentesting web clásico.</mark> El vector de entrada es un prompt, pero el bug está en un sink de toda la vida, y se prueba con las herramientas de siempre. Lo único específico de IA es el descubrimiento.

# Por fase

| Fase | Herramienta | Para qué |
| - | - | - |
| Descubrir sinks | **`garak`** (`--spec`) | Barrido automatizado: qué sinks responden |
| | `Burp Suite` | Ver la petición y la respuesta reales, incluido el JSON intermedio de las llamadas a herramienta |
| Explotar el sink | Burp Repeater, payloads manuales | El bug es clásico; la explotación también |
| Confirmar exfiltración | `interactsh`, Burp Collaborator, `python3 -m http.server` | Canal fuera de banda sin adjuntar datos reales |
| Payloads invisibles | `ASCII Smuggler` | [[07 - ASCII smuggling y payloads invisibles\|Entrega sigilosa]] del payload que genera la salida |
| Cadena de suministro | `pip-audit`, `OSV-Scanner`, `Socket`, `Syft`+`Grype` | Auditar dependencias contra [[08 - Slopsquatting y alucinación de paquetes\|slopsquatting]] |
| Regresión para el cliente | `promptfoo` | Batería reproducible con mapeo a OWASP LLM Top 10 |
| Agentes con herramientas | `AgentDojo` | Benchmark de inyección indirecta contra agentes |

# garak — las probes que aplican aquí

Las familias de [[01 - Probes, detectors y buffs de garak|probes]] que cubren esta carpeta, y que son distintas de las del módulo de prompt injection:

| Probe | Qué mide | Nota del vault |
| - | - | - |
| `web_injection` | XSS y markdown malicioso en la salida | [[01 - XSS desde la salida del modelo]] |
| `exploitation` | Generación de payloads de explotación | Varias |
| `packagehallucination` | **Tasa de paquetes inexistentes recomendados** | [[08 - Slopsquatting y alucinación de paquetes]] |
| `ansiescape` | Secuencias de escape ANSI en la salida | Relevante si se renderiza en terminal — agentes CLI |
| `apikey`, `propile` | Fuga de claves y datos personales | [[06 - Exfiltración por renderizado de markdown]] |
| `latentinjection` | Inyección desde documentos, que es el vector de entrada | [[05 - Inyección indirecta en RAG, email y web]] |
| `divergence` | Extracción de datos de entrenamiento | — |

```shell-session
# Barrido enfocado a salida insegura
$ python -m garak --target_type rest --config target.yaml \
    --spec 'probes.web_injection,probes.packagehallucination,probes.ansiescape,probes.apikey' -g 10
```

<mark style="background: #FFB8EBA6;">`packagehallucination` merece ejecutarse siempre que el cliente use asistentes de programación</mark>, aunque el objetivo del engagement sea otro: da una cifra concreta de exposición a slopsquatting para el modelo que usa el equipo, y es un hallazgo que casi nadie mide.

La configuración del generador `rest` contra la aplicación real está en [[03 - garak contra una aplicación real y en CI]].

# Herramientas web aplicadas al sink

Una vez confirmado el sink, se ataca con el arsenal de siempre:

- **XSS** — payloads y ofuscación de [[06 - Evasión de filtros XSS y ofuscación]]. Ojo con la particularidad del canal: el payload tiene que sobrevivir **al modelo** antes de llegar al DOM, así que los más cortos y menos "maliciosos a la vista" ganan.
- **SQLi** — `sqlmap` **no** encaja aquí: automatiza la inyección sobre un parámetro HTTP, y en [[02 - SQL injection a través del LLM|text-to-SQL]] el "parámetro" es lenguaje natural y la consulta la escribe el modelo. La explotación es manual, apoyada en el catálogo de [[06 - Enumeración de la base de datos]]. Sí sirve, en cambio, sobre una [[05 - Agencia excesiva y funciones vulnerables|función vulnerable]] alcanzable por HTTP directo.
- **Inyección de comandos** — operadores y bypasses de [[07 - Ofuscación avanzada de comandos]], y `Argument injection` cuando los metacaracteres están filtrados.
- **Sanitizadores** — para evaluar la defensa del cliente, probar su configuración de `DOMPurify` o del renderizador markdown contra un corpus de bypasses conocidos.

# Auditar la cadena de suministro

Para el vector de [[08 - Slopsquatting y alucinación de paquetes|paquetes alucinados]], que se trabaja desde el lado defensivo:

| Herramienta | Para qué |
| - | - |
| `pip-audit`, `npm audit` | Vulnerabilidades conocidas en dependencias. Punto de partida, no detecta slopsquatting |
| **`OSV-Scanner`** | Contra la base OSV; cobertura amplia y multi-ecosistema |
| **`Socket`** | <mark style="background: #FF5582A6;">El más útil aquí</mark> — analiza **comportamiento** del paquete (scripts de instalación, red, acceso al sistema de ficheros) y señala paquetes nuevos o de baja reputación |
| `Syft` + `Grype` | Generar SBOM y escanearlo. Necesario para el inventario del paso 1 de la auditoría |
| `deps.dev` | Consultar antigüedad, mantenedores y grafo de dependencias de un paquete concreto |

El flujo de auditoría: `Syft` para el inventario → contrastar fecha de publicación contra la del código → `Socket` sobre las sospechosas → revisar `README` y documentación en busca de comandos de instalación no verificados.

# Detectores de contenido como objetivo

Si el alcance incluye evaluar la moderación, estos son los modelos que hay al otro lado y que conviene poder ejecutar en local para calibrar el ataque:

- **`Detoxify`** y **`HateXplain`** — clasificadores de toxicidad. Ejecutarlos en local permite medir el `toxicity score` de cada variante **antes** de enviarla al objetivo, que es la diferencia entre iterar a ciegas y iterar con retroalimentación.
- **`TextAttack`** — implementa `DeepWordBug`, `PWWS` y el resto de ataques adversariales de NLP de [[11 - Evasión de detectores de contenido]]. Es la herramienta que automatiza las tres capas de evasión.
- **`ShieldGemma`** — descargable y ejecutable en local; permite reproducir el guardrail del objetivo si se ha identificado. Su formato de prompt y sus puntos débiles, en [[13 - Safeguards en producción (Model Armor y ShieldGemma)]].

<mark style="background: #8000E1A6;">Ejecutar el detector en local es la medida de OPSEC más importante de esta parte</mark>: cada variante probada contra el objetivo es un evento de moderación registrado. Con una copia local, contra el objetivo solo van las variantes que ya se sabe que puntúan por debajo del umbral.

# Flujo sugerido

1. **Sondas de sink** manuales, en orden de coste: `Test<b>HelloWorld</b>` para HTML, una comilla para SQL, una pregunta en prosa para detectar `eval()`, una imagen markdown para el canal de exfiltración.
2. **Enumerar funciones** preguntando al modelo, y probar cada una como un endpoint ([[05 - Agencia excesiva y funciones vulnerables]]).
3. **Barrido con `garak`** contra el endpoint real, para cubrir lo que las sondas manuales no alcanzan.
4. **Explotar el sink** con el arsenal web clásico, usando el patrón del indirector cuando el modelo se resista.
5. **Confirmar impacto** con canario propio, sin exfiltrar datos reales.
6. **Auditar dependencias** si el cliente usa asistentes de programación.
7. **Entregar** los hallazgos con [[09 - Mitigación del tratamiento inseguro de la salida#Cómo redactarlo en el informe|CWE clásico y control del sink]], más una batería `promptfoo` reproducible.
