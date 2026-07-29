---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - HTTP/Session-Puzzling
  - Tipo/Deteccion
Descripción: "Cierre del bloque y del módulo. El session puzzling es el único vector de aquí que ningún escáner detecta: es lógica de estado pura"
Fecha de actualización: 2026-07-14
Nota previa: "[[16 - Variables de sesión compartidas - account takeover]]"
Nota siguiente: ""
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

Cierre del bloque y del módulo. El session puzzling es el único vector de aquí que <mark style="background: #FF5582A6;">**ningún escáner detecta**</mark>: es lógica de estado pura. Por eso la "detección" es una **metodología manual**, y las herramientas solo ayudan a manipular peticiones.

# Detección: la metodología manual

No hay atajo automático. El proceso, con o sin código fuente:

1. **Inventaría los flujos** que usan sesión: login, registro, reset, cambio de email, 2FA, checkout, KYC.
2. **Mapea cada variable de sesión**: <mark style="background: #ADCCFFA6;">dónde se **escribe** (y con qué protección) y dónde se **lee** para decidir algo</mark> (acceso, fase, identidad).
3. **Busca cruces peligrosos**:
   - Una variable **escrita** con poca validación que se **lee** para autorizar → [[14 - Variables de sesión compartidas - bypass de autenticación|reuse]].
   - Una variable de auth poblada **antes** de verificar → [[15 - Población prematura de sesión|premature population]] (prueba **dropear** el redirect de limpieza).
   - Un **contador de fase** compartido entre dos flujos → [[16 - Variables de sesión compartidas - account takeover|interleaving]] (intercala sus pasos en una misma sesión).
   - Un **valor por defecto** que coincide con una cuenta real (`user_id=0`) → [[12 - Introducción a Session Puzzling|insecure default]].
4. **Cruza flujos**: empieza uno, abandónalo a medias, entra en otro. Observa qué estado queda.

<mark style="background: #FF5582A6;">Es mentalidad de lógica de negocio: razonar sobre la máquina de estados, no lanzar payloads.</mark>

# Herramientas (de manipulación, no de detección)

| Herramienta | Uso |
| - | - |
| **Burp Repeater / Intercept** | Reordenar pasos, **dropear** redirects, reenviar peticiones fuera de secuencia |
| **Burp session handling rules / macros** | Automatizar secuencias multi-paso con cookies distintas |
| **Caido** | Alternativa moderna a Burp para el mismo flujo manual |
| **AuthMatrix / Autorize** | Matrices de acceso: probar qué endpoints acepta cada estado de sesión |
| Dos navegadores / perfiles | Ejecutar dos flujos **concurrentes** con sesiones separadas |

No existe un "session-puzzling-scanner": <mark style="background: #8000E1A6;">el valor lo pone el pentester manipulando el estado</mark> con estas herramientas.

# Prevención (a nivel de código)

**Valores por defecto** — nunca reinicializar a un valor; **destruir** la sesión:

```php
// logout SEGURO
session_start();
session_unset();
session_destroy();     // en vez de $_SESSION['user_id'] = 0;
```

**Reutilización** — una variable, un solo propósito, y un flag de auth **dedicado**:

```php
// login SEGURO: variable separada + flag explícito
if (login($_POST['Username'], $_POST['Password'])) {
    $_SESSION['auth_username'] = $_POST['Username'];
    $_SESSION['is_logged_in']  = true;     // ← el control de acceso comprueba ESTE flag
}
```

**Población prematura** — poblar la sesión **solo tras completar** el proceso:

```php
if (isset($_POST['Submit'])) {
    $_SESSION['login_fail_user'] = $_POST['Username'];   // dato inocuo para el mensaje
    if (login($_POST['Username'], $_POST['Password'])) {
        $_SESSION['auth_username'] = $_POST['Username'];  // ← auth SOLO si login() == true
        $_SESSION['is_logged_in']  = true;
    }
}
```

> [!success] Las tres reglas de oro
> 1. **Unset completo** de las variables al reiniciar, nunca un valor por defecto.
> 2. **Una variable de sesión = un único propósito** (namespacing por flujo: `reset_phase`, `reg_phase`, no una `Phase` global).
> 3. **Poblar solo cuando todos los prerrequisitos** se cumplen y el proceso está **completo**.

> [!info] Dónde encaja en el PKM
> El session puzzling es primo de los [[10 - Ataques a tokens de sesión|ataques a tokens de sesión]] y de los [[00 - Introducción a la autenticación|bypass de autenticación]] del módulo de autenticación: allí se ataca el token o las credenciales; aquí, la **lógica de estado** que los rodea. Con esto cierra el módulo de HTTP Misconfigurations (cache poisoning, host header, session puzzling).

## Referencias

- [OWASP — Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [PortSwigger — Business logic vulnerabilities](https://portswigger.net/web-security/logic-flaws)
