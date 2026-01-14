# 1. React Contexts: ¿Qué son y para qué sirven?
Imagina que tu aplicación es un **árbol genealógico**.
- Actualmente, para pasar datos (ej: el usuario o la sesión) desde el componente "Abuelo" (App) al "Nieto" (Tarjeta), tienes que pasarlo mano a mano por el "Padre". Esto se llama **Prop Drilling** y es sucio y difícil de mantener.
 
**React Context** es como un **sistema de teletransporte** o una "nube" global.
- **¿Qué es?**: Una forma de crear variables globales para una rama de tu aplicación.
	- **¿Cómo se usa?**: Creas un `Provider` (proveedor) que envuelve tu App. Cualquier componente dentro, sin importar lo profundo que esté, puede usar un `hook` (ej: `useSession()`) para leer esos datos directamente.
- **¿Dónde nos ayudaría aquí?**:
    - **Gestión de Sesión**: En lugar de pasar `sessionId` o los datos de la sesión manualmente por cada componente, podríamos tener un `SessionContext`. Así, el componente `NavBar`, `Board`, `Game`, etc., podrían saber instantáneamente en qué sesión están y sus datos sin pedírselos al padre.
    - **Estado Global del Juego**: Para saber si el juego está pausado, los puntos, o el tiempo restante desde cualquier lugar (ej: un modal de pausa).

---

# 2. Fuentes de recursos frontend pre-fabricados
[[Herramientas para estilos]]