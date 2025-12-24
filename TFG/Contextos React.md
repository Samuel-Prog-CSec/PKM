¡Tu profesor tiene toda la razón! El Context API de React es la herramienta **perfecta** para esos dos escenarios. Es una de las características más potentes (y a veces confusas) de React.

Vamos a desglosarlo en un lenguaje sencillo y aplicado a tu proyecto.

## 1. 🎒 ¿Qué es el Context API? (El Concepto)

Imagina que tu aplicación React es un edificio de apartamentos.

- **`App.js`** es la entrada principal (Planta 0).
    
- Tienes un componente **`<GamePage>`** (Planta 3).
    
- Dentro, un componente **`<ScoreDisplay>`** (Apartamento 3B).
    
- Dentro, un **`<Button>`** (en el baño del 3B).
    

Ahora, imagina que tienes un dato que todos necesitan saber, como "la luz del edificio está encendida o apagada".

**El método tradicional (Props):** Para que el `<Button>` en el baño del 3B sepa si la luz está encendida, tendrías que pasar la información _manualmente_ por cada nivel: `App.js` se lo pasa a `<GamePage>`. `<GamePage>` se lo pasa a `<ScoreDisplay>`. `<ScoreDisplay>` se lo pasa a `<Button>`.

Esto se llama **"prop drilling" (perforación de props)** y es un infierno de mantener.

**La solución (Context API):** El Context API es como un **sistema de megafonía global** para el edificio.

1. **Creas un "Contexto":** (`LightContext`).
    
2. **Envuelves tu app en un "Proveedor":** (`<LightContext.Provider>`). Este es el altavoz principal en la entrada (`App.js`) que emite el mensaje: "¡La luz está ENCENDIDA!".
    
3. **Consumes el Contexto:** Ahora, cualquier componente, sin importar lo profundo que esté (como el `<Button>` en el baño del 3B), puede "sintonizar" ese altavoz con un solo gancho (`useContext(LightContext)`) y obtener el mensaje ("ENCENDIDA") directamente, sin que sus padres (Planta 3, Apartamento 3B) tengan que pasárselo.
    

---

## 2. 👨‍🏫 / 🧑‍🎓 Aplicación 1: Gestión de Usuario (Alumno vs. Profesor)

Este es el caso de uso **perfecto** para Context.

- **El Problema:** Casi todos los componentes de tu app necesitan saber dos cosas: "¿Hay un usuario logueado?" y "¿Es un profesor o un alumno?".
    
- **La Solución:** Creas un `AuthContext`.
    
- **Cómo funciona:**
    
    1. Cuando la app se carga, el `<AuthContext.Provider>` envuelve todo. Su valor inicial es `{ user: null, role: null }`.
        
    2. El usuario inicia sesión. Llamas a una función `login(userData)` que vive en tu Provider.
        
    3. El Provider actualiza su estado a `{ user: { name: 'Profesor Alba' }, role: 'professor' }`.
        
    4. **Automágicamente**, todos los componentes que "sintonizan" este contexto se vuelven a renderizar.
        
- **El Resultado:**
    
    - **`<Navbar>`:** Llama a `useContext(AuthContext)` y ve `{ role: 'professor' }`. Muestra el botón "Crear Sesión".
        
    - **`<Sidebar>`:** Llama a `useContext(AuthContext)` y ve `{ role: 'professor' }`. Muestra el enlace "/admin/dashboard".
        
    - **`<GameCard>`:** Llama a `useContext(AuthContext)` y ve `{ role: 'student' }`. Muestra el botón "¡Jugar!".
        

No tienes que pasar `props` de "role" por toda tu aplicación.

---

## 3. 🎨 Aplicación 2: Temas Dinámicos (Contexto de Juego)

Aquí es donde se pone elegante. Tu profesor te dio una pista genial. Confundes un poco los términos, pero la idea es correcta: usar el **React Context** para manejar el tema visual basado en tu **Game Context** (el modelo de Mongoose).

- **El Problema:** Quieres que la partida de "Matemáticas" tenga un fondo azul y botones serios, pero que la de "Países y Banderas" tenga un fondo verde y botones divertidos.
    
- **La Solución:** Creas un `ThemeContext` o `GameThemeContext`.
    
- **Cómo funciona:**
    
    1. El `<GameThemeContext.Provider>` envuelve tu página de juego (`<GamePage>`).
        
    2. Cuando el jugador selecciona la sesión de "Matemáticas", tú (programáticamente) le pasas un objeto de tema al Provider:
        
        JSON
        
        ```
        {
          "primaryColor": "#3b82f6", // Azul
          "backgroundColor": "#efefef",
          "font": "Arial"
        }
        ```
        
    3. Cuando selecciona "Países":
        
        JSON
        
        ```
        {
          "primaryColor": "#22c55e", // Verde
          "backgroundColor": "#f0fff4",
          "font": "Comic Sans" // (¡O algo divertido!)
        }
        ```
        
- **El Resultado:**
    
    - Tu componente `<GamePage>` llama a `useContext(GameThemeContext)` y obtiene el `backgroundColor` para su `div` principal.
        
    - Tu componente `<BotonValidar>` llama a `useContext(GameThemeContext)` y obtiene el `primaryColor` para su estilo.
        

Los componentes no saben _por qué_ son azules o verdes. Solo le preguntan al "Contexto de Tema" cuál es el color primario actual. Esto te permite tener **una sola lógica de juego** (`GameEngine`) pero **infinitas apariencias visuales**.

---

## ⚠️ Una Advertencia Importante: Cuándo NO usarlo

Esto es clave: **Context NO es bueno para datos que cambian muy rápido.**

El `GameEngine` del backend te enviará eventos por WebSocket (como `new_round` o `validation_result`). Tu primer instinto podría ser poner el `score` o el `timer` en un Contexto.

**¡No lo hagas (generalmente)!**

- **El Problema:** Cuando un valor de Context cambia, _todos_ los componentes que lo consumen se vuelven a renderizar.
    
- **Por qué es malo:** Si pones el `timer` (que cambia cada segundo) en un Context, y 10 componentes lo usan, esos 10 componentes se renderizarán _cada segundo_, lo que puede hacer que la app se sienta lenta.
    
- **La Regla:**
    
    - **Usa Context para:** Datos globales que cambian _con poca frecuencia_: el usuario logueado, el tema (theme), el idioma.
        
    - **Usa State (`useState`) para:** Datos locales que cambian _con frecuencia_: el score de la partida actual, el tiempo restante, lo que el usuario escribe en un formulario.
        

**En tu caso:** Los datos de la partida (score, ronda, desafío) deben vivir en el estado (`useState`) del componente `<GamePage>` y pasarse como _props_ a sus hijos (`<ScoreDisplay>`, `<ChallengeView>`). Como solo están a 1 o 2 niveles de profundidad, el "prop drilling" no es un problema.

---

### 1. 👨‍🏫 / 🧑‍🎓 Guía 1: `AuthContext` (Profesor vs. Alumno)

Este contexto "envolverá" a toda tu aplicación para que cada componente sepa quién está conectado y cuál es su rol.

#### Paso 1: Crear el Contexto (`src/contexts/AuthContext.js`)

Primero, creamos el contexto y un "hook" personalizado (`useAuth`) para que sea más fácil de usar.

JavaScript

```
import React, { createContext, useState, useContext } from 'react';

// 1. Crear el Contexto
// El valor por defecto (null) es para un usuario no logueado
const AuthContext = createContext(null);

// 2. Crear el Proveedor (El "Altavoz")
// Este es el componente que envolverá tu app
export function AuthProvider({ children }) {
  const [user, setUser] = useState(null); // Aquí vivirán los datos del usuario

  // Función para simular un login
  // En tu app real, aquí llamarías a tu API
  const login = (email, password) => {
    // Lógica de API...
    // Si es exitoso:
    const userData = {
      email: "profesor@tfg.com",
      name: "Profesor Alba",
      role: "professor" // ¡El dato clave!
    };
    setUser(userData);
  };

  const logout = () => {
    setUser(null);
  };

  // El "valor" es lo que el altavoz emite
  const value = {
    user,
    role: user?.role, // Acceso directo al rol
    isLoggedIn: !!user,
    login,
    logout
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

// 3. Crear el Hook (El "Receptor")
// Así los componentes sintonizan el altavoz
export function useAuth() {
  return useContext(AuthContext);
}
```

#### Paso 2: Proveer el Contexto (`src/App.js`)

Ahora, envolvemos toda la aplicación con el `AuthProvider` para que todos los componentes hijos puedan "sintonizarlo".

JavaScript

```
import React from 'react';
import { AuthProvider } from './contexts/AuthContext';
import Navbar from './components/Navbar';
import YourRoutes from './YourRoutes';

function App() {
  return (
    <AuthProvider>
      {/* Ahora Navbar y todos los componentes en YourRoutes
          pueden usar el hook useAuth() */}
      <Navbar />
      <YourRoutes />
    </AuthProvider>
  );
}

export default App;
```

#### Paso 3: Consumir el Contexto (En cualquier componente)

Aquí está la magia. En lugar de _prop drilling_, cualquier componente puede saber quién es el usuario.

**Ejemplo: `src/components/Navbar.js`**

JavaScript

```
import React from 'react';
import { useAuth } from '../contexts/AuthContext'; // ¡Importamos nuestro hook!

function Navbar() {
  // 3. Consumir
  const { isLoggedIn, user, role, logout } = useAuth();

  return (
    <nav>
      <h1>🎮 RFID Games</h1>
      <div>
        {isLoggedIn ? (
          <>
            <span>Hola, {user.name} ({role})</span>
            <button onClick={logout}>Cerrar Sesión</button>

            {/* Renderizado condicional basado en el rol */}
            {role === 'professor' && (
              <a href="/admin/create-session">Crear Sesión</a>
            )}
            
            {role === 'student' && (
              <a href="/play">Jugar</a>
            )}
          </>
        ) : (
          <a href="/login">Iniciar Sesión</a>
        )}
      </div>
    </nav>
  );
}
```

---

### 2. 🎨 Guía 2: `ThemeContext` (Temas Dinámicos)

Este contexto gestionará el tema visual (colores, fuentes) de una página de juego, basándose en el contexto de la partida seleccionada.

#### Paso 1: Crear el Contexto (`src/contexts/ThemeContext.js`)

Similar al anterior, pero este guardará un objeto de tema.

JavaScript

```
import React, { createContext, useState, useContext } from 'react';

// Temas predefinidos (podrían venir de tu GameContext de la BD)
const THEMES = {
  default: {
    backgroundColor: '#FFFFFF',
    primaryColor: '#6366F1' // Indigo
  },
  math: {
    backgroundColor: '#EFF6FF', // Azul claro
    primaryColor: '#3B82F6' // Azul
  },
  geography: {
    backgroundColor: '#F0FDF4', // Verde claro
    primaryColor: '#22C55E' // Verde
  }
};

// 1. Crear el Contexto
const ThemeContext = createContext({
  theme: THEMES.default,
  setTheme: () => {} // Función vacía por defecto
});

// 2. Crear el Proveedor
export function ThemeProvider({ children }) {
  const [theme, setTheme] = useState(THEMES.default);

  // Función para cambiar el tema por su nombre
  const changeTheme = (themeName) => {
    setTheme(THEMES[themeName] || THEMES.default);
  };

  const value = {
    theme,
    changeTheme
  };

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
}

// 3. Crear el Hook
export function useTheme() {
  return useContext(ThemeContext);
}
```

#### Paso 2: Proveer el Contexto (`src/pages/GamePage.js`)

No envolvemos _toda_ la app, solo la sección que debe cambiar de tema, como la página del juego.

JavaScript

```
import React, { useEffect } from 'react';
import { ThemeProvider, useTheme } from '../contexts/ThemeContext';
import ScoreDisplay from '../components/ScoreDisplay';

// Este es el componente que usa el tema
function GameLayout() {
  const { theme, changeTheme } = useTheme();

  // Simulamos que el juego de "Matemáticas" se carga
  useEffect(() => {
    // Esta info vendría del GameSession
    const gameContextName = "math"; 
    changeTheme(gameContextName);
  }, [changeTheme]);

  // Aplicamos el tema
  return (
    <div style={{ backgroundColor: theme.backgroundColor, minHeight: '100vh' }}>
      <h2 style={{ color: theme.primaryColor }}>¡A Jugar!</h2>
      <ScoreDisplay />
      {/* ...El resto de tu juego... */}
    </div>
  );
}

// Este es el componente "padre" que exportas
export default function GamePage() {
  // Envolvemos el layout con el proveedor
  return (
    <ThemeProvider>
      <GameLayout />
    </T-h>e>m;eP>r
o;v>i
d;e>r
>
  )
}
```

#### Paso 3: Consumir el Contexto (Componente hijo)

Ahora, un componente nieto (como el marcador) puede usar los colores del tema sin _prop drilling_.

**Ejemplo: `src/components/ScoreDisplay.js`**

JavaScript

```
import React from 'react';
import { useTheme } from '../contexts/ThemeContext';

function ScoreDisplay() {
  // 3. Consumir
  const { theme } = useTheme();

  // El estilo de este botón es controlado por el tema
  // sin que este componente sepa si es "math" o "geography"
  return (
    <div>
      <h3>Puntuación: 100</h3>
      <button style={{ backgroundColor: theme.primaryColor, color: 'white' }}>
        Botón con Tema
      </button>
    </div>
  );
}
```

Estos dos patrones (`AuthContext` y `ThemeContext`) te dan un poder increíble para gestionar el estado global y reducir la complejidad de tu aplicación.

Este vídeo explica cómo implementar un contexto de autenticación en React, similar a nuestro primer ejemplo. [Building an Authentication Context in React](https://www.youtube.com/watch?v=2-6K-TMA-nw)