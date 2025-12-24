---
tags:
  - Ingenieria
  - Introduccion
  - Web/Front-end
Fecha de actualización:
Nota previa:
Nota siguiente:
Area:
---
---

HTML, o **HyperText Markup Language**, no es un lenguaje de programación como `JavaScript`. Es un **lenguaje de marcado** que permite organizar y describir los diferentes elementos de una página web, como textos, imágenes, enlaces, listas y tablas. 

# Estructura Básica de un Documento HTML
Todo documento *HTML* sigue una estructura básica. Dos primeros elementos principales:
- **`<!DOCTYPE html>`:** esta declaración le dice al navegador que estamos usando la versión más reciente de *HTML* (**HTML5**). Siempre va al principio del documento.
- **`<html lang="es">`:** es el elemento raíz que engloba todo el contenido de la página. El atributo `lang="es"` indica que el idioma principal del contenido es el español.
> [!caution]+
> ¡La declaración `<!DOCTYPE html>` no es una etiqueta *HTML*! Es una declaración que le dice al navegador que estamos usando la versión más reciente.

---

# Primer documento HTML
Vamos a crear un archivo `index.html` con esta estructura para nuestro proyecto DevJobs. Aquí te dejo un ejemplo de cómo se vería una página básica. ¡Intenta replicarlo!
```html
<!DOCTYPE html>
<html lang="es"></html>
```

---

# ¿Cómo son los elementos en HTML?
Los elementos en *HTML* son las etiquetas que se utilizan para estructurar el contenido de la página. Se componen, normalmente, de una etiqueta de apertura y una etiqueta de cierre. Dentro de ellas, se encuentra el contenido del elemento.
```html
<p>Este es un párrafo</p>
```
> [!info]+
> En este ejemplo, la etiqueta `<p>` es el elemento que se utiliza para crear un párrafo.

Además los elementos pueden tener atributos. Los atributos son información adicional que se puede añadir a los elementos. En el siguiente ejemplo, el atributo `type` es el atributo que se utiliza para crear un botón del tipo “*submit*”. 
```html
<button type="submit">Este es un botón</button>
```

---

# La Estructura Básica de HTML
## La cabeza del documento: `<head>`
La etiqueta `<head>` es como el **cerebro** de tu documento HTML. Contiene información crucial que no es visible para el usuario, pero que es fundamental para el funcionamiento de la página.

> 💡 **Dato importante:** Si pones texto directamente en `<head>`, no aparecerá en la página. Su función es **describir** el documento, no mostrarlo.

### Elementos esenciales del `<head>`
#### 1. Codificación de caracteres
```html
<meta charset="UTF-8" />
```

**¿Para qué sirve?**
- Permite mostrar correctamente tildes, eñes, símbolos y emojis
- Sin esto verías caracteres extraños como `Ã±` en lugar de `ñ`

#### 2. Viewport para dispositivos móviles
```html
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
```

**¿Para qué sirve?**
- Hace que tu página se vea bien en móviles y tablets
- Es **fundamental** para el diseño responsive
- Le dice al navegador cómo escalar la página en diferentes pantallas

#### 3. Título de la página
```html
<title>DevJobs - Inicio</title>
```

**¿Para qué sirve?**

- Aparece en la pestaña del navegador
- Se muestra en los resultados de Google
- Debe ser descriptivo y único para cada página

#### 4. Descripción para buscadores
```html
<meta
  name="description"
  content="Encuentra las mejores ofertas de trabajo para desarrolladores en DevJobs."
/>
```

**¿Para qué sirve?**
- **SEO:** Google la usa en los resultados de búsqueda
- Aparece como el texto descriptivo debajo del título
- Debe ser atractiva y resumir el contenido de la página
> 🔍 **Ejemplo práctico:** Si buscas “midudev” en Google, la descripción que aparece debajo del título proviene de esta metaetiqueta.

#### 5. Favicon
Podemos indicar que logo queremos en la pestaña del buscador modificando el favicon.ico:
```html
<meta
  rel="icon"
  type="image/jpg"
  href="/images/icono.jpg
/>
```

## El cuerpo del documento: `<body>`
La etiqueta `<body>` es donde vive **todo el contenido visible** de tu página web. Es lo que los usuarios realmente ven e interactúan.

### ¿Qué va dentro de `<body>`?

| Tipo de contenido | Ejemplos                         |
| ----------------- | -------------------------------- |
| **Texto**         | Párrafos, títulos, listas        |
| **Multimedia**    | Imágenes, videos, audio          |
| **Interactivos**  | Formularios, botones, enlaces    |
| **Estructura**    | Navegación, secciones, artículos |

### Construcción del marcado
En `<body>` es donde construiremos toda la estructura de DevJobs:
- Header con navegación
- Secciones de contenido
- Formularios de búsqueda
- Listado de trabajos
- Footer

### Algunos elementos HTML explicados:
#### `<header>`
- Elemento **semántico** (tiene significado)
- Le dice al navegador: “esto es el encabezado”
- Puede haber varios headers en una página (uno principal y otros en secciones)
- NO confundir con `<head>` (que es metadatos, el que vimos antes)

#### Etiqueta *heading* `<h2>`
- Heading 2 (Encabezado de nivel 2)
- Los headings van del `<h1>` al `<h6>` (como los títulos en Word)
- Jerarquía: h1 > h2 > h3 > h4 > h5 > h6
- ¿Por qué h2 y no h1? Reservamos h1 para el título principal del contenido
> **Nota sobre accesibilidad**: Es crucial mantener una jerarquía correcta de headings (h1, h2, h3…) sin saltar niveles. Por ejemplo, no uses un `<h3>` directamente después de un `<h1>` sin tener un `<h2>` antes. Los lectores de pantalla usan los headings para navegar por la página, y una jerarquía incorrecta dificulta la navegación. Además, cada página debe tener un único `<h1>` que represente el título principal del contenido.

#### Etiqueta `<nav>`
- Navigation (navegación)
- Elemento semántico para menús de navegación
- Google y lectores de pantalla lo reconocen como navegación principal

#### Etiqueta *anchor* `<a href="...">`
- Anchor (ancla) - crea un enlace
- **href** = hypertext reference (referencia de hipertexto)
- Tipos de valores para href:
    - `href="/"` = página principal (home)
    - `href="/empleos"` = ruta relativa
    - `href="https://google.com"` = URL completa
    - `href="#"` = placeholder (no lleva a ningún lado, temporal)
    - `href="#seccion"` = ancla a una sección de la misma página
El elemento `<a>` es uno de los más importantes en HTML, porque nos permite crear enlaces a otras páginas o a secciones de la misma página. Es la base de la navegación en la web.

#### Etiqueta `<div>`
- Division (división)
- Es un contenedor genérico SIN significado semántico
- Se usa para agrupar elementos cuando no hay un elemento semántico apropiado
- Es como una caja invisible para organizar

El elemento `<div>` es un elemento muy popular, ya que nos permite agrupar elementos… sólo hay que tener cuidado de no usarlo cuando haya un mejor elemento semántico para el contenido que estamos creando.

---

# Estructura completa básica
```html
<!DOCTYPE html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <title>DevJobs - Inicio</title>
    <meta
      name="description"
      content="Encuentra las mejores ofertas de trabajo para desarrolladores en DevJobs."
    />
  </head>
  <body>
	<header>
	    <h2>DevJobs</h2>
	    
	    <nav>
	      <a href="#">Inicio</a>
	      <a href="#">Empleos</a>
	    </nav>
	    
	    <div>
	      <a href="#">Publicar un empleo</a>
	      <a href="#">Iniciar sesión</a>
		</div>
	</header>
  </body>
</html>
```

---

# Sobre el atributo `lang`
El atributo `lang="es"` en la etiqueta `<html>` es importante por varias razones:
- **Accesibilidad**: Los lectores de pantalla usan el valor de `lang` para pronunciar correctamente el contenido según el idioma. Sin este atributo, un lector de pantalla podría pronunciar palabras en español con acento inglés, por ejemplo.
- **SEO**: Los motores de búsqueda usan `lang` para entender el idioma del contenido y mostrar tu página a usuarios que buscan en ese idioma.
- **Navegadores**: Algunos navegadores pueden ofrecer traducción automática basándose en el atributo `lang`.

**Ejemplos de valores comunes:**
- `lang="es"` - Español
- `lang="en"` - Inglés
- `lang="fr"` - Francés
- `lang="pt"` - Portugués

> **Importante**: Si tienes contenido en diferentes idiomas dentro de la misma página, puedes usar `lang` en elementos específicos: `<p lang="en">Hello world</p>` dentro de una página en español.
