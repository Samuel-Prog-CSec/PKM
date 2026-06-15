---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - JavaScript
Fecha de actualización: 2026-06-02
Nota previa: "[[01 - Ofuscación de código JavaScript]]"
Nota siguiente: "[[03 - Desofuscación y análisis de código]]"
Area: "[[JavaScript Deobfuscation.base|JavaScript Deobfuscation]]"
---
---

El *packing* deja los strings en texto claro. Los ofuscadores avanzados <mark style="background: #FFB86CA6;">eliminan todo rastro legible del código original</mark>, incluidas las cadenas.

# `obfuscator.io`

Es el ofuscador más usado en la práctica. Activando `String Array Encoding: Base64`, una simple línea se convierte en:

```javascript
var _0x1ec6=['Bg9N','sfrciePHDMfty3jPChqGrgvVyMz1C2nHDgLVBIbnB2r1Bgu='];
(function(_0x13249d,_0x1ec6e5){ /* rota el array */ }(_0x1ec6,0xb4));
var _0x14f8=function(_0x13249d,_0x1ec6e5){ /* decodifica Base64 bajo demanda */ };
console[_0x14f8('0x0')](_0x14f8('0x1'));
```

Lo que hace, y por lo que es difícil de leer:

- **Nombres hexadecimales** (`_0x14f8`, `_0x1ec6`) sin significado.
- **String array**: todas las cadenas se mueven a un array, se **rotan** y se codifican en `Base64`, y se referencian por índice (`_0x14f8('0x0')`). <mark style="background: #ADCCFFA6;">Ya no hay cadenas en texto claro</mark>.

> [!info]+ Las defensas de obfuscator.io que encontrarás en la práctica
> Más allá del string array, sus opciones endurecen el reversing:
> - **Control flow flattening**: convierte el flujo en una máquina de estados con un `switch` gigante, rompiendo la lógica lineal.
> - **Dead code injection**: mete ramas muertas para despistar.
> - **Self-defending**: el código se rompe si lo pasas por un *beautifier* (detecta el reformateo).
> - **Debug protection**: bucles de `debugger` que cuelgan las DevTools si intentas depurarlo.
> Saber que existen te dice **qué** estás combatiendo cuando un objetivo real usa este ofuscador.

# Ofuscadores extremos

Existen ofuscadores que reescriben el código usando un alfabeto mínimo de caracteres. `JSFuck` usa **solo seis**: `[ ] ( ) ! +`. La misma línea se convierte en miles de caracteres de esto:

```javascript
[][(![]+[])[+[]]+([![]]+[][[]])[+!+[]+[+[]]]+(![]+[])[!+[]+!+[]]+ ...SNIP... ](!+[]+!+[]+[+[]]))()
```

Sigue ejecutándose y produce el mismo resultado, aunque **mucho más lento** —prueba de que la ofuscación afecta al rendimiento—. Otros similares son `JJEncode` y `AAEncode` (que dibuja el código con emoticonos japoneses).

> [!important]+ Por qué importan estos en ataque: evasión de WAF
> Estos ofuscadores extremos rara vez se usan en producción legítima por su lentitud, pero <mark style="background: #FF5582A6;">son una técnica directa de *bypass* de filtros web y WAFs</mark>. Un payload `XSS` reescrito en `JSFuck` (solo `[]()!+`, sin letras ni comillas) o en `AAEncode` puede saltarse filtros que bloquean palabras como `alert` o `script`. Es una herramienta habitual al evadir defensas en el [[04 - Descubrimiento de XSS|descubrimiento de XSS]].

> [!warning]+ Ofuscación ≠ irreversibilidad
> Por muy retorcido que sea el resultado, <mark style="background: #8000E1A6;">el navegador tiene que ejecutarlo, así que siempre se puede revertir</mark>: ejecutándolo en un *sandbox* y observando el resultado, o pasándolo por un desofuscador. No existe ofuscación que oculte la funcionalidad de forma permanente.

Visto cómo se ofusca, toca lo contrario: revertirlo. Eso es [[03 - Desofuscación y análisis de código]].
