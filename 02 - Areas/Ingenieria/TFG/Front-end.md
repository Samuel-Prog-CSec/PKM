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

# 2. Propuesta Sprint 2 (Backend Integration & Hardware Core)
Ahora que tenemos un Frontend sólido ("Mockeado"), el objetivo del Sprint 2 debería ser **hacerlo real**.
**Duración**: 2 Semanas **Objetivo Principal**: Conectar Front y Back, y establecer la comunicación base con el Hardware (MQTT).

## Semana 1: Conexión y Persistencia (Adiós MockApi)
- **Backend (Node/Express)**:
    - [ ]  Implementar **Base de Datos Real** (PostgreSQL/Supabase o MongoDB). Diseñar el esquema definitivo de `Sessions`, `Users`, `Contexts`.
    - [ ]  Crear **API REST real**: Endpoints que sustituyan a nuestro `mockApi.js` (`GET /sessions`, `POST /sessions`, `PUT /board-setup`).
- **Frontend**:
    - [ ]  Crear capa de servicios limpia (`api.js`) usando `fetch` o `axios` para llamar al Backend real.
    - [ ]  Reemplazar todas las llamadas de `mockApi` por llamadas reales.

## Semana 2: Hardware Real y Comunicación (MQTT)
- **Backend**:
    - [ ]  Configurar **Broker MQTT** (Mosquitto) o integrarlo en Node.js.
    - [ ]  Crear servicio de escucha MQTT: Recibir mensajes cuando un lector lea una tarjeta física.
    - [ ]  Lógica de validación en tiempo real: ¿La tarjeta leída corresponde al hueco correcto?
- **Frontend**:
    - [ ]  Implementar **WebSockets** (Socket.io) para recibir eventos del backend sin recargar (ej: "El alumno XXX ha puesto la tarjeta ZZZ").
    - [ ]  Pantalla de Juego Real: Que las cartas aparezcan solas cuando se escanean físicamente.