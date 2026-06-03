---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
  - JavaScript
Fecha de actualización: 2026-06-02
Nota previa: "[[00 - Introducción y código fuente]]"
Nota siguiente: "[[02 - Ofuscación avanzada]]"
Area: "[[JavaScript Deobfuscation.base|JavaScript Deobfuscation]]"
---
---

<mark style="background: #ADCCFFA6;">La **ofuscación** transforma un script para hacerlo difícil de leer por humanos, manteniéndolo funcionalmente idéntico</mark> (aunque algo más lento). Se hace con herramientas automáticas: toman el código y lo reescriben de forma ilegible. Un patrón típico es convertir el código en un **diccionario** de todas sus palabras y símbolos, y reconstruir el original en tiempo de ejecución referenciando cada entrada del diccionario.

# Por qué con JavaScript

En lenguajes **interpretados** (`Python`, `PHP`, `JavaScript`) el código se publica y ejecuta sin compilar. Pero `Python` y `PHP` viven en el servidor —ocultos al usuario—, mientras que <mark style="background: #FFB86CA6;">el `JavaScript` se ejecuta en el navegador del cliente y se envía en texto claro</mark>. Cualquiera puede leerlo. Por eso la ofuscación se usa muchísimo en JS: es el único modo de dificultar (que no impedir) su lectura.

# Casos de uso

- **Proteger la propiedad intelectual**: dificultar que se copie o se haga *reverse engineering* del código.
- **Capa de "seguridad"** sobre lógica de autenticación o cifrado.
- **Malware y evasión**: el uso más común en el mundo ofensivo — los atacantes ofuscan sus scripts para que los `IDS`/`IPS` y antivirus no los detecten por firma.

> [!warning]+ La ofuscación no es seguridad
> Hacer autenticación o cifrado en el lado cliente es una mala práctica: el código está expuesto y es más atacable. <mark style="background: #FF5582A6;">Ofuscar **no** protege un secreto</mark> — el navegador tiene que ejecutar el código, así que la lógica siempre es recuperable. La ofuscación solo añade fricción, nunca una barrera real. Para un atacante, eso significa que todo lo que el JS hace es, en última instancia, reversible.

# Minificación

La forma más básica de reducir legibilidad sin tocar la funcionalidad. <mark style="background: #FFB8EBA6;">`Code minification` comprime el código eliminando espacios, comentarios y saltos</mark> (a menudo a una sola línea larguísima). Las herramientas modernas (`terser`, `esbuild`) además **renombran las variables locales** (`userName` → `a`) y eliminan código muerto; su fin es reducir bytes, no ocultar. Los ficheros minificados suelen guardarse como `.min.js`. Un *beautifier* recupera el formato, pero <mark style="background: #FFB8EBA6;">**no** los nombres originales de variables — eso se pierde para siempre</mark>.

# Packing

Subimos un nivel. Tomemos esta línea:

```javascript
console.log('HTB JavaScript Deobfuscation Module');
```

Un *packer* la convierte en algo así:

```javascript
eval(function(p,a,c,k,e,d){e=function(c){return c};if(!''.replace(/^/,String)){while(c--){d[c]=k[c]||c}k=[function(e){return d[e]}];e=function(){return'\\w+'};c=1};while(c--){if(k[c]){p=p.replace(new RegExp('\\b'+e(c)+'\\b','g'),k[c])}}return p}('5.4(\'3 2 1 0\');',6,6,'Module|Deobfuscation|JavaScript|HTB|log|console'.split('|'),0,{}))
```

Ejecuta exactamente lo mismo. Claves para reconocerlo y revertirlo:

- <mark style="background: #FFB8EBA6;">La firma `function(p,a,c,k,e,d)` con esos seis argumentos delata un *packer*</mark> (el clásico *Dean Edwards packer*). El orden de `(p,a,c,k,e,d)` puede variar entre packers, pero la estructura es la misma.
- Convierte palabras y símbolos en una **lista/diccionario** (`'Module|Deobfuscation|JavaScript|HTB|log|console'`) y los reordena en ejecución para reconstruir el original.
- **Punto débil**: las cadenas principales siguen en texto claro en ese diccionario. <mark style="background: #8000E1A6;">Aunque el flujo sea ilegible, leer el array de strings ya te revela buena parte de la funcionalidad</mark>.

Como el packing deja los strings visibles, existen técnicas que ocultan también eso. Las vemos en [[02 - Ofuscación avanzada]].
