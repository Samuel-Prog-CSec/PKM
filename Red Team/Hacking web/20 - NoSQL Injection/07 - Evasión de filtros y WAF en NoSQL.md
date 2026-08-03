---
tags:
  - Web/Red-Team
  - NoSQLi
  - Pentesting/Explotacion
Descripción: "Igual que en el resto de inyecciones, lo que separa al profesional es explotar a pesar de los filtros"
Fecha de actualización: 2026-07-16
Nota previa: "[[06 - Server-Side JavaScript Injection]]"
Nota siguiente: "[[08 - Arsenal de herramientas para NoSQL]]"
Area: "[[NoSQL Injection.base|NoSQL Injection]]"
---
---

Igual que en el resto de inyecciones, lo que separa al profesional es explotar **a pesar de los filtros**. En NoSQLi hay dos capas: el **filtro de aplicación** (sanitizadores que quitan `$`, casting de tipo) y el **WAF**.

# Saltar el filtro de aplicación

El sanitizador clásico en Node es `express-mongo-sanitize` (elimina claves que empiezan por `$` o contienen `.`) — aunque hoy está **abandonado y roto en Express 5** (ver [[09 - Prevención de NoSQL injection|prevención]]); donde siga en uso, estas vías lo evaden:

- **Notación de corchetes vs JSON**: si el WAF/sanitizador solo inspecciona el cuerpo JSON, pasar el operador como `param[$ne]=x` en `x-www-form-urlencoded` puede colarse (y viceversa). <mark style="background: #FFB86CA6;">Probar siempre ambos formatos</mark>.
- **Anidamiento**: sanitizadores que solo limpian el nivel superior de claves dejan pasar operadores anidados más profundos. Verificar la cobertura real del sanitizador.
- **Operador alternativo**: si `$where` está bloqueado, la inyección de operadores (`$ne`, `$gt`, `$regex`) suele seguir viva; si `$regex` está filtrado, `$gt`/`$lt` cubren la extracción.

> [!warning]+ Contra un casting de tipo correcto, poco que hacer
> Si la app hace `strval()` (o Mongoose castea por schema), la inyección de **operadores** muere: `[$ne]` pasa a ser la string `"Array"`. <mark style="background: #FF5582A6;">La excepción es la SSJI</mark>: un `$where` con concatenación de strings sigue explotable aunque se castee, porque no depende de pasar un array. Ahí la evasión se centra en el JavaScript.

# Evasión en la SSJI (comentarios y null byte)

Como el `$where` evalúa JavaScript, valen los trucos de JS. Terminar la consulta original y comentar el resto:

```text
' || 'a'=='a
' && this.password.match(/.*/)//+%00
```

<mark style="background: #8000E1A6;">El `//` comenta lo que sigue en la expresión JS</mark> y es lo que de verdad corta lo que el motor añada después. El `%00` **no** trunca el JavaScript que evalúa MongoDB (los strings de V8/SpiderMonkey no son *null-terminated*); solo sirve para evadir un WAF o sanitizador escrito en C que trate el `\0` como fin de cadena. En forma URL-encoded aparece como `'%20%26%26%20this.password.match(/.*/)//+%00`.

# Evasión de WAF

Los WAF modernos ya detectan patrones `$ne`/`$gt`/`$where` en JSON, pero:

- **Cambio de formato**: `param[$ne]=` en form-encoded si el WAF solo mira JSON.
- **Encoding**: URL-encoding, doble encoding, unicode, y el null byte (`%00`) que rompe el patrón buscado.
- **Estructura**: espacios extra, objetos anidados, arrays — variaciones que el motor de firmas no contempla.

> [!important]+ Principio de evasión
> El blacklist es finito; las representaciones equivalentes, prácticamente infinitas. Contra un WAF por firmas, cambia el **formato** (bracket vs JSON) o el **encoding**, no ofusques el operador conocido. Misma regla que en [[06 - Evasión de filtros y WAF en XPath|XPath]], [[04 - Evasión de filtros en LDAP Injection|LDAP]] y [[05 - Bypass de caracteres comunes|SQLi]].

> [!info]+ Fuentes
> [HackTricks — NoSQL injection](https://book.hacktricks.wiki/en/pentesting-web/nosql-injection.html) · [PayloadsAllTheThings — NoSQL Injection](https://swisskyrepo.github.io/PayloadsAllTheThings/NoSQL%20Injection/) · wordlists `seclists/Fuzzing/Databases/NoSQL.txt`.
