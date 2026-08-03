---
tags:
  - Web/Red-Team
  - Whitebox
  - Tipo/Introduccion
Descripción: "Semgrep (*Semantic grep*) busca patrones en el AST del código, no en el texto: un grep que entiende la estructura del lenguaje"
Fecha de actualización: 2026-08-01
Nota previa: 
Nota siguiente: "[[01 - Reglas de Semgrep - sintaxis y patrones]]"
Area: "[[Semgrep.base|Semgrep]]"
---
---

<mark style="background: #ADCCFFA6;">Semgrep (*Semantic grep*) es un motor de análisis estático que busca patrones en el árbol de sintaxis abstracta (AST) del código en lugar de en su texto.</mark> Es la herramienta que convierte el barrido manual de `sinks` de un [[02 - Code review - alcance, priorización y lectura|whitebox pentest]] en algo repetible, y por eso es la primera del [[18 - Arsenal del whitebox pentesting|arsenal]] de esa fase.

# El problema que resuelve

Un `grep` de `eval` falla en los casos que importan: no encuentra `eval (x)` con espacio, ni `window["eval"]`, ni la llamada partida en varias líneas, y marca como positivo cualquier `eval` dentro de un comentario o una cadena. La razón es que `grep` ve **texto**, no código.

Semgrep parsea el fichero al AST del lenguaje y hace *matching* sobre esa estructura. Consecuencia práctica: <mark style="background: #FFB86CA6;">un solo patrón captura todas las variantes sintácticas de la misma construcción</mark> —espaciado, saltos de línea, comentarios intercalados, nombres de variable distintos— sin falsos positivos por texto que solo *parece* código.

```yaml
# Este patrón captura eval(cualquier_cosa) en todas sus formas
rules:
  - id: js-eval
    languages: [javascript]
    message: Uso de eval - posible inyección de código
    severity: WARNING
    pattern: eval(...)
```

`...` es el *metavariable ellipsis*: casa con cualquier lista de argumentos. `pattern: eval(...)` encuentra `eval(x)`, `eval( a, b )` y `eval(\n foo \n)` por igual, y **no** casa con la palabra `eval` dentro de un string.

# Dónde encaja en el proceso

| Fase del whitebox | Uso de Semgrep |
| --- | --- |
| [[02 - Code review - alcance, priorización y lectura\|Revisión de código]] | Barrido de `sinks` por patrón; `taint mode` para conectar `source` y `sink` |
| Enriquecer la lista corta | Reglas propias para el estilo del código base concreto |
| CI / revisión incremental | Correr en cada `pull request` (el modo *diff-based*) |
| [[16 - Patching del eval injection\|Verificación del parche]] | Confirmar que el `sink` desapareció tras el parche |

<mark style="background: #8000E1A6;">Semgrep no sustituye la lectura humana: produce candidatos.</mark> Decidir si un `sink` es alcanzable y con qué impacto sigue siendo el trabajo que se factura ([[00 - Qué es el whitebox pentesting]]).

# Lenguajes y modos de uso

Soporta más de 30 lenguajes (JavaScript/TypeScript, Python, Java, Go, C/C++, C#, Ruby, PHP, Rust…) con distinta madurez. Se usa de tres formas:

1. **Reglas del registro**: `semgrep --config auto` descarga reglas mantenidas por la comunidad y por Semgrep para el lenguaje detectado.
2. **Reglas propias**: `semgrep --config ./mis-reglas.yaml`, para el patrón concreto de un código base ([[01 - Reglas de Semgrep - sintaxis y patrones]]).
3. **Taint mode**: seguir el flujo de datos de `source` a `sink` a través de la función ([[02 - Taint mode - seguir el flujo de datos]]).

```shell-session
$ semgrep --config auto .
$ semgrep --config ./reglas.yaml --json -o hallazgos.json src/
$ semgrep --config "p/javascript" --sarif -o out.sarif .
```

La salida en formato **SARIF** (`--sarif`) es la que integra los hallazgos en GitHub, GitLab o cualquier plataforma que consuma ese estándar; el uso operativo en un engagement está en [[03 - Uso de Semgrep en un engagement]].

> [!warning]+ El cambio de licencia y el fork Opengrep
> En diciembre de 2024 Semgrep renombró su edición abierta a *Semgrep Community Edition* e introdujo una **Semgrep Rules License** que restringe el uso de sus reglas en productos comerciales o competidores, y movió capacidades como el *taint* entre funciones a su plataforma de pago. En enero de 2025, un consorcio de más de diez empresas de seguridad (Aikido, Endor Labs, Orca…) forkeó la última CE bajo **LGPL-2.1** como **[Opengrep](https://www.opengrep.dev/)**, que restaura esas capacidades en abierto y mantiene compatibilidad de línea de comandos y de sintaxis de reglas. <mark style="background: #FF5582A6;">Para trabajo en cliente importa: el binario CE es gratuito, pero las reglas del Registry pueden tener restricciones de uso comercial</mark>. Opengrep evita esa fricción con reglas propias LGPL.

> [!info]+ Semgrep vs CodeQL, en una frase
> Semgrep es rápido, sin compilación y con reglas legibles en YAML — ideal para el primer barrido y para el CI. [[00 - Qué es CodeQL y el modelo de datos|CodeQL]] es más potente en flujo de datos entre ficheros y búsqueda de variantes, a costa de compilar el código y de un lenguaje de consulta más complejo. En un whitebox se usan los dos: Semgrep para empezar, CodeQL cuando hace falta seguir el dato a fondo ([[18 - Arsenal del whitebox pentesting]]).
