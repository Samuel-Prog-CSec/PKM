---
tags:
  - Full-Stack
  - React
  - Frontend
Fecha de actualización: 2026-06-22
Nota previa: "[[Consumo de APIs REST con axios]]"
Nota siguiente: "[[Hooks en React]]"
Area: "[[React.js.base|React.js]]"
---
---

Cuando una aplicación tiene muchos componentes con estados que cambian constantemente, gestionarlos de forma eficiente se vuelve complejo. Ahí entran los **reducers** y la librería **Redux**.

<mark style="background: #ADCCFFA6;">Redux es una librería que desacopla el estado global de la aplicación de la parte visual (los componentes)</mark>, permitiendo controlar el estado de forma fácil, consistente entre cliente y servidor, y fácilmente testeable. Está influenciada por el patrón **Flux**, pensado para React. → [[Patrones de diseño web (MVC y SPA)]]

# Los 3 principios de Redux

1. **Una sola fuente de verdad**: todo el estado de la aplicación vive en un único `store` (con estructura de árbol).
2. <mark style="background: #FFB8EBA6;">**El estado es de solo lectura**: la única forma de modificarlo es emitir una `action` que describa el cambio.</mark> Ninguna parte de la app (eventos, callbacks, sockets) altera el estado directamente; emite una **intención** de cambio.
3. **Los cambios se hacen con funciones puras**: los `reducers`.

# Reducers

<mark style="background: #FFB86CA6;">Un reducer es una función pura que recibe el estado actual y una acción, y devuelve un nuevo estado, sin modificar el actual.</mark> Se puede tener un único reducer para toda la app o, si crece, dividirlo en varios y controlar su orden de ejecución.

```javascript
function counter(state = 0, action) {
  switch (action.type) {
    case 'INCREMENT': return state + 1;
    case 'DECREMENT': return state - 1;
    default:          return state;
  }
}
```

El flujo Redux: la vista despacha (`dispatch`) una **acción** → el **reducer** calcula el nuevo estado → el **store** se actualiza → la vista se rerenderiza. <mark style="background: #8000E1A6;">Así se evita que un componente cambie estados interactuando con otros, algo que en apps complejas hace imposible seguir el flujo al depurar.</mark>

```shell-session
$ npm install --save redux
```

> [!info]+ ¿Sigue siendo necesario Redux?
> Las versiones modernas de React, con los [[Hooks en React|React hooks]] (`useState`, `useReducer`, `useContext`), cubren buena parte de lo que antes requería Redux. En proyectos con muchísimos componentes Redux sigue aportando, pero ya no es imprescindible.

# El flujo completo de Redux

Las piezas de Redux y cómo encajan:

| Pieza | Qué es |
| - | - |
| **Store** | Objeto único que guarda todo el estado |
| **Action** | Objeto plano que describe *qué pasó* (`{ type: 'ADD_TODO', payload }`) |
| **Action creator** | Función que construye una action |
| **Reducer** | Función pura `(estado, action) → nuevo estado` |
| **dispatch** | Método que envía una action al store |

El ciclo: la vista llama a **`dispatch(action)`** → el **reducer** recibe el estado actual y la action y devuelve un **nuevo estado** → el **store** se actualiza → los componentes suscritos se rerenderizan.

# Conexión con React

La librería **`react-redux`** conecta los componentes con el store: el hook `useSelector` lee estado y `useDispatch` envía acciones (en código antiguo, la función `connect`). Internamente se apoya en componentes de orden superior ([[Componentes de React (tipos y ciclo de vida)|HOC]]).

> [!important]+ Para el examen
> **Redux** = librería de gestión de **estado global**, basada en el patrón **Flux** (flujo unidireccional). 3 principios: **(1)** una sola fuente de verdad (un `store`), **(2)** estado de **solo lectura** (se cambia emitiendo **acciones**), **(3)** cambios mediante **funciones puras** (**reducers**). Un **reducer** recibe `(estado, acción)` y devuelve un **nuevo estado**.
