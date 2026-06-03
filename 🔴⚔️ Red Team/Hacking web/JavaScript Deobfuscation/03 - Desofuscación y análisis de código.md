---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Enumeracion
  - JavaScript
Fecha de actualización: 2026-06-02
Nota previa: "[[02 - Ofuscación avanzada]]"
Nota siguiente: "[[04 - Peticiones HTTP y decodificación]]"
Area: "[[JavaScript Deobfuscation.base|JavaScript Deobfuscation]]"
---
---

Igual que hay herramientas para ofuscar, las hay para revertir. El proceso tiene dos pasos que conviene no confundir: **beautify** (formatear) y **deobfuscate** (revertir la ofuscación).

# Beautify ≠ deobfuscate

<mark style="background: #FFB8EBA6;">Hacer *beautify* solo reformatea el código minificado en varias líneas con indentación, pero no deshace la ofuscación</mark>. El método más básico está en las propias DevTools: en el debugger (`CTRL+SHIFT+Z` en Firefox), abres el script y pulsas el botón `{ }` (*Pretty Print*). Herramientas online como [Prettier](https://prettier.io/playground/) o [Beautifier](https://beautifier.io/) hacen lo mismo.

El problema: si el código está *packed* (no solo minificado), tras beautificarlo **sigue siendo ilegible** —el `eval(function(p,a,c,k,e,d)...)` queda formateado pero igual de opaco—. Para eso hace falta desofuscar.

# Deobfuscate

Para código *packed*, un desempaquetador como [UnPacker](https://matthewfl.com/unPacker.html) revierte la transformación. Tomando nuestro `secret.js`:

```javascript
eval(function (p, a, c, k, e, d) { ...SNIP... }('g 4(){0 5="6{7!}";0 1=8 a();0 2="/9.c";1.d("e",2,f);1.b(3)}', 17, 17, 'var|xhr|url|null|generateSerial|flag|HTB|flag|new|serial|XMLHttpRequest|send|php|open|POST|true|function'.split('|'), 0, {}))
```

Fíjate en algo ya conocido: <mark style="background: #FFB86CA6;">el diccionario del *packer* (`generateSerial|...|XMLHttpRequest|send|php|open|POST`) revela casi toda la función en texto claro</mark>, antes incluso de desempaquetar. Tras pasarlo por UnPacker:

```javascript
function generateSerial() {
  var xhr = new XMLHttpRequest;
  var url = "/serial.php";
  xhr.open("POST", url, true);
  xhr.send(null);
};
```

> [!important]+ El truco del `console.log` y por qué importa la seguridad
> Otra forma de desempaquetar manualmente: en lugar de **ejecutar** el código, sustituye el `eval` final por `console.log` para que **imprima** el resultado en vez de correrlo. Esto es crítico con código sospechoso: <mark style="background: #FF5582A6;">nunca ejecutes ciegamente JavaScript ofuscado de origen desconocido</mark> —podría ser el *stager* de un malware—. Transfórmalo e imprímelo, o ejecútalo en un *sandbox* aislado, nunca en tu equipo.

> [!info]+ Cuando los tools automáticos fallan
> `UnPacker` resuelve el *packing* clásico, pero contra ofuscación pesada o **custom** (la de [[02 - Ofuscación avanzada|obfuscator.io]] con *control flow flattening*, *self-defending*, etc.) los desofuscadores genéricos se atascan y toca *reverse engineering* manual. Herramientas modernas más capaces que UnPacker: `de4js` (todo en uno, soporta varios packers), `webcrack` y `synchrony` (especializados en deshacer la ofuscación de obfuscator.io). HTB cubre el RE avanzado en su módulo *Secure Coding 101*.

# Análisis del código

Con la función legible, la analizamos línea a línea:

- `var xhr = new XMLHttpRequest` — crea un objeto que maneja peticiones web (si no conoces una API, googléala: `XMLHttpRequest` es el cliente HTTP nativo del navegador).
- `var url = "/serial.php"` — apunta a `/serial.php` en el **mismo dominio** (no se especifica host).
- `xhr.open("POST", url, true)` + `xhr.send(null)` — abre y envía una petición `POST` a esa URL, **sin datos** y sin recoger nada.

En resumen: `generateSerial` envía un `POST` vacío a `/serial.php`. No hay ningún botón en el HTML que la invoque, así que <mark style="background: #FF5582A6;">es funcionalidad **sin liberar** que los desarrolladores dejaron para uso futuro</mark>. <mark style="background: #FFB86CA6;">El código no publicado suele tener más bugs y vulnerabilidades</mark> precisamente porque nadie lo ha probado en producción. Desofuscar y analizar el JS nos ha destapado un endpoint oculto que ahora podemos sondear manualmente.

Replicar esa petición con `curl` —y decodificar lo que devuelve— es [[04 - Peticiones HTTP y decodificación]].
