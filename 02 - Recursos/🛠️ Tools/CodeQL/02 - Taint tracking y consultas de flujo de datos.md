---
tags:
  - Web/Red-Team
  - Whitebox
  - Code-Injection
Descripción: "La capacidad central de CodeQL: modelar una vulnerabilidad como un flujo de RemoteFlowSource a un sink y dejar que el motor encuentre todos los caminos"
Fecha de actualización: 2026-08-01
Nota previa: "[[01 - El lenguaje de consulta QL]]"
Nota siguiente: "[[03 - CodeQL en un engagement y análisis de variantes]]"
Area: "[[CodeQL.base|CodeQL]]"
---
---

El motivo por el que CodeQL existe en un [[18 - Arsenal del whitebox pentesting|arsenal de whitebox]] es este: <mark style="background: #ADCCFFA6;">modelar una vulnerabilidad como un flujo de datos desde una fuente no confiable hasta un sumidero peligroso, y dejar que el motor encuentre todos los caminos posibles a través del programa completo</mark>. Es el mismo modelo `source → sink → sanitizer` del [[02 - Taint mode - seguir el flujo de datos|taint mode de Semgrep]], pero con seguimiento global sin coste extra de licencia.

# Data flow frente a taint tracking

CodeQL distingue dos análisis relacionados:

| Análisis | Qué sigue |
| --- | --- |
| **Data flow** | El **mismo valor** propagándose (asignaciones, paso de parámetros, retornos) |
| **Taint tracking** | Extiende data flow con pasos donde el valor **cambia pero sigue contaminado** (concatenación, interpolación, `.toString()`, formateo) |

<mark style="background: #8000E1A6;">Para vulnerabilidades de inyección se usa taint tracking</mark>, porque la entrada del atacante casi nunca llega intacta al `sink`: se concatena, se interpola, se mete en una plantilla. El caso práctico del [[07 - Caso práctico - revisión del servicio y hallazgo del eval|whitebox]] es el ejemplo — `req.body.text` se interpola en una plantilla antes de llegar al `eval`, y solo el taint tracking (no el data flow puro) sigue ese salto.

# La estructura de una consulta de taint

En las versiones modernas de CodeQL, una configuración de flujo es un módulo que implementa `isSource`, `isSink` y opcionalmente `isBarrier` (el sanitizer):

```ql
import javascript
import semmle.javascript.dataflow.TaintTracking

module EvalInjectionConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) {
    source instanceof RemoteFlowSource        // cualquier entrada remota
  }
  predicate isSink(DataFlow::Node sink) {
    exists(CallExpr call |
      call.getCalleeName() = "eval" and
      sink.asExpr() = call.getArgument(0)
    )
  }
  predicate isBarrier(DataFlow::Node node) {
    // corta el flujo: la entrada validada contra un esquema (p. ej. zodSchema.parse(x))
    exists(CallExpr c |
      c.getCalleeName() = "parse" and
      node.asExpr() = c
    )
  }
}

module EvalFlow = TaintTracking::Global<EvalInjectionConfig>;

from DataFlow::Node source, DataFlow::Node sink
where EvalFlow::flow(source, sink)
select sink, "Entrada remota llega a eval desde $@", source, "esta fuente"
```

Los tres predicados son el mismo modelo conceptual de siempre:

- `isSource` → `RemoteFlowSource`, la clase de la librería que ya modela **todas** las entradas remotas del lenguaje. No hay que enumerar `req.body`, `req.query`, etc.: la librería lo hace.
- `isSink` → dónde el dato causa daño.
- `isBarrier` → qué corta el flujo (el sanitizer).

<mark style="background: #FFB86CA6;">La potencia está en `RemoteFlowSource` y en `EvalFlow::flow`</mark>: la primera cubre toda la superficie de entrada sin escribirla a mano; la segunda encuentra cualquier camino entre fuente y sumidero, por largo que sea y por cuantos ficheros cruce.

# Por qué gana en flujos largos

El data flow de CodeQL es **inter-procedural y global por diseño**, sin la restricción de licencia que Semgrep puso al taint entre funciones ([[02 - Taint mode - seguir el flujo de datos]]). Sigue el dato:

- A través de llamadas a función y retornos.
- Entre ficheros y módulos.
- Por asignaciones a campos de objeto.
- A través de pasos de taint personalizados (`isAdditionalFlowStep`) cuando el flujo pasa por una API que la librería no modela.

El último punto es clave en código real: cuando el dato pasa por una librería propia del cliente que CodeQL no conoce, se le enseña ese paso con `isAdditionalFlowStep`, y el análisis vuelve a seguir el rastro. Es lo que permite modelar los saltos raros que rompen el seguimiento en herramientas más simples.

# Path queries: mostrar el camino, no solo los extremos

Una consulta de `select` normal devuelve fuente y sumidero. Una **path query** devuelve además **el camino completo** entre ambos, paso a paso — que es lo que hace que un hallazgo sea explicable y reproducible:

```ql
/**
 * @kind path-problem
 */
import EvalFlow::PathGraph

from EvalFlow::PathNode source, EvalFlow::PathNode sink
where EvalFlow::flowPath(source, sink)
select sink.getNode(), source, sink, "Inyección de código desde entrada remota"
```

<mark style="background: #FF5582A6;">El grafo de camino es lo que convierte un hallazgo de SAST en algo que el cliente puede seguir con el dedo</mark>: muestra exactamente por qué funciones y asignaciones viaja el dato del atacante hasta el `eval`. Es la evidencia que respalda la severidad en el [[06 - Cómo redactar un hallazgo|hallazgo del informe]] y lo que dirige la [[03 - Local testing - réplica del backend y depuración|verificación dinámica]].

> [!warning]+ Modelar mal el sanitizer da falsos negativos
> Igual que en Semgrep, si se declara como `isBarrier` una función que en realidad no sanea, CodeQL corta el flujo y **no reporta** una vulnerabilidad real. La [[16 - Patching del eval injection|lista negra evadible]] del caso práctico es el ejemplo clásico de "sanitizer" que no lo es. El motor es tan bueno como el modelo que se le da — entender la vulnerabilidad sigue siendo requisito.

> [!info]+ Las consultas ya están escritas
> El repositorio [`github/codeql`](https://github.com/github/codeql) trae *query suites* de seguridad por lenguaje (`javascript-security-and-quality`, `python-security-extended`…) que ya modelan los flujos de los CWE comunes: inyección de comandos, SQLi, path traversal, SSRF, XSS, deserialización. El barrido de un engagement empieza por ahí; las consultas propias se reservan para los `sinks` específicos del cliente o para el [[03 - CodeQL en un engagement y análisis de variantes|análisis de variantes]].

El flujo operativo completo —construir la base, correr las suites, triar y explotar el análisis de variantes— está en [[03 - CodeQL en un engagement y análisis de variantes]].
