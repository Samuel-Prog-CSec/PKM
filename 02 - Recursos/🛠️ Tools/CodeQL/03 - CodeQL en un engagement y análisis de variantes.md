---
tags:
  - Web/Red-Team
  - Whitebox
  - Tipo/Arsenal
Descripción: "El flujo real: crear la base, correr las query suites, triar SARIF y usar el análisis de variantes para multiplicar un hallazgo por todo el código base"
Fecha de actualización: 2026-08-01
Nota previa: "[[02 - Taint tracking y consultas de flujo de datos]]"
Nota siguiente: 
Area: "[[CodeQL.base|CodeQL]]"
---
---

CodeQL entra en un [[02 - Code review - alcance, priorización y lectura|whitebox]] cuando el código base es grande o el flujo cruza muchas capas — el escenario que [[00 - Qué es el whitebox pentesting|HTB evita]] con su lab de juguete. Esta nota es el flujo operativo de principio a fin y su técnica estrella: el análisis de variantes.

# Construir la base de datos

El paso previo a todo. Para lenguajes interpretados es directo; para compilados hay que envolver el build:

```shell-session
# Interpretado (JS, Python, Ruby): sin compilar
$ codeql database create db --language=javascript --source-root .

# Compilado (Java, C#, C/C++, Go): CodeQL observa el build
$ codeql database create db --language=java --command="mvn clean install -DskipTests"
```

> [!warning]+ El build es el cuello de botella
> Para un proyecto compilado, si no se reproduce el entorno de build del cliente no hay base de datos, y montar ese entorno puede llevar más que el análisis ([[00 - Qué es CodeQL y el modelo de datos]]). Coordinarlo con el cliente en el [[03 - Pre-engagement I - contratos, NDA y scoping|scoping]] evita perder el primer día del engagement peleando con dependencias de compilación.

# Correr las query suites

Sobre la base ya construida se ejecutan las suites de seguridad estándar, que modelan los CWE comunes sin escribir una línea de QL:

```shell-session
$ codeql database analyze db \
    codeql/javascript-queries:codeql-suites/javascript-security-extended.qls \
    --format=sarif-latest -o hallazgos.sarif
```

| Suite | Alcance |
| --- | --- |
| `*-security-and-quality` | Seguridad + problemas de calidad (más ruido) |
| `*-security-extended` | Seguridad, incluidas consultas de menor severidad |
| `code-scanning` | El set por defecto de GitHub, equilibrado para CI |

<mark style="background: #ADCCFFA6;">La salida es SARIF</mark>, el mismo formato que [[03 - Uso de Semgrep en un engagement|Semgrep]], así que las dos herramientas se fusionan y deduplican en una vista con el plugin `static-analysis`/`sarif-parsing` de Trail of Bits.

# Triar — igual de obligatorio que con Semgrep

CodeQL tiene menos falsos positivos que un SAST por patrones, gracias al análisis de flujo, pero **no cero**. El triaje sigue el mismo criterio de [[02 - Code review - alcance, priorización y lectura|revisión de código]]: descartar el falso positivo, confirmar alcanzabilidad, anotar el privilegio, priorizar por impacto. La ventaja concreta de CodeQL en esta fase son las **path queries**: cada hallazgo viene con el camino completo del dato, así que verificar la alcanzabilidad es leer el grafo en vez de reconstruirlo a mano.

Cada hallazgo que sobrevive se lleva a [[03 - Local testing - réplica del backend y depuración|local testing]] para confirmarlo dinámicamente. <mark style="background: #FF5582A6;">Un hallazgo de CodeQL sin verificación dinámica no es explotable, es "potencialmente explotable"</mark> — y así hay que redactarlo si no se llegó a probar.

# El análisis de variantes: donde CodeQL vale su curva

Es el uso que justifica aprender la herramienta. El flujo:

1. Se encuentra **un** bug (por lectura, por Semgrep, por fuzzing).
2. Se **modela** ese patrón como una consulta de taint ([[02 - Taint tracking y consultas de flujo de datos]]).
3. CodeQL la aplica al **código base entero** y devuelve **todas** las instancias del mismo patrón.

<mark style="background: #8000E1A6;">Un hallazgo se convierte en diez.</mark> Es la técnica con la que el equipo de seguridad de GitHub encuentra variantes de un CVE en cientos de proyectos, y la que un whitebox usa para asegurarse de que el parche de [[05 - Patching y remediación|remediación]] cubre **todas** las rutas al mismo `sink`, no solo la que se explotó. El plugin `variant-analysis` de Trail of Bits (instalado en el vault) empaqueta este flujo.

> [!info]+ Ejemplo concreto del caso práctico
> En el [[07 - Caso práctico - revisión del servicio y hallazgo del eval|lab del módulo]] hay un solo `eval`. En un código base real, tras encontrar el primero, la consulta "entrada remota que llega a `eval`, `Function` o `execSync`" barre el proyecto entero y revela si el mismo antipatrón se repite en otros diez endpoints que la lectura manual no alcanzó. Ese barrido es lo que asegura que la [[16 - Patching del eval injection|remediación]] es de clase y no de síntoma.

# Integración en CI: GitHub code scanning

En un cliente que ya usa GitHub, CodeQL se integra como `code scanning` en el pipeline, subiendo el SARIF a la pestaña de seguridad del repositorio. Recomendarlo es parte del entregable de remediación cuando el hallazgo es sistémico: cada `pull request` futuro pasa por las mismas consultas y la regresión salta sola. Para proyectos privados, esto requiere **GitHub Advanced Security** — el factor de licencia de [[00 - Qué es CodeQL y el modelo de datos]] que hay que confirmar antes de proponerlo.

# Cuándo NO usar CodeQL

Para no caer en usarlo por defecto:

- **Barrido rápido o CI ligero** → [[00 - Qué es Semgrep y para qué sirve|Semgrep]]/Opengrep, sin compilar ni licencia.
- **Un `sink` con `source` y `sink` en la misma función** → el taint mode de Semgrep resuelve en minutos.
- **Lógica de negocio y autorización** → ningún SAST lo ve; es [[02 - Code review - alcance, priorización y lectura|lectura humana]]. El fallo de [[06 - Caso práctico - revisión del código de autenticación|`includes("@hackthebox.com")`]] no es un flujo de datos, es una decisión de diseño.
- **Código que no compila en la réplica** → sin base de datos, no hay análisis.

> [!important]+ CodeQL produce caminos, no veredictos
> Un flujo de `source` a `sink` es una **hipótesis muy fundamentada**, no una explotación. La severidad final, el privilegio requerido y el impacto real siguen saliendo del triaje humano y de la [[04 - Proof of Concept - del hallazgo al exploit|verificación dinámica]] ([[18 - Arsenal del whitebox pentesting]]). CodeQL es el mejor microscopio del arsenal para seguir datos; no sustituye a quien decide qué significan.
