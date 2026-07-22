---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - IDOR
Fecha de actualización: 2026-07-15
Nota previa: "[[09 - Bypass de referencias codificadas]]"
Nota siguiente: "[[11 - Encadenamiento de IDOR]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Hasta ahora el IDOR nos daba **lectura** de ficheros. Pero también vive en **funciones y APIs**, donde permite <mark style="background: #FFB86CA6;">ejecutar acciones como otro usuario</mark>: cambiar su información, resetear su contraseña, comprar con su tarjeta. Es el salto de *Information Disclosure* a *Insecure Function Calls*.

# Identificar la API insegura

En *Edit Profile* del *Employee Manager*, actualizar el perfil lanza un `PUT` a `/profile/api.php/profile/1`. Los verbos REST tienen semántica: `PUT` actualiza, `POST` crea, `DELETE` borra, `GET` lee. Interceptando el `PUT` vemos el JSON:

```json
{
  "uid": 1,
  "uuid": "40f5888b67c748df7efba008e7c2f9d2",
  "role": "employee",
  "full_name": "Amy Lindon",
  "email": "a_lindon@employees.htb",
  "about": "A Release is like a boat..."
}
```

El formulario solo deja editar `full_name`, `email` y `about`, pero la petición incluye parámetros **ocultos**: `uid`, `uuid` y —lo más goloso— `role: employee`. Además, la privilegización viaja también en la cookie `role=employee`.

> [!important]+ El antipatrón: privilegios bajo control del cliente
> <mark style="background: #FF5582A6;">Enviar el `role` en la cookie o en el JSON deja el nivel de acceso en manos del cliente</mark>. Salvo que el back-end tenga un control de acceso sólido, deberíamos poder ponernos un rol arbitrario. Esto es *mass assignment* + control de acceso roto, y en el mundo de las APIs se cataloga como [[03 - Broken Object Property Level Authorization (API3)\|BOPLA/Mass Assignment (API3:2023)]] y [[05 - Broken Function Level Authorization (API5)\|BFLA (API5:2023)]].

# Explotar (los intentos que fallan)

Con los parámetros ocultos bajo nuestro control, probamos la batería de ataques. Aquí el back-end **sí** tiene controles parciales, y es instructivo ver qué bloquea:

| Intento | Petición | Respuesta | Control detectado |
| - | - | - | - |
| Suplantar `uid` | `PUT /profile/1` con `"uid": 2` | `uid mismatch` | Compara `uid` del body con el del endpoint (`/1`) |
| Editar a otro | `PUT /profile/2` con `"uid": 2` | `uuid mismatch` | Compara el `uuid` enviado con el del usuario 2 |
| Crear usuario | `POST /profile/N` | `Creating new employees is for admins only` | Autoriza por la cookie `role` |
| Borrar usuario | `DELETE /profile/N` | `Deleting employees is for admins only` | Ídem |
| Escalar rol | `PUT` con `"role": "admin"` | `Invalid role` | Valida el nombre del rol |

Todos fallan: no podemos cambiar nuestro `uid` (hay comprobación contra el endpoint), ni editar a otro (nos falta su `uuid`), ni crear/borrar (nos falta un rol válido), ni escalar (no conocemos un nombre de rol válido). <mark style="background: #8000E1A6;">¿Es segura la app entonces?</mark>

No. Hemos probado solo los `Insecure Function Calls` (`PUT`/`POST`/`DELETE`), pero **no** el `GET` para *Information Disclosure*. Si el `GET` de la API no tiene control de acceso, podremos **leer** los detalles de otros usuarios —incluido su `uuid` y los nombres de rol válidos— y esa información es exactamente la pieza que nos falta para completar los ataques anteriores.

> [!info]+ La lección de arquitectura
> Un control de acceso **parcial** (validar `uid`/`uuid` en escritura) da falsa sensación de seguridad si se deja un `GET` sin proteger. El atacante encadena: **leer** para obtener los secretos que le faltan → **escribir** con ellos. Un control de acceso debe ser **completo y coherente** en todos los verbos y endpoints.

Ese encadenamiento —combinar el IDOR de lectura con el de función— es lo que convierte "todos mis ataques fallaron" en un **account takeover** completo. Lo vemos en [[11 - Encadenamiento de IDOR|encadenamiento de IDOR]].

## Referencias

- OWASP API Security Top 10 — [API1:2023 BOLA](https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/) y [API3:2023 BOPLA](https://owasp.org/API-Security/editions/2023/en/0xa3-broken-object-property-level-authorization/)
- PortSwigger — [Access control vulnerabilities](https://portswigger.net/web-security/access-control)
- HTB Academy — *Web Attacks* (base, 2021)
