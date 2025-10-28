---
tags:
  - Introduccion
  - Web/Red-Team
  - Pentesting/Vulnerabilidad
Fecha de actualización: 2025-10-20
Nota previa:
Nota siguiente: "[[Bypass de autenticación]]"
Area: "[[Web Pentesting.base|Web Pentesting]]"
---
---

[Lenguaje de ruta XML (XPath)](https://www.w3.org/TR/xpath-3/), es un lenguaje de consulta para [Lenguaje de marcado extensible (XML)](https://datatracker.ietf.org/doc/html/rfc5364) de datos. Específicamente, podemos usar *XPath* para construir consultas *XPath* para datos almacenados en formato *XML*. Si la entrada del usuario se inserta en consultas *XPath* **sin una desinfección adecuada**, las vulnerabilidades [Inyección XPath](https://owasp.org/www-community/attacks/XPATH_Injection) surgen de manera similar a las vulnerabilidades de [[SQL Inyection]]

# Fundamentos XPath
Para profundizar, primero debemos establecer una línea de base en la terminología *XPath*. Para ello, consideremos el siguiente documento *XML*:
```xml
<?xml version="1.0" encoding="UTF-8"?>

<academy_modules>  
  <module>
    <title>Web Attacks</title>
    <author>21y4d</author>
    <tier difficulty="medium">2</tier>
    <category>offensive</category>
  </module>

  <!-- this is a comment -->
  <module>
    <title>Attacking Enterprise Networks</title>
    <author co-author="LTNB0B">mrb3n</author>
    <tier difficulty="medium">2</tier>
    <category>offensive</category>
  </module>
</academy_modules>
```
> [!info]
> - `XML declaration`: especifica la **versión XML y la codificación**.. <mark style="background: #FFB8EBA6;">Si se omite la declaración, el analizador XML asume la versión `1.0` y la codificación `UTF-8`</mark>.
> - Datos formateados en una **estructura de árbol** que consta de `nodes` con el elemento superior llamado `root element node`. Además, los hay `element nodes` como `module` y `title`, y `attribute nodes` como `co-author="LTNB0B"` o `difficulty="medium"`. Además, hay `comment nodes` (**comentarios**) y `text nodes` (datos de **caracteres** de nodos).
> - `namespace nodes` y `processing instruction nodes`, que no consideraremos aquí, sumando un total de <mark style="background: #ADCCFFA6;">`7` diferentes tipos de nodos</mark>.
> - `sibling nodes`: <mark style="background: #FFB86CA6;">nodos con el mismo padre</mark>.

---

# Nodos
En este módulo, solo discutiremos el `abbreviated syntax`. Para obtener más detalles sobre la sintaxis *XPath*, se puede consultar [Especificación del W3C](https://www.w3.org/TR/xpath-3/).

<mark style="background: #ADCCFFA6;">Cada consulta *XPath* selecciona un conjunto de nodos del documento *XML*</mark>. Una consulta se evalúa a partir de a `context node`, que **marca el punto de partida**. Por lo tanto, <mark style="background: #FFB8EBA6;">dependiendo del nodo de contexto, la misma consulta puede tener resultados diferentes</mark>. A continuación se muestra una descripción general de los casos base de las consultas *XPath* para seleccionar nodos:

| Consulta      | Explicación                                                                        |
| ------------- | ---------------------------------------------------------------------------------- |
| `module`      | Seleccionar **todos los nodos secundarios** (`module`) del nodo de contexto        |
| `/`           | Seleccionar el **nodo raíz del documento**                                         |
| `//`          | Seleccionar **nodos descendientes** del nodo de contexto                           |
| `.`           | Seleccionar el **nodo de contexto**                                                |
| `..`          | Seleccionar el **nodo principal** del nodo de contexto                             |
| `@difficulty` | Seleccionar el **nodo de atributo** (`difficulty`) del nodo de contexto            |
| `text()`      | Seleccionar **todos los nodos secundarios del nodo de texto** del nodo de contexto |

Podemos utilizar estos casos base para construir consultas más complicadas. Para evitar ambigüedades en el resultado de la consulta dependiendo del nodo de contexto, podemos iniciar nuestra consulta en la raíz del documento:

|Consulta|Explicación|
|---|---|
|`/academy_modules/module`|Seleccionar todo `module` nodos secundarios de `academy_modules` nodo|
|`//module`|Seleccionar todo `module` nodos|
|`/academy_modules//title`|Seleccionar todo `title` nodos que son descendientes del `academy_modules` nodo|
|`/academy_modules/module/tier/@difficulty`|Seleccione el `difficulty` atributo nodo de todos `tier` nodos de elementos bajo la ruta especificada|
|`//@difficulty`|Seleccionar todo `difficulty` nodos de atributos|
> [!tip]
> Si una consulta comienza con `//`, la **consulta se evalúa desde la raíz del documento** y no en el nodo de contexto.

---

# Predicados
Los predicados filtran el resultado de una consulta *XPath* <mark style="background: #8000E1A6;">similar a la cláusula en una consulta [[💬 Sentencias SQL|SQL]] </mark>`WHERE`. Los predicados están <mark style="background: #FFB86CA6;">contenidos entre corchetes</mark> `[]`. Ejemplos:

|Consulta|Explicación|
|---|---|
|`/academy_modules/module[1]`|Seleccione el primero `module` nodo secundario del `academy_modules` nodo|
|`/academy_modules/module[position()=1]`|Equivalente a la consulta anterior|
|`/academy_modules/module[last()]`|Seleccione el último `module` nodo secundario del `academy_modules` nodo|
|`/academy_modules/module[position()<3]`|Seleccione los dos primeros `module` nodos secundarios del `academy_modules` nodo|
|`//module[tier=2]/title`|Seleccione el `title` de todos los módulos donde el `tier` el nodo del elemento es igual `2`|
|`//module/author[@co-author]/../title`|Seleccione el `title` de todos los módulos donde el `author` El nodo de elemento tiene un `co-author` nodo atributo|
|`//module/tier[@difficulty="medium"]/..`|Seleccione todos los módulos donde se encuentran `tier` El nodo de elemento tiene un `difficulty` nodo de atributo establecido en `medium`|

Los <mark style="background: #ADCCFFA6;">predicados admiten los siguientes operandos</mark>:

| Operando | Explicación    |
| -------- | -------------- |
| `+`      | **Adición**        |
| `-`      | **Resta**          |
| `*`      | **Multiplicación** |
| `div`    | **División**       |
| `=`      | **Igual**          |
| `!=`     | **No es igual**    |
| `<`      | **Menos que**      |
| `<=`     | **Menos o igual**  |
| `>`      | **Mayor que**      |
| `>=`     | **Mayor o igual**  |
| `or`     | **Lógico o**       |
| `and`    | **Lógico y**       |
| `mod`    | **Módulo**         |

---

# Comodines y unión
<mark style="background: #ADCCFFA6;">A veces, no nos importa el tipo de nodo en una ruta</mark>. En ese caso, podemos utilizar uno de los siguientes comodines:

| Consulta | Explicación                                 |
| -------- | ------------------------------------------- |
| `node()` | **Coincide con cualquier nodo**             |
| `*`      | Coincide con **cualquier nodo `element`**   |
| `@*`     | Coincide con **cualquier nodo `attribute`** |

Podemos usar estos comodines para construir consultas de la siguiente manera:

|Consulta|Explicación|
|---|---|
|`//*`|Seleccione todos los nodos de elementos en el documento|
|`//module/author[@*]/..`|Seleccione todos los módulos donde el nodo del elemento autor tenga al menos un nodo de atributo de cualquier tipo|
|`/*/*/title`|Seleccione todos los nodos de título que estén exactamente dos niveles por debajo de la raíz del documento|
> [!attention]+
> El comodín `*` coincide con cualquier nodo pero no con ningún descendiente como `//` hace. Por lo tanto, **necesitamos especificar la cantidad correcta de comodines en nuestra consulta**. En nuestro documento *XML* de ejemplo, la consulta `/*/*/title` devuelve todos los títulos de los módulos, excepto la consulta `/*/title` no devuelve nada.

Por último, podemos **combinar múltiples consultas XPath con el operador de unión `|`** así:

| Consulta                                                         | Explicación                                                    |
| ---------------------------------------------------------------- | -------------------------------------------------------------- |
| `//module[tier=2]/title/text() \| //module[tier=3]/title/text()` | Seleccione el título de todos los módulos en niveles `2` y `3` |
