---
tags:
  - Web/Red-Team
  - Whitebox
Descripción: "Los fundamentos de QL para leer y escribir consultas: select, from-where, predicados, clases y la jerarquía de la librería estándar"
Fecha de actualización: 2026-08-01
Nota previa: "[[00 - Qué es CodeQL y el modelo de datos]]"
Nota siguiente: "[[02 - Taint tracking y consultas de flujo de datos]]"
Area: "[[CodeQL.base|CodeQL]]"
---
---

QL es el lenguaje declarativo con el que se consulta la [[00 - Qué es CodeQL y el modelo de datos|base de datos de código]]. Es lógico y orientado a objetos, se parece a SQL en la estructura y a Datalog en la evaluación. <mark style="background: #ADCCFFA6;">No hace falta dominarlo para usar CodeQL —las consultas estándar cubren la mayoría de casos— pero saber leerlo permite adaptar una consulta al código base concreto</mark>, que es donde está el valor en un whitebox.

# La estructura mínima

Una consulta tiene forma `from … where … select`, idéntica en espíritu a SQL:

```ql
import javascript

from CallExpr call
where call.getCalleeName() = "eval"
select call, "Llamada a eval"
```

- `import javascript` carga la librería del lenguaje objetivo.
- `from` declara variables tipadas sobre las que iterar (aquí, todas las expresiones de llamada).
- `where` filtra con condiciones lógicas.
- `select` produce el resultado: el elemento y un mensaje.

Esta consulta encuentra cada `eval(...)` del código base, igual que el patrón de Semgrep — pero es la base sobre la que se construye el análisis de flujo, que es lo que Semgrep no iguala.

# Predicados: la unidad de reutilización

Un **predicado** es una relación lógica reutilizable, el equivalente a una función que devuelve verdadero/falso o un conjunto:

```ql
predicate esSinkPeligroso(CallExpr call) {
  call.getCalleeName() = "eval" or
  call.getCalleeName() = "Function" or
  call.getCalleeName() = "execSync"
}
```

Los predicados componen consultas complejas a partir de piezas nombradas. La librería estándar de CodeQL es, en esencia, miles de predicados que modelan `sinks`, `sources`, sanitizers y pasos de flujo para cada lenguaje.

# Clases: modelar conceptos del dominio

Una **clase** en QL no es un objeto, es un **conjunto lógico con predicados asociados** — un subconjunto de valores que cumplen una condición, con métodos para operar sobre ellos:

```ql
class EvalCall extends CallExpr {
  EvalCall() {                          // "constructor": qué pertenece a la clase
    this.getCalleeName() = "eval"
  }
  Expr getCode() {                      // método propio
    result = this.getArgument(0)
  }
}
```

Ahora `EvalCall` se usa como un tipo: `from EvalCall e select e.getCode()`. <mark style="background: #8000E1A6;">Este mecanismo es el que permite que la librería estándar modele "todas las fuentes de datos del usuario" o "todos los sinks de ejecución de comandos" como clases reutilizables</mark>, que es exactamente lo que necesita el [[02 - Taint tracking y consultas de flujo de datos|taint tracking]].

# La librería estándar es el 90% del trabajo

Casi nunca se escribe una consulta desde cero. La librería de cada lenguaje ya define las clases que importan:

| Clase / concepto | Qué modela |
| --- | --- |
| `RemoteFlowSource` | Cualquier entrada controlada por un atacante remoto (request, etc.) |
| `DataFlow::Node` | Un punto en el grafo de flujo de datos |
| `TaintTracking` | El framework de seguimiento de taint |
| Clases de `sink` por CWE | Ejecución de comandos, inyección SQL, path traversal… |

Escribir una consulta de seguridad es, casi siempre, **conectar `RemoteFlowSource` (fuente) con un `sink` de la librería** a través del framework de flujo — no reinventar la detección de entradas del usuario.

# Evaluación recursiva

QL evalúa por punto fijo, lo que permite predicados **recursivos** — imposibles de expresar con patrones. El ejemplo canónico es la relación de subtipo o la de alcanzabilidad en un grafo de llamadas:

```ql
// ¿La función f puede, directa o indirectamente, llamar a g?
predicate llamaTransitivamente(Function f, Function g) {
  f.calls(g) or
  exists(Function h | f.calls(h) and llamaTransitivamente(h, g))
}
```

<mark style="background: #FFB86CA6;">Esta capacidad de razonar sobre relaciones transitivas —"¿existe algún camino?"— es la diferencia de fondo con Semgrep</mark> y la razón de que CodeQL siga flujos de datos que atraviesan cadenas largas de funciones.

> [!info]+ Cómo se aprende de verdad
> El material oficial es bueno: la serie **"CodeQL zero to hero"** del [blog de seguridad de GitHub](https://github.blog/tag/codeql/) enseña QL orientado a encontrar vulnerabilidades, no como lenguaje abstracto. El **CodeQL for VS Code** da autocompletado y ejecución de consultas contra una base local, que es como se prototipa. Y las [consultas estándar del repositorio `github/codeql`](https://github.com/github/codeql) son la mejor referencia de patrones reales.

> [!warning]+ La curva es real, y a veces no compensa
> QL es más expresivo que las reglas YAML de [[01 - Reglas de Semgrep - sintaxis y patrones|Semgrep]], pero también más lento de escribir y depurar. Para un `sink` estándar con `source` y `sink` en la misma función, el taint mode de Semgrep resuelve en cinco minutos lo que en CodeQL cuesta media hora. <mark style="background: #FF5582A6;">CodeQL compensa cuando el flujo es largo, cruza muchos ficheros, o cuando se busca cada variante de un bug ya confirmado</mark> — no para el barrido inicial.

Con la base del lenguaje, el uso que de verdad importa en seguridad es el seguimiento de datos contaminados: [[02 - Taint tracking y consultas de flujo de datos]].
