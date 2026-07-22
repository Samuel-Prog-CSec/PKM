---
tags:
  - Web/Red-Team
  - Server-Side/Prototype-Pollution
  - Pentesting/Explotacion
Fecha de actualización: 2026-07-17
Nota previa: ""
Nota siguiente: "[[01 - Prototype Pollution server-side]]"
Area: "[[Prototype Pollution.base|Prototype Pollution]]"
---
---

En JavaScript casi todos los objetos heredan de `Object.prototype`. <mark style="background: #ADCCFFA6;">La `prototype pollution` es la técnica que abusa de esa herencia: si el atacante consigue escribir una propiedad en `Object.prototype`, **todos** los objetos del programa la heredan</mark> —incluidos los que el código da por vacíos o de confianza—. No es un fin en sí misma, sino un <mark style="background: #FFB86CA6;">primitivo</mark>: su impacto depende de qué haga la aplicación con esa propiedad envenenada.

Se volvió un vector de primera línea porque la web moderna vive de mezclar objetos: opciones de configuración, cuerpos JSON de APIs, *merges* de estado en frameworks. Cada uno de esos puntos es un candidato.

# El modelo de prototipos

Cada objeto tiene un enlace interno a su prototipo, accesible de forma legada por la propiedad `__proto__`. Ese prototipo es un objeto **compartido**: `({}).__proto__ === Object.prototype`. Escribir en él contamina a toda instancia, presente y futura:

```javascript
({}).polluted            // undefined
Object.prototype.polluted = "yes"
({}).polluted            // "yes"  — cualquier objeto {} lo hereda ahora
```

Las tres claves mágicas que dan acceso al prototipo desde una cadena controlada por el usuario son `__proto__`, `constructor` y `prototype` (`obj.constructor.prototype === Object.prototype`).

# Anatomía universal: source → contaminación → gadget

Toda explotación de PP encadena tres piezas, idénticas en cliente y servidor:

1. **Source**: un punto donde la entrada del usuario se escribe en una propiedad cuyo *nombre* también controla, usando `__proto__`/`constructor`/`prototype`. En la práctica: <mark style="background: #FFB8EBA6;">funciones de *merge*/clonado recursivo inseguras</mark> (`lodash.merge`/`defaultsDeep`, `$.extend(true, …)`, un `Object.assign` profundo casero) o el parseo de query-string y cuerpos JSON a objeto.
2. **Contaminación**: la escritura acaba en `Object.prototype`, afectando a toda la aplicación.
3. **Gadget**: código legítimo que **lee** una propiedad no inicializada del objeto contaminado y la pasa a un *sink* peligroso.

```javascript
merge({}, JSON.parse('{"__proto__":{"polluted":"yes"}}'));
({}).polluted   // "yes"
```

<mark style="background: #FF5582A6;">El reto rara vez es contaminar; es encontrar el gadget</mark> que convierte la propiedad heredada en un efecto útil.

# Dos ramas, dos impactos

Aquí se bifurca la familia. Aunque el *source* y la contaminación son iguales, el *sink* —y por tanto el impacto— cambia por completo según dónde se ejecute el JavaScript:

| | Client-side | Server-side (Node.js) |
| - | - | - |
| Dónde corre | Navegador de la víctima | Proceso Node del servidor |
| Sink típico | `innerHTML`, `script.src`, `eval` | Config de la app, `child_process`, motor de plantillas |
| Impacto | [[09 - Prototype Pollution hacia XSS\|XSS]] | Bypass de autorización, DoS, [[02 - Gadgets y RCE server-side\|RCE]] |
| Contaminación | Por petición (una recarga la limpia) | Persistente en el proceso |
| Detección | DOM Invader (Burp) | Gadgets seguros / scanner dedicado |

La rama **client-side** desemboca casi siempre en XSS y se trata en [[09 - Prototype Pollution hacia XSS]]. La rama **server-side** —el foco de este sub-tema— es más peligrosa: <mark style="background: #8000E1A6;">la contaminación persiste durante toda la vida del proceso Node</mark>, así que afecta a cada petición de cada usuario, y el abanico de gadgets llega hasta la ejecución remota de código.

> [!warning]+ La PP no es su propio impacto
> Encontrar `({}).polluted` reflejado solo prueba que **puedes** contaminar. El valor está en mapear **todos** los gadgets disponibles: la misma primitiva se queda en un bypass de lógica o escala a RCE según la librería que lea la propiedad. Nunca reportes "prototype pollution" a secas —reporta el gadget concreto y su impacto—.

# Por dónde seguir

- [[01 - Prototype Pollution server-side]] — cómo surge en Node.js, por qué es más grave, y detección por reflexión.
- [[02 - Gadgets y RCE server-side]] — de contaminar a ejecutar comandos.
- [[03 - Detección, herramientas y prevención]] — detección a ciegas sin reflexión, tooling y defensa.

> [!info]+ Fuentes
> - [PortSwigger — Prototype pollution](https://portswigger.net/web-security/prototype-pollution)
> - Para la salida a XSS en el navegador: [[09 - Prototype Pollution hacia XSS]] (rama client-side, dentro de XSS avanzado).
