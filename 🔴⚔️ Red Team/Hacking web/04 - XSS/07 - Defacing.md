---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
Descripción: "El ataque más simple sobre una XSS almacenada es el defacing. *Defacing* es cambiar el aspecto de una web para todo el que la visite"
Fecha de actualización: 2026-06-02
Nota previa: "[[06 - Herramientas para XSS]]"
Nota siguiente: "[[08 - Phishing]]"
Area: "[[XSS.base|XSS]]"
---
---

El ataque más simple sobre una [[01 - XSS Almacenado|XSS almacenada]] es el `defacing`. <mark style="background: #ADCCFFA6;">*Defacing* es cambiar el aspecto de una web para todo el que la visite</mark>. Es la firma típica de los grupos hacktivistas para reclamar un hackeo —como el *defacing* del NHS británico en 2018—; cuando le pasa a un banco o una tecnológica, el eco mediático puede afectar a su reputación y cotización.

# Elementos para el defacing

Con JavaScript inyectado podemos dar a la página el aspecto que queramos. Cuatro propiedades cubren casi todo:

| Elemento | Propiedad |
| - | - |
| Color de fondo | `document.body.style.background` |
| Imagen de fondo | `document.body.background` |
| Título de la página | `document.title` |
| Texto de la página | `DOM.innerHTML` |

# Los payloads

Cambiar el color de fondo (aquí, el fondo oscuro de HTB):

```html
<script>document.body.style.background = "#141d2b"</script>
```

Cambiar el título de la pestaña:

```html
<script>document.title = 'HackTheBox Academy'</script>
```

Para el mensaje, los grupos suelen reemplazar **todo** el `body`. Conviene preparar el HTML aparte, probarlo en local, minificarlo a una línea y meterlo en el payload:

```html
<script>document.getElementsByTagName('body')[0].innerHTML = '<center><h1 style="color: white">Cyber Security Training</h1></center>'</script>
```

`document.getElementsByTagName('body')[0]` selecciona el primer (y único) `body`, e `innerHTML` reescribe su contenido entero. Combinando los tres payloads, la página queda *defaced* para cualquier visitante. En el código fuente, el original sigue ahí y los payloads aparecen **al final** —porque el JS reescribe el aspecto al ejecutarse—; si la inyección estuviera en mitad del documento, habría que contar con los scripts que vienen después.

> [!important]+ Qué es realmente el defacing en un pentest
> El defacing tiene poco valor de negocio por sí mismo —más allá del daño reputacional, no roba nada—. <mark style="background: #8000E1A6;">Su utilidad real en una evaluación es como **prueba visual** del impacto</mark>: una captura de la web alterada demuestra de forma incontestable que puedes ejecutar JavaScript arbitrario en el navegador de **todos** los usuarios. <mark style="background: #FF5582A6;">Ese mismo primitivo —ejecución de JS arbitrario— es el que habilita los ataques serios</mark>: inyectar formularios de [[08 - Phishing|phishing]] o robar sesiones. El defacing es la demo suave; el payload de verdad viene después.

El primer ataque con impacto real es el phishing: inyectar un formulario de login falso para robar credenciales. Eso es [[08 - Phishing]].
