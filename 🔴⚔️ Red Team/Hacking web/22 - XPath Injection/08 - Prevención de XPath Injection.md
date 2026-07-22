---
tags:
  - Web/Red-Team
  - XPath
Fecha de actualización: 2026-07-16
Nota previa: "[[07 - Arsenal de herramientas XPath]]"
Nota siguiente: ""
Area: "[[XPath Injection.base|XPath Injection]]"
---
---

La XPath injection se previene, pero con un matiz que la diferencia de la SQLi: <mark style="background: #FFB8EBA6;">no existe un mecanismo de consultas parametrizadas universal para XPath</mark> en todos los lenguajes y librerías.

# Parametrización: la defensa robusta donde existe

HTB afirma que "la sanitización manual es el único método universal". Es cierto *como universal*, pero se queda corto: <mark style="background: #ADCCFFA6;">varias plataformas sí ofrecen parametrización de XPath, y es siempre preferible a sanitizar</mark>. Como en SQL, la idea es **precompilar** la expresión con variables y *bindear* los valores, nunca concatenar:

- **Java** (`javax.xml.xpath`): implementar un `XPathVariableResolver` y referenciar `$username` en la expresión, en lugar de concatenar la entrada.
- **.NET** (`System.Xml.XPath`): pasar los valores mediante variables XPath (`XsltContext` / `XsltArgumentList`) en vez de construir la cadena.
- **Python** (`lxml`): usar `xpath()` con **variables** (`tree.xpath("//user[username=$u]", u=user_input)`), que escapa el valor automáticamente.

```python
# lxml — parametrizado, seguro
tree.xpath("/users/user[username=$u and password=$p]", u=username, p=password)
```

Donde la librería lo soporte, esta es la solución correcta: elimina la clase de bug de raíz, no la parchea.

# Sanitización (cuando no hay parametrización)

Si la plataforma no permite variables XPath, hay que sanitizar toda entrada antes de insertarla:

- **Allowlist (lista blanca)** — la opción preferida: permitir solo caracteres alfanuméricos y rechazar cualquier entrada que contenga otra cosa.
- **Validar tipo, formato y semántica**: si se espera un entero, exigir solo dígitos; si el valor pertenece a un conjunto fijo (como el parámetro `f ∈ {fullstreetname, streetname}` del buscador), <mark style="background: #8000E1A6;">validarlo contra ese conjunto</mark> — corrección semántica, no solo sintáctica.
- **Blacklist (lista negra)** — menos segura, como último recurso: bloquear los caracteres de control de XPath.

| Carácter | Símbolo |
| - | - |
| Comilla simple / doble | `'` `"` |
| Barra | `/` |
| Arroba | `@` |
| Igual | `=` |
| Comodín | `*` |
| Corchetes / paréntesis | `[` `]` `(` `)` |

> [!warning]+ El hash de la contraseña no es una defensa
> Un error recurrente: creer que hashear la contraseña antes de insertarla cierra el bug. Solo cierra **un** punto de inyección; el `username` sigue abierto (ver [[02 - Bypass de autenticación con XPath]]). La mitigación real es parametrizar o sanitizar **toda** entrada, no una sola.

> [!info]+ Defensa en profundidad
> Minimizar los datos sensibles almacenados en XML accesible (no guardar credenciales junto a datos consultables), y usar un WAF como capa adicional —nunca como arreglo—. La misma filosofía que en la [[10 - Prevención de SQL Injection|prevención de SQLi]] y la [[06 - Prevención de LDAP Injection|de LDAP]].
