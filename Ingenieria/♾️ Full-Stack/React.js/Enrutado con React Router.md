---
tags:
  - Full-Stack
  - React
  - Frontend
Descripción: "React Router es la librería de enrutado del cliente: asocia rutas (URLs) a los componentes y páginas que la aplicación renderiza según dónde se encuentre el usuario"
Fecha de actualización: 2026-06-22
Nota previa: "[[Propiedades y estado en React]]"
Nota siguiente: "[[Consumo de APIs REST con axios]]"
Area: "[[React.js.base|React.js]]"
---
---

<mark style="background: #ADCCFFA6;">React Router es la librería de enrutado del cliente: asocia rutas (URLs) a los componentes y páginas que la aplicación renderiza según dónde se encuentre el usuario.</mark>

> [!warning]+ React Router ≠ Express Router
> En el back-end, [[02-Rutas, manejadores y Express Router|Express Router]] maneja rutas a **recursos** que el cliente solicita por **HTTP**. React Router maneja rutas en el **cliente**, asociadas a **componentes** que se renderizan en el navegador. Misma palabra, lados opuestos de la arquitectura.

La librería es `react-router`, con dos *add-ons*: **`react-router-dom`** (web) y `react-router-native` (móvil).

```shell-session
$ npm install react-router-dom --save
```

# Enrutamiento estático vs dinámico

- **Estático**: las rutas se definen al inicializar la aplicación, antes de renderizar.
- <mark style="background: #FFB8EBA6;">**Dinámico** (el de react-router): las rutas se resuelven durante el renderizado, usando componentes para definirlas.</mark>

# Componentes del Router

<mark style="background: #ADCCFFA6;">Como react-router está hecho en React, las rutas se definen con componentes.</mark> Los componentes que muestran rutas siempre renderizan: o un componente, o `null`, según la localización.

| Componente | Función |
| - | - |
| **`BrowserRouter`** | Envoltura de la app; usa el History API de HTML5 para sincronizar la UI con la URL. Solo un hijo (normalmente `Switch`) |
| **`Switch`** | Renderiza **solo el primer** `Route`/`Redirect` que coincida (sin él, se renderizan todos los que coincidan) |
| **`Route`** | Define una ruta y elige qué renderizar según la localización |
| **`Redirect`** | Redirige a otra ruta (reemplaza la localización actual) |
| **`Link`** | Crea un hipervínculo para navegar entre rutas |

```jsx
import { BrowserRouter, Switch, Route, Redirect } from 'react-router-dom';

class App extends Component {
  render() {
    return (
      <BrowserRouter>
        <div>
          <NavBar />
          <Redirect from="/" to="/home" />
          <Switch>
            <Route path="/home" component={Home} />
            <Route exact path="/page1" render={() => <Page1 name="Ejemplo" />} />
            <Route component={PageError} />   {/* ruta no válida */}
          </Switch>
        </div>
      </BrowserRouter>
    );
  }
}
```

# Propiedades de `Route`

- **`path`**: la ruta en la que se renderiza el componente.
- **`exact`**: booleano; exige coincidencia exacta (`/index !== /index/all`).
- **`strict`**: tiene en cuenta la barra final (`/index !== /index/`).
- **`sensitive`**: distingue mayúsculas (`/index !== /Index`).
- **`component`**: componente a renderizar (lo monta y desmonta cada vez).
- **`render`**: función que retorna un componente (no lo remonta).
- **`children`**: similar a `render`, con añadidos.

<mark style="background: #8000E1A6;">Los métodos de render (`component`/`render`/`children`) dan acceso a tres props del History API: `match`, `location` e `history`.</mark> Para acceder a ellas desde un componente no renderizado por una ruta, se usa el HOC **`withRouter`**.

# Navegación: `Link` y `Redirect`

- **`Link`** (`to`, `replace`): crea un hipervínculo; **agrega** una nueva entrada al historial del navegador.
- **`Redirect`** (`from`, `to`, `push`): redirige; por defecto **reemplaza** la localización actual.

```jsx
<Link to="/page1" className="link">Página 1</Link>
```

# Acceder a los parámetros de la ruta

Una ruta como `/post/:id` expone su parámetro. En componentes de clase llega por `props.match.params`; con hooks, mediante `useParams`:

```jsx
// /post/123
const { id } = useParams();   // "123"
```

Para navegar por código (sin un `<Link>`), se usa el objeto `history` (`history.push('/home')`) o, en versiones modernas, el hook `useNavigate`.

> [!info]+ Versiones de React Router
> El libro usa **React Router v4/v5** (`Switch`, `component`/`render`, `Redirect`). En **v6** (actual), `Switch` pasa a llamarse `Routes`, `component` se sustituye por `element={<Comp />}` y aparecen hooks como `useNavigate` y `useParams`. Para el examen vale el modelo del libro; conviene saber que la API evolucionó.

> [!important]+ Para el examen
> **React Router** = enrutado del **cliente** (componentes ↔ URLs), no del servidor. Add-on web: **`react-router-dom`**. Componentes: **`BrowserRouter`** (envoltura, History API), **`Switch`** (solo la primera coincidencia), **`Route`** (`path`, `exact`, `component`/`render`), **`Link`** (navegación), **`Redirect`**. Usa enrutamiento **dinámico** (durante el render).
