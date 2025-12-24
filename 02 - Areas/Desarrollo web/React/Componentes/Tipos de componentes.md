# 1.- Componentes de comportamiento

En función del tipo de comportamiento que vaya a realizar el componente, tendremos componentes Stateful, Stateless, Pure Components y/o HOC.

## Componente con estado (Stateful)
Son el tipo de componentes más utilizados, también denominados componentes con estado. Su principal característica es que utilizan la encapsulación en clases, tienen un estado que definen y actualizan, y cada cambio tanto en las propiedades props como en el estado state hace que se llame al método render. A continuación, se presenta un ejemplo de este tipo de componentes.
```jsx
class MiBoton extends React.Component {
  constructor(props) {
    super(props);
    // Inicialización incorrecta del estado (debería ser this.state = { ... })
    // Corregido para ejemplo conceptual:
    this.state = { style: { background: 'blue', color: 'white' } };
  }

  render () {
    // Se asume que MiBoton es un componente simple que renderiza un botón
    return (
      <button style={this.state.style}>
        {this.props.children || 'Mi Botón'}
      </button>
    );
  }
}
```

## Componente sin estado (Stateless)  
Son una versión simplificada del tipo de componente anterior. Estos componentes se definen como si fueran funciones, y no tienen ni trabajan con estados (son componentes sin estado). Los únicos datos con los que trabajan son las propiedades props recibidas, además no sobrescriben los métodos de su ciclo de vida. La ventaja de este tipo de componentes es que son sencillos de escribir, fácilmente testeables y suelen mejorar el rendimiento. A continuación, se muestra un ejemplo de un componente stateless.
```jsx
const MiBoton = props => {
  const styles = {
    background: 'blue',
    color: 'white'
  }
  // Se asume que MiBoton renderiza un botón
  return (
    <button style={styles}>
      {props.children || 'Mi Botón'}
    </button>
  )
}
```

## Componente puro (Pure Component)  
Este componente es similar a los stateful en cuanto a su definición. También se implementan como clases, pero en este caso heredan de React.PureComponent. Al igual que los componentes stateless, estos no definen un estado, siendo puramente solo un componente visual. Esto hace que se consiga un mayor rendimiento en el renderizado, ya que solo cambian si detectan un cambio en sus props y sus valores son distintos a los valores que tenían anteriormente. La implementación, como se muestra en el ejemplo a continuación, es muy parecida a un componente con estado.
```jsx
class MiBoton extends React.PureComponent {
  // Estilos definidos directamente, ya que no cambian con el estado interno
  const styles = { // Corrección: styles debería ser una propiedad de la clase o estar dentro de render
    background: 'blue',
    color: 'white'
  }

  render () {
    const styles = { // Forma correcta de definirlo si no es propiedad de clase
        background: 'blue',
        color: 'white'
      }
    return (
      <button style={styles}>
         {this.props.children || 'Mi Botón Puro'}
      </button>
    );
  }
}
```

## Componente de orden superior (HOC - Higher-Order Component)
Este tipo de componentes constituyen un patrón de diseño utilizado en aplicaciones React.js. Suelen ser funciones que toman como parámetro otro componente, extendiendo su funcionalidad y devolviendo un nuevo componente con funcionalidad extendida. Si las props del HOC cambian, este se renderizará de nuevo y actualizará el componente envuelto en él, por lo que también se denominan wrappers. Este tipo de componentes se usan para implementar funcionalidades comunes en aplicaciones webs como pueden ser la paginación, interceptar y modificar la renderización, hacer llamadas a APIs y alimentar el componente envuelto, controlar las entradas en campos de formularios, etc. Estos componentes son usados en otros paquetes de React.js como react-redux y react-redux-form. Básicamente es un buen método para desacoplar funcionalidad, extender la funcionalidad de nuestros componentes y reutilizar el código en nuestra aplicación. Puedes conocer más acerca de este tipo de componentes en la [web de React.js](https://www.google.com/url?sa=E&q=https%3A%2F%2Freactjs.org%2Fdocs%2Fhigher-order-components.html) así como en otras fuentes de interés conforme a las lecturas recomendadas.

# Componentes estructurales
Estos componentes no se corresponden técnicamente con ningún elemento de la API, clase o función en React.js, son simplemente puramente conceptuales. El propósito por tanto de esta categoría es organizar nuestra aplicación para que sea más sencilla e intutiva a la hora de su desarrollo. No se trata de un estándar React.js, sino más bien de la propia comunidad y permite definir una arquitectura en nuestras aplicaciones. Así, tenemos dos tipos de componentes estructurales.

## Componentes visuales
Este tipo de componentes únicamente centran y enfocan sus esfuerzos en cómo debe renderizarse la interfaz de usuario (UI). Además, pueden componerse de otros elementos visuales y suelen incluir estilos y clases. Por último, todos los datos implicados en su renderización se deben recibir a través de propiedades props, por lo que deben ser independientes a llamadas a servicios externos y suelen ser componentes Stateless ya que no necesitan estado. A continuación, se muestra un ejemplo sencillo al respecto.
```jsx
class Item extends React.Component {
  render () {
    return (
      <li>
        { this.props.valor }
      </li>
    );
  }
}
```

## Componentes contenedores
A diferencia de los visuales, estos componentes dejan a un lado la interfaz para encargarse de la parte funcional. Son contenedores de otros componentes encargándose de gestionar la lógica de interacción y la lógica de los datos, mediante las llamadas necesarias a servicios externos. También como diferencia de los componentes anteriores, estos suelen gestionar su propio estado, siendo un nodo importante en la jerarquía del árbol de componentes. A continuación, se muestra un ejemplo que utiliza un bucle para recorrer un array de ítems del tipo `<Item>`, anteriormente implementado.
```jsx
import Item from './Item'; // Asumiendo que Item está en otro archivo

class ItemsContainer extends React.Component {
  constructor (props) {
    super(props);
    this.state = {
      temas: ['Vue', 'React', 'Angular']
    };
  }

  render () {
    const items = this.state.temas.map((t, index) => ( // Añadir key para listas
      <Item key={index} valor={t} />
    ));
    return (
      <ul>
        { items }
      </ul>
    );
  }
}
```

Los componentes contenedores pueden representar cada una de las páginas, y en este caso, coincidir con las rutas definidas. Igualmente, puedes profundizar más en estos componentes si así lo deseas, aunque no es nuestro objetivo principal.
> **NOTA:** La aparición de los **React hooks** simplifica en gran medida esta categorización.