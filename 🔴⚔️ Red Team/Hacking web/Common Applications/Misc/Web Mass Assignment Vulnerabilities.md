---
tags:
  - Web/Red-Team
  - Mass-Assignment
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[Attacking LDAP]]"
Nota siguiente: "[[Attacking Applications Connecting to Services]]"
Area: "[[Common Applications.base|Common Applications]]"
---
---

<mark style="background: #ADCCFFA6;">El *mass assignment* ocurre cuando un framework enlaza automáticamente los parámetros de la petición a los atributos de un objeto</mark>, sin una lista blanca. El atacante envía **campos extra** que no debería controlar y modifica atributos internos del modelo (o de la base de datos).

# El ejemplo canónico (Ruby on Rails)

```ruby
class User < ActiveRecord::Base
  attr_accessible :username, :email    # solo estos deberían asignarse
end
```

Aunque el modelo no expone `admin`, si llega en los parámetros se asigna igual:

```javascript
{ "user" => { "username" => "hacker", "email" => "hacker@example.com", "admin" => true } }
```

<mark style="background: #FF5582A6;">→ usuario creado con privilegios de admin</mark>, saltándose el control de acceso.

# Ejemplo real: saltarse la aprobación del admin

Una app *Asset Manager* deja el registro en estado "pendiente de aprobación". Revisando el código (Python), el registro inserta un flag `confirmed`, y el login solo comprueba ese flag:

```python
try:
    if request.form['confirmed']: cond = True     # ← si el param existe, cuenta aprobada
except: cond = False
cur.execute('insert into users values(?,?,?)', (username, password, cond))
```

<mark style="background: #FFB86CA6;">Basta añadir `confirmed` a la petición de registro</mark> (con Burp) para auto-aprobarse:

```http
POST /register HTTP/1.1
Content-Type: application/x-www-form-urlencoded

username=new&password=test&confirmed=test
```

→ login inmediato como `new:test` sin esperar al administrador.

# Campos a probar y prevención

Clásicos a inyectar: `admin`, `is_admin`, `role`, `confirmed`, `verified`, `balance`, `user_id`. Prevención — asignación explícita / lista blanca del framework:

| Framework | Control |
| - | - |
| Rails | *Strong Parameters*: `params.require(:user).permit(:username, :email)` |
| Laravel | `$fillable` / `$guarded` |
| Spring / Node | DTOs explícitos, validación (`joi`), nunca pasar `req.body` crudo |

> [!info]+ Modernización
> Es un *staple* de bug bounty en **APIs JSON**: en cada endpoint de creación/actualización, probar a añadir `isAdmin`, `role`, `verified`, `user_id`. Misma raíz que la [[06 - Server-Side JavaScript Injection|confusión de tipos en NoSQLi]] y la [[11 - Inyección en ORMs|inyección en ORMs]]: confiar en la entrada del usuario para construir objetos. Fuzzear nombres de campo con wordlists de parámetros comunes.

Siguiente, aplicaciones que se conectan a servicios y cómo abusar esa confianza: [[Attacking Applications Connecting to Services]].
