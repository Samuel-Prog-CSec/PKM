---
tags:
  - Web/Red-Team
  - Whitebox
  - Tipo/Introduccion
Descripción: "CodeQL trata el código como una base de datos y las vulnerabilidades como consultas: qué gana frente a Semgrep y cuándo compensa su curva"
Fecha de actualización: 2026-08-01
Nota previa: 
Nota siguiente: "[[01 - El lenguaje de consulta QL]]"
Area: "[[CodeQL.base|CodeQL]]"
---
---

<mark style="background: #ADCCFFA6;">CodeQL trata el código como una base de datos relacional y las vulnerabilidades como consultas sobre ella.</mark> Es el análisis estático más potente del [[18 - Arsenal del whitebox pentesting|arsenal del whitebox]] para seguir flujo de datos y buscar variantes, a cambio de compilar el código y de un lenguaje de consulta con curva real. Es la herramienta a la que se escala cuando [[00 - Qué es Semgrep y para qué sirve|Semgrep]] se queda corto.

# El modelo: compilar el código a una base de datos

Donde Semgrep casa patrones sobre el AST de cada fichero, CodeQL primero **extrae** todo el código a una base de datos relacional que captura el AST, el grafo de flujo de control, el grafo de flujo de datos y la información de tipos de **todo el proyecto a la vez**. Después se consulta esa base con QL, un lenguaje declarativo tipo SQL.

```shell-session
$ codeql database create db --language=javascript --source-root .
$ codeql database analyze db codeql/javascript-queries --format=sarif-latest -o out.sarif
```

La consecuencia de ese modelo es la diferencia clave: <mark style="background: #8000E1A6;">CodeQL razona sobre el programa completo, con relaciones entre ficheros, funciones y tipos que un análisis fichero-a-fichero no puede ver</mark>. Por eso encuentra flujos de `source` a `sink` que atraviesan muchas funciones y muchos módulos.

# Lenguajes soportados

C/C++, C#, Go, Java/Kotlin, JavaScript/TypeScript, Python, Ruby, Rust y Swift. Los **compilados** exigen que CodeQL observe la compilación real para extraer la base (`codeql database create` envuelve el build); los **interpretados** (JS, Python, Ruby) se extraen sin compilar.

> [!warning]+ La extracción de lenguajes compilados es el paso que falla
> Para C/C++, Java o C#, CodeQL necesita **ver el build entero**: si el proyecto no compila en la réplica, no hay base de datos. Esto convierte "montar el entorno de build del cliente" en un prerrequisito que puede llevar más tiempo que el análisis. Los lenguajes interpretados no tienen este problema, y por eso el barrido con CodeQL de una app NodeJS o Python es inmediato mientras que el de un proyecto Java grande puede requerir un día de preparación ([[03 - Local testing - réplica del backend y depuración]]).

# CodeQL frente a Semgrep

No compiten: se complementan, y saber cuál usar cuándo es parte del oficio.

| Criterio | Semgrep / Opengrep | CodeQL |
| --- | --- | --- |
| Velocidad de arranque | Inmediata, sin compilar | Requiere construir la base (minutos a horas) |
| Curva del lenguaje de reglas | Baja (YAML) | Alta (QL, tipo SQL con lógica) |
| Flujo entre ficheros | Bueno (taint mode; inter-procedural en Opengrep) | Excelente, es su razón de ser |
| Búsqueda de variantes | Regla por regla | Su punto fuerte: una consulta encuentra todas |
| Uso en CI ligero | Ideal | Pesado, mejor en `code scanning` programado |
| Coste | Gratuito (CE / Opengrep) | Ver licencia abajo |

<mark style="background: #FFB86CA6;">Regla práctica: Semgrep para el primer barrido y el CI; CodeQL cuando hay que seguir un dato a fondo entre muchos ficheros o encontrar todas las variantes de un bug ya confirmado</mark> ([[18 - Arsenal del whitebox pentesting]]).

# El análisis de variantes: su caso estrella

El uso más rentable de CodeQL en investigación de seguridad no es encontrar el primer bug, sino **encontrar todos los que se le parecen**. Cuando se confirma una inyección en un punto, se escribe una consulta que modela ese patrón de `source` a `sink` y CodeQL la aplica al código base entero, devolviendo todas las instancias. Es la técnica que usa el propio equipo de seguridad de GitHub y la que multiplica un hallazgo en diez. El plugin `variant-analysis` de Trail of Bits (instalado en el vault) automatiza este flujo.

> [!info]+ Licencia — el punto que hay que verificar en cada engagement
> La CLI de CodeQL y sus *query packs* estándar son **gratuitos para código open source en repositorios públicos y para investigación académica**, bajo los CodeQL Terms & Conditions. Para **repositorios privados**, CodeQL se distribuye como parte de **GitHub Advanced Security (GHAS)**, con licencia por *committer* activo. <mark style="background: #FF5582A6;">En un whitebox sobre código privado de un cliente hay que confirmar que existe cobertura de licencia antes de usarlo</mark> — a diferencia de Semgrep CE / Opengrep, que no tienen esa restricción. Es un factor real en la elección de herramienta.

# Dónde encaja en el proceso

CodeQL entra en la [[02 - Code review - alcance, priorización y lectura|revisión de código]] cuando el código base es grande y el flujo de datos cruza muchas capas — justo el escenario que HTB evita con su lab de 120 líneas. Su salida es SARIF, así que se integra con el resto del arsenal igual que Semgrep ([[03 - Uso de Semgrep en un engagement]]). El lenguaje que hace todo esto posible, QL, se introduce en [[01 - El lenguaje de consulta QL]].
