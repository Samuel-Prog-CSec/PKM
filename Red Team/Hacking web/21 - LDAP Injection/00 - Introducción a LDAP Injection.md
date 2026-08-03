---
tags:
  - Web/Red-Team
  - Introduccion
  - LDAP
  - Tipo/Introduccion
Descripción: "LDAP (Lightweight Directory Access Protocol) es el protocolo para consultar servidores de directorio como Active Directory u OpenLDAP. Muchas aplicaciones —sobre todo…"
Fecha de actualización: 2026-07-16
Nota previa: ""
Nota siguiente: "[[01 - Detección de LDAP Injection]]"
Area: "[[LDAP Injection.base|LDAP Injection]]"
---
---

<mark style="background: #ADCCFFA6;">LDAP (Lightweight Directory Access Protocol) es el protocolo para consultar servidores de directorio</mark> como Active Directory u OpenLDAP. Muchas aplicaciones —sobre todo corporativas— lo usan para autenticar usuarios o buscar datos contra el directorio. Si la entrada del usuario se concatena en un *search filter* LDAP sin sanitizar, surge la **LDAP injection**: <mark style="background: #FFB86CA6;">bypass de autenticación y exfiltración de datos del directorio, incluido el atributo `userPassword`</mark>.

<mark style="background: #FFB8EBA6;">A diferencia de XPath, la LDAP injection es muy relevante en entornos empresariales</mark>: intranets, SSO, portales de RRHH y libretas de direcciones tiran de AD constantemente. Es un vector habitual tanto en pentest interno como en aplicaciones corporativas expuestas al exterior.

# Fundamentos de LDAP

- **Directory Server (DS)**: almacena los datos (p. ej. OpenLDAP), con un modelo distinto al de una base de datos relacional.
- **Entry (entrada)**: representa una entidad y se compone de:
  - **DN (Distinguished Name)**: identificador único formado por varios **RDN** (pares clave-valor separados por comas). Ejemplo: `uid=admin,dc=hackthebox,dc=com`.
  - **Atributos**: tipo + valores (ver tabla abajo).
  - **Object Classes**: agrupan atributos según el tipo de objeto (`Person`, `Group`…).
- **Operaciones**: `Bind` (autenticación), `Search` (consulta) son las relevantes para nosotros; también `Add`, `Delete`, `Modify`, `Unbind`.

# La sintaxis de los search filters

<mark style="background: #8000E1A6;">El detalle clave de LDAP: los filtros usan notación **prefija**</mark> — el operador va delante y cada componente entre paréntesis `()`. Así, `(&(name=Kaylie)(title=Manager))` significa "name=Kaylie **AND** title=Manager". Cada componente base es `(atributo operando valor)`.

| Tipo | Operando | Ejemplo |
| - | - | - |
| Igualdad | `=` | `(name=Kaylie)` |
| Mayor-o-igual | `>=` | `(uid>=10)` |
| Menor-o-igual | `<=` | `(uid<=10)` |
| Aproximado | `~=` | `(name~=Kaylie)` |

Operadores de combinación (y los literales booleanos y el comodín):

| Nombre | Sintaxis | Ejemplo |
| - | - | - |
| And | `(&()())` | `(&(name=Kaylie)(title=Manager))` |
| Or | `(\|()())` | `(\|(name=Kaylie)(title=Manager))` |
| Not | `(!())` | `(!(name=Kaylie))` |
| True / False | `(&)` / `(\|)` | filtros universalmente verdadero / falso |
| Wildcard | `*` | `(name=*)`, `(name=K*)`, `(name=*a*)` |

`&` y `\|` admiten más de dos argumentos: `(&(a=1)(b=2)(c=3))` es válido. <mark style="background: #FF5582A6;">Este comodín `*` y los booleanos `(&)`/`(|)` son la base de casi todos los `payloads` de LDAP injection.</mark>

# Atributos comunes

| Atributo | Significado | Atributo | Significado |
| - | - | - | - |
| `cn` | Nombre completo | `uid` | User ID |
| `givenName` | Nombre | `sn` | Apellido |
| `mail` | Email | `member` | Pertenencia a grupos |
| `objectClass` | Tipo de objeto | `userPassword` | Contraseña |
| `ou` | Unidad organizativa | `description` | Descripción |

> [!info]+ RFCs y un *gotcha*
> La sintaxis de filtros está en [RFC 4515](https://www.rfc-editor.org/rfc/rfc4515) y los tipos de atributo en RFC 2256. Ojo con el operando aproximado `~=`: <mark style="background: #FFB8EBA6;">la especificación no define cómo debe implementarse</mark>, así que el mismo filtro puede dar resultados distintos según el servidor LDAP — algo a tener en cuenta al portar un `payload` entre objetivos.

Con la sintaxis clara, el siguiente paso es reconocer y confirmar el punto de inyección: [[01 - Detección de LDAP Injection]].
