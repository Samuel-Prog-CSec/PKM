Una **_promesa_** en JavaScript es un ==objeto que representa un valor que puede estar disponible ahora, en el futuro, o nunca==. Facilitan el manejo de operaciones asincrónicas, proporcionando un enfoque más legible y organizado que los callbacks anidados.


# Estados de una promesa
1. **Pendiente (Pending):** ==inicialmente==, una promesa está en este estado.
2. **Resuelta (Fulfilled):** la operación se ==completó con éxito== y se devuelve un resultado.
3. **Rechazada (Rejected):** la ==operación falló== y devuelve un error o razón del fallo.
```javascript
const myPromise = new Promise((resolve, reject) => {
    const success = true; // Simula un resultado
    setTimeout(() => {
        if (success) resolve('¡Operación exitosa!');
        else reject('Hubo un error.');
    }, 1000);
});

myPromise
    .then(result => console.log(result)) // Manejo del éxito
    .catch(error => console.error(error)) // Manejo del error
    .finally(() => console.log('Operación completada')); // Código que siempre se ejecuta
```


# Ventajas de las promesas sobre los callbacks
1. **Evitan el callback hell:**  las promesas facilitan la encadenación de operaciones asincrónicas, haciendo el **código más legible**.
2. **Manejo de errores centralizado:**  los errores en cualquier punto de una cadena de promesas pueden capturarse en un ==único bloque== `catch`.
3. **Composición fácil:**  las promesas permiten combinar múltiples operaciones asincrónicas con métodos como `Promise.all()` o `Promise.race()`.


# Uso práctico en Node.js
## 1. Consultar una base de datos con promesas
Las promesas son muy útiles al trabajar con bibliotecas modernas que devuelven promesas nativas o al envolver APIs tradicionales basadas en callbacks:
```javascript
const mysql = require('mysql2/promise'); // Librería que usa promesas

async function fetchUsers() {
    const connection = await mysql.createConnection({
        host: 'localhost',
        user: 'root',
        database: 'company'
    });

    try {
        const [rows] = await connection.execute('SELECT * FROM users');
        return rows;
    } finally {
        await connection.end();
    }
}

fetchUsers()
    .then(users => console.log('Usuarios:', users))
    .catch(error => console.error('Error:', error));
```

## 2. Encadenar varias operaciones dependientes
Supongamos que deseas autenticar un usuario, cargar su perfil y registrar un log:
```javascript
function authenticateUser(username, password) {
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            if (username === 'admin' && password === '1234') resolve({ id: 1, name: 'Admin' });
            else reject('Credenciales inválidas');
        }, 1000);
    });
}

function fetchUserProfile(userId) {
    return new Promise((resolve) => {
        setTimeout(() => resolve({ userId, role: 'admin', permissions: ['read', 'write'] }), 1000);
    });
}

function logAccess(user) {
    return new Promise((resolve) => {
        setTimeout(() => resolve(`Acceso registrado para ${user.name}`), 500);
    });
}

authenticateUser('admin', '1234')
    .then(user => {
        console.log('Usuario autenticado:', user);
        return fetchUserProfile(user.id);
    })
    .then(profile => {
        console.log('Perfil del usuario:', profile);
        return logAccess(profile);
    })
    .then(logMessage => console.log(logMessage))
    .catch(error => console.error('Error:', error));
```
>[!Nota]
>- Cada `.then` **espera a que se complete la promesa devuelta por el bloque anterior** antes de ejecutarse.
>- Aunque algunas promesas sean más rápidas (como `logAccess`, que tarda 500 ms), el siguiente `.then` **no se ejecutará hasta que la promesa previa haya finalizado**.


# Manejo avanzado de errores
Uno de los beneficios más importantes de las promesas es su **capacidad para centralizar el manejo de errores**.

## Ejemplo profesional: promesas con manejo robusto de errores
```javascript
function fetchData(apiUrl) {
    return new Promise((resolve, reject) => {
        const success = Math.random() > 0.5; // Simula éxito o fallo
        setTimeout(() => {
            if (success) resolve({ data: 'Datos obtenidos' });
            else reject(new Error('Error al obtener datos'));
        }, 1000);
    });
}

fetchData('https://api.example.com/data')
    .then(response => {
        console.log('Respuesta:', response);
        return response.data;
    })
    .then(data => {
        console.log('Procesando datos:', data);
        // Simula un fallo durante el procesamiento
        if (data === 'Datos obtenidos') throw new Error('Fallo en el procesamiento');
    })
    .catch(error => {
        console.error('Error capturado:', error.message);
    })
    .finally(() => {
        console.log('Limpieza de recursos o tareas finales.');
    });
```
>[!Nota]
>En este ejemplo, cualquier error en la cadena se captura automáticamente en el bloque `catch`.


# Patrones útiles con promesas
## 1. Ejecutar múltiples operaciones simultáneamente: `Promise.all()`
```javascript
const fetchUser = () => Promise.resolve({ id: 1, name: 'John Doe' });
const fetchPosts = () => Promise.resolve(['Post 1', 'Post 2']);
const fetchComments = () => Promise.resolve(['Comment 1', 'Comment 2']);

Promise.all([fetchUser(), fetchPosts(), fetchComments()])
    .then(([user, posts, comments]) => {
        console.log('Usuario:', user);
        console.log('Publicaciones:', posts);
        console.log('Comentarios:', comments);
    })
    .catch(error => console.error('Error:', error));
```

## 2. Ejecutar solo la más rápida: `Promise.race()`
```javascript
const fetchSlow = new Promise(resolve => setTimeout(() => resolve('Lento'), 3000));
const fetchFast = new Promise(resolve => setTimeout(() => resolve('Rápido'), 1000));

Promise.race([fetchSlow, fetchFast])
    .then(result => console.log('Resultado más rápido:', result))
    .catch(error => console.error('Error:', error));
```


# Limitaciones de las promesas
1. **Verbosas en tareas complejas:** aunque más legibles que los callbacks, las promesas ==pueden volverse difíciles de manejar si hay muchas dependencias==.
2. **Encadenamiento excesivo:** si no se diseña correctamente, el ==encadenamiento puede parecerse al ***callback hell***==.
> [!Solución] 
> Usar `async/await` para un flujo más intuitivo.


# Conclusión
Las promesas son una herramienta esencial para manejar la asincronía en Node.js, especialmente en aplicaciones profesionales donde el flujo de datos y el manejo de errores deben ser robustos y eficientes. Entender cómo y cuándo usarlas permite escribir código más legible, modular y confiable.