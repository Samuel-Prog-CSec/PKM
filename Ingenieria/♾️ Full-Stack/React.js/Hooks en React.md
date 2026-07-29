---
tags:
  - Full-Stack
  - React
  - Frontend
Descripción: "Los hooks son funciones, incorporadas en React 16.8, que permiten 'enganchar' el estado y el ciclo de vida desde componentes funcionales"
Fecha de actualización: 2026-06-22
Nota previa: "[[Reducers y Redux]]"
Nota siguiente: 
Area: "[[React.js.base|React.js]]"
---
---

<mark style="background: #ADCCFFA6;">Los hooks son funciones, incorporadas en React 16.8, que permiten "enganchar" el estado y el ciclo de vida desde componentes funcionales.</mark> Con ellos los componentes ya no necesitan ser clases: se escriben como **funciones**, más legibles, con menos código y optimizadas. Son compatibles con los componentes-clase existentes (a partir de React 16.8).

# De clase a función

```jsx
// Antes (clase)
class HeaderApp extends Component {
  render() { return (<div>…</div>); }
}
// Ahora (función)
export default function HeaderApp(props) {
  return (<div>…</div>);
}
```

Ya no se importa `Component`, no se hereda de él y no hay método `render` ni clase. Las props se reciben como **argumento de la función** (`props`), sin tomarlas del padre vía `this`.

# useState — hook de estado

<mark style="background: #ADCCFFA6;">`useState` manipula el estado de un componente funcional: devuelve un par `[valor, función actualizadora]`.</mark> Su único argumento es el estado inicial (solo se usa en el primer render); React mantiene el estado entre rerenderizados.

```jsx
import React, { useState } from 'react';

function Example() {
  const [count, setCount] = useState(0);   // [valor, setter], inicial 0
  return (
    <div>
      <p>Has hecho clic {count} veces</p>
      <button onClick={() => setCount(count + 1)}>Clic</button>
    </div>
  );
}
```

Frente a `this.state` de las clases: no combina estado antiguo y nuevo (lo reemplaza), no hay que "bindear" funciones ni usar `this`. Se pueden declarar **varias** variables de estado; por convenio, la actualizadora se nombra `setEstado`:

```jsx
const [username, setUsername] = useState('');
const [role, setRole] = useState('subscriber');
// actualizar: onChange={(e) => setUsername(e.target.value)}
```

# useEffect — hook de efecto

<mark style="background: #ADCCFFA6;">`useEffect` permite ejecutar efectos secundarios desde un componente funcional.</mark> <mark style="background: #8000E1A6;">Unifica en una sola función el propósito de `componentDidMount`, `componentDidUpdate` y `componentWillUnmount`.</mark>

```jsx
import React, { useState, useEffect } from 'react';

function PostList() {
  const [posts, setPosts] = useState([]);
  useEffect(() => {
    getAllPosts().then(p => setPosts(p));   // p. ej. petición con axios
  }, []);   // <- array de dependencias
  return (/* … */);
}
```

El **segundo argumento** controla cuándo se ejecuta el efecto:

- `[]` (vacío): se ejecuta **una sola vez** tras el primer render (como `componentDidMount`). <mark style="background: #FF5582A6;">Omitir el `[]` provoca un bucle infinito de renderizado.</mark>
- `[dep1, dep2]`: se ejecuta solo cuando esas dependencias cambian (sustituye a `componentWillReceiveProps`).
- Devolver una función dentro del efecto sirve para **limpiar** (como `componentWillUnmount`).

```jsx
useEffect(() => {
  setTitle(props.post.title);
}, [props.post]);   // solo cuando cambie props.post
```

# Reglas de los hooks

<mark style="background: #FFB86CA6;">Dos reglas obligatorias:</mark>

1. **Solo llamarlos en el nivel superior**: nunca dentro de bucles, condiciones o funciones anidadas.
2. **Solo llamarlos desde componentes funcionales de React** (o desde otros hooks personalizados), nunca desde funciones JavaScript normales.

El plugin `eslint-plugin-react-hooks` fuerza estas reglas automáticamente.

# Hooks personalizados y otros hooks

Un **hook personalizado** reutiliza lógica de estado entre componentes **sin añadir componentes al árbol** (alternativa a los HOC y las *render props*). Puede embeber `useState` y `useEffect`:

```jsx
function useFriendStatus(friendID) {
  const [isOnline, setIsOnline] = useState(null);
  useEffect(() => {
    // suscripción…
    return () => { /* limpieza */ };
  }, [friendID]);
  return isOnline;
}
```

Otros hooks menos comunes: **`useContext`** (consumir contexto) y **`useReducer`** (estado gestionado con un reducer, al estilo [[Reducers y Redux|Redux]]).

# Otros hooks útiles

Además de `useState`, `useEffect`, `useContext` y `useReducer`, conviene reconocer:

| Hook | Para qué |
| - | - |
| **`useRef`** | Guardar un valor mutable que persiste entre renders sin provocar rerender (o referenciar un nodo del DOM) |
| **`useMemo`** | Memorizar un cálculo costoso y recalcularlo solo si cambian sus dependencias |
| **`useCallback`** | Memorizar una función para no recrearla en cada render |

Los tres son **optimizaciones**: no son necesarios para que la app funcione, pero evitan trabajo redundante en componentes que renderizan mucho.

> [!important]+ Para el examen
> **Hooks** (React **16.8**) = funciones que dan estado y ciclo de vida a componentes **funcionales**. **`useState(inicial)`** → `[valor, setter]`. **`useEffect(fn, [deps])`** = efectos secundarios; unifica `componentDidMount`/`DidUpdate`/`WillUnmount`; `[]` = solo al montar. Reglas: solo en el **nivel superior** y solo desde **componentes funcionales**. Los **hooks personalizados** reutilizan lógica sin añadir componentes al árbol.
