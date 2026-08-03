---
tags:
  - Web/Red-Team
  - LDAP
  - Pentesting/Enumeracion
  - Tipo/Deteccion
Descripción: "Como en XPath, HTB salta directo a explotar"
Fecha de actualización: 2026-07-16
Nota previa: "[[00 - Introducción a LDAP Injection]]"
Nota siguiente: "[[02 - Bypass de autenticación con LDAP]]"
Area: "[[LDAP Injection.base|LDAP Injection]]"
---
---

Como en XPath, HTB salta directo a explotar. En un test real primero hay que <mark style="background: #ADCCFFA6;">reconocer que detrás hay un directorio LDAP</mark> y confirmar la inyección. Sistematizamos la fase igual que en la [[01 - Detección de XPath Injection|detección de XPath]].

# Reconocer un backend LDAP

LDAP aparece donde hay integración con directorios corporativos. Señales:

- **Contexto de la app**: login que menciona "domain account", SSO corporativo, buscadores de empleados / libretas de direcciones, gestión de usuarios de intranet.
- **Mensajes de error** que delatan el backend: `LDAP: error code 34 - invalid DN syntax`, `javax.naming.directory`, `ldap_search(): search failed`, o errores de `OpenLDAP`/AD.
- **Pista de infraestructura**: el servicio detrás escucha en 389/636; menciones a `dc=`, `ou=`, `cn=`.

# Superficie de inyección

Cualquier entrada que alimente un `search filter`: usuario y contraseña del login, campos de búsqueda/lookup (buscar por nombre, email, teléfono) y filtros de listados.

# Confirmar la inyección

<mark style="background: #FF5582A6;">Los caracteres que rompen un filtro LDAP son `( ) * \ & | =` y el null byte</mark>. Pruebas de confirmación:

- **Basada en error**: inyectar un `)` o `(` suelto desbalancea el filtro → error de sintaxis LDAP o comportamiento anómalo.
- **Diferencial con comodín**: un `*` en un campo debería devolver más resultados (o autenticar). `admin*` vs `admin` distinguen el comportamiento.
- **Booleanos universales**: `(&)` (verdadero) frente a `(|)` (falso) inyectados deben producir respuestas opuestas.
- **Ciega**: sin salida ni error, buscar la diferencia de respuesta (como en [[03 - Exfiltración de datos y explotación ciega|la explotación ciega]]).

# Fingerprinting: LDAP vs SQLi vs XPath

<mark style="background: #FFB86CA6;">La clave para distinguir LDAP: sus filtros **no usan comillas** ni la keyword `or` al estilo SQL/XPath</mark> — usan paréntesis y operadores prefijos. Por eso `' or '1'='1` **no** funciona en LDAP, y sí lo hace `*)(uid=*` o `)(|(&`:

| Prueba | SQLi | XPath | LDAP |
| - | - | - | - |
| `' or '1'='1` | ✅ | ✅ | ❌ |
| `count(/*)`, `substring()` | ❌ | ✅ | ❌ |
| `*)(uid=*` / `)(\|(&` | ❌ | ❌ | ✅ |
| Comodín `*` amplía resultados | a veces | ❌ | ✅ |

Confirmar con sintaxis propia de LDAP (comodín `*`, cierre de paréntesis `)(`) descarta los otros motores y fija el vector — mismo criterio en espejo que la [[01 - Detección de XPath Injection|detección de XPath]] y la [[02 - Detección de NoSQL injection|de NoSQL]].

> [!info]+ WAF y realidad en 2026
> Igual que XPath, <mark style="background: #8000E1A6;">los WAF rara vez traen firmas específicas de LDAP</mark>: poco bloqueo, pero también un bug poco frecuente y con baja concienciación entre desarrolladores. La detección es manual (proxy + prueba de caracteres de control); las herramientas confirman y automatizan, no descubren el punto → [[05 - Arsenal de herramientas LDAP]].

> [!info]+ Fuentes
> [OWASP — LDAP Injection](https://owasp.org/www-community/attacks/LDAP_Injection) · [OWASP WSTG-INPV-06 (Testing for LDAP Injection)](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/07-Input_Validation_Testing/06-Testing_for_LDAP_Injection) · [HackTricks — LDAP Injection](https://book.hacktricks.wiki/en/pentesting-web/ldap-injection.html) · [PayloadsAllTheThings — LDAP Injection](https://swisskyrepo.github.io/PayloadsAllTheThings/LDAP%20Injection/).

Confirmada la inyección, el primer objetivo suele ser el bypass de autenticación: [[02 - Bypass de autenticación con LDAP]].
