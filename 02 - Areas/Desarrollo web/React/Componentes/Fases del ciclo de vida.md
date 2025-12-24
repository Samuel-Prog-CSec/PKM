Podemos definir el ciclo de vida de un componente como una serie de estados o fases por las que pasa este a lo largo de su existencia. Esos estados tienen correspondencia en diversos métodos (funciones), que podemos implementar para realizar diferentes acciones cuando se pasa por los mismos. En React.js es fundamental el ciclo de vida, ya que hay determinadas acciones que debemos realizar necesariamente en el momento correcto de ese ciclo. Algunos de estos estados son fáciles de comprender, pero otros no son una tarea trivial.

Las fases o estados por los que pasa un componente, es algo específico de componentes con estado (Stateful), ya que los componentes sin estado tienen apenas un método que se usará para renderizar el componente y React.js no controlará su ciclo de vida.

(Descripción original de la Figura 50: Diagrama de flujo. Fases del ciclo de vida de un componente React.js)

> **NOTA:** Nuevamente, las últimas versiones de React.js y la refactorización de las clases como React hooks simplifica las fases del ciclo de vida, y las sustituye por los denominados hooks de efecto. Sin embargo, estudiar y comprender todos los estados por los que puede pasar un componente, supondrá una base de conocimiento que nos ayudará a entender mejor la implementación de estos componentes bajo la filosofía de los React hooks.

Las funciones o métodos usados para controlar el ciclo de vida de un componente corresponden a métodos de: montaje, actualización y desmontaje.

En cuanto a esas etapas, podríamos decir que:

- El **montaje** se produce la primera vez que un componente va a generarse, incluyéndose en el DOM.
    
- La **actualización** se produce cuando el componente ya generado se está actualizando.
    
- El **desmontaje** ocurre cuando el componente se elimina del DOM.
    

Además, dependiendo del estado actual de un componente y lo que está ocurriendo en él, se producirán grupos diferentes de etapas del ciclo de vida.

(Descripción original de la Figura 51: Etapas del ciclo de vida de un componente React.js)

A continuación, describiremos de forma breve cada una de estas funciones, que permitirán ejecutar código en diferentes instantes (dependiendo de las situaciones), tal y como suelen hacer los manejadores de eventos en cualquier lenguaje de programación.

**componentWillMount()** (OBSOLETO/NO RECOMENDADO)  
Este método, que se da en el montaje del componente, se ejecuta justo antes de su primer renderizado. Si dentro de este método se fija el estado del componente con setState(), el primer renderizado mostrará ya el dato actualizado y sólo se renderizará una vez el componente. Nota: Este método se considera obsoleto y se debe evitar en nuevo código.

**componentDidMount()**  
Es un método de montaje que solo se ejecuta en el lado del cliente. Se produce inmediatamente después del primer renderizado. Una vez invocado este método, ya están disponibles los elementos asociados al componente en el DOM. Es el lugar ideal para realizar llamadas a APIs, suscripciones o manipulaciones del DOM. Si el elemento tuviera otros componentes hijos, se tiene certeza que estos se han inicializado también y han pasado por los correspondientes componentDidMount().

**componentWillReceiveProps(nextProps)** (OBSOLETO/NO RECOMENDADO)  
Método de actualización que se invoca cuando las propiedades se van a actualizar, aunque no en el primer renderizado del componente, así que no se invocará antes de inicializar las propiedades por primera vez. Tiene como particularidad que recibe el valor futuro del objeto de propiedades (nextProps) que se va a tener. El valor anterior es el que está todavía en el componente, pues este método se invocará antes de que esos cambios se hayan producido. Nota: Este método también es obsoleto. Usar getDerivedStateFromProps o componentDidUpdate en su lugar.

**shouldComponentUpdate(nextProps, nextState)**  
Es un método de actualización y tiene la particularidad de que debe devolver un valor booleano. Si devuelve true quiere decir que el componente se debe renderizar de nuevo y si se recibe false quiere decir que el componente no se debe renderizar de nuevo. Se invocará cuando se produzcan cambios en propiedades o estados, y es una oportunidad de comprobar si esos cambios debieran producir una actualización en la vista del componente. Por defecto (si no se definen) devuelve siempre true, para que los componentes se actualicen ante cualquier cambio de propiedades o estado. El motivo de su existencia es la optimización, puesto que el proceso de renderizado tiene un coste computacional y podemos evitarlo si realmente no es necesario realizarlo. Recibe dos parámetros con el conjunto de propiedades (nextProps) y estado (nextState) futuro.

**componentWillUpdate(nextProps, nextState)** (OBSOLETO/NO RECOMENDADO)  
Este método de actualización se invoca justo antes de que el componente vaya a actualizar su vista (después de shouldComponentUpdate si devuelve true). Es indicado para tareas de preparación de esa inminente renderización causada por una actualización de propiedades o estado. Nota: También obsoleto. Usar getSnapshotBeforeUpdate o componentDidUpdate.

**componentDidUpdate(prevProps, prevState)**  
Supone un método de actualización que se ejecuta justo después de haberse producido la actualización del componente y el renderizado en el DOM. En este caso, los cambios ya están trasladados al DOM del navegador, así que se podría operar con el DOM para hacer nuevos cambios o realizar llamadas a APIs basadas en las nuevas props/state. Como parámetros se reciben el valor anterior de las propiedades (prevProps) y el estado (prevState).

**componentWillUnmount()**  
Es el único método de desmontado y se ejecuta en el momento que el componente se va a retirar del DOM. Es un método importante, porque es el momento en el que se debe realizar una limpieza de cualquier cosa que tuviese el componente y que no deba seguir existiendo cuando se retire de la página. Por ejemplo, cancelar temporizadores, cancelar suscripciones (event listeners, llamadas a API), etc.

Con esto finalizamos la parte teórica sobre los componentes, su ciclo de vida y los métodos asociados. Se recomienda profundizar sobre ello y revisar las lecturas recomendadas al respecto.