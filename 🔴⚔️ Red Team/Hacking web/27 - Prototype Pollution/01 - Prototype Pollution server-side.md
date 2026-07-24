---
tags:
  - Web/Red-Team
  - Server-Side/Prototype-Pollution
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-17
Nota previa: "[[00 - Introducción a Prototype Pollution]]"
Nota siguiente: "[[02 - Gadgets y RCE server-side]]"
Area: "[[Prototype Pollution.base|Prototype Pollution]]"
---
---

La misma primitiva de [[00 - Introducción a Prototype Pollution|contaminar `Object.prototype`]], pero en el proceso Node del servidor. Cambia todo: el impacto sube (de XSS a RCE) y la dificultad de explotación también.

# Por qué el server-side es harina de otro costal

La PP client-side la depuras en el navegador: tienes DevTools, el bundle fuente y, en cada recarga, un `Object.prototype` limpio. En Node.js pierdes las tres cosas:

- **Sin acceso al código**: la lógica vive en el servidor; trabajas a ciegas (*black-box*).
- **Sin inspección en runtime**: no hay consola donde comprobar `({}).probe`.
- **Riesgo de DoS**: contaminar una propiedad que la app usa de verdad puede <mark style="background: #FFB86CA6;">romper la aplicación para todos los usuarios</mark>, sin forma de revertirlo salvo reiniciar el proceso.
- **Persistencia**: <mark style="background: #8000E1A6;">la contaminación dura toda la vida del proceso Node</mark>. No es por-petición como en el navegador —una vez escrita en `Object.prototype`, afecta a cada request de cada usuario hasta el próximo reinicio—.

Esa persistencia es un arma de doble filo: hace la PP server-side mucho más impactante (contaminas una vez, afecta a todos) pero también más peligrosa de probar en producción.

# Dónde surge en Node

El patrón es el de siempre —un *merge* recursivo de datos que controlas—, pero los *sources* típicos en backend son:

- <mark style="background: #FFB8EBA6;">Peticiones `POST`/`PUT` que envían JSON</mark> a una API: son el candidato principal. El cuerpo se parsea a objeto y a menudo se fusiona contra un objeto de configuración o de usuario.
- Funciones de *merge*/clonado inseguras: `lodash.merge`/`defaultsDeep`, `Object.assign` profundo casero, utilidades `extend`.
- Parseo de query-strings a objetos anidados (`foo[__proto__][bar]=x`).

```javascript
// Sink clásico: la app fusiona el cuerpo del usuario en un objeto de config/perfil
const user = {};
merge(user, req.body);   // req.body = {"__proto__":{"isAdmin":true}}
```

El mecanismo que lo hace explotable: <mark style="background: #ADCCFFA6;">un bucle `for...in` recorre **todas** las propiedades enumerables del objeto, incluidas las heredadas por la cadena de prototipos</mark>. Una propiedad inyectada en `Object.prototype` aparece, por tanto, en cualquier objeto que la aplicación itere o serialice.

# Detección por reflexión de propiedad

El caso más cómodo: la app serializa a JSON un objeto que recorre con `for...in`. Si inyectamos una propiedad por `__proto__`, aparece reflejada en la respuesta aunque nunca la enviáramos como campo propio:

```http
POST /user/update HTTP/1.1
Content-Type: application/json

{
  "user":"wiener",
  "__proto__":{"foo":"bar"}
}
```

Si es vulnerable, la respuesta incluye la propiedad heredada:

```json
{
  "username":"wiener",
  "foo":"bar"
}
```

<mark style="background: #FF5582A6;">Ver `"foo":"bar"` en la respuesta confirma la contaminación</mark> sin haber roto nada. El problema es que esta reflexión es rara: la mayoría de apps no devuelven un volcado del objeto contaminado. Cuando no la hay, se recurre a la detección a ciegas con gadgets seguros de [[03 - Detección, herramientas y prevención]].

# Impacto directo: property injection

Antes siquiera de pensar en RCE, la contaminación ya permite **inyectar propiedades** que la lógica de negocio lee sin validar:

- **Bypass de autorización** ([[06 - Introducción a IDOR|control de acceso]]): si un control comprueba `user.isAdmin` y el objeto no la define explícitamente, `__proto__.isAdmin = true` la vuelve heredada y verdadera para todos. Igual con `role`, `verified`, `canEdit`…
- **Alteración de comportamiento**: activar flags de debug, cambiar límites, saltarse validaciones que dependen de propiedades opcionales.
- **DoS**: contaminar con un tipo inesperado una propiedad que el framework usa internamente tumba la app.

De aquí, con el gadget adecuado, <mark style="background: #FFB86CA6;">se salta a ejecución remota de código</mark> —el impacto máximo, que cubre [[02 - Gadgets y RCE server-side]]—.

> [!warning]+ Riesgo real de DoS: no contamines a lo bruto en producción
> En un target real (bug bounty, pentest), inyectar `__proto__` con propiedades arbitrarias puede **romper la aplicación de forma persistente** hasta que reinicien el proceso, afectando a usuarios reales. La contaminación no se auto-revierte. Por eso la detección seria usa **gadgets no destructivos y reversibles** (`json spaces`, `status`), nunca escrituras a ciegas sobre propiedades de negocio. Ver [[03 - Detección, herramientas y prevención]].

> [!info]+ ¿Y `constructor.prototype`?
> Muchos filtros solo bloquean la cadena literal `__proto__`. La vía `constructor.prototype` llega al mismo `Object.prototype` y suele pasar: `{"constructor":{"prototype":{"foo":"bar"}}}`. Tenerla siempre como plan B (más en [[03 - Detección, herramientas y prevención]]).

Con la contaminación confirmada, el siguiente paso es convertirla en ejecución de comandos: [[02 - Gadgets y RCE server-side]].
