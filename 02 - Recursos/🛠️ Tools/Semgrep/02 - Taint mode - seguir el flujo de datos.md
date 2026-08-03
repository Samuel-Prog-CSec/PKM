---
tags:
  - Web/Red-Team
  - Whitebox
  - Code-Injection
Descripción: "El modo que conecta source y sink automáticamente: cómo declarar fuentes, sumideros, sanitizadores y propagadores para detectar inyecciones"
Fecha de actualización: 2026-08-01
Nota previa: "[[01 - Reglas de Semgrep - sintaxis y patrones]]"
Nota siguiente: "[[03 - Uso de Semgrep en un engagement]]"
Area: "[[Semgrep.base|Semgrep]]"
---
---

Buscar un `sink` con un patrón encuentra el `sink`, pero no dice si le llega dato del atacante. <mark style="background: #ADCCFFA6;">El `taint mode` sigue el flujo de datos desde una `source` hasta un `sink` y solo dispara cuando existe un camino entre ambos sin sanitizar</mark> — que es exactamente la definición operativa de una inyección de [[09 - Inyección de código y funciones peligrosas|el catálogo de sinks]].

# El modelo: source → sink, con sanitizer en medio

Una regla de `taint` tiene cuatro componentes, tres de ellos ya conocidos del vocabulario de [[02 - Code review - alcance, priorización y lectura|revisión de código]]:

```yaml
rules:
  - id: req-a-eval
    languages: [javascript]
    severity: ERROR
    message: Entrada de la request llega a eval → inyección de código
    mode: taint
    pattern-sources:
      - pattern: req.body
      - pattern: req.query
      - pattern: req.params
    pattern-sanitizers:
      - pattern: validator.escape(...)
      - pattern: zodSchema.parse(...)
    pattern-sinks:
      - pattern: eval(...)
      - pattern: new Function(...)
```

| Componente | Qué declara |
| --- | --- |
| `pattern-sources` | De dónde entra el dato no confiable |
| `pattern-sinks` | Dónde causa daño |
| `pattern-sanitizers` | Qué **corta** el flujo (rompe el taint) |
| `pattern-propagators` | Qué **transmite** el taint sin ser fuente (p. ej. `dst = concat(src, x)`) |

<mark style="background: #8000E1A6;">Solo se reporta un hallazgo cuando hay un camino source → sink que no pasa por ningún sanitizer.</mark> Eso elimina de golpe el ruido de los `eval` que solo reciben literales o valores ya validados.

> [!info]+ Sintaxis nueva (experimental)
> La sintaxis reciente anida todo bajo una clave `taint:` de nivel superior y renombra los campos (`pattern-sources` → `sources`, `pattern-sinks` → `sinks`, etc.), sin necesitar `mode: taint`. La forma con `mode: taint` y `pattern-*` sigue soportada y es la más documentada; se usa aquí por estabilidad.

# Por qué esto encuentra lo que el patrón no

El caso práctico del módulo de [[07 - Caso práctico - revisión del servicio y hallazgo del eval|whitebox]] es el ejemplo perfecto: el `eval(onError)` no recibe la entrada directamente, sino que `req.body.text` se interpola en una plantilla y esa plantilla viaja como `onError`. Un `pattern: eval($X)` marca el `eval`, pero no sabe que `$X` está contaminado. El `taint mode`, en cambio, sigue el dato desde `req.body` a través de la interpolación hasta el `eval` y confirma el camino — **el propagador es la interpolación de cadena**.

Este seguimiento es *intra-procedural* por defecto (dentro de una función) y *inter-procedural* en las versiones con esa capacidad. Aquí es donde muerde el [[00 - Qué es Semgrep y para qué sirve|cambio de licencia]]: <mark style="background: #FF5582A6;">el taint entre funciones (inter-procedural) fue una de las capacidades que Semgrep movió a su plataforma de pago en 2024, y [Opengrep](https://www.opengrep.dev/) la restauró en abierto</mark>. Para un código base donde el `source` y el `sink` están en ficheros distintos, esa diferencia decide si Semgrep encuentra o no la vulnerabilidad.

# Sanitizadores: declararlos bien o ahogarse en falsos positivos

El sanitizer es el componente más delicado. Si se declara de menos, la regla reporta flujos que en realidad están validados; si se declara de más, silencia flujos reales. En el caso del [[16 - Patching del eval injection|parche]], el sanitizer correcto sería el esquema de Zod:

```yaml
pattern-sanitizers:
  - pattern: z.string().regex(...).parse($X)
  - pattern: $SCHEMA.parse($X)
```

> [!warning]+ Un sanitizer que no sanitiza de verdad
> Semgrep cree lo que se le declara. Si se marca como sanitizer una función que en realidad no limpia —una `blacklist` evadible, por ejemplo—, la regla dará luz verde a código vulnerable. <mark style="background: #FFB8EBA6;">La lista negra `text.replace(/['"`;]/g, "")` del caso práctico es exactamente ese peligro</mark>: parece un sanitizer y se evade. El `taint mode` es tan bueno como el criterio de quien declara los sanitizers — no exime de entender la vulnerabilidad ([[16 - Patching del eval injection]]).

# Reglas por defecto, ya escritas

No hace falta escribir todo desde cero. Las reglas del registro (`p/javascript`, `p/nodejs`, `p/owasp-top-ten`) ya traen configuraciones de `taint` para los `sinks` comunes: `eval`, `child_process`, consultas SQL, `res.redirect` (open redirect), rutas de fichero (path traversal). El barrido inicial de un engagement es:

```shell-session
$ semgrep --config "p/javascript" --config "p/nodejs" --sarif -o out.sarif src/
```

…y sobre los hallazgos se escriben reglas propias para los `sinks` que el registro no cubre o para el estilo particular del código base.

> [!info]+ Comparación con CodeQL en flujo de datos
> El `taint mode` de Semgrep y el *taint tracking* de [[00 - Qué es CodeQL y el modelo de datos|CodeQL]] resuelven el mismo problema con filosofías distintas: Semgrep con reglas declarativas rápidas de escribir, CodeQL con un lenguaje de consulta ([[02 - Taint tracking y consultas de flujo de datos]]) mucho más expresivo pero con más curva. Para inyecciones estándar, el `taint mode` de Semgrep basta y es más rápido; para flujos complejos con muchos pasos entre ficheros y para buscar todas las variantes, CodeQL gana.

El uso de todo esto dentro de un engagement real —qué se corre, en qué orden y cómo se integra la salida SARIF— está en [[03 - Uso de Semgrep en un engagement]].
