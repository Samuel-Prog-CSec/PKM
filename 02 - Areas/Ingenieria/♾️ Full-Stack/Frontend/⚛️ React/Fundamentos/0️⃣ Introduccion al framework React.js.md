El **framework React.js** constituye la tecnología de **cliente o front-end** en la pila MERN. En este caso, también se trata de una librería JavaScript, creada por Facebook, que nos ayuda a la hora de desarrollar aplicaciones en una sola página, conocidas como *SPA* (==Single Page Application==).

Los desarrolladores podrán crear aplicaciones React.js basadas en **componentes propios y/o importarlos de terceros**. Otra de las características de React.js que la diferencia de otras librerías, es el uso de la sintaxis [JSX](https://www.google.com/url?sa=E&q=https%3A%2F%2Fjsx.github.io%2F) para construir componentes de interfaz de usuario. **JSX** ==crea plantillas donde se pueden anidar elementos==.

Por otra parte, React.js utiliza un **DOM virtual o Virtual DOM** que ==recarga cada componente de forma individual cuando hace falta==, por lo que ofrece gran velocidad a la hora de renderizar las vistas. En este sentido, cuando una aplicación cliente pretende mostrar la información al usuario a través de su interfaz, esta se representa como un árbol de etiquetas (HTML, XML, etc.) jerarquizado. A dicha representación se le denomina **DOM** (*Document Object Model*). Teniendo en cuenta esto, el **Virtual DOM** es considerado una abstracción del DOM, de forma que, al renderizar las vistas, ==se renderizará lo estrictamente necesario de una forma mucho más optimizada==.

Otro de los elementos interesantes de este framework son los **componentes**. Estas “piezas de software” son independientes y contienen ==su propio comportamiento, un estado y el contenido a renderizar== (es decir, la vista a mostrar al usuario). De esta forma se pueden establecer jerarquías y relaciones entre componentes para posibilitar su comunicación. A su vez, las aplicaciones creadas con React.js tienen un **estado global** que repercute en el estado individual de cada componente. Por tanto, estamos tratando con un ==framework orientado a componentes==.

El **isomorfismo** (==renderización de código HTML tanto en el servidor como en cliente==) es otra de las características de React.js, ofreciendo la posibilidad de entregar el HTML ya renderizado a los buscadores web (por ejemplo, Google) y así mejorar el posicionamiento. De esta manera se evita el problema de que el buscador se encuentre el cuerpo de la página vacío.

En la [página web oficial de React.js](https://www.google.com/url?sa=E&q=https%3A%2F%2Freactjs.org%2F) se tiene toda la información detallada de este framework, así como tutoriales y ejemplos prácticos.


# Empaquetadores de módulos
A la hora de crear una aplicación con React.js conviene conocer el papel que juegan los **empaquetadores de módulos o bundler**. Estas herramientas permiten ==automatizar procesos== como la **transpilación** de código y el **preprocesamiento**, además de realizar otras tareas. Su finalidad es traducir todo el código implementado, junto con sus dependencias, en un conjunto reducido de *assets* en lenguajes comunes y comprensibles por cualquier navegador. En definitiva, lo que realizan es el ==procesamiento de unos archivos de entrada para convertirlos en otros archivos de salida (mediante cargadores o loaders==). Un ejemplo muy conocido de bundler, es [webpack](https://www.google.com/url?sa=E&q=https%3A%2F%2Fwebpack.js.org%2F).

(Descripción original de la Figura 42: Ejemplo de ficheros de entrada y salida del bundler webpack)

Una vez construido ese conjunto de assets estáticos, la aplicación quedará embebida en estos y podrá ser desplegada fácilmente en el servidor.

Junto a estos empaquetadores, se encuentran los **loaders**, los cuales pueden definirse como ==plugins para soportar las transformaciones que va a tener el código fuente== de nuestra aplicación. Por ejemplo, un loader de un archivo `.scss` se encargará de cargar el archivo y convertirlo en un fichero .`css` por medio de paquetes externos. De igual forma, otro loader diferente (por ejemplo, *babel*) podría convertir código JavaScript ES-2017 o JSX a una especificación JavaScript que la mayoría de navegadores de Internet puedan ejecutar. A este proceso, se le denomina **transpilación** de código.

Los comandos tanto para instalar `webpack` de forma global como algunos de los loaders o cargadores más interesantes son los siguientes. Igualmente, la forma de instalar todos estos paquetes conlleva el uso del gestor `npm`, previamente instalado en nuestro sistema operativo.
```bash
npm install -g webpack
npm install --save-dev babel-loader babel-core babel-preset-env
```

Además, se le puede dotar a webpack de diversas configuraciones, proporcionando información sobre el componente principal de nuestra aplicación (para su despliegue inicial), el nombre del archivo del bundle final generado, especificar un determinado loader para la transpilación, etc. Dichas configuraciones residirán en el archivo webpack.config.js de la aplicación.

# Hola Mundo en React.js
Al igual que sucedía con [[Express.js]], existen ==paquetes que nos posibilitan la generación de aplicaciones React.js desde cero== componiendo todo el esqueleto y estructura de directorios y ficheros necesaria para su ejecución. En este caso, la herramienta de scaffolding a instalar vía npm es la siguiente:
```bash
npm install -g create-react-app
```

Cuando finalice la instalación ya podremos crear nuestra primera aplicación en React.js con el comando create-react-app. Para ello, en una carpeta del sistema o en la unidad raíz ejecutaremos el siguiente comando desde el terminal (necesitaremos abrir una consola en modo Administrador para ello):
```powershell
C:\>create-react-app microblogging-example-react
```

A continuación, comentaremos de forma general cada uno de estos directorios y ficheros:
- **/node_modules**: Este directorio contendrá todos los módulos como dependencias del proyecto. Por defecto se instalarán las contenidas por defecto en el package.json, pero podremos instalar más a través de la herramienta npm y el propio package.json.

- **/public**: Es la raíz del proyecto, dónde se encuentra el archivo principal index.html y recursos como el icono que aparecerá en la pestaña del navegador cuando se despliegue la aplicación (favicon.ico). En el index.html habrá una etiqueta `<div>` con un id root que indica en qué lugar de la página se va a introducir el componente principal de nuestra aplicación. Este estará implementado en el fichero App.js. (Descripción original de la Figura 45: Archivos del directorio /public generados automáticamente).

- **/src**: Es la carpeta donde se almacenan los componentes (implementados en JavaScript o JSX) y los estilos .css, aparte de otros ficheros. Por defecto, el componente principal del proyecto se encuentra en App.js (o bien App.jsx). También existe un fichero index.js que se encarga de introducir el componente App en el `<div>` del index.html. (Descripción original de la Figura 46: Archivos del directorio /src) Podemos observar que también se encuentran las hojas de estilos App.css e index.css, una imagen en formato svg del logo de React.js, un archivo para realizar tests sobre el componente App y un archivo llamado registerServiceWorker.js. Este archivo será usado por la aplicación para intentar obtener los recursos de caché antes de obtener alguna información de la red, proporcionando experiencia de uso determinada incluso cuando se está sin conexión. Habitualmente, esta estructura de directorios y ficheros dentro de /src es adaptada a las necesidades del desarrollador y de la propia aplicación, teniendo una organización en subdirectorios para los componentes, modelos, estilos, y otro tipo de recursos necesarios.

- **package.json**: Al igual que en la aplicación back-end asociada a nuestro API REST, en el caso de la aplicación React.js también tendremos un archivo package.json a modo de manifiesto con información del proyecto, paquetes necesarios, dependencias y scripts.

- **.gitignore**: En este fichero se describen aquellos archivos y/o directorios a ignorar cuando usamos Git (por ejemplo, es común ignorar el directorio /node_modules, y no almacenar todo el código de los módulos en el repositorio, ya que podemos instalarlos a la hora de desplegarlo con el comando npm install). Igualmente podemos decidir ignorar archivos como el .env si nuestra aplicación tuviera variables de entorno definidas y que no queremos sincronizar con el repositorio (cómo ya hicimos durante la implementación de la API REST).

___ 
### 4.1.6 Propiedades y estados

A lo largo de las secciones anteriores ya habían aparecido las palabras propiedades (props) y estados (state) de un componente, y es que no se puede entender React.js sin explicar lo que significan.

Debemos saber que, tanto las props como el state son objetos JavaScript simples y los cambios en ambos desencadenan la ejecución de la función render() del componente.

Entonces, ¿Cuándo utilizamos props y cuando state? La respuesta es sencilla. Si un componente va a necesitar modificar alguno de sus atributos en algún momento de su vida, entonces ese atributo debe formar parte de su estado, de lo contrario será una propiedad de dicho componente.

Cada componente puede tener uno o varios estados además de sus propiedades. Estos estados son intrínsecos al componente y no dependen de componentes superiores o padre (si no, los pasaríamos por propiedades). Hay que tener en cuenta estas tres consideraciones:

- Es mejor tener componentes sin estado (más reusables).
    
- Los estados se definen en el constructor de clase mediante this.state.
    
- Si queremos modificar un estado, se debe usar el método this.setState() (no se puede modificar directamente this.state).
    

A continuación, detallaremos con mayor nivel de detalle lo que suponen tanto las propiedades como los estados de un componente React.js.

#### 4.1.6.1 PROPIEDADES

Pueden definirse como los atributos de configuración para un componente. Son recibidos desde un nivel superior (normalmente al instanciar el componente) y por definición **inmutables**, es decir, un componente **no puede** cambiar sus propias propiedades o props. A continuación, se presenta un ejemplo de uso en un componente al que se le pasan las propiedades cuando se va a renderizar el DOM.

```jsx
import React from 'react';
import ReactDOM from 'react-dom';

class MyComponent extends React.Component {
  render(){
    return (
      <div>
        Me llamo {this.props.name} y tengo {this.props.anios} años.
      </div>
    );
  }
}

export default MyComponent;

// Uso (ejemplo en otro archivo o más abajo)
// ReactDOM.render(<MyComponent name="Ana" anios="30" />, document.getElementById('app'));
```

De esta forma, al renderizar el componente con ReactDOM.render() se pasan los valores de las propiedades name y anios. Si lo hacemos desde el fichero app.js, sería:

```javascript
import React from 'react';
import ReactDOM from 'react-dom';
import MyComponent from "./components/ejemplo"; // Asegúrate de que la ruta es correcta

const app = document.getElementById('app'); // Asume que existe un <div id="app"> en tu HTML
ReactDOM.render(<MyComponent name="Ana" anios="30" />, app);
```

content_copydownload

Use code [with caution](https://support.google.com/legal/answer/13505487).Jsx

También podemos definir en el componente unos valores por defecto para las propiedades utilizando de forma conveniente la variable defaultProps una vez creado el componente, de esta forma:

```jsx
import React from 'react';
import ReactDOM from 'react-dom';

class MyComponent extends React.Component{
  render(){
    return (
      <div>
        Me llamo {this.props.name} y tengo {this.props.anios} años.
      </div>
    )
  }
}

// Definición de valores por defecto para las props
MyComponent.defaultProps = {
  name: 'Jesus',
  anios: '35'
};

// Ahora, si no se pasan las props, usará las default
ReactDOM.render(<MyComponent />, document.getElementById('app'));
// Se renderizará: Me llamo Jesus y tengo 35 años.

// También se pueden sobrescribir:
// ReactDOM.render(<MyComponent name="Maria"/>, document.getElementById('app'));
// Se renderizará: Me llamo Maria y tengo 35 años.
```

content_copydownload

Use code [with caution](https://support.google.com/legal/answer/13505487).Jsx

Así, si renderizamos el componente sin dar valores a las props, este se creará con los valores por defecto que se hayan indicado.

Por otra parte, los componentes React.js están diseñados para poder agruparlos en componentes más grandes y ser reutilizados, ya sea en el mismo proyecto, en otro proyecto, o por otros desarrolladores. De modo que, es una buena práctica definir explícitamente las propiedades que acepta un componente, cuáles serán requeridas, y los tipos de dato de cada una de ellas. Este es el propósito de las propTypes de un componente, que nos ayudará a revisar rápidamente cuáles son las propiedades que debemos pasar a dicho componente (por ejemplo, cuando hay un error, React.js mostrará un mensaje en la consola indicando qué propiedades faltan y qué método generó el problema). Esto supone una herramienta útil tanto a nivel de depuración como para validar valores de propiedades a nivel de front-end del cliente.

El objeto propTypes se define como una propiedad estática en la clase. En el siguiente ejemplo se puede apreciar un componente Titulo que recibe una propiedad nombre que se muestra dentro de un encabezado `<h1>`.

```jsx
import React from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types'; // Necesitas importar PropTypes

class Titulo extends React.Component {
  render () {
    return (
      <h1>
        { this.props.nombre }
      </h1>
    );
  }
}

// Definición de los tipos de props
Titulo.propTypes = {
  nombre: PropTypes.string.isRequired // 'nombre' debe ser string y es requerido
};

// Uso
ReactDOM.render(<Titulo nombre="Mi Título" />, document.getElementById('root'));
// Si no pasas 'nombre' o pasas otro tipo, verás un warning en consola
```

content_copydownload

Use code [with caution](https://support.google.com/legal/answer/13505487).Jsx

Para especificar que esa propiedad es de tipo string indicamos el tipo PropTypes.string.isRequired. La parte isRequired (opcional) sirve para especificar que una propiedad es obligatoria. Esto nos da una idea de cómo la implementación de validaciones de determinados valores de variables en React.js puede ser una tarea bastante sencilla.

Una vez explicado, de forma general, lo que son las propiedades y algunas características importantes al respecto, pasaremos a comentar la parte de los estados de un componente React.js.

#### 4.1.6.2 ESTADOS

Un estado se podría definir como una representación del componente en un instante determinado. El estado o state de un componente se iniciará con un valor por defecto, pero a diferencia de las propiedades ese valor sí podrá cambiar durante la vida del componente.

Al contrario que ocurre con las propiedades, un componente **puede** gestionar su propio state. Debemos ser cuidadosos al utilizar estados ya que estos podrían aumentar la complejidad y reducir la previsibilidad en el código.

La forma usual de informar a un componente React.js que sus datos han cambiado, es a través del método setState(). Este método recibe un objeto JavaScript plano (o una función), **combina** los nuevos datos en el state (no lo reemplaza entero) y dispara un nuevo render del componente. Cuando el renderizado finaliza, se ejecuta un [callback](https://www.google.com/url?sa=E&q=https%3A%2F%2Fdeveloper.mozilla.org%2Fes%2Fdocs%2FGlossary%2FCallback_function) si fue especificado como segundo argumento de setState.

```javascript
this.setState({ key: 'value' }, () => {
  // Callback opcional que se ejecuta después de que el estado se actualice y el componente se re-renderice
  console.log('Estado actualizado');
});

// O usando una función para actualizar el estado basado en el estado anterior o props
this.setState((prevState, props) => ({
    counter: prevState.counter + 1
}));
```

El estado del componente se almacena en la propiedad state y está formado por aquella información que sí es gestionada y modificada directamente por el componente. Cada vez que se realiza un cambio en el estado del componente como respuesta a una acción del usuario (o debido a algún otro factor externo como una llamada a API), el framework se encargará de renderizar nuevamente el componente por completo (llamando a render()).

Cabe destacar que, como un componente puede contener a otros componentes, en el proceso de renderizado se volverán a crear/actualizar estos componentes hijos con la nueva información (posiblemente pasada como props). Es posible, y bastante habitual, que el estado cambiante de un componente padre se pase como props (inmutables para el hijo) a sus componentes hijos.

A continuación, se muestra un ejemplo que inicializa el estado de un componente con unos valores determinados. Si antes esos valores se definían en las props, ahora vamos a ver qué pasa si forman parte del state.

```jsx
import React from 'react';

class MyComponent extends React.Component{
  constructor(props){
    super(props);
    // Inicialización del estado en el constructor
    this.state = {
      name:'Jesus',
      edad: '35'
    };
  }

  render(){
    return (
      <div>
        {/* Acceso al estado mediante this.state */}
        Me llamo {this.state.name} y tengo {this.state.edad} años.
      </div>
    );
  }
};

export default MyComponent;
```

content_copydownload

Use code [with caution](https://support.google.com/legal/answer/13505487).Jsx

Los valores de los estados pueden ser modificados a través de eventos disparados desde los propios componentes (por ejemplo, de un componente hijo hacia uno padre, usando callbacks pasados como props). En el caso de las propiedades, estas suelen pasar de padres a hijos (se heredan). De esta forma, si nosotros quisiéramos cambiar el valor de name, del estado del componente, lo podríamos hacer a través de un evento, cuyo método asociado llame a setState sobre la propia variable name, tal y como se muestra en el bloque de código siguiente (añadiendo un botón y un manejador):

```jsx
import React from 'react';

class MyComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: 'Jesus',
      edad: '35'
    };
    // Es necesario hacer bind del 'this' en el constructor o usar arrow functions
    this.handleChangeName = this.handleChangeName.bind(this);
  }

  // Método para cambiar el estado
  handleChangeName() {
    // Usamos setState para actualizar el estado 'name'
    this.setState({ name: 'Maria' }); // Cambia el nombre a 'Maria'
  }

  // También podrías pasar un valor nuevo si el evento lo proporcionara
  // handleChangeName(newName) {
  //   this.setState({ name: newName });
  // }

  render() {
    return (
      <div>
        Me llamo {this.state.name} y tengo {this.state.edad} años.
        {/* Botón que al hacer click llama a handleChangeName */}
        <button onClick={this.handleChangeName}>Cambiar Nombre</button>

        {/* Ejemplo con componente hijo (necesitaría definir <InputComponent>)
           Si quisieras que un hijo modifique el estado del padre, pasarías
           la función como prop:
           <InputComponent onChangeName={this.handleChangeName} />
        */}
      </div>
    );
  }
}

export default MyComponent;

/* Código original en el PDF para la sección del render, asumo que intentaba ilustrar pasar un callback:
render() {
  return (
    <InputComponent onChangeName={this.handleChangeName} /> // Falta la definición de InputComponent
  )
}

// Y la función en el componente padre:
handleChangeName () {
  this.setState({ name: this.state.name }) // Esto no cambiaría el nombre, usa el mismo valor.
  // Probablemente la intención era:
  // handleChangeName (newNameFromInput) {
  //   this.setState({ name: newNameFromInput })
  // }
}
*/
```

content_copydownload

Use code [with caution](https://support.google.com/legal/answer/13505487).Jsx

Este será el mecanismo que utilizaremos en nuestra aplicación front-end, y que permitirá volver a renderizar los componentes ante cambios en determinadas variables que forman parte de su estado. Si deseas conocer más acerca de los estados y las propiedades de los componentes en React.js, te aconsejo que eches un vistazo a las lecturas recomendadas.

> **NOTA:** La forma de manejar las propiedades y los estados a partir de la versión de React.js 16.8 también ha experimentado algunos cambios. En este caso se han introducido los hooks de estado (como useState), así como otras particularidades (como useEffect para ciclos de vida). Para más información, nuevamente te emplazamos a la sección del libro Introducción a los hooks en React.js.

### 4.1.7 Enrutado con React Router

Una aplicación React.js, como toda aplicación web, se basa en rutas que determinan qué páginas y componentes se deben mostrar al usuario dependiendo donde este se encuentre dentro de la aplicación. Recuerda que en nuestra API REST, el framework Express.js se encarga de manejar las rutas a los recursos del back-end que el cliente puede solicitar haciendo uso de peticiones HTTP. Mientras que, en este caso, las rutas estarán asociadas a componentes y páginas que nuestra aplicación web cliente podrá renderizar.

La librería usada para manejar las rutas en una aplicación React.js se llama react-router, que cuenta con dos add-ons, uno más enfocado a web (react-router-dom) y otro para desarrollo móvil (react-router-native). La última versión de dicha librería corresponde a React Router v4 (y posteriores, como v5, v6), que difiere en algunas cosas con respecto a versiones anteriores, haciendo distinción entre el enrutamiento estático que se usaba en anteriores versiones y el enrutamiento dinámico actual.

Para instalar la librería correspondiente en nuestro proyecto (si aún no la hemos instalado), ejecutaremos el siguiente comando:

```
C:\microblogging-example-react>npm install react-router-dom --save
```

content_copydownload

Use code [with caution](https://support.google.com/legal/answer/13505487).Bash

Recuerda que, en secciones posteriores del libro implementaremos una aplicación cliente completa y abordaremos estos conceptos de forma práctica, pero mientras, podemos trabajar en el directorio del proyecto inicialmente creado para tal fin.

#### 4.1.7.1 TIPOS DE ENRUTAMIENTO Y COMPONENTES DEL ROUTER

Como se ha mencionado anteriormente, una de las mejoras de la última versión de react-router radica en la distinción y uso del enrutamiento dinámico con respecto al estático.

- **Enrutamiento estático:** es el enrutamiento más común en otros frameworks. En este caso, las rutas son definidas al momento en que nuestra aplicación es inicializada. Es decir, antes de que nuestra aplicación se renderice.
    
- **Enrutamiento dinámico:** es el usado por react-router (especialmente desde v4). A diferencia del estático, este se da en el momento en que la aplicación se está renderizando, debido a que también hace uso de componentes para definir sus rutas.
    

Dado que react-router es una librería implementada en React.js, está basada en componentes. A continuación, vamos a describir los componentes del Router más utilizados en las aplicaciones web. Ten en cuenta que, los componentes encargados de mostrar las diferentes rutas siempre renderizan, o bien un componente o un null, dependiendo de la localización.

**BrowserRouter**  
Podríamos decir que es una envoltura de nuestra aplicación, la cual nos da acceso a la [History API](https://www.google.com/url?sa=E&q=https%3A%2F%2Fdeveloper.mozilla.org%2Fes%2Fdocs%2FDOM%2FManipulando_el_historial_del_navegador) de HTML5 para mantener nuestra interfaz gráfica en sincronía con la localización o URL actual. Esta envoltura solo puede tener un hijo, que por lo general es el componente Switch (en v5) o Routes (en v6).

**Switch** (React Router v4/v5)  
Este componente causa que **solo se renderice el primer hijo Route o Redirect que coincida** con la localización o URL actual. En el caso de no usar Switch, todas las rutas que cumplan con la condición se renderizarán. (Nota: En React Router v6, se reemplaza por <Routes>).

**Route**  
Este componente se usa para definir las diferentes rutas de nuestra aplicación. La función de Route es elegir qué renderizar según la localización actual. Al igual que se expuso anteriormente, todos los componentes Route siempre renderizan, pero algunas veces renderizan un componente y otras veces retornan null (si la ruta no coincide y no está dentro de un Switch/Routes). Teniendo en cuenta el siguiente ejemplo (v4/v5):

```
import React, { Component } from 'react';
import { BrowserRouter, Switch, Route } from 'react-router-dom';
import Home from './Home'; // Asume componentes definidos
import About from './About';

export default class App extends Component {
  render() {
    return (
      <BrowserRouter>
        <Switch>
          <Route path="/about" component={About} />
          <Route path="/index" component={Home} /> {/* Se mostraría para /index */}
          {/* Ruta sin path renderizará si no hay match anterior dentro de Switch */}
          <Route component={NotFoundComponent}/>
        </Switch>
      </BrowserRouter>
    );
  }
}
```

content_copydownload

Use code [with caution](https://support.google.com/legal/answer/13505487).Jsx

En caso de que la URL actual sea similar a www.midominio.com/index, se mostrará la ruta con path="/index" (renderizando Home).

El componente Route puede recibir las siguientes propiedades (principales en v4/v5):

- path: define la ruta (string o array de strings) en la que se renderizará el componente.
    
- exact: un booleano que define si queremos que la ruta sea o no exacta para renderizar un componente. Ej: con exact, /index no coincide con /index/all. Sin exact, sí coincidiría.
    
- strict: un booleano que define si queremos que la última barra / se tenga en cuenta para renderizar un componente. Ej: con strict, /index/ no coincide con /index.
    
- sensitive: booleano para distinguir entre mayúsculas y minúsculas. Ej: con sensitive, /index no coincide con /Index.
    
- component: recibe un componente a renderizar. **Importante:** Crea un nuevo elemento React.js cada vez, y causa que el componente se monte y desmonte cada vez (no actualiza si solo cambian props del router). Generalmente se prefiere render o children si se necesita pasar props o rendimiento.
    
- render: recibe una función que retorna un elemento React. A diferencia de component, no remonta el componente si las props del router cambian. Ideal para pasar props o renderizado inline. render={props => <MiComponente {...props} miPropExtra="valor" />}
    
- children: es similar a render, pero se renderiza **siempre**, coincida o no la ruta (recibe match como null si no coincide). Útil para renderizado condicional basado en match.
    

(Nota: En React Router v6, la sintaxis cambia significativamente. Se usa <Routes> en lugar de <Switch>, y element={<MiComponente />} en lugar de component o render.)

Los tres métodos para renderizar (component, render, children) en v4/v5, nos permiten acceder a tres props adicionales pasadas automáticamente al componente renderizado. Estos van a contener los datos (data) del History API de HTML5 y son: match, location, history.

En el caso de querer acceder a estas propiedades desde un componente que no fue renderizado directamente por un Route (p.ej., un componente anidado profundamente), react-router nos permite el uso de un HOC (Higher-Order Component) para darnos este acceso. Este componente se llama withRouter. (Nota: En v6, se usan hooks como useParams, useLocation, useNavigate).

A continuación, se muestra un ejemplo (v4/v5) de componentes del react-router y las propiedades que pueden incluir:

```
import React, { Component } from 'react';
import { BrowserRouter, Route, Switch, Redirect } from 'react-router-dom';
import NavBar from './NavBar/NavBar';
import Home from './Home/Home';
import Page1 from './Page1/Page1';
import Page2 from './Page2/Page2';
import PageError from './PageError/PageError';
import './App.css';

class App extends Component {
  render() {
    return (
      <BrowserRouter>
        <div> {/* BrowserRouter solo puede tener un hijo */}
          <NavBar /> {/* NavBar fuera del Switch para que siempre se muestre */}
          <Switch>
            {/* Redirige de la raíz a /home */}
            <Redirect exact from="/" to="/home" />

            <Route path="/home" component={Home} />
            <Route exact path="/page1" component={Page1} />
            <Route exact path="/page2" component={Page2} />

            {/* Ruta catch-all para páginas no encontradas */}
            <Route component={PageError} />
            {/* O podrías redirigir a una página de error:
               <Redirect to="/error" />
               Y tener una ruta para /error
               <Route path="/error" component={PageError} />
            */}
          </Switch>
        </div>
      </BrowserRouter>
    );
  }
}

export default App;
```

content_copydownload

Use code [with caution](https://support.google.com/legal/answer/13505487).Jsx

En dicho ejemplo se renderizan los componentes de la siguiente forma:

- Si la ruta es /, redirige a /home.
    
- Si la ruta es /home (o después de la redirección), renderizará el componente Home.
    
- Si la ruta es exactamente /page1, renderizará el componente Page1.
    
- Si la ruta es exactamente /page2, renderizará el componente Page2.
    
- Y si no es ninguna de las anteriores (y está dentro del Switch), se renderizará el componente PageError (la última Route sin path).
    

**Redirect**  
Este componente, el cual aparece en el ejemplo anterior, causa un redireccionamiento a una ruta diferente a la actual. La ruta a la que nos redirecciona **reemplaza** la localización actual en la historia del navegador por defecto. Redirect a su vez puede recibir las siguientes propiedades (v4/v5):

- from: localización (string, path-to-regexp) desde la cual se va a hacer el redireccionamiento. Esta propiedad funciona de forma similar a path del componente Route, y cuando la localización coincide con from (y está dentro de un Switch), se ejecuta el Redirect.
    
- to: localización (string o object) a la cual se realizará el redireccionamiento.
    
- push: define un booleano que permite modificar el comportamiento de Redirect. Cuando es true, en lugar de reemplazar la localización actual en la historia, este **agrega** una nueva localización (como si el usuario hubiera navegado a ella).
    
- Al igual que en Route, también podemos usar las propiedades strict y exact con from.
    

Dicho esto, en el caso del ejemplo anterior, si navegamos al index de la aplicación (/), el componente Redirect cambiará esa localización por /home. Y el Switch renderizará el componente Route que coincida con esta nueva ruta (/home), en este caso Home.

**Link**  
Para navegar entre las rutas configuradas, lo que puede suponer cambiar de un componente a otro, habría que cambiar la URL “de forma manual” o mediante programación (history.push). Con el componente Link se crea un hipervínculo (<a>) que nos permite navegar por nuestra aplicación de forma declarativa, **gestionando correctamente el historial del navegador sin recargar la página**. Al contrario que Redirect por defecto, este componente **agrega** una nueva localización a la historia. Link puede recibir las siguientes propiedades (v4/v5):

- to: será la localización (string o object) a la que navegaremos cuando hacemos click sobre el hipervínculo.
    
- replace: booleano que nos permite modificar el comportamiento de Link. Cuando es true en lugar de agregar una nueva localización a la historia (push), este **reemplaza** la localización actual (como Redirect).
    
- Otras props como className, style, etc., se pasan al elemento <a> renderizado.
    

(Nota: En v6 existe también <NavLink> que permite aplicar estilos al enlace activo).

A continuación, se muestra un ejemplo de componente NavBar que utiliza Link (v4/v5). La propiedad className indica que se usará el estilo CSS denominado "link" a la hora de mostrar dicho enlace.

```
import React, { Component } from 'react';
import { Link } from 'react-router-dom';
import './NavBar.css'; // Asume que tienes estilos definidos

class NavBar extends Component {
  render() {
    return (
      <nav>
        <ul>
          <li>
            <Link to="/home" className="link">Home</Link>
          </li>
          <li>
            <Link to="/page1" className="link">Página 1</Link>
          </li>
          <li>
            <Link to="/page2" className="link">Página 2</Link>
          </li>
        </ul>
      </nav>
    );
  }
}

export default NavBar;
```

content_copydownload

Use code [with caution](https://support.google.com/legal/answer/13505487).Jsx

---

Espero que este formato te sea muy útil para tus apuntes en Obsidian. ¡Avísame si necesitas algo más!