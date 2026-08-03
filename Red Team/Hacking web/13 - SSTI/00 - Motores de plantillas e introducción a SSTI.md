---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Server-Side/SSTI
  - Tipo/Introduccion
Descripción: "Un motor de plantillas (*template engine*) es software que combina plantillas predefinidas con datos generados dinámicamente para producir una respuesta —típicamente HTML—"
Fecha de actualización: 2026-06-22
Nota previa: ""
Nota siguiente: "[[01 - Identificación de SSTI]]"
Area: "[[SSTI.base|SSTI]]"
---
---

Un **motor de plantillas** (*template engine*) es software que combina plantillas predefinidas con datos generados dinámicamente para producir una respuesta —típicamente HTML—. Es lo que permite a una web compartir cabecera y pie en todas sus páginas mientras cambia el contenido central, evitando duplicar código. Ejemplos populares: [Jinja](https://jinja.palletsprojects.com/) (Python) y [Twig](https://twig.symfony.com/) (PHP). <mark style="background: #ADCCFFA6;">Cuando un atacante consigue inyectar código de plantilla que el servidor renderiza, ocurre una `Server-Side Template Injection` (SSTI)</mark> — y eso suele acabar en RCE.

# Cómo funciona un motor de plantillas

El motor toma **dos entradas**: una **plantilla** (un string o fichero con huecos marcados) y un conjunto de **valores** (pares clave-valor). El proceso de combinarlos y producir el string final se llama **`rendering`**. En sintaxis Jinja, una plantilla con una variable:

```jinja2
Hello {{ name }}!
```

renderizada con `name="vautia"` produce `Hello vautia!`. Los motores modernos soportan además lógica de programación —condiciones, bucles—:

```jinja2
{% for name in names %}
Hello {{ name }}!
{% endfor %}
```

con `names=["vautia","21y4d","Pedant"]` genera una línea por elemento. La sintaxis exacta depende del motor, pero el modelo —plantilla + valores → render— es universal.

# De plantilla a vulnerabilidad: SSTI

La distinción que lo explica todo: <mark style="background: #FF5582A6;">los **valores** son seguros; la **plantilla** es código</mark>. El motor inserta los valores en sus huecos **sin ejecutarlos** —por eso pasar input de usuario como *valor* es seguro—. Pero si el input del usuario acaba formando parte del **string de plantilla**, el motor lo interpreta como código y lo ejecuta durante el render. Ahí nace la SSTI.

# Cómo aparece en el código

Tres patrones la provocan:

1. **Concatenar input en la plantilla antes de renderizar** —el error clásico—:

```python
# VULNERABLE: el nombre entra en el string de plantilla
render_template_string("<h1>Hello " + request.args.get('name') + "</h1>")
```

2. **Doble render**: la salida de un primer render se usa como plantilla de un segundo. Si el input se insertó como valor en el primero, en el segundo ya es parte de la plantilla.
3. **Plantillas editables por el usuario**: si la app deja modificar o subir plantillas (temas, plantillas de email/factura), la SSTI es casi inmediata.

> [!success]+ La forma segura
> Pasar el input **siempre como valor** a la función de render lo neutraliza: `render_template("page.html", name=user_input)`. El bug surge cuando el input toca el *string de plantilla*, no cuando se pasa como dato.

# Impacto: de fuga de datos a RCE

<mark style="background: #FFB86CA6;">La SSTI es una vulnerabilidad de clase RCE</mark>. Según el motor y el endurecimiento, escala desde fuga de información (config, claves, código fuente) y [[01 - Local File Inclusion (LFI)|lectura de ficheros]] hasta **ejecución remota de código** y el compromiso total del servidor —porque el atacante ejecuta código en el lenguaje del back-end (Python en Jinja, PHP en Twig)—.

# SSTI vs. XSS: no confundir

Ambas nacen de reflejar input, pero en lados distintos de la frontera. <mark style="background: #8000E1A6;">Si inyectas `{{7*7}}` y el servidor devuelve `49`, es **SSTI** (se evaluó en el servidor)</mark>; si devuelve el literal `{{7*7}}` que luego ejecuta JavaScript en el navegador, es [[00 - Introducción a XSS|XSS]] (client-side). El `49` es la firma de que hay un motor de plantillas evaluando tu entrada.

# Cómo se organiza el sub-tema

El flujo de un ataque SSTI estructura las notas:

1. [[01 - Identificación de SSTI|Identificación]]: confirmar la inyección y **averiguar qué motor** se usa (cada uno tiene su sintaxis).
2. [[02 - Explotación de SSTI - Jinja2|Jinja2]] (Python) y [[03 - Explotación de SSTI - Twig|Twig]] (PHP): explotación por motor.
3. [[04 - Evasión de filtros y sandbox en SSTI|Evasión]]: sortear sandboxes y filtros de caracteres.
4. [[05 - Prevención de SSTI|Prevención]] y [[06 - Arsenal de herramientas SSTI|arsenal]].

> [!info]+ Fuentes
> - [OWASP WSTG — Testing for SSTI](https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/07-Input_Validation_Testing/18-Testing_for_Server_Side_Template_Injection) · [PortSwigger — SSTI](https://portswigger.net/web-security/server-side-template-injection)
> - [Jinja](https://jinja.palletsprojects.com/) · [Twig](https://twig.symfony.com/) · [PayloadsAllTheThings — SSTI](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Server%20Side%20Template%20Injection)

Lo primero en un objetivo real es **confirmar la SSTI e identificar el motor** —el paso que decide qué payloads usar—: [[01 - Identificación de SSTI]].
