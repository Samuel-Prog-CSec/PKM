---
tags:
  - Full-Stack
  - React
  - Frontend
Fecha de actualización: 2026-06-22
Nota previa: "[[Componentes de React (tipos y ciclo de vida)]]"
Nota siguiente: "[[Enrutado con React Router]]"
Area: "[[React.js.base|React.js]]"
---
---

Las **props** (propiedades) y el **state** (estado) son objetos JavaScript planos; un cambio en cualquiera de los dos dispara el método `render()` del componente. La diferencia entre ambos es una de las preguntas clásicas de examen.

# props vs state: la regla

<mark style="background: #FF5582A6;">Si un componente necesita modificar un atributo durante su vida, ese atributo es state; si no, es una prop.</mark>

| | props | state |
| - | - | - |
| Origen | Recibidas del componente **padre** | Gestionado por el **propio** componente |
| Mutabilidad | **Inmutables** | **Mutable** (con `setState`) |
| Propósito | Configurar el componente | Datos que cambian en el tiempo |
| Cambio → `render()` | Sí | Sí |

# Propiedades (props)

<mark style="background: #ADCCFFA6;">Las props son los atributos de configuración de un componente, recibidos desde un nivel superior e inmutables: un componente no puede cambiar sus propias props.</mark>

```jsx
class MyComponent extends React.Component {
  render() {
    return <div>Me llamo {this.props.name} y tengo {this.props.anios}</div>;
  }
}
// se pasan al renderizar:
ReactDOM.render(<MyComponent name="Jesus" anios="35" />, app);
```

- **`defaultProps`**: valores por defecto si no se pasan props.

```jsx
MyComponent.defaultProps = { name: 'Jesus', anios: '35' };
```

- **`propTypes`**: declara el **tipo** de cada prop y si es obligatoria (`isRequired`). Sirve para validar y depurar: React avisa por consola si falta una prop o el tipo no coincide. (En React moderno, `PropTypes` viene del paquete `prop-types`; el libro usa el antiguo `React.PropTypes`.)

```jsx
Titulo.propTypes = { nombre: PropTypes.string.isRequired };
```

# Estado (state)

<mark style="background: #ADCCFFA6;">El state es la representación del componente en un instante dado; arranca con un valor por defecto que sí puede cambiar durante su vida.</mark> A diferencia de las props, el componente **gestiona su propio state**.

- Se define en el **constructor** con `this.state`.
- Se modifica **solo** con `this.setState()` (nunca asignando directamente a `this.state`).

```jsx
class MyComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = { name: 'Jesus', edad: '35' };
  }
  render() {
    return <div>Me llamo {this.state.name} y tengo {this.state.edad}</div>;
  }
}
```

<mark style="background: #8000E1A6;">`setState()` recibe un objeto plano, lo combina con el estado actual y vuelve a renderizar el componente (y sus hijos).</mark>

```jsx
this.setState({ name: 'Ada' });
```

# Buenas prácticas y flujo de datos

- <mark style="background: #FFB8EBA6;">Es mejor tener componentes sin estado: son más reutilizables.</mark> El estado añade complejidad y reduce la previsibilidad.
- El flujo de datos es **unidireccional**: es habitual que el state mutable de un padre se pase como props inmutables a sus hijos.

# Elevar el estado (*lifting state up*)

Cuando dos componentes hermanos necesitan compartir datos, el estado se **eleva** al ancestro común más cercano, que lo pasa a ambos por props. <mark style="background: #FFB8EBA6;">El estado vive en un solo sitio (la "fuente de verdad") y se distribuye hacia abajo;</mark> los hijos notifican los cambios mediante callbacks. Es la consecuencia directa del flujo unidireccional.

# Componentes controlados

Un campo de formulario es **controlado** cuando su valor lo gobierna el state de React, no el DOM:

```jsx
<input value={nombre} onChange={e => setNombre(e.target.value)} />
```

El `value` viene del estado y cada pulsación lo actualiza, de modo que React es la única fuente de verdad del formulario.

> [!warning]+ No mutar el estado directamente
> Nunca modifiques `this.state` ni un objeto/array del estado en el sitio (`state.lista.push(...)`). Crea una **copia nueva** y pásala a `setState`: `setState({ lista: [...lista, nuevo] })`. React detecta cambios comparando referencias; mutar en el sitio puede impedir el rerender.

> [!important]+ Para el examen
> **props** = configuración recibida del padre, **inmutables** (el componente no las cambia). **state** = datos internos del componente, **mutables** solo vía **`setState()`** (definido en el constructor con `this.state`). Regla: ¿el componente necesita cambiar el dato? → **state**; si no → **prop**. Ambos cambios disparan `render()`. Validación de props con **`propTypes`** (`isRequired`).
