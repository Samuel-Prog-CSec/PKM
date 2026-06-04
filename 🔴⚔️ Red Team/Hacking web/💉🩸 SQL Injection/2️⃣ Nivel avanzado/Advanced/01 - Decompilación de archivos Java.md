---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Enumeracion
Fecha de actualización: 2026-06-04
Nota previa: "[[00 - Introducción a PostgreSQL]]"
Nota siguiente: "[[02 - Búsqueda de strings en el código]]"
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

En un assessment [[00 - Introducción a PostgreSQL|white-box]] de una aplicación Java compilada, el primer paso es recuperar el código fuente a partir del binario. La app objetivo, `BlueBird`, es una web Java Spring Boot empaquetada en un `JAR` —esencialmente un ejecutable Java—. <mark style="background: #ADCCFFA6;">Decompilar el `JAR` nos devuelve un código fuente legible donde buscar las consultas SQL vulnerables directamente</mark>, sin adivinar a ciegas.

# Decompiladores

El módulo usa dos herramientas clásicas, pero conviene conocer las modernas:

| Herramienta | Estado | Nota |
| ----------- | ------ | ---- |
| Fernflower | Mantenido (JetBrains, en IntelliJ) | Hay que compilarlo con Gradle; sensible a la versión de JDK |
| JD-GUI | Último release 2019, casi discontinuado | GUI cómoda pero anticuada |
| **Vineflower** | Activo (sucesor de Fernflower) | <mark style="background: #FFB8EBA6;">Recomendado en 2026</mark>: mejor salida, binario listo |
| **CFR** | Activo | Un solo JAR, sin compilar: `java -jar cfr.jar app.jar` |
| **Recaf** | Activo | GUI moderna, edición de bytecode |

## Fernflower

Se clona un mirror ligero (el repo oficial de IntelliJ es enorme) y se compila con Gradle. <mark style="background: #FF5582A6;">Su talón de Aquiles es la versión de JDK</mark>: si la del sistema no coincide con la que espera Fernflower (JDK 17), el build falla con `invalid source release: 17`. Se resuelve instalando `openjdk-17-jdk` y fijándolo con `update-java-alternatives --set java-1.17.0-openjdk-amd64` (el nombre exacto se obtiene con `--list`):

```shell-session
$ git clone https://github.com/fesh0r/fernflower.git
$ cd fernflower && ./gradlew build
$ java -jar build/libs/fernflower.jar BlueBird-0.0.1-SNAPSHOT.jar out
```

## CFR / Vineflower (la vía rápida moderna)

Sin compilar nada, un solo comando:

```shell-session
$ java -jar cfr.jar BlueBird-0.0.1-SNAPSHOT.jar --outputdir out
```

> [!info]+
> Para un assessment real en 2026, **Vineflower** o **CFR** ahorran el calvario de Gradle/JDK de Fernflower y producen mejor código. JD-GUI sigue siendo útil para una vista rápida con búsqueda, pero su antigüedad hace que falle con bytecode moderno.

# Extraer el código del JAR

Tras decompilar, el resultado es otro `JAR` con los `.java`. Se extrae con `jar`:

```shell-session
$ cd out && jar -xf BlueBird-0.0.1-SNAPSHOT.jar
```

# La estructura de un Spring Boot fat-JAR

El código de la aplicación queda en `BOOT-INF/classes/`. La organización típica de Spring Boot:

```text
BOOT-INF/classes/
├── application.properties          <- ¡configuración y credenciales!
└── com/bmdyy/bluebird/
    ├── controller/                 <- endpoints (donde están las queries)
    │   ├── AuthController.java
    │   ├── ProfileController.java
    │   └── ...
    ├── model/                      <- entidades (User, Post)
    └── security/                   <- JWT, config de seguridad
```

> [!important]+
> <mark style="background: #FFB86CA6;">`application.properties` es el primer fichero a leer</mark>: contiene la cadena de conexión a la base de datos (host, usuario, **contraseña**), claves JWT y otros secretos. Tras él, los `controller/` son donde viven los endpoints y, por tanto, las consultas SQL: ahí se centra la [[02 - Búsqueda de strings en el código|búsqueda de vulnerabilidades]].

> [!info]+
> **Qué buscar tras decompilar**, más allá de las queries: `application.properties`/`application.yml` (credenciales, claves), dependencias en `BOOT-INF/lib` con versiones vulnerables (cotéjalas con CVEs conocidas), secretos hardcodeados (claves JWT, API keys) y la lógica de autenticación/autorización en `security/`. Si el JAR está **ofuscado** (nombres tipo `a.b.c`), el renombrado asistido de IntelliJ o herramientas como `deobfuscator` ayudan: la ofuscación dificulta pero no impide el análisis. Formatos hermanos `.war`/`.ear` (apps web Java) se desempaquetan igual con `jar -xf`.

Con el código fuente extraído, se puede revisar en cualquier editor (VS Code, IntelliJ) o, más eficientemente, buscar patrones peligrosos con herramientas de línea de comandos —el siguiente paso—: [[02 - Búsqueda de strings en el código]].
