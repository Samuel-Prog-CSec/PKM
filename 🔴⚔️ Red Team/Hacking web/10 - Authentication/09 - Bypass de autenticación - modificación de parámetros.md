---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
Fecha de actualización: 2026-06-23
Nota previa: "[[08 - Bypass de autenticación - acceso directo]]"
Nota siguiente: "[[10 - Ataques a tokens de sesión]]"
Area: "[[Authentication.base|Authentication]]"
---
---

La autenticación está rota cuando <mark style="background: #ADCCFFA6;">depende de la presencia o el valor de un parámetro HTTP que el cliente controla</mark>. Si el estado de "quién soy" o "qué privilegios tengo" viaja en un parámetro en vez de atarse a la sesión server-side, se manipula.

# El caso: un parámetro que decide el acceso

Tras loguearse como `htb-stdnt`, la app redirige a `/admin.php?user_id=183` y muestra datos limitados. Dos pruebas revelan el fallo:

1. **Quitar el parámetro** → te redirige al login, *aunque la cookie `PHPSESSID` siga siendo válida*. <mark style="background: #FF5582A6;">Eso delata que `user_id`, no la sesión, es lo que gobierna el acceso.</mark>
2. **Acceder directo** a `/admin.php?user_id=183` → `200 OK` con los datos.

```http
GET /admin.php?user_id=183 HTTP/1.1
Cookie: PHPSESSID=<válida>
```

Si `user_id` identifica al usuario y puedes <mark style="background: #FFB86CA6;">adivinar o forzar el ID del administrador</mark>, accedes con sus privilegios. El ID admin se obtiene con [[02 - Fuerza bruta de contraseñas en el login|fuerza bruta]] del parámetro. Es la frontera con [[06 - Introducción a IDOR|IDOR]]: el `user_id` controlable es un *Insecure Direct Object Reference* aplicado a la autenticación.

# La clase completa: confiar en el cliente

`user_id` es un caso; el patrón es "el servidor cree lo que dice el cliente". Parámetros que suelen gobernar acceso indebidamente:

| Parámetro | Manipulación |
| - | - |
| `role=user` / `isAdmin=false` | → `role=admin` / `isAdmin=true` |
| `admin=0` / `authenticated=false` | → `admin=1` / `authenticated=true` |
| `user_id=183` | → ID de otra cuenta (IDOR) |
| Respuesta `{"success":false}` | interceptar y → `true` (control en cliente) |

<mark style="background: #8000E1A6;">Estos parámetros aparecen en cookies, cuerpo POST, query string y JSON.</mark> Una variante en registro/edición de perfil es el **mass assignment**: interceptar el POST y **añadir** campos que el backend mapea ciegamente al modelo — `role=admin`, `is_admin=true`, `email_verified=true`, `account_balance=...`. Es endémico en frameworks que bindean el request entero al objeto (Rails `update_attributes`, Spring `@ModelAttribute`, Mongoose sin proyección). La clave es **añadir** el campo, no solo modificar uno existente.

> [!warning]+ Probar añadiendo, no solo modificando
> No basta con cambiar parámetros existentes: a veces hay que **inyectar** uno que el backend lee si está presente. Añadir `&admin=true`, `&debug=1` o `&role=admin` a una petición que no los traía es una prueba estándar. Herramientas como **Param Miner** (Burp) o **Arjun** descubren parámetros ocultos que disparan estos comportamientos.

# Bypass por vías más avanzadas

La modificación de parámetros es el caso simple. La misma idea —saltarse la autenticación manipulando entrada— escala con técnicas que tienen su propio sub-tema:

- **Type juggling** (`==` laxo en PHP, `0e123` == `0`) → bypass en comparaciones de contraseña/hash. Whitebox.
- **Inyección** que altera la consulta de login: `' OR 1=1 -- ` en [[02 - Subvertir la lógica de consulta|SQLi]].
- **Manipulación de tokens firmados** mal validados → [[01 - Introducción a JWT|JWT]] y la sesión, en [[10 - Ataques a tokens de sesión|la siguiente nota]].

> [!info]+ Fuentes
> - [OWASP WSTG — Bypassing Authentication Schema](https://owasp.org/www-project-web-security-testing-guide/stable/4-Web_Application_Security_Testing/04-Authentication_Testing/04-Testing_for_Bypassing_Authentication_Schema)
> - [PortSwigger — Access control & IDOR](https://portswigger.net/web-security/access-control/idor) · [Arjun (param discovery)](https://github.com/s0md3v/Arjun)
