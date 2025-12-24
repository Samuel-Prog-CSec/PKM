---
tags:
Fecha de actualización:
Nota previa:
Nota siguiente:
Area:
---
---

# La etiqueta `<main>`
La etiqueta `<main>` es la etiqueta que se utiliza para el contenido principal de la página. Es importante que solo haya un `<main>` por página y que no contenga contenido que se repita (como navegación, pie de página, cabecera de la página, etc).
```html
<header>La cabecera de la página</header>

<main>Contenido principal de nuestra página...</main>
```

> **Nota sobre accesibilidad**: El elemento `<main>` es un landmark semántico que ayuda a los lectores de pantalla a identificar y navegar directamente al contenido principal de la página. Los usuarios pueden saltar la navegación y otros elementos repetitivos yendo directamente al `<main>`. Por eso es importante que solo haya un `<main>` por página y que contenga el contenido único y principal.

---

# La etiqueta `<section>`
Dentro de nuestra página, tendremos siempre secciones con la información relacionada. Por ejemplo, en nuestra página de empleos, tendremos una sección con un formulario de búsqueda, otra sección con las características del servicio, etc.
```html
<main>
  <section>
    <h2>Sección de búsqueda</h2>
    Aquí irá el formulario de búsqueda
  </section>

  <section>
    <h2>Sección de características</h2>
    Aquí irán las características del servicio
  </section>

  <section>
    <h2>Sección de contacto</h2>
    Aquí irá el formulario de contacto
  </section>
</main>
```

> **Nota sobre accesibilidad**: Cada `<section>` debe tener un heading (h2, h3, etc.) que identifique su propósito. Esto ayuda a los lectores de pantalla a navegar por las diferentes secciones de la página. No uses `<section>` solo para estilizar; úsalo cuando el contenido tenga un propósito temático claro y distinto.

Ahora que ya sabemos esto, vamos a empezar a crear la sección más importante de nuestra página principal: la sección hero. El _hero_ normalmente es la primera sección de la página y es la que más destaca visualmente, además que suele tener un título y un botón de llamada a la acción o un formulario para que el usuario haga algo.

---

# La etiqueta `<img>`
La etiqueta `<img>` es la etiqueta que se utiliza para agregar imágenes a tu página web.

## Atributos de la etiqueta `<img>`
Algunos atributos importantes de la etiqueta `<img>` son:
- `src`: de dónde viene la imagen. Puede ser una ruta local o una URL.
- `alt`: texto alternativo para accesibilidad, SEO y si la imagen no carga
- `width/height`: dimensiones en píxeles para que el navegador reserve espacio

## Ejemplo de uso
```html
<img src="https://dominio.com/imagen.png" alt="Descripción de la imagen" width="200" height="200" />
```
Como ves, la etiqueta `<img>` es una etiqueta autocerrante. Esto quiere decir que no envuelve contenido interno como los elementos que vimos en la clase anterior.
> [!tip]+
> Podemos usar el atributo `hidden` para controlar la visibilidad de la imagen, como un booleano, implica que si esta presente ya está a true y si no esta, se supone a false. No se necesario hacer `hidden="true"`, con escribir `hidden` ya se supone que es true.

### Sobre el atributo `alt`
El atributo `alt` es **obligatorio** y tiene múltiples propósitos importantes:
1. **Accesibilidad**: Los lectores de pantalla leen el texto `alt` para describir la imagen a usuarios con discapacidad visual.
2. **SEO**: Los motores de búsqueda usan el `alt` para entender el contenido de la imagen.
3. **Fallback**: Si la imagen no carga, se muestra el texto `alt` en su lugar.

#### Buenas prácticas para escribir textos `alt`
- **Imágenes informativas**: Describe lo que muestra la imagen de forma concisa y específica:
```html
    <img
      src="grafico-ventas.png"
      alt="Gráfico de barras mostrando un aumento del 25% en ventas durante el último trimestre"
    />
 ```
- **Imágenes decorativas**: Si la imagen es puramente decorativa y no añade información, usa un `alt` vacío:
```html
<img src="patron-fondo.png" alt="" />
```
- **Evita textos genéricos**: No uses textos como “imagen”, “foto” o “gráfico” sin más contexto. Los lectores de pantalla ya anuncian que es una imagen.
- **No repitas información**: Si el texto `alt` repite información que ya está en el texto cercano, puedes usar un `alt` más corto o vacío si es decorativa.

> **Importante**: El atributo `alt` siempre debe estar presente, incluso si está vacío (`alt=""`). Nunca omitas el atributo `alt`.

No es la única etiqueta autocerrante. Hay otras como `<br>`, `<input>`, `<hr>`, etc.

> ¡Ojo! En nuestra página ahora vamos a usar esta etiqueta `<img>` para agregar la imagen de fondo de la sección hero pero más adelante veremos que lo más recomendable es usar CSS. Más adelante entenderás cuándo usar cada una de ellas.