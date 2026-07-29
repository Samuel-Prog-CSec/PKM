---
tags:
  - Biblioteca
  - Web
Fecha de actualización: 2026-07-22
Autores:
  - Michal Zalewski
Editorial: No Starch Press
Año: 2012
ISBN: 978-1-59327-388-0
Portada: https://covers.openlibrary.org/b/isbn/9781593273880-L.jpg
PDF: "[[thetangledweb.pdf]]"
Estado: Aceptada
Rating:
Area: "[[Librería.base|Librería]]"
---
# The Tangled Web

![Portada de The Tangled Web](https://covers.openlibrary.org/b/isbn/9781593273880-L.jpg)

**A Guide to Securing Modern Web Applications** — de Michal Zalewski (`lcamtuf`), investigador de seguridad de navegadores en Google y autor de *Silence on the Wire* y del *Browser Security Handbook*.

## Sinopsis

La pila de tecnologías web (`URL`, `HTTP`, `HTML`, `CSS`, scripts de navegador, tipos de documento no-HTML, plugins) no se diseñó como sistema coherente: se fue apilando durante 20 años a base de parches, hacks de compatibilidad e implementaciones divergentes entre navegadores. Zalewski —descubridor de cientos de vulnerabilidades notables— diseca esa acumulación histórica capa por capa, explicando **por qué** cada pieza del stack se comporta como se comporta y qué asunciones de seguridad rotas hereda de la anterior.

La columna vertebral del libro es el modelo de seguridad del navegador: la `same-origin policy` y sus múltiples variantes según el contexto (`cookies`, DOM, `postMessage`, XMLHttpRequest, frames), herencia de origen, y los límites de seguridad que existen fuera de esas reglas (content-type sniffing, gestión de scripts maliciosos, privilegios extrínsecos de ciertos sitios). Cada capítulo cierra con un "Security Engineering Cheat Sheet" — una tabla de referencia rápida pensada para consultarse durante el desarrollo, no solo para leerse una vez.

<mark style="background: #FFB8EBA6;">Publicado en 2012</mark>, con el know-how de Zalewski sigue siendo la explicación de referencia del modelo de seguridad del navegador, pero varias piezas que trata como "emergentes" (`Content Security Policy`, `HSTS`, `CORS`) llevan años siendo estándares consolidados, y el libro no cubre APIs posteriores (`Fetch`, `Service Workers`, `Permissions Policy`) ni ataques modernos derivados de ellas. Útil como fundamento, no como referencia de superficie de ataque actual — para eso hace falta complementar con material más reciente (PortSwigger Web Security Academy, HTML Living Standard).

## Qué cubre el libro

- Anatomía completa del stack web: parsing de `URL`, `HTTP`, `HTML`, `CSS`, scripts de navegador, tipos de documento no-HTML y plugins de renderizado.
- Lógica de aislamiento de contenido y herencia de origen entre documentos, frames y ventanas.
- Variantes de la `same-origin policy` según el mecanismo (cookies, DOM, postMessage, XHR).
- Límites de seguridad fuera de las reglas de origen: privilegios extrínsecos de sitio, mecanismos de reconocimiento de contenido.
- Gestión de scripts maliciosos y mitigaciones del navegador ante ellos.
- Funciones de seguridad emergentes en su momento (CSP, HSTS, CORS) y su evolución posterior.
- "Security Engineering Cheat Sheets" al final de cada capítulo como referencia rápida.
- Panorama de vulnerabilidades web comunes desde la perspectiva del propio navegador.

## Enlace

[[thetangledweb.pdf|Abrir PDF]]

## Notas propias

