---
tags:
  - Web/Red-Team
  - LDAP
  - Tipo/Defensa
Descripción: "La LDAP injection es más rara que la SQLi, así que hay mucha menos concienciación — potencialmente existe en cualquier aplicación con integración LDAP/AD. La buena noticia: las…"
Fecha de actualización: 2026-07-16
Nota previa: "[[05 - Arsenal de herramientas LDAP]]"
Nota siguiente: ""
Area: "[[LDAP Injection.base|LDAP Injection]]"
---
---

La LDAP injection es más rara que la SQLi, así que <mark style="background: #FFB8EBA6;">hay mucha menos concienciación</mark> — potencialmente existe en cualquier aplicación con integración LDAP/AD. La buena noticia: las contramedidas son simples y bien conocidas.

# Escapar los caracteres de control

La sanitización básica es escapar los caracteres especiales de los `search filters` a su forma hex:

| Carácter | Escape |
| - | - |
| `(` | `\28` |
| `)` | `\29` |
| `*` | `\2a` |
| `\` | `\5c` |
| null byte | `\00` |

La mayoría de lenguajes traen una función para esto — no hay que implementarla a mano. En PHP es `ldap_escape()`. Sobre el código vulnerable típico:

```php
// Vulnerable: concatena la entrada directamente
$filter = '(&(cn=' . $_POST['username'] . ')(userPassword=' . $_POST['password'] . '))';

// Corregido: escapa cada valor
$filter = '(&(cn=' . ldap_escape($_POST['username']) . ')(userPassword=' . ldap_escape($_POST['password']) . '))';
```

> [!info]+ Escape en otros lenguajes
> HTB solo muestra PHP, pero el equivalente existe en todas partes: <mark style="background: #ADCCFFA6;">Java → OWASP ESAPI `encodeForLDAP()` / `encodeForDN()`; Python → `ldap.filter.escape_filter_chars()` (python-ldap) o el escaping de `ldap3`; .NET → escaping manual en `System.DirectoryServices`; Node → paquete `ldap-escape`</mark>. Usar siempre la función de la librería, nunca un `str_replace` casero.

# Mejores prácticas (más allá de sanitizar)

**1. Autenticar con `bind`, no con `search`.** Es la defensa más robusta para logins: en lugar de construir un filtro y buscar, se hace un `bind` con las credenciales del usuario y <mark style="background: #8000E1A6;">se delega la comprobación al Directory Server — no hay filtro, luego no hay inyección posible</mark>:

```php
// Autenticación por bind: no hay search filter que inyectar
$dn = "cn=" . ldap_escape($_POST['username'], "", LDAP_ESCAPE_DN) . ",dc=example,dc=htb";
$bind = ldap_bind($conn, $dn, $_POST['password']);   // el DS valida las credenciales
```

**2. Least privilege en la cuenta de `bind`.** La cuenta con la que la app se conecta al DS debe tener solo los permisos mínimos para su búsqueda. <mark style="background: #FFB86CA6;">Limita cuántos datos puede leer un atacante</mark> si hay inyección.

**3. Deshabilitar los *anonymous binds*** en el DS, para que ninguna operación se pueda realizar sin autenticación.

> [!warning]+ El error clásico
> Como en la [[08 - Prevención de XPath Injection|prevención de XPath]], sanitizar **un solo** campo no basta: si el login escapa la contraseña pero no el usuario (o al revés), sigue siendo explotable. Escapar **toda** entrada, o mejor, migrar a autenticación por `bind`. La misma filosofía de defensa en profundidad que en la [[10 - Prevención de SQL Injection|prevención de SQLi]].
