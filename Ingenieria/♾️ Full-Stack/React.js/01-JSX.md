---
tags:
  - Full-Stack
  - React
  - Frontend
Fecha de actualización: 2026-06-22
Nota previa: "[[00-React.js, SPA y Virtual DOM]]"
Nota siguiente: "[[Componentes de React (tipos y ciclo de vida)]]"
Area: "[[React.js.base|React.js]]"
---
---

<mark style="background: #ADCCFFA6;">JSX es una extensión de la sintaxis de JavaScript, creada por Facebook, que permite mezclar código JavaScript y HTML (XML) para describir componentes de interfaz.</mark> Los ficheros suelen llevar extensión `.jsx` (aunque también valen `.js`). Es una sintaxis específica de React.

<mark style="background: #8000E1A6;">React usa JSX para generar su Virtual DOM y después sincronizarlo con el DOM real</mark>, representando las vistas en el navegador.

# Por qué JSX: `createElement` vs JSX

Sin JSX, un componente se construye con `React.createElement`, que resulta verboso:

```javascript
var image = React.createElement('img', { src: 'react-icon.png', className: 'icon-image' });
var container = React.createElement('div', { className: 'icon-container' }, image);
ReactDOM.render(container, document.getElementById('app'));
```

Con JSX, lo mismo se escribe como si fuera HTML:

```jsx
var Icon = (
  <div className='icon-container'>
    <img src='icon-react.png' className='icon-image' />
  </div>
);
ReactDOM.render(Icon, document.getElementById('app'));
```

<mark style="background: #FFB86CA6;">Es como escribir HTML, pero realmente es JavaScript.</mark> Más legible y menos repetitivo.

# Reglas y palabras reservadas

JSX no es HTML literal: hay atributos que cambian de nombre porque chocan con palabras reservadas de JavaScript.

- `class` → **`className`**
- `for` (en `label`) → `htmlFor`
- Los atributos van en *camelCase* (`onClick`, `tabIndex`).

<mark style="background: #FFB8EBA6;">Las expresiones JavaScript se insertan entre llaves `{ }` dentro del JSX.</mark>

```jsx
class Componente extends React.Component {
  constructor(props) {
    super(props);
    this.state = { title: 'Introducción React' };
  }
  render() {
    const { title } = this.state;
    return (
      <div>
        <h1>Cabecera 1 {title}</h1>
        <h2>Cabecera 2</h2>
      </div>
    );
  }
}
```

# JSX necesita transpilación

<mark style="background: #FF5582A6;">Como el navegador no entiende JSX directamente, se necesita un transpilador (Babel) y un bundler (webpack) que conviertan el JSX a JavaScript (ES5/ES6) antes del despliegue.</mark> → [[La especificación JavaScript]]

# Patrones habituales en JSX

**Renderizado condicional** con el operador ternario o `&&`:

```jsx
{ logueado ? <Logout /> : <Login /> }
{ hayErrores && <Alerta /> }
```

**Listas** con `.map()`, donde cada elemento necesita una prop **`key`** única (ayuda a React a identificar qué cambió):

```jsx
<ul>
  { posts.map(p => <li key={p.id}>{p.title}</li>) }
</ul>
```

**Eventos** en *camelCase*, recibiendo una función (no una cadena):

```jsx
<button onClick={handleClick}>Enviar</button>
```

**Fragmentos** (`<>…</>` o `<Fragment>`) para devolver varios elementos sin añadir un `<div>` extra al DOM:

```jsx
return (
  <>
    <h1>Título</h1>
    <p>Texto</p>
  </>
);
```

> [!warning]+ La prop `key`
> Olvidar `key` en una lista genera un *warning* en consola y puede provocar renders incorrectos. Debe ser un identificador **estable y único** (el `_id` del documento, no el índice del array si la lista puede reordenarse).

> [!important]+ Para el examen
> **JSX** = extensión de sintaxis de JavaScript que mezcla **JS + HTML/XML** para describir componentes (ficheros `.jsx`). Es la alternativa legible a `React.createElement`. Reglas: `class` → **`className`**, atributos en *camelCase*, expresiones JS entre **`{ }`**. Requiere **transpilación** (Babel) a JavaScript.
