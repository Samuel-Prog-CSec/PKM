El **lenguaje JSX** que se define como una ==extensión de la sintaxis JavaScript,== y cuyos ficheros albergan la extensión `.jsx`.

Esta sintaxis es específica de React.js y ==permite mezclar código JavaScript y HTML== (XML). De esta forma, podremos escribir un código más limpio, sin tantas repeticiones, y con pocos factores o condiciones a tener en cuenta. JSX será usado por React.js para generar su Virtual DOM, sincronizando después con el DOM real, para representar la información de las vistas en el navegador.

Al basar el desarrollo de aplicaciones en componentes, necesitamos crear ==elementos HTML que definan nuestros componentes==. De esta forma, cuando se trata de componentes creados por nosotros lo podemos implementar directamente en JavaScript a partir de los métodos y funciones que nos ofrece React.js mediante `React.createElement`. 
Imagina que quieres crear un componente HTML `<Icon/>`, definido por una imagen y algunas hojas de estilo CSS. **Usando JavaScript**, la implementación sería similar a esta:
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


# Ejemplo de componente usando: especificación ES6 vs JSX
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