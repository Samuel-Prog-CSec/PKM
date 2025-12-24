---
tags:
  - Web/Front-end
  - Introduccion
  - Ingenieria
Fecha de actualización: 2025-11-17
Nota previa:
Nota siguiente:
Area:
---
---

[FUENTE PRINCIPAL DOCUMENTACION DE REACT PARA APRENDER](https://es.react.dev/learn)

---

El **framework React.js** constituye la tecnología de **cliente o front-end** en la pila `MERN`. En este caso, también se trata de una librería JavaScript, creada por Facebook, que nos ayuda a la hora de desarrollar aplicaciones en una sola página, conocidas como `SPA` (*Single Page Application*).

Los desarrolladores podrán crear aplicaciones React.js basadas en **componentes propios y/o importarlos de terceros**. Otra de las características de React.js que la diferencia de otras librerías, es el uso de la sintaxis [JSX](https://www.google.com/url?sa=E&q=https%3A%2F%2Fjsx.github.io%2F) para construir componentes de interfaz de usuario. **JSX** ==crea plantillas donde se pueden anidar elementos==.

Por otra parte, `ReactJS` utiliza un **DOM virtual o Virtual DOM** que ==recarga cada componente de forma individual cuando hace falta==, por lo que ofrece gran velocidad a la hora de renderizar las vistas. En este sentido, cuando una aplicación cliente pretende mostrar la información al usuario a través de su interfaz, esta se representa como un árbol de etiquetas (HTML, XML, etc.) jerarquizado. A dicha representación se le denomina **DOM** (*Document Object Model*). Teniendo en cuenta esto, el **Virtual DOM** es considerado una abstracción del DOM, de forma que, al renderizar las vistas, ==se renderizará lo estrictamente necesario de una forma mucho más optimizada==.

Otro de los elementos interesantes de este framework son los **componentes**. Estas “piezas de software” son independientes y contienen ==su propio comportamiento, un estado y el contenido a renderizar== (es decir, la vista a mostrar al usuario). De esta forma se pueden establecer jerarquías y relaciones entre componentes para posibilitar su comunicación. A su vez, las aplicaciones creadas con React.js tienen un **estado global** que repercute en el estado individual de cada componente. Por tanto, estamos tratando con un ==framework orientado a componentes==.

El **isomorfismo** (==renderización de código HTML tanto en el servidor como en cliente==) es otra de las características de React.js, ofreciendo la posibilidad de entregar el HTML ya renderizado a los buscadores web (por ejemplo, Google) y así mejorar el posicionamiento. De esta manera se evita el problema de que el buscador se encuentre el cuerpo de la página vacío.

En la [página web oficial de React.js](https://www.google.com/url?sa=E&q=https%3A%2F%2Freactjs.org%2F) se tiene toda la información detallada de este framework, así como tutoriales y ejemplos prácticos.

---

# React Developer Tools
[React Developer Tools](https://www.google.com/url?sa=E&q=https%3A%2F%2Freactjs.org%2Fblog%2F2019%2F08%2F15%2Fnew-react-devtools.html) es una extensión para los navegadores Google Chrome y Mozilla Firefox que, instalada, nos provee de un conjunto de utilidades para la inspección de los componentes de una aplicación web React.js en ejecución. De esta forma podremos observar una vista del árbol de componentes, así como el estado actual y las propiedades de cada componente seleccionado.

Tan solo tenemos que hacer `click` con el botón derecho del ratón y seleccionar “`inspeccionar`” para acceder a la información de la web. Después, en la pestaña React accedemos a la información proporcionada por estas herramientas.

Así mismo, gracias a estas herramientas, podemos ver si una aplicación web está desarrollada en React.js y si se está ejecutando en producción o en depuración, entre otras características. Es muy aconsejable utilizar este tipo de herramientas para depurar tus aplicaciones web, a nivel de cliente desde el navegador.

---

# Sintaxis JSX
El **lenguaje JSX** que se define como una ==extensión de la sintaxis JavaScript,== y cuyos ficheros albergan la extensión `.jsx`.

Esta sintaxis es específica de React.js y ==permite mezclar código JavaScript y HTML== (XML). De esta forma, podremos escribir un código más limpio, sin tantas repeticiones, y con pocos factores o condiciones a tener en cuenta. JSX será usado por React.js para generar su Virtual DOM, sincronizando después con el DOM real, para representar la información de las vistas en el navegador.

Al basar el desarrollo de aplicaciones en componentes, necesitamos crear ==elementos HTML que definan nuestros componentes==. De esta forma, cuando se trata de componentes creados por nosotros lo podemos implementar directamente en JavaScript a partir de los métodos y funciones que nos ofrece React.js mediante `React.createElement`. 

Imagina que quieres crear un componente *HTML* `<Icon/>`, definido por una imagen y algunas hojas de estilo CSS. **Usando JavaScript**, la implementación sería similar a esta:
```javascript
var image = React.createElement('img', { 
	src: 'react-icon.png', 
	className: 'icon-image' 
});

var container = React.createElement('div', { 
	className: 'icon-container' 
}, image);

var icon = React.createElement('Icon', { 
	className: 'avatarContainer' 
}, container);

ReactDOM.render(icon, document.getElementById('app'));
```

Este componente se traduciría en el siguiente **código HTML**:
```html
<div class="avatarContainer">
  <div class="icon-container">
    <img class="icon-image" src="react-icon.png">
  </div>
</div>
```

Siendo el **CSS asociado**, el siguiente:
```css
.icon-image {
  width: 100px
}
.icon-container {
  background-color: #222;
  width: 100px
}
```

De esta forma, si quisiéramos hacer lo mismo, pero empleando la **sintaxis JSX**, el código del componente quedaría:
```jsx
var Icon = (
  <div className="avatarContainer">
    <div className="icon-container">
      <img className="icon-image" src="react-icon.png" />
    </div>
  </div>
)

ReactDOM.render(Icon, document.getElementById('app'))
```

Como se puede observar, este código es ==más fácil de comprender y más legible==. Es como escribir código HTML pero realmente es JavaScript. Obviamente debemos de tener en cuenta algunas **palabras reservadas propias de la sintaxis JSX**, como puede el caso del atributo `class` ==que pasa a ser== `className`, entre otras.

Cuando nuestra aplicación va creciendo en componentes y complejidad, usar JSX nos ayudará a agilizar nuestros desarrollos. Así, el hecho de usar JSX para codificar los componentes de nuestra aplicación, ==hace que tengamos que utilizar un bundler== como **webpack** para empaquetar, ==junto con un transpilador== como **babel** que permita la transpilación del código JS a JSX antes de desplegarlo.


## Ejemplo de componente usando: especificación ES6 vs JSX
Ejemplo del código de un componente utilizando la **especificación ES6 con su sintaxis de clases**, y el mismo ejemplo utilizando la sintaxis **JSX**. E==n el primer caso (sin JSX)==, el código sería similar a este:
```javascript
class ComponenteConEstado extends React.Component{

  constructor(props) {
    super(props);
  }
  
  render() {
    return React.createElement(
      'div',
      null,
      React.createElement(
        'h1',
        null,
        'Cabecera 1'
      ),
      React.createElement(
        'h2',
        null,
        'Cabecera 2'
      )
    );
  }
}
```

Mientras que, ==usando JSX== se podría simplificar a algo como:
```jsx
class ComponenteConEstado extends React.Component{

  constructor(props){
    super(props);
    this.state = { title: 'Introducción React'};
  }
  
  render() {
    const { title } = this.state;
    return (
      <div>
        <h1>Cabecera 1 { title }</h1>
        <h2>Cabecera 2</h2>
      </div>
    );
  }
}
```

Nuevamente podemos comprobar la **facilidad de comprensión de dicho código usando JSX**, así como las ventajas de renderización aportadas por el framework React.js. Por eso, lo mejor y más recomendable cuando desarrollamos una aplicación en React.js es usar la sintaxis JSX en todos nuestros ficheros, ya que, a la hora de desplegar la aplicación, ==será el transpilador quien se encargue de convertir esa sintaxis a JavaScript== (en sus diferentes especificaciones: ES5, ES6, etc.). Aunque también podría existir un fichero JavaScript en el proyecto que será el punto de entrada (o *entry point*), como puede ser el `index.js`.