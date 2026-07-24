---
tags:
  - Web/Red-Team
  - SQLi
  - Pentesting/Explotacion
Fecha de actualización: 2026-06-13
Nota previa: "[[10 - Prevención de SQL Injection]]"
Nota siguiente:
Area: "[[SQL Injection.base|SQL Injection]]"
---
---

La [[10 - Prevención de SQL Injection|prevención]] concluye que parametrizar separa código y datos y elimina la SQLi. Los `ORM` (Object-Relational Mappers) hacen justo eso **por defecto**: `User.objects.filter(name=x)` genera una consulta parametrizada sin que el desarrollador piense en ello. <mark style="background: #8000E1A6;">Esa comodidad crea una falsa sensación de inmunidad</mark>, y como casi toda aplicación moderna accede a datos a través de un ORM (Hibernate, Django ORM, Sequelize, Prisma, SQLAlchemy, Eloquent), <mark style="background: #FF5582A6;">es exactamente donde sobrevive la SQLi en 2026</mark>: en los huecos donde el ORM deja de parametrizar. HTB no cubre esto; en bug bounty real es de lo más rentable.

# Por qué un ORM puede ser inyectable

Un ORM protege mientras uses su capa de abstracción. Se rompe en cuatro patrones:

1. **Métodos *raw*** — el ORM expone una puerta a SQL crudo, y el desarrollador concatena entrada en ella.
2. **Inyección en el lenguaje del ORM** (`HQL`/`JPQL`) — manipular la consulta del propio ORM, aunque no se vea SQL.
3. **Operator injection / mass assignment** — pasar estructuras (objetos, JSON) donde se espera un valor, inyectando operadores o campos.
4. **Identificadores dinámicos** — `ORDER BY`, nombres de columna o tabla, que el ORM **no parametriza** nunca.

# Métodos raw: el caso más común

Cada ORM ofrece un escape a SQL nativo. Usado con concatenación, es SQLi clásica:

| Framework | Método peligroso (concatenado) | Forma segura |
| - | - | - |
| **Django** | `User.objects.raw("... id=%s" % id)` · `.extra(where=[...])` | `.raw("... id=%s", [id])` (params) |
| **Hibernate/JPA** | `createQuery("FROM User WHERE n='"+n+"'")` | `setParameter(":n", n)` |
| **Sequelize** | `sequelize.query("... "+x)` | `replacements`/`bind` |
| **Prisma** | `$queryRawUnsafe("... "+x)` | `$queryRaw\`...${x}\`` (tag) |
| **SQLAlchemy** | `text("... "+x)` / `.filter("name='"+x+"'")` | `text("...:x").bindparams(x=x)` |

```python
# Django — vulnerable: el formateo de cadena ocurre ANTES de llegar al ORM
User.objects.raw("SELECT * FROM users WHERE id = %s" % request.GET['id'])
# Seguro: el ORM parametriza
User.objects.raw("SELECT * FROM users WHERE id = %s", [request.GET['id']])
```

<mark style="background: #FFB86CA6;">La diferencia entre `% id` y `, [id]` es toda la vulnerabilidad</mark>: el primero interpola en Python antes de que el ORM vea nada; el segundo deja que el driver lo trate como parámetro.

# HQL / JPQL injection

`Hibernate` y `JPA` tienen su propio lenguaje de consulta (`HQL`/`JPQL`) que opera sobre objetos, no tablas. Concatenar entrada en una `HQL` permite <mark style="background: #ADCCFFA6;">`HQL injection`: manipular la consulta a nivel del ORM</mark>. No siempre da acceso a toda la base (HQL solo ve las entidades mapeadas), pero permite saltarse condiciones, enumerar entidades y, según el dialecto, llegar a funciones SQL:

```java
// Vulnerable: HQL concatenada
session.createQuery("FROM User WHERE name = '" + name + "'");
// name = x' OR '1'='1  →  devuelve todos los usuarios
```

Es más restringida que la SQLi cruda, pero el patrón de detección es idéntico: una comilla que rompe la consulta.

# Operator injection y mass assignment

El vector más característico de los ORM de Node. Si la entrada del usuario se pasa **directa** como filtro o cuerpo de actualización, el atacante inyecta **operadores** o **campos** que el desarrollador no previó:

```javascript
// Sequelize — vulnerable: el filtro viene crudo del usuario
User.findOne({ where: { username: req.query.username } });
// petición:  ?username[Op.ne]=  →  el operador "distinto de" salta la comprobación
```

<mark style="background: #FF5582A6;">Pasar `req.query`/`req.body` directo a `where`, `update` o `create`</mark> abre dos problemas: *operator injection* (inyectar `Op.gt`, `Op.ne`, `Op.like`) y *mass assignment* (setear columnas como `isAdmin` que no estaban en el formulario). Es la versión SQL del clásico de [[01 - Introducción a la NoSQL injection|NoSQL injection]], y comparte raíz: confiar en la estructura de la entrada.

# Identificadores dinámicos

Aunque uses el ORM correctamente, <mark style="background: #FFB8EBA6;">ningún ORM parametriza nombres de columna ni la dirección de `ORDER BY`</mark> —SQL no lo permite—. Un `?sort=name&dir=ASC` que se concatene para construir el `order` es inyectable igual que en SQL crudo —es uno de los huecos que [[01 - Detección de SQL Injection|sobreviven a los prepared statements]]—. La defensa aquí no es parametrizar (no se puede) sino una *allowlist* de columnas permitidas.

# Detección y prevención

- **White-box** (lo más eficaz): busca los métodos raw con [[02 - Búsqueda de strings en el código|grep/SAST]] — `\.raw\(`, `\.extra\(`, `createQuery`, `queryRawUnsafe`, `sequelize.query`, `text(` — y comprueba si el argumento se construye con concatenación o formateo. `semgrep` tiene reglas dedicadas para cada ORM.
- **Black-box**: el síntoma es el de cualquier [[01 - Detección de SQL Injection|SQLi]] —comilla que rompe, diferencias booleanas, retardos— en parámetros que filtran, ordenan o actualizan. Si el stack es un framework con ORM, sospecha de un método raw o de operator injection detrás.
- **Prevención**: usar siempre la capa parametrizada del ORM; *bind parameters* en los métodos raw cuando sean inevitables; *allowlist* para identificadores dinámicos; nunca pasar `req.body`/`req.query` directo a `where`/`update`; y *strong parameters* contra mass assignment.

> [!info]+ Fuentes
> - [PortSwigger — SQL injection](https://portswigger.net/web-security/sql-injection) · [OWASP — SQL Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
> - [PayloadsAllTheThings — HQL injection](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/SQL%20Injection) · docs de seguridad de Django (`raw()`/`extra()`), Sequelize (`Op`) y Prisma (`$queryRawUnsafe`).

La inyección en ORMs cierra el panorama de SQLi moderna: la vulnerabilidad clásica vive ahora escondida bajo capas de abstracción que se asumen seguras. El siguiente territorio de inyección sin SQL es la [[01 - Introducción a la NoSQL injection|NoSQL injection]], que comparte la lógica de operator injection vista aquí.
