---
tags:
  - Full-Stack
  - React
  - Frontend
  - REST
Fecha de actualización: 2026-06-22
Nota previa: "[[Enrutado con React Router]]"
Nota siguiente: "[[Reducers y Redux]]"
Area: "[[React.js.base|React.js]]"
---
---

<mark style="background: #ADCCFFA6;">axios es una librería JavaScript que implementa un cliente HTTP ligero, basado en promesas, para consumir servicios de una API REST desde el front-end.</mark> Es similar a `Fetch` y, al basarse en promesas, se integra con `async`/`await`.

<mark style="background: #FFB8EBA6;">Gracias al agnosticismo entre back-end y front-end, al cliente solo le importa el nombre del servicio, los argumentos y el formato de la respuesta.</mark> Por eso la API y el cliente pueden usar tecnologías distintas, unidos por HTTP.

```shell-session
$ npm install axios --save
```

# GET

```jsx
import axios from 'axios';

export default class PersonList extends React.Component {
  state = { persons: [] }
  componentDidMount() {
    axios.get('https://jsonplaceholder.typicode.com/users')
      .then(res => {
        const persons = res.data;
        this.setState({ persons });
      });
  }
  render() {
    return <ul>{this.state.persons.map(p => <li>{p.name}</li>)}</ul>;
  }
}
```

`axios.get(url)` devuelve una **promesa** con un objeto `response`. Los datos están en **`res.data`**; también hay `res.status` (código de estado) o `res.request`. <mark style="background: #8000E1A6;">La petición se lanza en `componentDidMount` para que ocurra tras el primer render, y `setState` actualiza la vista con los datos.</mark> → [[Componentes de React (tipos y ciclo de vida)]]

# POST

```jsx
handleSubmit = event => {
  event.preventDefault();
  const user = { name: this.state.name };
  axios.post('https://jsonplaceholder.typicode.com/users', { user })
    .then(res => console.log(res.data));
}
```

`axios.post(url, datos)` envía datos, normalmente desde un formulario. `event.preventDefault()` evita la recarga de la página; `handleChange` actualiza el state con `event.target.value`. PUT es análogo.

# DELETE

```jsx
handleSubmit = event => {
  event.preventDefault();
  axios.delete(`https://jsonplaceholder.typicode.com/users/${this.state.id}`)
    .then(res => console.log(res.data));
}
```

`axios.delete(url)` borra el recurso identificado por la URL (aquí, el `id` de la persona).

# Instancia base

<mark style="background: #FFB86CA6;">Una instancia base define una URL base y configuración común (autenticación…) para no importar axios ni repetir la URL en cada componente.</mark>

```jsx
// api.js
import axios from 'axios';
export default axios.create({ baseURL: 'http://jsonplaceholder.typicode.com/' });
```

```jsx
// en un componente
import API from '../api';
API.delete(`users/${this.state.id}`).then(res => console.log(res.data));
```

> [!info]+ Buena práctica
> Aislar las llamadas a la API en ficheros JavaScript independientes (p. ej. `api.js`, una carpeta `services/`) desacopla la lógica de la interfaz. Es justo lo que facilita la instancia base.

# Manejo de errores

Toda petición puede fallar (red caída, 4xx/5xx). axios rechaza la promesa, que se captura con `.catch`:

```jsx
axios.get('/api/users')
  .then(res => this.setState({ users: res.data }))
  .catch(err => {
    console.error(err.response?.status);   // p. ej. 404, 500
    this.setState({ error: 'No se pudo cargar' });
  });
```

# Con async/await e interceptores

La misma petición con `async`/`await` y `try`/`catch`:

```jsx
async componentDidMount() {
  try {
    const res = await axios.get('/api/users');
    this.setState({ users: res.data });
  } catch (err) {
    this.setState({ error: 'No se pudo cargar' });
  }
}
```

axios permite **interceptores** que se ejecutan en cada petición —típico para añadir el token de autenticación a todas las llamadas—:

```jsx
axios.interceptors.request.use(config => {
  config.headers.Authorization = `Bearer ${token}`;
  return config;
});
```

<mark style="background: #FFB8EBA6;">Frente a `fetch` (nativo), axios añade parseo automático de JSON, rechazo automático en errores HTTP, interceptores y cancelación.</mark>

> [!important]+ Para el examen
> **axios** = cliente HTTP basado en **promesas** para consumir una API REST. `axios.get/post/put/delete(url[, datos])` devuelve una promesa; los datos llegan en **`res.data`**. El GET suele ir en **`componentDidMount`** + `setState`. **Instancia base**: `axios.create({ baseURL })` centraliza la configuración.
