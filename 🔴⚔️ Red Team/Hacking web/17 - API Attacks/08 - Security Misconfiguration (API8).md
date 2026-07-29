---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - API
Descripción: "Las APIs sufren las mismas malas configuraciones que las apps web clásicas"
Fecha de actualización: 2026-07-15
Nota previa: "[[07 - Server-Side Request Forgery (API7)]]"
Nota siguiente: "[[09 - Improper Inventory Management (API9)]]"
Area: "[[API Attacks.base|API Attacks]]"
---
---

Las APIs sufren las **mismas** malas configuraciones que las apps web clásicas. `Security Misconfiguration` es la categoría paraguas: <mark style="background: #ADCCFFA6;">desde inyecciones por falta de validación hasta cabeceras de seguridad ausentes</mark>. En el lab se materializa como una `SQL Injection` (`CWE-89`).

# SQL Injection en la API

Como supplier con rol `Products_GetProductsTotalCountByNameSubstring`, el endpoint `/api/v1/products/{Name}/count` devuelve cuántos productos contienen un substring en su nombre. Con `laptop` → 18. Probamos con una comilla:

```http
GET /api/v1/products/laptop'/count
```

La respuesta es un **error** → posible [[00 - Introducción a SQL Injection|SQLi]]. Confirmamos con un `OR 1=1` que ignora el filtro de nombre y cuenta toda la tabla:

```text
GET /api/v1/products/laptop' OR 1=1 -- /count   (los espacios van URL-encodeados al enviar)
→ 720 productos (todos los de la tabla Products)
```

<mark style="background: #FF5582A6;">El substring se concatena sin sanear en la consulta SQL</mark>. A partir de aquí aplica todo el módulo de [[01 - Detección de SQL Injection|SQL Injection]]: [[05 - Inyección UNION|UNION]] para extraer datos, [[01 - Introducción a Blind SQL Injection|blind]] si no hay salida, etc. Que el punto de inyección esté en el **path** (`{Name}`) y no en un parámetro clásico no cambia nada de fondo.

> [!warning]+ Los WAF/ORM no siempre están donde crees
> En APIs modernas es común que el front esté protegido por un ORM pero un endpoint suelto construya SQL a mano. La inyección se cuela por **paths, cabeceras, y campos JSON anidados** que el WAF inspecciona peor que un `?param=`. Prueba la comilla en **todos** los puntos de entrada, no solo en la query string.

# Cabeceras de seguridad y CORS

Otra faceta de la misma categoría: la API omite o configura mal las **cabeceras de seguridad HTTP**. El caso más crítico es una política `CORS` permisiva:

```http
Access-Control-Allow-Origin: https://atacante.com
Access-Control-Allow-Credentials: true
```

El fallo explotable es <mark style="background: #FFB86CA6;">**reflejar** el `Origin` de la petición junto a `Allow-Credentials: true`</mark>: cualquier web del atacante lee respuestas autenticadas de la API → robo de datos entre orígenes, y facilita [[01 - Fundamentos y defensas de CSRF|CSRF]].

> [!warning]+ `*` + credenciales NO es explotable
> `Access-Control-Allow-Origin: *` junto a `Allow-Credentials: true` es **inerte**: los navegadores **rechazan** el wildcard cuando la petición lleva credenciales (bloquean la lectura de la respuesta). El caso peligroso es que la API **refleje** el `Origin` recibido (validación laxa tipo `endsWith`/`startsWith`) en vez de usar un allowlist estricto. Revisa siempre si el `Origin` se refleja.

# El resto de la categoría (más allá del lab)

`API8:2023` es amplia. En un pentest, revisa también:

- **Errores verbosos**: stack traces, versiones, rutas del servidor (útiles para [[19 - Detección, evasión y prevención de XXE|error-based]] y para fingerprint).
- **Endpoints de debug/actuator** expuestos (`/actuator`, `/debug`, `/swagger` en producción, `/graphql` con introspección).
- **Métodos HTTP innecesarios** habilitados ([[04 - Detección, evasión y prevención de Verb Tampering|verb tampering]]).
- **Credenciales/tokens por defecto**, CORS mal configurado, TLS débil, ausencia de `HSTS`/`CSP`/`X-Content-Type-Options`.

# Prevención

- **Consultas parametrizadas** u `ORM` para toda entrada en SQL; validación como refuerzo, nunca como única defensa.
- **Cabeceras seguras** siguiendo [OWASP Secure Headers](https://owasp.org/www-project-secure-headers/); `CORS` restrictivo (allowlist de orígenes, nunca `*` con credenciales).
- Deshabilitar debug/introspección y errores verbosos en producción; hardening de la plataforma.

Siguiente: [[09 - Improper Inventory Management (API9)|Improper Inventory Management]].

## Referencias

- OWASP — [API8:2023 Security Misconfiguration](https://owasp.org/API-Security/editions/2023/en/0xa8-security-misconfiguration/)
- OWASP — [Secure Headers Project](https://owasp.org/www-project-secure-headers/)
- MITRE — [CWE-89](https://cwe.mitre.org/data/definitions/89.html)
- HTB Academy — *API Attacks* (base, 2024)
