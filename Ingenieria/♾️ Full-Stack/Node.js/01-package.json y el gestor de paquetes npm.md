---
tags:
  - Full-Stack
  - npm
  - NodeJS
Fecha de actualización: 2026-06-22
Nota previa: "[[00-Node.js, entorno de ejecución del servidor]]"
Nota siguiente: "[[00-Express.js, framework y middleware]]"
Area: "[[Node.js.base|Node.js]]"
---
---

<mark style="background: #ADCCFFA6;">`package.json` es el manifiesto de un proyecto Node: el fichero que define sus características principales y sus dependencias.</mark> Sigue el estándar JSON (pares clave-valor, comillas dobles obligatorias).

# Contenido del package.json

Campos habituales: **`name`**, **`version`**, **`description`**, **`main`** (punto de entrada), **`scripts`**, **`dependencies`**, **`devDependencies`**, **`repository`**, **`author`**, **`license`**, **`engines`**.

```json
{
  "name": "test-project",
  "version": "1.0.0",
  "description": "Another project",
  "main": "src/main.js",
  "scripts": {
    "start": "npm run dev",
    "build": "node build/build.js"
  },
  "dependencies": { "vue": "^2.5.2" },
  "devDependencies": { "babel-core": "^6.22.1", "eslint": "^4.15.0" }
}
```

<mark style="background: #FFB8EBA6;">`dependencies` son las librerías que la aplicación necesita en producción; `devDependencies`, solo en desarrollo</mark> (linters, transpiladores, bundlers). El prefijo `^` en las versiones admite actualizaciones menores compatibles (*semver*). Los **`scripts`** definen comandos del proyecto (p. ej. seleccionar entornos de depuración o producción).

Dos formas de crearlo: **manual** (crear el fichero con al menos `name` y `version`) o **automática** con el asistente `npm init`.

# npm: el gestor de paquetes

<mark style="background: #ADCCFFA6;">npm es el gestor de paquetes de Node.js: permite crear, compartir y reutilizar módulos de un extenso catálogo mantenido por la comunidad.</mark> Se instala junto con Node.

Al instalar un paquete, npm lo coloca en la carpeta local **`/node_modules`** del proyecto y, con `--save`, lo añade a las dependencias del `package.json`. También puede instalarse de forma **global** (`-g`) para usarlo desde cualquier proyecto.

```shell-session
$ npm init                          # crea package.json (asistente)
$ npm install <modulo> --save       # instala en local y añade a dependencies
$ npm install <modulo> --save-dev   # añade a devDependencies
$ npm install -g <modulo>           # instala de forma global
$ npm install                       # instala TODAS las dependencias del package.json
$ npm uninstall <modulo>            # desinstala
$ npm ls --depth 0                  # lista los paquetes del proyecto
```

> [!important]+ El truco de `npm install`
> No se comparte la carpeta `/node_modules` (pesa demasiado). Se comparte solo el `package.json`, y `npm install` en el destino reconstruye `/node_modules` con todas las dependencias listadas. Por eso `node_modules/` casi siempre está en `.gitignore`.

# Recetario npm (comandos básicos)

| Acción | Comando |
| - | - |
| Instalar y guardar en `package.json` | `npm install <pkg> --save` |
| Instalar versión específica | `npm install <pkg>@<version>` |
| Instalar en `devDependencies` | `npm install <pkg> --save-dev` |
| Instalar de forma global | `npm install <pkg> -g` |
| Restaurar dependencias del proyecto | `npm install` |
| Desinstalar (y quitar de `package.json`) | `npm uninstall <pkg> --save` |
| Limpiar la caché | `npm cache clean` |
| Listar paquetes (sin dependencias) | `npm ls --depth 0` |
| Ver versión de un paquete en npm | `npm view <pkg> version` |

> [!info]+ Versionado semántico (semver)
> Las versiones siguen el formato **`MAYOR.MENOR.PARCHE`** (p. ej. `2.5.1`): **MAYOR** = cambios incompatibles (*breaking*), **MENOR** = nueva funcionalidad compatible, **PARCHE** = corrección de bugs. Los prefijos controlan qué se acepta al actualizar: `^2.5.1` admite menores y parches (`2.x.x`), `~2.5.1` solo parches (`2.5.x`), y `2.5.1` fija la versión exacta.

<mark style="background: #FFB86CA6;">`package-lock.json` fija las versiones exactas de todo el árbol de dependencias</mark>, garantizando que `npm install` reproduzca la **misma** instalación en cualquier máquina. A diferencia de `node_modules`, **sí** se versiona en git.

> [!info]+ Módulos nativos
> Algunos módulos vienen incluidos en Node (`http`, `fs`, `path`…) y **no requieren npm**. Para usar cualquier módulo, instalado o nativo: `require('modulo')`.

Express y React, por ejemplo, se distribuyen como paquetes npm. → [[00-Express.js, framework y middleware]]
