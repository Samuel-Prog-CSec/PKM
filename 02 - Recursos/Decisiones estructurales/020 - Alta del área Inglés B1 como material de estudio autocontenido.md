---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-08-03
Estado: Aceptada
---
---

## Contexto

El grado de Ingeniería Informática (UCLM) exige acreditar un **B1 de lengua extranjera** para expedir el título. Se necesitaba material de estudio propio, completo y **autocontenido**, para preparar el examen (referencia: Cambridge B1 Preliminary; válido también para Linguaskill/Aptis/EOI) sin depender de webs externas dispersas. El vault estaba enfocado 100 % a ciberseguridad, así que el idioma es un dominio nuevo dentro del PKM.

## Decisión

Crear un **área nueva de primer nivel `Inglés/`** (hermana de Red Team, Blue Team, Redes, Ingeniería), con la misma jerarquía `.base` de 3 niveles del vault (ADR 009):

- **Level 0** `Inglés.base` — panel del área.
- **Level 1** `Gramática.base` y **Level 2** por sub-tema (Tiempos verbales, Modales, Condicionales, Sustantivos/artículos/cuantificadores, Adjetivos/adverbios, Estructuras verbales, Oraciones, Preposiciones).
- **Level 2** directos para Vocabulario, Writing, Speaking, Reading y Listening, Recursos y práctica, y Guía y examen.

Convenciones: notas atómicas encadenadas (Zettelkasten `prev`/`next`) por sub-tema; **teoría en español, ejemplos en inglés**; glosario de colores y callouts estándar; **ejercicios variados con solución en callout desplegable** en cada nota de gramática/vocabulario, incluyendo casos atípicos, trampas de examen y fallos típicos. Familia de tags nueva `Ingles/…` (Gramatica, Vocabulario, Writing, Speaking, Reading, Listening, Examen, Recursos) + reutilización de `Tipo/Introduccion` y `Tipo/Arsenal`. Total inicial: **76 notas + 16 `.base`**.

## Alternativas descartadas

- **Colgarlo de `02 - Recursos/` o `Ingeniería/`** — el idioma no es un recurso auxiliar ni parte de la ingeniería; es un dominio de estudio con entidad propia y volumen suficiente para un área.
- **Un único documento largo (o el tracker HTML) como material** — no encaja con el PKM: se pierde la navegación por grafo, los `.base` y el repaso atómico. El tracker HTML se mantiene aparte como plan temporal; la teoría vive en notas.
- **Enlazar a webs externas para la teoría** — contradice el requisito explícito de autocontención; las webs quedan solo para ejercicios y simulacros (nota `Recursos y práctica`).
- **Tags con tilde (`Inglés/…`)** — se usa `Ingles/…` sin tilde para robustez, aunque la carpeta sí lleva tilde (`Inglés/`).

## Consecuencias

- El Level 0 `Inglés.base` filtra por `file.folder.startsWith("Inglés/")`; el Level 1 `Gramática.base` por `startsWith("Inglés/01 - Gramática/")`, lo que **autoexcluye** al propio índice (su carpeta no lleva la barra final). No se toca `CLAUDE.md` ni la Home/Temario (decisión del usuario: área aparte).
- Se introduce la familia de tags `Ingles/…`, primera taxonomía no-ciberseguridad del vault; futuras auditorías de tags deben contemplarla como legítima, no como huérfana.
- Los `.base` se crearon por fuera de Obsidian: requieren un **reload** de la app para indexar (los índices aparecen vacíos hasta recargar el caché de metadatos).
- Deuda menor asumida: parte del vocabulario se cubre "por lo más rentable"; la exhaustividad total queda delegada a la lista oficial de Cambridge, enlazada en la nota de método.
