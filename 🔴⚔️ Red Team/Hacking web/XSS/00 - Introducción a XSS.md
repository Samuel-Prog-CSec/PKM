---
tags:
  - Web/Red-Team
  - Pentesting
  - Pentesting/Explotacion
  - XSS
  - Introduccion
Fecha de actualización: 2026-06-02
Nota previa:
Nota siguiente: "[[01 - XSS Almacenado]]"
Area: "[[XSS.base|XSS]]"
---
---

<mark style="background: #ADCCFFA6;">El `Cross-Site Scripting` (XSS) explota un fallo en la sanitización de la entrada del usuario para "escribir" código JavaScript en la página y ejecutarlo en el lado cliente</mark>. Una web normal recibe el HTML del servidor y lo renderiza en el navegador; si la app no sanea la entrada, un atacante inyecta JS extra en un campo (un comentario, un nombre) y, cuando otro usuario carga esa página, ejecuta el código malicioso sin saberlo.

# El riesgo: cliente, no servidor

<mark style="background: #FFB8EBA6;">XSS se ejecuta **solo en el cliente** y no afecta directamente al servidor back-end</mark> — solo al usuario que dispara la vulnerabilidad. Por eso HTB lo clasifica como riesgo medio: poco impacto directo pero altísima probabilidad (`bajo impacto + alta probabilidad = riesgo medio`).

![Matriz de riesgo: probabilidad × impacto, con las estrategias Reduce / Avoid / Accept / Transfer](https://academy.hackthebox.com/storage/modules/103/xss_risk_chart_1.jpg)

> [!warning]+ El "impacto bajo" es una visión anticuada
> Esa clasificación de riesgo medio se queda corta en aplicaciones modernas. <mark style="background: #FF5582A6;">Hoy un XSS suele escalar a *Account Takeover* completo</mark>: con SPAs que guardan tokens `JWT` en `localStorage`, robar ese token equivale a tomar la cuenta; un XSS también permite saltarse protecciones `CSRF`, exfiltrar datos de la API en nombre de la víctima o realizar acciones privilegiadas. En bug bounty, un XSS bien orientado se paga como *high/critical*, no como medio.

# Qué permite un XSS

Cualquier cosa ejecutable con JavaScript en el navegador de la víctima:

- Enviar la **cookie de sesión** al servidor del atacante (robo de sesión).
- Lanzar **llamadas a la API** que ejecuten acciones maliciosas (cambiar la contraseña del usuario).
- Inyectar formularios de **phishing**, *defacing*, minado, etc.

Tiene límites: <mark style="background: #FFB8EBA6;">se ejecuta dentro del motor JS del navegador (V8 en Chrome) y, en navegadores modernos, confinado al mismo dominio de la web vulnerable</mark>. No da ejecución a nivel de sistema por sí solo. Pero <mark style="background: #FFB86CA6;">si se encadena con un fallo binario del navegador (un *heap overflow* en Chrome), un XSS puede servir el exploit que rompe el *sandbox* y ejecuta código en la máquina</mark>.

> [!info]+ XSS lleva dos décadas haciendo estragos
> El [Samy Worm](https://en.wikipedia.org/wiki/Samy_(computer_worm)) (MySpace, 2005) fue un XSS almacenado que se auto-replicaba: en un día infectó más de un millón de perfiles. En 2014, un XSS en TweetDeck creó un tuit que se auto-retuiteaba, alcanzando 38.000 retweets en dos minutos y forzando a Twitter a apagar el servicio. Hasta Google y Apache han tenido XSS explotados activamente. No es una vulnerabilidad "menor".

# Los tres tipos de XSS

| Tipo | Descripción |
| - | - |
| `Stored` (Persistente) | El más crítico. La entrada se **guarda** en la BD del back-end y se muestra al recuperarla (posts, comentarios) → afecta a todo el que visite la página |
| `Reflected` (No persistente) | La entrada se refleja en la página tras procesarla el servidor, **sin guardarla** (resultado de búsqueda, mensaje de error) |
| `DOM-based` | No persistente y **100% cliente**: la entrada se procesa en el navegador sin llegar al back-end (parámetros HTTP del lado cliente, *anchors*) |

Cada tipo tiene su forma de descubrirse y explotarse. Empezamos por el más crítico: [[01 - XSS Almacenado]].
