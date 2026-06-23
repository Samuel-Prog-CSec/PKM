---
tags:
  - Full-Stack
  - JavaScript
  - Introduccion
Fecha de actualización: 2026-06-22
Nota previa: "[[Operaciones CRUD, HTTP y SQL]]"
Nota siguiente: "[[MongoDB y el modelo NoSQL documental]]"
Area: "[[Fundamentos.base|Fundamentos]]"
---
---

<mark style="background: #ADCCFFA6;">JavaScript es el lenguaje base del desarrollo web: junto con HTML y CSS forma la tríada del front-end.</mark> Nació para manejar el comportamiento de los elementos de la interfaz —originalmente documentos HTML estáticos con estilo CSS— y su **orientación a eventos** lo convierte en una herramienta potente para manipular el comportamiento de cualquier página o aplicación web.

<mark style="background: #8000E1A6;">En MERN, JavaScript es además el lenguaje del servidor: Node.js, Express.js y React.js están implementados en JavaScript.</mark> Un único lenguaje cubre toda la pila.

# ECMAScript: el estándar detrás de JavaScript

<mark style="background: #ADCCFFA6;">ECMAScript (ES) es la especificación estándar que define el lenguaje JavaScript.</mark> Evoluciona año tras año manteniendo gran compatibilidad con los navegadores. El salto relevante fue de **ES5** a **ECMAScript 6 (ES6 / ES2015)**, que introdujo cambios mayores conservando la **retrocompatibilidad**:

- Nueva sintaxis: `let`/`const`, *arrow functions* (`=>`), *template literals*, *destructuring*, parámetros por defecto, *spread/rest*.
- **Modularidad** nativa (`import` / `export`).
- Soporte directo para **clases** y herencia.
- **Promesas** para el manejo de datos asíncronos.

> [!info]+ Transpiladores
> Como muchos navegadores no entienden directamente las últimas especificaciones, se usan **transpiladores** (como Babel) que traducen el código ES6+ a una versión compatible. Así se programa de forma nativa en ES6+ sin preocuparse por la conversión. React, por ejemplo, se apoya en Babel para transpilar JSX y sintaxis moderna.

# Asincronía: el rasgo que más importa en MERN

<mark style="background: #FF5582A6;">El manejo de datos asíncronos es central en MERN</mark>: el modelo de Node es asíncrono y dirigido por eventos, y las operaciones de red o de base de datos no bloquean. Desde ES6, la herramienta base son las **promesas**, que representan un valor que estará disponible en el futuro. Sobre ellas, ES2017 añadió `async`/`await`, que permite escribir código asíncrono con aspecto secuencial.

```javascript
// Promesa
fetch("/api/users")
  .then(res => res.json())
  .then(data => console.log(data))
  .catch(err => console.error(err));

// async / await (equivalente)
async function getUsers() {
  try {
    const res = await fetch("/api/users");
    const data = await res.json();
    console.log(data);
  } catch (err) {
    console.error(err);
  }
}
```

# Operaciones y expresiones básicas

El lenguaje ofrece un amplio catálogo de utilidades que conviene **reconocer**, no memorizar:

- **Cadenas (`String`)**: `charAt()`, `concat()`, `indexOf()`, `slice()`, `split()`, `replace()`, `toUpperCase()`/`toLowerCase()`, `length`.
- **Arrays**: `push()`/`pop()`, `shift()`/`unshift()`, `slice()`/`splice()`, `join()`, `sort()`, `reverse()`.
- **Conversión**: `Number()`, `String()`, `parseInt()`, `parseFloat()`, `isNaN()`, `encodeURIComponent()`.
- **`Math` / `Date`**: `Math.floor()`, `Math.random()`, `Math.max()`/`min()`, `new Date()`, `getFullYear()`…
- **Expresiones regulares**: metacaracteres (`^`, `$`, `.`, `[abc]`, `a+`, `a*`, `a?`, `a{3,6}`) y *flags* (`g` global, `i` ignora mayúsculas, `m` multilínea); los métodos `match()`, `replace()`, `search()` y `split()` las soportan.

# ES6 en la práctica

Las novedades de ES6 que más aparecen en el código MERN:

```javascript
// let / const (ámbito de bloque, frente a var)
const PI = 3.14;   let contador = 0;

// arrow functions
const doble = x => x * 2;

// template literals
const saludo = `Hola, ${nombre}`;

// destructuring
const { title, description } = post;
const [primero, segundo] = lista;

// spread / rest
const copia = { ...post, leido: true };

// módulos
import express from 'express';
export default App;
```

# Promesas frente a callbacks

Antes de ES6, la asincronía se manejaba con **callbacks** anidados (el "*callback hell*"). Las **promesas** encadenan operaciones asíncronas de forma plana con `.then()`/`.catch()`, y `async`/`await` (ES2017) las hace leer como código síncrono. <mark style="background: #FFB8EBA6;">React (axios), Express (mongoose) y Node usan promesas por todas partes</mark>, así que dominarlas es clave para seguir el código de la pila.

> [!important]+ Para el examen
> JavaScript = lenguaje base de la web (con HTML y CSS), **orientado a eventos**. **ECMAScript** es su estándar; **ES6** trajo clases, módulos, `let`/`const`, *arrow functions* y **promesas**. Los **transpiladores** (Babel) traducen ES6+ a código compatible. MERN usa JS en cliente y servidor; la **asincronía** (promesas / `async`-`await`) es transversal.
