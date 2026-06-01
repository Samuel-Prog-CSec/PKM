---
tags:
  - SIE
  - SIE/Temporal
Fecha de actualización: 2026-05-31
Nota previa: ""
Nota siguiente: ""
---
---

> [!danger]+ Nota temporal — BORRAR antes del examen
> Esto es un plan de estudio privado, **no forma parte del cuerpo de apuntes**. No está en la cadena Zettelkasten ni en la MOC a propósito. Bórrala cuando ya no la necesites.

# Plan de lectura — 3 días para el examen SIEA

**Examen: miércoles 3-jun-2026** · 2,5 h · 4 ejercicios · BD nueva `junio26` con datos demo.
Tienes **hoy + 2 días**. El plan es de **solo lectura** (tu decisión): lees soluciones resueltas y entiendes cómo se hacen; no memorizas y llevas las notas al examen.

> [!info]+ Sobre los "ensayos"
> Elegiste no practicar a teclado. Las soluciones de las notas están **resueltas**, y el módulo está **verificado contra la del profesor**. Lo único que la lectura no de-riesga del todo son los *gotchas* de entorno (que Odoo esté levantado, el valor de la **master password**, el **modo desarrollador**) — todos están en el pre-vuelo del [[22 - Cheatsheet de examen (chuleta operativa)#Antes de empezar — pre-vuelo (5 min)]]. Si quieres, **pídeme a mí** que ejecute en vivo cualquiera de los dos scripts o que monte el módulo y te pase las capturas/validación.

## Mapa rápido: qué ejercicio se apoya en qué nota

| Ejercicio | Notas clave |
| - | - |
| Ej. 1 — Uso de Odoo (compra) | [[05 - Administración funcional]], [[06 - Operativa compra-venta]] |
| Ej. 2 — Python: gestión de BD | [[07 - Servicios web XML-RPC]] (sección copia/renombrado), [[01 - Python para Odoo]] |
| Ej. 3 — Python: listado `purchase.order` | [[07 - Servicios web XML-RPC]] (sección 4 columnas), [[01 - Python para Odoo]] |
| Ej. 4 — Módulo Odoo (vale 4 pts) | [[08 - Estructura de un módulo y scaffold]]→[[14 - Seguridad y datos demo]], [[15 - Campos computados y onchange]] (constraint), [[18 - Filmoteca paso a paso]], [[19 - Variantes y práctica]], [[21 - Ejercicio de práctica - Biblioteca (resuelto)]] |

---

## Día 1 — hoy (31-may): el módulo (Ej. 4) + base Python

El ejercicio que más vale (4 pts) y el que más cuesta interiorizar. Hoy te quedas con el **patrón maestro–detalle–contactos** y el flujo de creación de un módulo.

1. [[01 - Python para Odoo]] — entero. Quédate con "clase = modelo" y la **nueva sección de scripting** (te sirve para Ej. 2/3). Ojea [[02 - Ejercicios Python resueltos]] por encima.
2. (Muy por encima) [[03 - Docker para Odoo]] y [[04 - Instalación con Docker]] — solo para saber levantar Odoo y dónde van los `addons`.
3. Arco de desarrollo, en orden: [[08 - Estructura de un módulo y scaffold]] → [[09 - Modelos y tipos de campo]] → [[10 - Relaciones entre modelos]] → [[12 - Vistas XML]] → [[13 - Acciones y menús]] → [[14 - Seguridad y datos demo]].
4. [[17 - Cómo programa el profesor (estilo y buenas prácticas)]] — convenciones a imitar.
5. **[[18 - Filmoteca paso a paso]]** — la resolución completa. **Lo más importante del día.**

**Meta del día:** "veo que el examen 'Ajedrez' es Filmoteca con otros nombres + un límite de contrincantes".

## Día 2 — (1-jun): cerrar Ej. 4 + Ej. 1 (uso de Odoo)

1. [[15 - Campos computados y onchange#Validar un máximo (máx. 2 contrincantes)]] — el **constraint** del Ej. 4 (las dos variantes: `onchange` con el modal del enunciado y `constrains` duro).
2. [[19 - Variantes y práctica]] — el patrón general + **checklist anti-error**.
3. [[21 - Ejercicio de práctica - Biblioteca (resuelto)]] — lee la solución completa de otro dominio (refuerza que el patrón es mecánico).
4. [[20 - Estrategia de examen y autoevaluación]] — táctica del día y test de autoevaluación (contéstate mentalmente).
5. Ej. 1: [[05 - Administración funcional#Instalación de apps]] + **[[06 - Operativa compra-venta#Flujo de compra (reproducible)]]** y [[06 - Operativa compra-venta#Stock: on hand vs. forecasted]].

**Meta del día:** reconoces el patrón bajo cualquier enunciado y tienes claro el flujo de compra y el stock real/virtual.

## Día 3 — (2-jun): Python API (Ej. 2 y 3) + cheatsheet + repaso

1. **[[07 - Servicios web XML-RPC]]** — entera, con foco en las dos secciones nuevas:
   - [[07 - Servicios web XML-RPC#Ejercicio tipo examen — órdenes de compra en 4 columnas]] (Ej. 3) → **el gotcha del Many2one `partner_id[1]`**.
   - [[07 - Servicios web XML-RPC#Ejercicio tipo examen — copia y renombrado de BD con confirmación]] (Ej. 2) → **master password**.
2. **[[22 - Cheatsheet de examen (chuleta operativa)]]** — léelo entero. Es tu mapa el día del examen; tenlo abierto.
3. Repaso de puntos flojos con la autoevaluación de [[20 - Estrategia de examen y autoevaluación#Autoevaluación]].
4. Repaso del **pre-vuelo**: BD `junio26` + demo, valor de la master password, modo desarrollador, carpeta `addons/` y plantillas `.py`.

**Meta del día:** dominas los dos scripts y el cheatsheet; entras al examen sabiendo en qué nota está cada cosa.

---

> [!tip]+ El día del examen
> Abre el [[22 - Cheatsheet de examen (chuleta operativa)]] y sigue su orden: pre-vuelo → Ej. 4 → Ej. 1 → Ej. 2 y 3. Un módulo que **instala y muestra datos** puntúa más que uno "perfecto" que no arranca.
