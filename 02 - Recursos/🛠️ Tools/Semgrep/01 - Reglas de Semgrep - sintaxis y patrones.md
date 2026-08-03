---
tags:
  - Web/Red-Team
  - Whitebox
Descripción: "Escribir reglas propias: metavariables, ellipsis, composición con patterns/pattern-either y el modo interactivo para prototiparlas"
Fecha de actualización: 2026-08-01
Nota previa: "[[00 - Qué es Semgrep y para qué sirve]]"
Nota siguiente: "[[02 - Taint mode - seguir el flujo de datos]]"
Area: "[[Semgrep.base|Semgrep]]"
---
---

El valor de Semgrep en un whitebox no está en las reglas del registro, sino en las que se escriben **para el código base concreto** que se audita. Como se vio en [[02 - Búsqueda de strings en el código|la búsqueda de patrones sobre BlueBird]], adaptar el barrido al estilo del desarrollador es lo que enfoca la caza; Semgrep hace eso mismo con precisión de AST en lugar de con expresiones regulares.

# Los cuatro bloques de una regla

Una regla es YAML. Los campos que importan:

```yaml
rules:
  - id: exec-con-entrada-de-request
    languages: [javascript, typescript]
    severity: ERROR
    message: child_process con datos de la request → posible RCE
    pattern: child_process.execSync(...)
```

`id`, `languages`, `severity` y `message` son metadatos. La lógica vive en `pattern` y sus variantes.

# Metavariables y ellipsis

Son las dos piezas que dan a Semgrep su poder sobre `grep`:

| Sintaxis | Significa | Ejemplo |
| --- | --- | --- |
| `...` | Cualquier secuencia (argumentos, sentencias, elementos) | `foo(...)` casa `foo(a, b, c)` |
| `$X` | Metavariable: captura y **recuerda** un valor | `$X == $X` casa comparaciones redundantes |
| `"..."` | Cualquier literal de cadena | `eval("...")` |
| `<... e ...>` | `e` en cualquier parte de una expresión | patrón profundo |

La clave de las metavariables es que **el mismo nombre debe casar el mismo valor** dentro de una regla. Esto encuentra bugs que un patrón textual no puede expresar:

```yaml
# Encuentra un sink que recibe exactamente la variable que vino de req.body
pattern: |
  $DATA = req.body.$FIELD;
  ...
  child_process.execSync($DATA);
```

El `$DATA` de la asignación y el de la llamada tienen que ser la misma variable para que la regla dispare. El `...` entre medias permite que haya cualquier cantidad de código entre el `source` y el `sink`.

# Componer patrones

Un solo `pattern` rara vez basta. La composición se hace con operadores:

| Operador | Efecto |
| --- | --- |
| `patterns:` | AND — todos deben cumplirse (afina) |
| `pattern-either:` | OR — cualquiera cumple (amplía cobertura) |
| `pattern-not:` | Excluye — quita falsos positivos |
| `pattern-inside:` | Solo dentro de otro patrón (un contexto) |
| `pattern-not-inside:` | Fuera de un contexto |
| `metavariable-regex:` | Restringe una metavariable con una regex |

Ejemplo real: marcar `eval` solo cuando el argumento **no** es un literal (los literales son inofensivos):

```yaml
rules:
  - id: eval-dinamico
    languages: [javascript]
    severity: ERROR
    message: eval con argumento no literal
    patterns:
      - pattern: eval($X)
      - pattern-not: eval("...")
```

<mark style="background: #ADCCFFA6;">`pattern-not` es lo que separa una regla usable de una que inunda de ruido</mark>: sin él, la regla marcaría cada `eval` legítimo del código base.

# Prototipar rápido

La forma eficiente de escribir una regla es iterar contra el propio código:

```shell-session
$ semgrep -e 'eval(...)' --lang js src/           # patrón suelto, sin fichero de regla
$ semgrep --config ./regla.yaml --verbose src/    # depurar por qué (no) casa
```

El [Semgrep Playground](https://semgrep.dev/playground) hace lo mismo en el navegador: se pega el código, se escribe el patrón y se ve qué casa en tiempo real. Para un whitebox es la vía más rápida de convertir un `sink` recién encontrado en una regla que busca todas sus variantes en el resto del código base — que es la técnica de **análisis de variantes** ([[18 - Arsenal del whitebox pentesting]]).

# `autofix`: la regla que también parchea

Una regla puede llevar `fix`, que reescribe el código que casa:

```yaml
rules:
  - id: usa-execFile
    languages: [javascript]
    severity: ERROR
    message: Preferir execFile (sin shell) sobre exec
    pattern: child_process.exec($CMD)
    fix: child_process.execFile($CMD)
```

`semgrep --config regla.yaml --autofix` aplica el cambio. En un whitebox esto sirve para **proponer el parche** de [[05 - Patching y remediación|remediación]] de forma mecánica sobre todas las ocurrencias, aunque siempre se revisa a mano: un `autofix` que compila puede seguir cambiando la semántica.

> [!warning]+ El `autofix` no razona sobre la lógica
> Reescribe sintaxis, no arregla la causa —y este ejemplo lo demuestra por partida doble—. Primero, el reemplazo **rompe la firma**: `exec(cmd)` recibe el comando como una cadena, pero `execFile(file, args)` espera el ejecutable y sus argumentos **por separado**, así que `execFile('ls -la')` buscaría un binario llamado literalmente `ls -la`. Y segundo, aunque la firma se corrigiera, si el comando se sigue construyendo por concatenación la inyección persiste igual. El `autofix` acelera el borrador del `diff`; verificar que corta el vector **y** que no rompe la funcionalidad es humano ([[16 - Patching del eval injection]]).

> [!info]+ Trail of Bits y las reglas de seguridad
> El plugin `semgrep-rule-creator` de Trail of Bits (instalado en este vault) asiste en la escritura de reglas de seguridad, y su repositorio de reglas públicas es una buena base de patrones para los `sinks` de [[09 - Inyección de código y funciones peligrosas]]. La sintaxis de reglas es idéntica en Semgrep CE y en Opengrep.

El siguiente paso —seguir el dato de `source` a `sink` en vez de casar un patrón fijo— es el [[02 - Taint mode - seguir el flujo de datos|taint mode]], que es lo que convierte a Semgrep en un detector de inyecciones de verdad.
