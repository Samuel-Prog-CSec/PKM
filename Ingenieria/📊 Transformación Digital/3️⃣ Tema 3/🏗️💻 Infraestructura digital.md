La *infraestructura* es el conjunto de **estructuras e instalaciones tanto físicas como organizativas necesarias para el funcionamiento** de una sociedad o empresa. La *infraestructura digital* se refiere a los ==componentes de TI que soportan el funcionamiento== de aplicaciones y servicios tecnológicos.
- **→ Aplicación o servicio empresarial:** usado por ==personas que no se ocupan principalmente de TI==.
- **→ Servicio de infraestructura de TI:** ==consumido por otros equipos== y prestaciones centrados en TI.

# Conceptos básicos de la infraestructura TI
* **Ciclos de computación:** relacionados con la ==capacidad de procesamiento de datos==.
* **Memoria y almacenamiento:** gestiona ==cómo se almacena y accede a la información==.
* **Redes y comunicaciones:** encargadas de la ==conexión y transmisión de datos entre sistemas==.
* **Características:** *escalabilidad*, *flexibilidad*, *seguridad*, *interoperabilidad* y *rendimiento*.

# Elegir la infraestructura correcta
Es fundamental ==entender las tendencias tecnológicas y cómo se alinean con la visión del producto o servicio==. Factores como la flexibilidad, seguridad, reducción de costos, y recuperación de desastres deben ser considerados al elegir una infraestructura, especialmente en contextos de cloud computing.

Una startup comenzará con un MVP e irá mejorándolo. Es importante **no caer en la "parálisis del análisis"**, hay que *ser crítico* y considerar si será ==escalable, sostenible a largo plazo== y si permitirá formar al equipo de manera eficaz.

# Virtualización
**Emulación de cualquier número de ordenadores virtuales con sus sistemas operativos a través de software `hipervisores`**, permitiendo la creación de *máquinas virtuales*.

## Tipos de virtualización
* **Tipo 1:** se ejecuta ==directamente sobre el hardware sin un sistema operativo huésped==.
    * OS (virtualizado) sobre Hypervisor sobre Hardware.
* **Tipo 2:** se ejecuta ==sobre un sistema operativo huésped==.
    * OS (virtualizado) sobre Hypervisor sobre Host OS sobre Hardware. Ejemplo: instalar en Windows, VMWare y crear un VM de Kali Linux.
* **Paravirtualización (contenedores):** el ==SO abstrae recursos hardware para múltiples entornos virtuales sin tener que virtualizar el hardware para cada huésped==, mejorando *eficiencia* y *rendimiento*.
    * "Containers" (Container, Container, `...`) sobre Shared libraries sobre Docker engine sobre Host OS sobre Hardware.

---

La virtualización surgió como solución cuando las empresas notaron que sus ==servidores estaban infrautilizados==, permitiendo **optimizar recursos, gestionar configuraciones de forma eficiente y reducir el número de servidores necesarios**. 

 *Aunque es fundamental para el cloud computing, se cuestiona si por sí sola basta para ser considerada cloud.*
 
# Modelos de cloud computing
## 1.- Infraestructura como servicio (IaaS)
**Ofrece recursos** como procesamiento, almacenamiento, redes y otros recursos ==sobre los cuales se puede desplegar software==.

## 2.- Plataforma como servicio (PaaS)
==Permite desplegar aplicaciones== en una **infraestructura proporcionada por el proveedor**.

## 3.- Software como servicio (SaaS)
El proveedor **ofrece aplicaciones listas para usar**, ==sin que el consumidor gestione== la infraestructura subyacente.

# Infraestructura como código
Enfoque que permite ==gestionar y automatizar la infraestructura TI mediante scripts y código==, facilitando la replicación, escalabilidad y configuración automática de servidores. Se pueden emplear técnicas ágiles como **Test Driven Development** (*TDD*), **Continuous Integration** (*CI*) y **Continuous Delivery** (*CD*) nos permite ==modificar la infraestructura de manera rápida y eficaz==.
* **Definir todo como código:** gestionar el desarrollo, la entrega y la administración del software ==definiendo y codificando la infraestructura y los procesos necesarios para crear, mantener y mejorar las aplicaciones==. Se aplica el enfoque de desarrollo de software a otros componentes de TI para asegurar que las mejores prácticas se sigan eficientemente y con poco esfuerzo. Es una **práctica fundamental para realizar cambios de forma rápida y fiable**, facilitando reutilización, consistencia y transparencia.
* **Entregar y testear continuamente:** ==automatizando el despliegue y las pruebas de cada componente de su sistema==, e integrar todo el trabajo en curso. La idea es **crear calidad en lugar de testearla**.
* **Desarrollar piezas pequeñas y sencillas:** cuanto más grande es un sistema, más difícil es cambiarlo y más fácil es romperlo. ==Dividir en componentes pequeños hace más fácil entender el sistema==, cambiar cada componente y desplegar y probar cada uno de forma aislada.

---

# Gestión de la configuración
Permite **controlar y hacer seguimiento de los cambios en los sistemas**, crucial para ==mantener la calidad y estabilidad desde el inicio== del desarrollo.

## Tres capacidades
1.   ==Hacer una copia de seguridad== o archivar el estado operativo de un sistema.
2.   ==Comparar dos versiones del estado== del sistema e identificar las diferencias.
3.   ==Restaurar el sistema== a un estado operativo.

## Control de versiones
Uno de los cuatro pilares de las metodologías ágiles, junto con el equipo, desarrollo iterativo y desarrollo incremental. Se emplea para ==gestionar el estado de la infraestructura==. **Registra y gestiona los cambios en los archivos y configuraciones**, asegurando que se pueda identificar *qué ha cambiado y cuándo*.
- **↳ Source control**
- **↳ Gestión de paquetes:** pueden servir como ==proxy para el mundo externo==. Colaboran equipos que trabajan en grandes sistemas.

## Gestión del despliegue
Los recursos en control de versiones ==no entregan valor hasta que se combinan con recursos informáticos==; la gestión del despliegue **administra la combinación de los artefactos con los recursos necesarios** para la *entrega de valor*.