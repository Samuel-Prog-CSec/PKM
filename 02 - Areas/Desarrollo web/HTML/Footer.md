---
tags:
Fecha de actualización:
Nota previa:
Nota siguiente:
Area:
---
---

La última sección de nuestra página es la sección de características donde mostramos características del servicio o producto que ofrecemos.
```html
<section>
  <header>
    <h2>¿Por qué DevJobs?</h2>
    <p>
      DevJobs es la principal bolsa de trabajo para desarrolladores. Conectamos a los
      desarrolladores con las mejores empresas del mundo.
    </p>
  </header>

  <footer>...</footer>
</section>
```

¡Eh! ¿Qué es esto? ¿Por qué tenemos un `<header>` y un `<footer>` dentro de una `<section>`?

Sí, como ves, podemos usar `<header>` y `<footer>` dentro de `<section>`. Esto es útil para estructurar mejor el contenido de nuestra página, ya que las secciones pueden tener un encabezado y un pie. A diferencia de `<main>`, que sólo puede existir un elemento en la página, las etiquetas `<header>` y `<footer>` pueden usarse dentro de otras etiquetas cuando tenga sentido.

---

# La etiqueta `<article>`
La etiqueta `<article>` es la etiqueta que se utiliza para crear un… ¿artículo? Bueno, no exactamente. En HTML un artículo se entiende como un contenido independiente y autónomo que puede ser reutilizado en otro sitio. Por ejemplo, un artículo de blog, un comentario, una tarjeta de producto, un tuit… NO significa siempre exactamente que tenga que ser literalmente un artículo de un periódico.
```html
<article>
  <h3>Característica 1</h3>
  <p>Descripción de la característica 1</p>
</article>

<article>
  <h3>Característica 2</h3>
  <p>Descripción de la característica 2</p>
</article>

<article>
  <h3>Característica 3</h3>
  <p>Descripción de la característica 3</p>
</article>
```
> [!important]+
> - ¡Sí! La etiqueta `<article>` también podría tener un `<header>` y un `<footer>` dentro.
> - También podemos incluir importancia dentro de los textos para resaltarlos (en un párrafo podemos destacar una parte), con la etiqueta `<strong>texto en negrita</strong>`.

---

# El pie de página
Finalmente, queremos que nuestra página web tenga un pie de página donde podamos poner información de contacto, enlaces a redes sociales, etc. En este caso vamos a poner simplemente un copyright.

```html
<footer>
  <small>© 2025 DevJobs. Todos los derechos reservados.</small>
</footer>
```

También tenemos la etiqueta `<small>` que se utiliza para poner texto de menor importancia que el contenido principal como anotaciones, comentarios legales, copyright, etc.

> ¡Sí! La etiqueta `<small>` suena a pequeño y es verdad que se renderiza por defecto con un tamaño de fuente más pequeño que el contenido principal. Pero siempre ten en cuenta que la idea de HTML es describir el contenido de la página, no su apariencia.

Bueno, por ahora nuestra página web se ve aburrida y con nada de estilo. **En la siguiente clase vamos a solucionar esto.**