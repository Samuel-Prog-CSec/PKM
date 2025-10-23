---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Introduccion
Fecha de actualización: 2025-10-16
Nota previa:
Nota siguiente: "[[XSS Almacenado]]"
Area: "[[Web Pentesting.base|Web Pentesting]]"
---
---

Una aplicación web típica funciona recibiendo el código HTML del servidor back-end y representándolo en el navegador del lado del cliente. Cuando una **aplicación web vulnerable no desinfecta adecuadamente la entrada del usuario**, un usuario malintencionado puede <mark style="background: #ADCCFFA6;">inyectar código JavaScript adicional en un campo de entrada</mark> (por ejemplo, comentario/respuesta), de modo que una vez que otro usuario ve la misma página, <mark style="background: #FFB86CA6;">ejecuta sin saberlo el código JavaScript malicioso</mark>.

Las vulnerabilidades [XSS](https://owasp.org/www-community/attacks/xss/) se ejecutan únicamente en el lado del cliente y, por lo tanto, **no afectan directamente al servidor back-end**. Sólo pueden afectar al usuario que ejecuta la vulnerabilidad. El impacto directo de las vulnerabilidades XSS en el servidor back-end puede ser relativamente bajo, pero<mark style="background: #FFB8EBA6;"> se encuentran muy comúnmente en aplicaciones web</mark>, por lo que esto equivale a un <mark style="background: #ADCCFFA6;">riesgo medio</mark> (`low impact + high probability = medium risk`), lo cual siempre debemos intentar `reducir` el riesgo al detectar, remediar y prevenir proactivamente este tipo de vulnerabilidades.
![Matriz de riesgo con ejes: Probabilidad (bajo a alto) e Impacto (bajo a alto), mostrando estrategias: Reducir, Evitar, Aceptar, Transferir.](https://academy.hackthebox.com/storage/modules/103/xss_risk_chart_1.jpg)

---

# Tipos de XSS
Hay tres <mark style="background: #FFB8EBA6;">tipos principales de vulnerabilidades XSS</mark>:

| Tipo               | Descripción                                                                                                                                                                                                                                                                                                                                    |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [[XSS Reflejado]]  | El tipo **más crítico de XSS**, que ocurre <mark style="background: #FFB86CA6;">cuando la entrada del usuario se almacena en la base de datos back-end y luego se muestra al recuperarla</mark> (por ejemplo, publicaciones o comentarios)                                                                                                     |
| [[XSS Almacenado]] | Ocurre <mark style="background: #FFB86CA6;">cuando la entrada del usuario se muestra en la página después de ser procesada por el servidor backend</mark>, pero <mark style="background: #FFB8EBA6;">sin almacenarse</mark> (por ejemplo, resultado de búsqueda o mensaje de error)                                                            |
| [[DOM-Based]]      | Otro tipo de **XSS no persistente** que ocurre <mark style="background: #FFB8EBA6;">cuando la entrada del usuario se muestra directamente en el navegador y se procesa completamente en el lado del cliente</mark>, sin llegar al servidor back-end (por ejemplo, a través de parámetros [[HTTP]] del lado del cliente o etiquetas de anclaje) |

