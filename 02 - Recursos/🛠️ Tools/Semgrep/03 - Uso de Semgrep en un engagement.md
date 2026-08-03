---
tags:
  - Web/Red-Team
  - Whitebox
  - Tipo/Arsenal
Descripción: "Flujo real: primer barrido, triaje de la salida SARIF, integración en CI para revisión incremental y los límites que obligan a validar a mano"
Fecha de actualización: 2026-08-01
Nota previa: "[[02 - Taint mode - seguir el flujo de datos]]"
Nota siguiente: 
Area: "[[Semgrep.base|Semgrep]]"
---
---

Semgrep produce candidatos; el engagement los convierte en hallazgos. Esta nota es el flujo operativo: <mark style="background: #ADCCFFA6;">qué se corre, en qué orden, cómo se tria la salida y dónde están los límites</mark> que obligan a volver a la lectura humana de [[02 - Code review - alcance, priorización y lectura|revisión de código]].

# El barrido inicial

Nada más montar la [[03 - Local testing - réplica del backend y depuración|réplica]], antes de leer código propio:

```shell-session
$ semgrep --config auto --sarif -o baseline.sarif .
$ semgrep --config "p/owasp-top-ten" --config "p/nodejs" --json -o hallazgos.json src/
```

`--config auto` detecta lenguajes y descarga reglas apropiadas; los packs explícitos (`p/owasp-top-ten`, `p/nodejs`, `p/javascript`) dan cobertura predecible. La salida **SARIF** es la que se archiva y se compara entre ejecuciones — es el formato estándar que consumen GitHub, GitLab y las plataformas de gestión de vulnerabilidades.

> [!info]+ SARIF, el formato que conecta todo el arsenal
> [SARIF](https://sarifweb.azurewebsites.net/) (*Static Analysis Results Interchange Format*) es JSON estandarizado por OASIS para resultados de análisis estático. Que Semgrep, [[00 - Qué es CodeQL y el modelo de datos|CodeQL]] y el resto de SAST hablen SARIF permite fusionar sus salidas, deduplicar y cargarlas en una sola vista. El plugin `static-analysis` de Trail of Bits (instalado en el vault) incluye parseo de SARIF precisamente para esto.

# Triaje de la salida

Una salida de SAST cruda **no es un entregable**: es una lista de candidatos con falsos positivos. El triaje es donde está el trabajo:

| Paso | Qué se decide |
| --- | --- |
| Descartar falsos positivos | ¿El `sink` recibe de verdad dato del atacante, o la regla se confundió? |
| Confirmar alcanzabilidad | ¿Hay una ruta desde una entrada no confiable? ([[02 - Code review - alcance, priorización y lectura]]) |
| Anotar el privilegio | ¿Anónimo, usuario, admin? Cambia la severidad |
| Priorizar | Impacto × probabilidad, primero lo barato de confirmar |

<mark style="background: #FF5582A6;">Entregar la salida de Semgrep sin triar es el error que quema la credibilidad del informe</mark>: el cliente encuentra el primer falso positivo y desconfía del resto. Cada hallazgo que sobrevive al triaje se lleva a [[03 - Local testing - réplica del backend y depuración|local testing]] para confirmarlo dinámicamente.

# Reducir el ruido de forma persistente

Dos mecanismos para que el ruido no vuelva en cada ejecución:

- **`.semgrepignore`**: excluye rutas (`node_modules/`, `test/`, `dist/`, ficheros generados). Análogo a `.gitignore`.
- **Comentario `nosemgrep`**: silencia una línea concreta ya revisada.

```javascript
const result = eval(trustedConfig); // nosemgrep: js-eval — config interna, no entrada de usuario
```

> [!warning]+ Cada `nosemgrep` es una decisión que hay que justificar
> Silenciar un hallazgo es afirmar que es seguro. En un whitebox, cada `nosemgrep` debería llevar el motivo en el comentario, porque es exactamente el tipo de supresión que un atacante busca: <mark style="background: #FFB8EBA6;">un `eval` marcado como "config interna" que en realidad recibe un valor de la base de datos es una inyección de segundo orden esperando</mark> ([[10 - Second-Order Command Injection]]). Revisar los `nosemgrep` existentes en el código del cliente es, en sí, una técnica de caza.

# Integración en CI — la revisión incremental

El mayor valor de Semgrep no es el barrido único, sino correr en cada `pull request` — el modo *diff-based* de la [[01 - El proceso de whitebox pentesting|Secure Code Review Cheat Sheet]] que hace viable el whitebox fuera de los sistemas críticos:

```shell-session
# Ejemplo de paso en CI: solo analiza lo que cambió
$ semgrep ci --config ./reglas-cliente.yaml
```

`semgrep ci` compara contra la rama base y reporta solo los hallazgos **nuevos**, de modo que un `pull request` no se bloquea por deuda preexistente. Recomendarlo es parte del entregable de [[05 - Patching y remediación|remediación]]: la regla que detectó el hallazgo se entrega al cliente para que su CI impida la regresión — el hallazgo convertido en control permanente.

# Opengrep en la práctica

Para un engagement con restricciones de uso comercial de las reglas de Semgrep Registry, [Opengrep](https://www.opengrep.dev/) es el reemplazo directo:

```shell-session
$ opengrep --config ./reglas.yaml --sarif -o out.sarif src/
```

La sintaxis de reglas y de línea de comandos es compatible; la diferencia es la licencia (LGPL-2.1) y que incluye en abierto el taint inter-procedural. <mark style="background: #8000E1A6;">La decisión entre uno y otro es contractual, no técnica</mark>: se elige Opengrep cuando el uso de las reglas de pago de Semgrep en el trabajo del cliente sería una violación de licencia.

# Los límites que Semgrep no cruza

Conviene tenerlos claros para no confiar de más:

1. **No entiende la lógica de negocio.** Un fallo de autorización como el de [[06 - Caso práctico - revisión del código de autenticación|`includes("@hackthebox.com")`]] no es un `sink`: ninguna regla lo marca. Eso es lectura humana.
2. **El taint se pierde en saltos que no modela.** Reflexión, `eval` anidado, callbacks dinámicos, paso por base de datos (segundo orden) rompen el seguimiento.
3. **Sanitizer mal declarado = falso negativo silencioso.** Ya tratado en [[02 - Taint mode - seguir el flujo de datos]].
4. **Cobertura desigual por lenguaje.** JavaScript y Python están maduros; lenguajes menos populares tienen menos reglas y peor parsing.

> [!important]+ La herramienta acelera, el criterio decide
> Semgrep recorta horas de barrido manual y encuentra variantes que el ojo se salta. Lo que no hace es sustituir el razonamiento sobre alcanzabilidad, privilegio e impacto ([[18 - Arsenal del whitebox pentesting]]). En un whitebox se usa para llegar rápido a la lista corta; el filtro que convierte 300 avisos en 3 hallazgos con PoC sigue siendo la persona que firma. Para flujos que Semgrep no sigue, se escala a [[00 - Qué es CodeQL y el modelo de datos|CodeQL]].
