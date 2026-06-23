---
tags:
  - Full-Stack
  - React
  - Frontend
Fecha de actualización: 2026-06-22
Nota previa: "[[JSX]]"
Nota siguiente: "[[Propiedades y estado en React]]"
Area: "[[React.js.base|React.js]]"
---
---

<mark style="background: #ADCCFFA6;">Un componente es un elemento software visual con su propio estado, que recibe propiedades (props) e implementa su propia lógica de renderizado.</mark> Las aplicaciones React están formadas por componentes; cada página puede desplegar uno o muchos.

# Tipos de componentes por comportamiento

| Tipo | Definición | Estado | Rerenderiza |
| - | - | - | - |
| **Stateful** | Clase; el más usado | Sí | Al cambiar props o state |
| **Stateless** | Función; solo props | No | (no controla ciclo de vida) |
| **Pure Component** | Clase que hereda de `React.PureComponent` | No | Solo si cambian las props |
| **HOC** | Función que envuelve a otro componente | — | Al cambiar sus props |

<mark style="background: #FFB8EBA6;">Stateful: usa encapsulación en clases; cada cambio en props o state llama a `render`.</mark>

```jsx
class MiBoton extends React.Component {
  constructor(props) { super(props); this.state = { styles: { background: 'blue' } }; }
  render() { return <button {...this.props} style={this.state.styles} />; }
}
```

**Stateless**: se define como función, solo trabaja con props; sencillo, testeable y más rápido.

```jsx
const MiBoton = props => <button {...props} style={{ background: 'blue' }} />;
```

**Pure Component**: como stateful en su forma, pero sin estado; solo se rerenderiza si sus props cambian de valor → mejor rendimiento. <mark style="background: #FFB86CA6;">HOC (Higher Order Component): función que toma un componente y devuelve otro con funcionalidad extendida (un *wrapper*).</mark> Útil para paginación, llamadas a API o formularios; lo usa `react-redux`.

# Tipos por estructura (patrón de la comunidad)

No son parte de la API de React; son **conceptuales**, para organizar la arquitectura:

- **Componentes visuales** (*presentational*): solo se ocupan de **cómo se renderiza la UI**; reciben todo por props y suelen ser *stateless*.
- **Componentes contenedores** (*container*): se ocupan de la **lógica y los datos** (llamadas a servicios externos) y suelen gestionar su propio estado. A menudo representan páginas y coinciden con las rutas.

> [!info]+ Los hooks simplifican esta categorización
> Con los [[Hooks en React|React hooks]], los componentes función pueden tener estado y efectos, difuminando la frontera *stateful*/*stateless* y la división visual/contenedor.

# Ciclo de vida de un componente

<mark style="background: #ADCCFFA6;">El ciclo de vida es la serie de fases por las que pasa un componente con estado, cada una con métodos que se pueden implementar.</mark> Solo aplica a componentes **Stateful** (los *stateless* solo tienen `render`). Tres fases:

- **Montaje** (*mounting*): primera vez que el componente se genera e inserta en el DOM.
- **Actualización** (*updating*): el componente ya generado se actualiza (cambian props o state).
- **Desmontaje** (*unmounting*): el componente se elimina del DOM.

| Fase | Método | Cuándo |
| - | - | - |
| Montaje | `constructor()` | Antes del render; fija el estado inicial |
| Montaje | `componentDidMount()` | Tras el primer render; el DOM ya existe (peticiones, *timers*) |
| Actualización | `shouldComponentUpdate(nextProps, nextState)` | Devuelve `boolean`; si `false`, salta el render (optimización) |
| Actualización | `componentDidUpdate(prevProps, prevState)` | Tras actualizar; ya operable sobre el DOM |
| Desmontaje | `componentWillUnmount()` | Antes de retirar del DOM; **limpieza** (*timers*, *listeners*) |

> [!warning]+ Métodos `Will...` obsoletos
> `componentWillMount`, `componentWillReceiveProps` y `componentWillUpdate` aparecen en el libro pero están **deprecados** en React moderno. Conviene reconocerlos para el examen; en código real se usan `constructor`, `componentDidMount`, `componentDidUpdate` y `componentWillUnmount` (o los hooks).

# Composición y la prop `children`

React favorece la **composición**: construir componentes grandes combinando pequeños. El contenido que un componente envuelve llega por la prop especial **`children`**:

```jsx
function Tarjeta({ children }) {
  return <div className="tarjeta">{children}</div>;
}
// uso:
<Tarjeta><h2>Hola</h2><p>Contenido</p></Tarjeta>
```

Esto permite componentes contenedores reutilizables (modales, paneles, *layouts*) agnósticos a lo que contienen.

> [!important]+ Para el examen
> Por comportamiento: **Stateful** (clase, con estado), **Stateless** (función, solo props), **PureComponent** (rerenderiza solo si cambian las props), **HOC** (envuelve y extiende un componente). Por estructura: **visual** (UI, props) vs **contenedor** (lógica/datos/estado). Ciclo de vida (solo stateful): **montaje** (`componentDidMount`), **actualización** (`shouldComponentUpdate`, `componentDidUpdate`), **desmontaje** (`componentWillUnmount`, para limpieza).
