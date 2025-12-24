---
tags:
Fecha de actualización:
Nota previa:
Nota siguiente:
Area:
---
---

# La etiqueta `<form>`
La etiqueta `<form>` es la etiqueta que se utiliza para crear un formulario. Un formulario es un conjunto de campos que el usuario puede rellenar y enviar a la página. Se usan otras etiquetas de forma interna para crear los campos del formulario, normalmente `<input>`.

## Ejemplo de uso
```html
<form>
  <input type="text" name="nombre" placeholder="Nombre" />
  <input type="email" name="email" placeholder="Email" />
  <button type="submit">Enviar</button>
</form>
/>
```

Primero, con `<form>` abrimos el formulario. Dentro de él, usamos `<input>` para crear los campos del formulario. Y finalmente, con `<button>` creamos el botón de envío.

---

# La etiqueta `<input>`
La etiqueta `<input>` es la etiqueta que se utiliza para crear un campo de formulario.

## Atributos de la etiqueta `<input>`
Algunos atributos importantes de la etiqueta `<input>` son:
- `type`: tipo de input. Puede ser `text`, `email`, `password`, `number`, `date`, etc.
- `name`: nombre del campo. Se usa para identificar el campo cuando se envía el formulario.
- `placeholder`: texto de ayuda que aparece en el campo cuando no se ha rellenado.
- `required`: indica si el campo es obligatorio.

## Ejemplo de uso
```html
<input type="text" name="nombre" placeholder="Nombre" />
```

> `type="text"` es el tipo de input por defecto y, por lo tanto, si no se especifica, se asume que es de tipo texto.

Como ves, la etiqueta `<input>` es una etiqueta autocerrante, como `<img>`. Esto quiere decir que no envuelve contenido interno como los elementos que vimos en la clase anterior.

### Una nota sobre accesibilidad
Por temas de accesibilidad, cada elemento `input` debería tener asociada una etiqueta `<label>` para que los lectores de pantalla y otras tecnologías asistivas puedan identificar correctamente el propósito del campo. En los ejemplos de este curso obviamos las etiquetas `label` para mantener el código más simple y evitar repetición, pero en producción siempre deberías usarlas:
```html
<label for="input-nombre">Nombre</label>
<input type="text" name="nombre" id="input-nombre" placeholder="Nombre" />
```

O también puedes anidar el input dentro del label:
```html
<label>
  Nombre
  <input type="text" name="nombre" placeholder="Nombre" />
</label>
```

> **Importante**: El atributo `placeholder` no es un sustituto del `label`. El `placeholder` desaparece cuando el usuario empieza a escribir, mientras que el `label` siempre está visible y ayuda a los lectores de pantalla.

---

# La etiqueta `<button>`
La etiqueta `<button>` es la etiqueta que se utiliza para crear un botón. Los botones son muy comunes en cualquier página web y sirven para que el usuario pueda realizar acciones en ella, como enviar el formulario, aplicar filtros, etc.

> ¡No uses un botón para crear enlaces! Para eso, usa la etiqueta `<a>`.

## Atributos de la etiqueta `<button>`
Algunos atributos importantes de la etiqueta `<button>` son:
- `type`: tipo de botón. Puede ser `submit`, `button`, `reset`.
- `disabled`: indica si el botón está deshabilitado.

## Ejemplo de uso
```html
<button type="submit">Enviar</button>
```

> `type="submit"` es el tipo de botón por defecto si es el último o único botón del formulario.

### Accesibilidad en botones
- **Botones con texto**: Siempre usa texto descriptivo en los botones. El texto debe indicar claramente qué acción realizará el botón:
```html
<button type="submit">Enviar formulario</button> <button type="button">Cancelar</button>
```
- **Botones con solo iconos**: Si un botón solo contiene un icono (SVG o imagen) sin texto visible, es esencial añadir un `aria-label` descriptivo:
```html
<button type="button" aria-label="Cerrar ventana">
  <svg width="24" height="24" aria-hidden="true">
    <!-- icono de X -->
  </svg>
</button>
```

> **Importante**: El texto del botón (o el `aria-label` si solo tiene icono) debe ser descriptivo. Evita textos genéricos como “Click aquí” o “Botón”. Los lectores de pantalla anuncian el texto del botón, así que debe tener sentido por sí solo.

---

# Sobre los `<svg>`
_SVG_ (Scalable Vector Graphics) es un formato de imagen vectorial que se usa mucho en la web. Una de sus ventajas es que son imágenes que se pueden escalar sin perder calidad, a diferencia de los formatos de imagen tradicionales como JPG o PNG.

Lo mejor de los SVG es que son código, por lo que podemos incluirlos directamente en nuestro HTML. [Esto es una página con mas de 2000 iconos SVG que se pueden usar gratis](https://tabler.io/icons)

Por ejemplo, el siguiente icono muestra un check verificado:
```html
<svg
  width="24"
  height="24"
  viewBox="0 0 24 24"
  stroke="currentColor"
  stroke-width="1"
  stroke-linecap="round"
  stroke-linejoin="round"
  fill="none"
>
  <path stroke="none" d="M0 0h24v24H0z" fill="none" />
  <path
    d="M5 7.2a2.2 2.2 0 0 1 2.2 -2.2h1a2.2 2.2 0 0 0 1.55 -.64l.7 -.7a2.2 2.2 0 0 1 3.12 0l.7 .7c.412 .41 .97 .64 1.55 .64h1a2.2 2.2 0 0 1 2.2 2.2v1c0 .58 .23 1.138 .64 1.55l.7 .7a2.2 2.2 0 0 1 0 3.12l-.7 .7a2.2 2.2 0 0 0 -.64 1.55v1a2.2 2.2 0 0 1 -2.2 2.2h-1a2.2 2.2 0 0 0 -1.55 .64l-.7 .7a2.2 2.2 0 0 1 -3.12 0l-.7 -.7a2.2 2.2 0 0 0 -1.55 -.64h-1a2.2 2.2 0 0 1 -2.2 -2.2v-1a2.2 2.2 0 0 0 -.64 -1.55l-.7 -.7a2.2 2.2 0 0 1 0 -3.12l.7 -.7a2.2 2.2 0 0 0 .64 -1.55v-1"
  />
  <path d="M9 12l2 2l4 -4" />
</svg>
```

Para dar una explicación rápida de los atributos más importantes:
- `width` y `height`: ancho y alto del SVG.
- `viewBox`: define el sistema de coordenadas del SVG.
- `stroke`: color del borde de las formas.
- `stroke-width`: grosor del borde de las formas.
- `stroke-linecap`: define la forma de los extremos de las líneas (puede ser `butt`, `round` o `square`).
- `stroke-linejoin`: define la forma de las uniones entre líneas (puede ser `arcs`, `bevel`, `miter`, `miter-clip` o `round`).
- `fill`: color de relleno de las formas.

Dentro tenemos más elementos HTML, como `<path>`, que define una forma a través de una serie de comandos en su atributo `d`.

Pero podríamos usar otros elementos como `<circle>`, `<rect>`, `<line>`, etc…

¡Podría estar horas hablando de SVG! Así que, si quieres aprender más sobre SVG, puedes echar un vistazo a la [documentación de MDN](https://developer.mozilla.org/es/docs/Web/SVG).

## Accesibilidad en SVG
Cuando uses SVG como iconos o elementos decorativos, es importante considerar la accesibilidad:
- **SVG decorativo**: Si el SVG es puramente decorativo y no añade información, usa `aria-hidden="true"` para ocultarlo de los lectores de pantalla:
```html
<svg aria-hidden="true" width="24" height="24">
  <!-- contenido del SVG -->
</svg>
```
- **SVG con significado**: Si el SVG transmite información importante (como un icono de alerta o un botón), añade un `aria-label` descriptivo:
```html
<button aria-label="Cerrar ventana">
  <svg width="24" height="24">
    <!-- icono de X -->
  </svg>
</button>
```
- O si el SVG está directamente en la página y tiene significado:
```html
<svg aria-label="Gráfico de ventas del mes" role="img" width="400" height="300">
  <!-- contenido del gráfico -->
</svg>
```

---

# Listas
```html
<ul>
	<li class="list-item">primer item</li>
	<li class="list-item">segundo item</li>
	<li class="list-item">tercer item</li>
</ul>
```
> [!note]+
> TODOS los elementos pueden tener `class` e `id` para referirnos a ellos, la diferencia es que la `class` de puede repetir y el `id` debe ser único.