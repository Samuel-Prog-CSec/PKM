---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
Descripción: "Hay dos tipos de XSS no persistente: el Reflected, que procesa el servidor back-end, y el DOM-based, que se procesa entero en el cliente"
Fecha de actualización: 2026-06-02
Nota previa: "[[01 - XSS Almacenado]]"
Nota siguiente: "[[03 - XSS basado en DOM]]"
Area: "[[XSS.base|XSS]]"
---
---

Hay dos tipos de XSS **no persistente**: el `Reflected`, que procesa el servidor back-end, y el [[03 - XSS basado en DOM|DOM-based]], que se procesa entero en el cliente. <mark style="background: #FFB8EBA6;">Lo no persistente es temporal: no sobrevive a un refresco y solo afecta al usuario al que se dirige el ataque</mark>, no a todos los visitantes.

<mark style="background: #ADCCFFA6;">El `Reflected XSS` ocurre cuando nuestra entrada llega al servidor y vuelve reflejada sin filtrar ni sanear</mark>. Es típico en mensajes de error o confirmación que repiten la entrada del usuario.

# Identificarlo

Sobre una app que devuelve `Task 'test' could not be added.` —reflejando el `test` en el error—, probamos el payload:

```html
<script>alert(window.origin)</script>
```

El `alert` salta. En el código fuente se ve el payload insertado dentro del mensaje:

```html
<div style="padding-left:25px">Task '<script>alert(window.origin)</script>' could not be added.</div>
```

Si volvemos a visitar la página sin el payload, el error desaparece y nada se ejecuta: <mark style="background: #FFB8EBA6;">es no persistente</mark>.

# ¿Cómo se ataca a una víctima?

Aquí está la diferencia clave con el almacenado: si el payload no persiste, ¿cómo llega a la víctima? <mark style="background: #FFB86CA6;">Depende del método HTTP con que se envía la entrada</mark>. Lo compruebas en la pestaña **Network** de las DevTools (`CTRL+Shift+I`):

- **`GET`**: los parámetros viajan en la URL. <mark style="background: #FF5582A6;">Basta con enviar a la víctima una URL que contenga el payload</mark> — al visitarla, se ejecuta:
  ```
  http://target/index.php?task=<script>alert(window.origin)</script>
  ```
- **`POST`**: los datos van en el cuerpo, así que no puedes meterlos en una URL directamente. Se requiere un paso extra: una página del atacante con un formulario que se **auto-envía** por JavaScript al cargar (una técnica tipo `CSRF` para *entregar* el payload por POST). <mark style="background: #FFB8EBA6;">Gotcha moderno: las cookies `SameSite=Lax` (por defecto en Chrome) rompen muchos POST cross-site con sesión</mark>, lo que limita la entrega si la explotación depende de la cookie de la víctima.

> [!warning]+ El reflected vive de la ingeniería social
> A diferencia del almacenado —que dispara solo con visitar la página—, el reflected <mark style="background: #8000E1A6;">necesita que la víctima haga clic en tu enlace</mark>. En la práctica el payload se *URL-encodea* para que el enlace no levante sospechas, y a veces se oculta tras un acortador. La entrega es la mitad del ataque: un reflected XSS sin un vector de entrega creíble tiene impacto limitado, y por eso muchos programas lo pagan menos que un stored.
>
> **Excepción moderna**: si el reflejo se puede **cachear** ([[01 - Introducción a Web Cache Poisoning|web cache poisoning]]) o inyectar en la petición de otro usuario ([[06 - Introducción a HTTP Request Smuggling|request smuggling]]), el reflected se sirve a **todos** sin interacción — y entonces vale tanto como un stored. Incluso un reflected solo en una **cabecera** (inexplotable de forma clásica) se weaponiza así.

El tercer tipo ni siquiera llega al servidor: se procesa entero en el navegador. Es el [[03 - XSS basado en DOM]].
