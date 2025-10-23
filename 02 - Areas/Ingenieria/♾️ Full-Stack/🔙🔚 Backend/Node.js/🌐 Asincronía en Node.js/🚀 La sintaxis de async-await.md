`async` y `await` son características de ECMAScript 2017 (ES8) que **simplifican la gestión de código asincrónico**. Aunque las promesas siguen siendo la base de la asincronía, `async/await` permite escribir código asincrónico de una manera que ==se parece más a código síncrono, mejorando la legibilidad y la facilidad de mantenimiento==.
- **`async`**: se coloca antes de una función, convirtiéndola en una **función que siempre devuelve una promesa**.
- **`await`**: se usa dentro de una función `async` para **esperar a que una promesa se resuelva o se rechace** ==antes de continuar con la ejecución del código==.


# Sintaxis básica de async/await
```javascript
async function fetchData() {
    const data = await fetch('https://api.example.com/data');
    const json = await data.json();
    console.log(json);
}

fetchData();
```
>[!Nota]
>- **`async`**: la función `fetchData()` es una función asincrónica, lo que significa que **siempre devuelve una promesa**.
>- **`await`**: **pausa la ejecución de la función** hasta que la promesa `fetch()` se resuelva.


# Uso práctico en Node.js
## 1. Consultar una base de datos de manera asincrónica
En Node.js, muchos módulos, como los clientes de bases de datos, permiten trabajar con promesas, lo que hace que `async/await` sea muy útil.
### **Ejemplo profesional: obtener usuarios desde una base de datos (con MySQL)**
```javascript
const mysql = require('mysql2/promise');

async function getUsers() {
    const connection = await mysql.createConnection({ host: 'localhost', user: 'root', database: 'company' });
    
    try {
        const [rows] = await connection.execute('SELECT * FROM users');
        return rows;
    } catch (error) {
        console.error('Error al consultar usuarios:', error);
    } finally {
        await connection.end();
    }
}

getUsers().then(users => console.log(users));
```
>[!Explicación]
>- El flujo de trabajo es secuencial, donde `await` se usa **para esperar cada operación asincrónica antes de pasar a la siguiente**. Esto mejora la legibilidad y facilita el manejo de errores.
>- Si alguna operación falla, el control pasa al bloque `catch`, **donde se captura el error**.


# Casos de uso comunes de async/await
## 1. Llamadas a APIs externas
Cuando trabajas con APIs de terceros o servicios externos, es común hacer solicitudes HTTP. Usando `async/await`, puedes escribir código mucho más limpio y entendible.
### Ejemplo: solicitar datos a una API externa
```javascript
async function getWeather(city) {
    try {
        const response = await fetch(`https://api.weather.com/${city}`);
        const weatherData = await response.json();
        console.log('Clima:', weatherData);
    } catch (error) {
        console.error('Error al obtener el clima:', error);
    }
}

getWeather('Madrid');
```
>[!Explicación]
>- Se usa `await` para esperar la respuesta de la API, y luego se procesa la respuesta como JSON.
>- Todo el flujo es secuencial y fácil de seguir.


## 2. Operaciones con archivos en el sistema de archivos (FS)
Node.js permite trabajar con archivos de forma asincrónica, y usando `async/await` se pueden manejar de manera más sencilla.
### Ejemplo: leer un archivo y procesarlo
```javascript
const fs = require('fs').promises; // Módulo fs con promesas

async function readFileAndProcess(path) {
    try {
        const data = await fs.readFile(path, 'utf8');
        console.log('Contenido del archivo:', data);
    } catch (error) {
        console.error('Error leyendo el archivo:', error);
    }
}

readFileAndProcess('file.txt');
```
>[!Explicación]
>- El método `fs.readFile` **devuelve una promesa**, que se espera con `await`.
>- El código es limpio y fácil de leer sin necesidad de anidar callbacks.


# Manejo de errores en async/await
Uno de los mayores beneficios de `async/await` es el manejo de errores. En lugar de usar múltiples `.catch()` o manejar errores dentro de cada callback, **todo el código asincrónico se puede envolver en un solo bloque** `try/catch`.
## Ejemplo: manejo de errores de múltiples operaciones asincrónicas
```javascript
async function processTasks() {
    try {
        const task1 = await performTask1();
        const task2 = await performTask2(task1);
        const task3 = await performTask3(task2);
        console.log('Tareas completadas:', task1, task2, task3);
    } catch (error) {
        console.error('Error en el proceso de tareas:', error);
    }
}

async function performTask1() {
    // Simula una operación asincrónica
    return new Promise((resolve, reject) => {
        setTimeout(() => resolve('Tarea 1'), 1000);
    });
}

async function performTask2(data) {
    // Simula otra operación asincrónica
    if (data === 'Tarea 1') {
        return new Promise((resolve) => {
            setTimeout(() => resolve('Tarea 2'), 1000);
        });
    }
    throw new Error('Error en Tarea 2');
}

async function performTask3(data) {
    // Simula una operación asincrónica
    return new Promise((resolve) => {
        setTimeout(() => resolve('Tarea 3'), 1000);
    });
}

processTasks();
```
>[!Explicación]
>- En este ejemplo, el flujo de ejecución es secuencial y fácil de leer.
>- Si alguna de las tareas falla, el control salta directamente al bloque `catch` **para manejar el error**.


# Ventajas de async/await sobre promesas
1. **Legibilidad**: el código asincrónico escrito con `async/await` ==es más parecido a código síncrono==, lo que **mejora la comprensión**.
2. **Manejo de errores centralizado**: puedes **capturar todos los errores en un solo bloque** `try/catch`.
3. **Evita la "promesa anidada"**: el uso de `async/await` ==evita tener que anidar== múltiples `.then()` y `.catch()`, lo que puede hacer que el código se vea más limpio y estructurado.


# Limitaciones de async/await
1. **No es completamente síncrono**: aunque `async/await` hace que el código sea más legible, **las operaciones siguen siendo asincrónicas**, por lo que ==el bloqueo del hilo principal no ocurre==.
2. **Requiere compatibilidad con promesas**: `async/await` ==solo funciona con funciones que devuelven promesas==.


# Conclusión
`async/await` transforma la forma en que gestionamos la asincronía en JavaScript. Es una herramienta poderosa que hace que el ==código asincrónico sea mucho más legible y fácil de mantener==. Aunque aún se basa en promesas, la **sintaxis limpia y el manejo de errores centralizado lo convierten en una elección preferida para muchos desarrolladore**s. Es una habilidad esencial para cualquier **full-stack developer**, especialmente cuando se trabaja con aplicaciones que dependen de operaciones asincrónicas, como consultas a bases de datos, llamadas a APIs y manejo de archivos.