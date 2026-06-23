---
tags:
  - Full-Stack
  - Express
  - REST
  - Seguridad
Fecha de actualización: 2026-06-22
Nota previa: "[[Mongoose y el patrón ODM en Express]]"
Nota siguiente: "[[React.js, SPA y Virtual DOM]]"
Area: "[[Express.js.base|Express.js]]"
---
---

# Variables de entorno

<mark style="background: #ADCCFFA6;">Las variables de entorno almacenan valores de configuración fuera del código, accesibles vía `process.env`.</mark> Se usan para valores **cambiantes** (como el puerto) o **sensibles** (cadenas de conexión a la BBDD, usuarios, contraseñas).

```javascript
var port = process.env.PORT || 3000;   // usa PORT, o 3000 por defecto
```

Su ventaja: cambiar el valor (puerto, credenciales) no obliga a tocar el código ni a redesplegar. Las plataformas de despliegue **PaaS** (*Platform as a Service*) como Heroku permiten fijarlas sin modificar el código. Se centralizan en un fichero `.env` en la raíz del proyecto:

```text
NODE_ENV=development
PORT=5000
DB_URI='mongodb+srv://<USER>:<PASSWORD>@<CLUSTER>.mongodb.net/<BBDD>'
```

Se cargan con el paquete `dotenv` (`require('dotenv').config()`) y se accede con `process.env.DB_URI`. <mark style="background: #FF5582A6;">El `.env` debe añadirse a `.gitignore` para no subir credenciales al repositorio.</mark>

> [!info]+ Conflicto de puertos en MERN
> El front-end React arranca por defecto en el **puerto 3000**, así que el back-end Express suele moverse al **5000** (vía `PORT`) para no chocar.

# Seguridad de la API REST: tokens

<mark style="background: #ADCCFFA6;">Un token es una cadena alfanumérica que identifica al cliente ante el servidor para consumir recursos protegidos.</mark> El proceso de autenticación basada en token:

1. El cliente se **autentica** por primera vez (login con usuario y contraseña).
2. El servidor **genera un token** asociado a ese usuario y se lo devuelve.
3. En cada petición posterior, el cliente **envía el token**; el servidor lo valida y autoriza la operación.

# JWT (JSON Web Tokens)

<mark style="background: #ADCCFFA6;">JWT es el tipo de token más usado para autenticar servicios REST: un token con estructura definida que el servidor puede validar.</mark> Tiene **3 partes**:

- **Header**: tipo de token y algoritmo de encriptación.
- **Payload**: datos que identifican al usuario (id, nombre de usuario…).
- **Signature**: se genera con las dos partes anteriores y valida que el contenido **no ha sido alterado**.

<mark style="background: #FFB86CA6;">El token no se almacena en el servidor: su payload contiene toda la información para validarlo (es *stateless*).</mark> El cliente lo guarda (en una **Cookie** o en el **LocalStorage** del navegador) y lo envía en la **cabecera** (`Header`) de cada solicitud. Todo token **expira**; al caducar, el usuario debe volver a autenticarse para obtener uno nuevo.

```shell-session
$ npm install --save jsonwebtoken
```

> [!info]+ Alternativa: OAuth 2.0
> Para APIs complejas, con muchos clientes y arquitecturas, otra opción muy extendida es **OAuth 2.0**, un estándar de autorización delegada.

# Anatomía de un JWT

Las tres partes van separadas por puntos y codificadas en **Base64URL**: `header.payload.signature`. <mark style="background: #FFB8EBA6;">El header y el payload NO están cifrados, solo codificados: cualquiera puede leer su contenido.</mark> Lo que protege el token es la **firma**, que el servidor verifica con su clave secreta. Por eso **nunca** se deben poner datos sensibles (contraseñas) en el payload.

# ¿Cookie o LocalStorage? (relevante en pentest)

Dónde guardar el token tiene implicaciones de seguridad:

| Almacén | Riesgo principal |
| - | - |
| **LocalStorage** | Accesible por JavaScript → vulnerable a **XSS** (un script inyectado roba el token) |
| **Cookie** `HttpOnly` | Inaccesible a JS (mitiga XSS), pero expuesta a **CSRF** si no se protege con `SameSite` |

No hay opción perfecta: la elección depende del modelo de amenazas. Una cookie `HttpOnly` + `Secure` + `SameSite` es una defensa habitual; usar LocalStorage exige blindar la app contra XSS.

> [!important]+ Para el examen
> **Variables de entorno**: configuración fuera del código (`process.env`), para datos sensibles o cambiantes; fichero `.env` + `dotenv`, con `.env` en `.gitignore`. **Token**: cadena que autentica al cliente. **JWT** = 3 partes: **Header** (tipo + algoritmo), **Payload** (datos del usuario), **Signature** (integridad). Es **stateless** (no se guarda en el servidor), se envía en la **cabecera** y **expira**.
