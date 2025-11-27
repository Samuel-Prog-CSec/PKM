Como hemos indicado anteriormente, el framework React.js está basado en componentes. Si estás acostumbrado o conoces la programación orientada a objetos, podríamos asemejar un componente a una clase (de hecho, son clases que heredan de una clase Component superior). Por ello, es recomendable tener una buena organización de los componentes en directorios del proyecto, y reutilizarlos en las partes del código donde se precisen. Los componentes podrán ser independientes o estar relacionados con otros componentes. De todo ello hablaremos con algo más de detalle en posteriores secciones.

En un principio, para ahondar más en el conocimiento de los componentes y su implementación, crearemos un nuevo componente en el directorio /src del proyecto anteriormente generado, a la misma altura que el componente principal App.js, que llamaremos Saludo.js. A continuación, se muestra el código de este componente:
```javascript
import React, { Component } from 'react';

class Saludo extends Component {
  render() {
    return (
      <div>
        <h1>Hola Mundo!</h1>
      </div>
    );
  }
}
export default Saludo;
```

Definiremos Saludo.js como una clase que va a heredar todo aquello que tiene un componente React.js (Component). El método render() de la clase Saludo, renderizará un bloque de código HTML con un título cuyo contenido es “Hola Mundo!”. También se puede implementar una función o método constructor donde definiremos el estado del componente y donde podremos acceder y definir las propiedades y comportamiento de dicho componente.

Una vez hecho esto, para poder hacer uso de este componente en App.js, o en cualquier otro fichero, y renderizarlo, debemos exportarlo (con export default) dándole un nombre. En este caso Saludo.

Desde el componente principal App.js se orquestará el despliegue de componentes de la aplicación, ya sean propios o de terceros. En nuestro ejemplo, vamos a embeber el componente Saludo.js en el componente App.js para observar el efecto que tiene. Para ello, gracias a React.js, podemos hacer uso de la etiqueta <Saludo /> (que representará el componente Saludo.js) tal y como se muestra a continuación.
```javascript
import React, { Component } from 'react';
import Saludo from './Saludo'; // Importamos el componente Saludo
import logo from './logo.svg';
import './App.css';

class App extends Component {
  render() {
    return (
      <div className="App">
        <header className="App-header">
          <img src={logo} className="App-logo" alt="logo" />
          <h1 className="App-title">Welcome to React</h1>
        </header>
        {/* Añadimos nuestro componente Saludo */}
        <Saludo />
        <p className="App-intro">
          To get started, edit <code>src/App.js</code> and save to reload.
        </p>
      </div>
    );
  }
}
export default App;
```

Obviamente lo tendremos que importar al inicio del fichero que lo usará, en nuestro caso el App.js. En el bloque de código anterior se observa cómo queda el App.js tras la integración del componente Saludo.js en el mismo.

> **NOTA:** Es posible que al generar la aplicación React.js con el generador de aplicaciones instalado, este haya creado el componente App.js como una función. Eso es porque dicha versión del generador ya está adaptada a la creación de aplicaciones React.js bajo la nueva versión del framework liberada hace poco, y que usa los denominados React hooks en lugar de clases. Por el momento, implementaremos nuestros componentes como clases, por lo que es aconsejable sustituir el código generado para el componente App.js por el mostrado anteriormente.


# ¿Qué contienen los ficheros index.js e index.html?

En el archivo index.js se define como incrustar nuestro componente principal App.js, que contendrá en su interior el componente Saludo.js que hemos creado anteriormente. Haciendo uso de la clase ReactDOM, podremos renderizar App.js en el fichero index.html, archivo base HTML de inicio de la aplicación. A continuación, se muestra el código del index.js que renderizará dicho componente principal App.js en el elemento HTML que contenga el id="root".
```javascript
import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import App from './App';
import registerServiceWorker from './registerServiceWorker';

ReactDOM.render(<App />, document.getElementById('root'));
registerServiceWorker();
```

El fichero index.html declara la cabecera del HTML, enlaces a librerías externas o scripts en JavaScript, y demás código HTML asociado. Además, define el lugar dónde queremos embeber el componente principal App.js a través de la etiqueta: <div id="root"></div>. A continuación, se muestra el contenido completo de este index.html.
```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="theme-color" content="#000000">
    <link rel="manifest" href="%PUBLIC_URL%/manifest.json">
    <link rel="shortcut icon" href="%PUBLIC_URL%/favicon.ico">
    <title>React App</title>
  </head>
  <body>
    <noscript>
      You need to enable JavaScript to run this app.
    </noscript>
    <div id="root"></div>
  </body>
</html>
```

Una vez hecho esto, podemos volver a ejecutar el proyecto con el comando npm start y visualizar en el navegador el nuevo resultado, comprobando el renderizado del nuevo componente Saludo.js creado.

(Descripción original de la Figura 48: Resultado del despliegue de la aplicación React.js “Hola mundo” en el navegador)
> **NOTA:** Hasta la versión 16.8 de React.js, los componentes se implementaban como clases heredadas, pero a partir de dicha versión aparece el concepto de React hooks, dónde los componentes son implementados como funciones JavaScript con algunas peculiaridades, sobre todo relacionadas con el uso de estados y etapas del ciclo de vida. En la sección Introducción a los hooks en React.js presentaremos estos cambios y sus consecuencias sobre la aplicación a implementar. No obstante, ambas filosofías son perfectamente compatibles hoy en día.