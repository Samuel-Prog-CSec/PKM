---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Verb-Tampering
  - Tipo/Deteccion
Descripción: "Nota dedicada a encontrar verb tampering en un pentest real, evadir las defensas modernas que lo dificultan, y prevenirlo"
Fecha de actualización: 2026-07-15
Nota previa: "[[03 - Bypass de filtros de seguridad]]"
Nota siguiente: "[[05 - Herramientas para HTTP Verb Tampering]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Nota dedicada a **encontrar** verb tampering en un pentest real, **evadir** las defensas modernas que lo dificultan, y **prevenirlo**. HTB cubre la prevención pero apenas la detección sistemática y la evasión — aquí se amplía con lo que se usa hoy.

# Detección

## Enumerar métodos aceptados

El primer paso es saber qué verbos habla el servidor. `OPTIONS` devuelve la cabecera `Allow`:

```shell-session
$ curl -i -s -X OPTIONS http://target/ | grep -i '^Allow:'
Allow: POST,OPTIONS,HEAD,GET
```

<mark style="background: #FFB8EBA6;">No te fíes solo de `Allow`</mark>: muchos servidores no lo reportan con precisión, o el WAF lo filtra. La detección fiable es **activa**: probar cada método contra el endpoint y comparar la respuesta.

## Probar el bypass de autorización

Para cada endpoint que devuelva `401`/`403`, reenvíalo con toda la batería de métodos y compara código de estado, longitud y efecto:

```shell-session
$ for M in GET POST HEAD PUT DELETE PATCH OPTIONS TRACE FOOBAR; do
    printf "%-8s " "$M"; curl -s -o /dev/null -w "%{http_code}\n" -X "$M" http://target/admin/reset.php
  done
```

<mark style="background: #FF5582A6;">Un método que devuelve `200` (o dispara la acción) donde `GET`/`POST` daban `401` es un bypass confirmado</mark>. Incluye verbos **inventados** (`FOOBAR`): Apache suele tratarlos como `GET`, saltándose reglas `<Limit>`.

## Probar el bypass de filtros

Cuando un payload de inyección es bloqueado, no asumas que el filtro es global. Intenta **mover la fuente** del parámetro:

- `POST` → `GET` (y viceversa): el payload pasa a `$_GET`/`$_POST` según convenga.
- Cuerpo `JSON` → query string, o `form-urlencoded` → `multipart`.
- **Duplicar** el parámetro: uno limpio en la fuente filtrada, el payload en la otra ([[03 - Bypass de filtros de seguridad|HTTP Parameter Pollution]]).

# Evasión de defensas modernas

En apps con routing explícito por método, el verb tampering "puro" falla, pero estas técnicas lo resucitan (documentadas en **The Hacker Recipes** y **HackTricks**):

## Cabeceras de *method override*

Muchos frameworks reescriben el método real leyendo una cabecera. Un `POST` "disfrazado" atraviesa proxies/WAFs que deciden por el verbo visible:

```http
POST /admin/user/42 HTTP/1.1
Host: target
X-HTTP-Method-Override: DELETE
Content-Length: 0
```

Variantes a probar todas: `X-HTTP-Method-Override`, `X-HTTP-Method`, `X-Method-Override`, `X-Original-HTTP-Method`. <mark style="background: #FFB86CA6;">Si el back-end las respeta, ejecutas `DELETE`/`PUT` restringidos aunque el borde solo vea un `POST` inocuo</mark>.

## Spoofing con `_method`

Rails, Laravel y Symfony convierten un `POST` con campo `_method` en el verbo indicado. Útil cuando el WAF solo tiene reglas para `POST`:

```http
POST /admin/user/42 HTTP/1.1
Host: target
Content-Type: application/x-www-form-urlencoded

_method=DELETE
```

## Encadenar con bypass de 401/403

El verb tampering es una pieza del arsenal de *access-control bypass*. Si un método no basta, combínalo con las técnicas de path/header de [[02 - Bypass de autenticación básica|401/403 bypass]]: `X-Original-URL`, `X-Rewrite-URL`, variaciones de path (`/admin/./`, `//admin`, `/admin/..;/`), y trucos de mayúsculas en el método.

> [!info]+ TRACE y Cross-Site Tracing (XST)
> El método `TRACE` refleja la petición. Históricamente permitía robar cookies `HttpOnly` (`XST`) y hoy sigue siendo útil para **ver qué cabeceras añaden los proxies intermedios** (útil en reconocimiento de infra). Deshabilítalo en defensa; pruébalo en ofensiva.

# Prevención

Insecure configuration e insecure coding son las dos raíces; se parchean distinto.

## Configuración

Nunca limites la autorización a verbos concretos. Ejemplos vulnerables y su corrección:

| Servidor | Patrón vulnerable | Solución |
| - | - | - |
| Apache | `<Limit GET>` | **Quitar el `<Limit>`**: `Require valid-user` directo bajo `<Directory>` (cubre todos los verbos) |
| Tomcat | `<http-method>GET</http-method>` | No restringir por método (o `<http-method-omission>` listando solo los que quedarán **sin** proteger) |
| ASP.NET | `<allow verbs="GET">` | No acotar por verbo: `deny` global + `allow` sin `verbs` |

> [!warning]+ `<LimitExcept>` es un footgun
> `<LimitExcept GET POST>` aplica la regla a todos los métodos **salvo** `GET` y `POST` — dejaría `GET`/`POST` **sin autenticar**, justo los que quieres proteger. Solo usa `<LimitExcept>` listando los métodos que quieres dejar **abiertos** (normalmente ninguno). Para exigir auth en todos los verbos, **no acotes por método**: `Require valid-user` va directo bajo `<Directory>`.

Además: **deny-all y luego allow** explícito, y **deshabilitar `HEAD`/`TRACE`** si la app no los necesita. Ejemplo de config Apache vulnerable que deja `/admin` abierto por `POST`/`HEAD`:

```xml
<Directory "/var/www/html/admin">
    AuthType Basic
    AuthName "Admin Panel"
    AuthUserFile /etc/apache2/.htpasswd
    <Limit GET>
        Require valid-user
    </Limit>
</Directory>
```

## Código

Identificar esto en código es más difícil: hay que encontrar **incoherencias en el uso de parámetros** entre la función que valida y la que ejecuta. Reglas:

- Usar **la misma fuente** de parámetros en filtro y acción. Evitar `$_REQUEST` (PHP), `request.values` (Flask), `Request['x']` (C#) cuando el filtro miró solo `$_POST`/`request.form`.
- Aplicar los filtros de seguridad a **todas** las fuentes, o normalizar la entrada a una sola.
- Routing **explícito** por método (no *catch-all* que luego lee cualquier verbo).

<mark style="background: #8000E1A6;">La invariante defensiva: el conjunto de datos que se valida debe ser un superconjunto del que se usa</mark>. Si validas `$_POST` pero ejecutas con `$_REQUEST`, hay un hueco por definición.

## Referencias

- OWASP WSTG — [Testing for HTTP Verb Tampering](https://owasp.org/www-project-web-security-testing-guide/v41/4-Web_Application_Security_Testing/07-Input_Validation_Testing/03-Testing_for_HTTP_Verb_Tampering)
- The Hacker Recipes — [HTTP methods](https://www.thehacker.recipes/web/config/http-methods) (cabeceras de override, `_method`)
- HackTricks — [403 & 401 Bypasses](https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/403-and-401-bypasses)
- OWASP — [REST Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html) (VBAAC)
- Apache — [`mod_core: <LimitExcept>`](https://httpd.apache.org/docs/2.4/mod/core.html#limitexcept)
