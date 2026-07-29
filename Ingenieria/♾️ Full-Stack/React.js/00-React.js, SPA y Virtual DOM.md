---
tags:
  - Full-Stack
  - React
  - Frontend
Descripción: "React.js es la tecnología de cliente (front-end) en MERN: una librería JavaScript creada por Facebook para desarrollar aplicaciones de una sola página (SPA)"
Fecha de actualización: 2026-06-22
Nota previa: "[[05-Seguridad de APIs REST (tokens y JWT)]]"
Nota siguiente: "[[01-JSX]]"
Area: "[[React.js.base|React.js]]"
---
---

<mark style="background: #ADCCFFA6;">React.js es la tecnología de cliente (front-end) en MERN: una librería JavaScript creada por Facebook para desarrollar aplicaciones de una sola página (SPA).</mark> Aunque por costumbre se le llama framework, técnicamente es una **librería**.

# Orientación a componentes

<mark style="background: #ADCCFFA6;">Un componente es una "pieza de software" independiente que contiene su propio comportamiento, un estado y el contenido a renderizar (la vista).</mark> Se establecen jerarquías y relaciones entre componentes para que se comuniquen. Una aplicación React tiene además un **estado global** que repercute en el estado individual de cada componente: por eso React está **orientado a componentes**. → [[Componentes de React (tipos y ciclo de vida)]]

Los componentes se construyen con la sintaxis **JSX**, que permite anidar elementos y crear componentes tan pequeños o grandes como haga falta. → [[01-JSX]]

# El Virtual DOM

<mark style="background: #ADCCFFA6;">El DOM (Document Object Model) es la representación en árbol jerárquico de las etiquetas (HTML/XML) de una interfaz.</mark> Manipular el DOM real es costoso.

<mark style="background: #FFB86CA6;">React usa un Virtual DOM, una abstracción del DOM que recarga cada componente individualmente solo cuando hace falta</mark>, renderizando lo estrictamente necesario. <mark style="background: #8000E1A6;">El resultado es gran velocidad al renderizar las vistas</mark>, porque se evita repintar todo el árbol ante cada cambio.

# Isomorfismo (SSR)

Otra característica es el **isomorfismo**: la capacidad de renderizar HTML tanto en el servidor como en el cliente. Entregar el HTML ya renderizado a los buscadores (Google) mejora el **posicionamiento (SEO)**, evitando que el buscador encuentre el cuerpo de la página vacío.

# Empaquetadores de módulos (bundlers)

Un empaquetador o *bundler* traduce todo el código de la aplicación y sus dependencias en un conjunto reducido de *assets* que cualquier navegador entiende. Procesa archivos de entrada y produce archivos de salida mediante **loaders** (cargadores). El bundler más conocido es **webpack**.

- Un **loader** es un plugin que soporta transformaciones del código fuente: p. ej., convertir `.scss` en `.css`, o transpilar (con **Babel**) JavaScript ES2017/JSX a una versión que la mayoría de navegadores ejecuten.
- La configuración reside en `webpack.config.js`.

> [!info]+ Librerías del ecosistema React
> React es solo la capa de vista; se complementa con librerías del ecosistema, varias de ellas usadas en este temario: **React Router** (enrutado de cliente), **axios** (peticiones HTTP a la API), **Redux** (estado global) y **reactstrap** (componentes de **Bootstrap** implementados como componentes React, para estilar la UI sin escribir CSS a mano).

# Hola Mundo y scaffolding

La herramienta de *scaffolding* `create-react-app` genera el esqueleto completo del proyecto. Estructura típica: `/node_modules` (dependencias), `/public` (con `index.html`, que contiene un `<div id="root">` donde se inyecta el componente principal) y `/src` (con `App.js`).

```javascript
import React from 'react';
import ReactDOM from 'react-dom';

class Hello extends React.Component {
  render() {
    return <div className='message-box'>Hello {this.props.name}</div>;
  }
}

ReactDOM.render(<Hello name='John' />, document.getElementById('root'));
```

`ReactDOM.render(componente, nodoDelDOM)` monta el componente en el `<div id="root">` del `index.html`.

# Declarativo, no imperativo

<mark style="background: #FFB8EBA6;">React es declarativo: describes cómo debe verse la UI para un estado dado, y React se encarga de actualizar el DOM.</mark> No manipulas el DOM "a mano" (estilo imperativo, como con jQuery o `document.getElementById`). Cambias el estado y React recalcula qué repintar usando el Virtual DOM.

# Flujo de datos unidireccional

Los datos fluyen en **una sola dirección**: de los componentes padres a los hijos, a través de las props. Un hijo no modifica directamente los datos del padre; si necesita comunicar un cambio, invoca una función (*callback*) que el padre le pasó. Este flujo predecible facilita razonar sobre la aplicación y depurarla. → [[Propiedades y estado en React]]

> [!important]+ Para el examen
> React.js = **librería** front-end de **Facebook** para **SPA**, **orientada a componentes**. Usa **JSX** para construir vistas y un **Virtual DOM** (abstracción del DOM) que rerenderiza solo lo necesario → más eficiencia. **Isomorfismo** = render en cliente y servidor (mejora SEO). Un **bundler** (webpack) empaqueta el código; **Babel** transpila JSX/ES6.
