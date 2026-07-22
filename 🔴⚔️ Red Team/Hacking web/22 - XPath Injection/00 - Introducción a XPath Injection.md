---
tags:
  - Web/Red-Team
  - Introduccion
  - XPath
Fecha de actualización: 2026-07-16
Nota previa: ""
Nota siguiente: "[[01 - Detección de XPath Injection]]"
Area: "[[XPath Injection.base|XPath Injection]]"
---
---

<mark style="background: #ADCCFFA6;">XPath (XML Path Language) es un lenguaje de consulta para navegar y extraer datos de documentos XML</mark> — el equivalente de SQL para las bases de datos relacionales. Cuando una aplicación construye una consulta XPath concatenando entrada del usuario sin sanitizar, aparece la **XPath injection**: <mark style="background: #FFB86CA6;">el atacante reescribe el predicado de la consulta para saltarse la autenticación o volcar el documento XML entero</mark>. La mecánica es la misma que en [[00 - Introducción a SQL Injection|SQL injection]] —romper el contexto de una cadena y alterar la lógica—, solo que el backend es un árbol XML en lugar de un DBMS.

<mark style="background: #FFB8EBA6;">Es un hallazgo menos frecuente que la SQLi</mark> porque pocas aplicaciones modernas usan XML como almacén principal, pero sobrevive en nichos que conviene reconocer: formularios de login respaldados por un fichero `users.xml`, buscadores sobre catálogos XML, lectores de configuración, y sobre todo sistemas *legacy* o embebidos (routers, appliances, IoT) donde XML sigue siendo el formato nativo. También aflora en flujos que procesan XML de terceros —SAML, feeds, documentos importados—. En bug bounty es nicho, pero de alto impacto cuando cae: un backend `users.xml` sin base de datos suele traducirse en <mark style="background: #8000E1A6;">bypass de login directo sin credenciales</mark>.

# El documento XML como árbol

Para inyectar en XPath hay que entender la estructura sobre la que opera. Un documento XML es un **árbol de nodos** con un único nodo raíz. Tomemos como referencia este documento, que reutilizaremos en todo el sub-tema:

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

El nodo raíz es `academy_modules`. A partir de él hay **nodos elemento** (`module`, `title`), **nodos atributo** (`difficulty="medium"`, `co-author="LTNB0B"`), **nodos texto** (el contenido `Web Attacks`, `mrb3n`) y **nodos comentario**. Sumando los nodos de *namespace* y de *processing instruction* —que rara vez tocaremos— hay <mark style="background: #ADCCFFA6;">7 tipos de nodo</mark> en total. Cada nodo elemento o atributo tiene exactamente un **padre** y un número arbitrario de **hijos**; los nodos con el mismo padre son **hermanos**. Toda consulta parte de un **nodo de contexto** que marca el punto de arranque — por eso la misma consulta puede dar resultados distintos según desde dónde se evalúe.

# Sintaxis XPath imprescindible

Estas son las piezas con las que se construyen los `payloads`. En el módulo trabajamos siempre con la **sintaxis abreviada** (la completa está en la especificación W3C).

**Selección de nodos:**

| Consulta | Selecciona |
| - | - |
| `module` | los nodos hijo `module` del nodo de contexto |
| `/` | el nodo raíz del documento |
| `//` | los descendientes del nodo de contexto (desde la raíz si la consulta empieza por `//`) |
| `.` | el nodo de contexto |
| `..` | el nodo padre |
| `@difficulty` | el nodo atributo `difficulty` |
| `text()` | los nodos texto hijos |

**Predicados** (filtran el resultado, como el `WHERE` de SQL; van entre corchetes `[]`):

| Consulta | Selecciona |
| - | - |
| `/academy_modules/module[1]` | el primer `module` (equivale a `[position()=1]`) |
| `/academy_modules/module[last()]` | el último `module` |
| `//module[tier=2]/title` | el `title` de los módulos con `tier` igual a 2 |
| `//module/tier[@difficulty="medium"]/..` | los módulos cuyo `tier` tiene `difficulty=medium` |

Los predicados admiten operandos aritméticos (`+ - * div mod`), de comparación (`= != < <= > >=`) y lógicos (`and`, `or`).

**Comodines y unión:**

| Consulta | Selecciona |
| - | - |
| `node()` | cualquier nodo |
| `*` | cualquier nodo elemento (no descendientes, a diferencia de `//`) |
| `@*` | cualquier nodo atributo |
| `//a/text() \| //b/text()` | une los resultados de dos consultas con el operador `\|` |

> [!info]+ El operador unión `|` es la clave de la exfiltración
> Igual que en SQLi la `UNION SELECT` permite injertar una segunda consulta, en XPath el operador `|` concatena el resultado de dos rutas. `' | //text()` filtrado en una consulta vulnerable devuelve **todos los nodos texto del documento** — la técnica base de la [[03 - Exfiltración de datos con XPath|exfiltración in-band]].

# Dónde aparece la XPath injection

<mark style="background: #FF5582A6;">Cualquier parámetro que termine dentro de una expresión XPath es candidato</mark>: campos de usuario/contraseña de un login contra `users.xml`, parámetros de búsqueda o filtrado sobre un catálogo XML, y valores que alimentan lectores de configuración. El patrón vulnerable canónico es la concatenación directa en PHP, Java o .NET:

```php
$query = "/users/user[username/text()='" . $_POST['username'] . "' and password/text()='" . $_POST['password'] . "']";
```

A diferencia de SQL, XPath **no distingue comillas simples de dobles a nivel de motor** pero sí las usa para delimitar literales dentro del predicado, así que el carácter que rompe la consulta suele ser la comilla (`'` o `"`) que cierra el literal — igual que en el contexto *string* de la SQLi. No hay `UNION SELECT`, `information_schema` ni comentarios `--`; en su lugar se abusa del operador `|`, de funciones como `substring()`, `count()` o `name()`, y de la lógica booleana del predicado.

> [!warning]+ No confundir con XXE ni con XSLT injection
> Las tres tocan XML pero son bugs distintos. <mark style="background: #FFB8EBA6;">XPath injection manipula una **consulta** sobre un documento XML</mark>; el `XXE` abusa del **parser** para declarar entidades externas (LFI/SSRF); la [[00 - Inyección XSLT|XSLT injection]] inyecta en la **plantilla de transformación**. Identificar cuál tienes delante determina toda la explotación posterior.

El siguiente paso es la metodología para **detectar** el punto de inyección y confirmar el contexto antes de explotar: [[01 - Detección de XPath Injection]].
