---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-07-24
Estado: Aceptada
---
---

## Contexto

El vault marcaba dos conceptos distintos con tags incoherentes. Las notas de **Nmap** usan el tag jerárquico `Escaneo/Redes` (escaneo de red: descubrimiento de hosts y puertos), mientras que las de **Nessus**, **OpenVAS** y la nota de *vulnerability assessment* del módulo `002` usaban un `Escaneo` **plano**. El plano rompía el esquema jerárquico y hacía ambiguo el filtrado: `#Escaneo` no decía *escaneo de qué*. Detectado en el barrido estructural de la auditoría CPTS (2026-07-24).

## Decisión

Renombrar el tag plano `Escaneo` → `Escaneo/Vulnerabilidades` en las **7 notas** de escaneo de vulnerabilidades (Nessus ×4, OpenVAS ×2, `002 - Evaluación de vulnerabilidades/05 - Escaneo de vulnerabilidades`). Queda un eje `Escaneo/` con dos hijos claros:

- `Escaneo/Redes` — escaneo de red (Nmap).
- `Escaneo/Vulnerabilidades` — escaneo de vulnerabilidades (Nessus, OpenVAS, VA).

El tag plano `Escaneo` se retira del scope de pentest.

## Alternativas descartadas

- **Dejar el `Escaneo` plano** — mantiene la inconsistencia y un tag ambiguo que no dice de qué escaneo habla; rompe el paralelismo con `Escaneo/Redes`.
- **Colapsar todo en un único `Escaneo`** (quitar también `/Redes`) — pierde la distinción red vs vulnerabilidades, que sí aporta al filtrar por fase de trabajo.
- **Reusar la fase `Pentesting/Vulnerabilidad`** en vez de un tag de tema — confunde ejes: la *fase* ya la marca `Pentesting/Vulnerabilidad`; el *tema/técnica* lo marca `Escaneo/*`. Se mantienen ambos ejes en paralelo.

## Consecuencias

- Filtrado coherente `Escaneo/Redes` vs `Escaneo/Vulnerabilidades`; buscar `#Escaneo` (namespace padre) sigue recogiendo ambos hijos en Obsidian.
- **1 nota fuera de scope conserva el `Escaneo` plano a propósito**: `01 - Proyectos/GO/01 - Redes TCP-IP/01 - Escáner TCP…` es un ejercicio de programación en Go (contexto distinto, no escaneo de vulns). Si se cataloga algún día, decidir su tag aparte.
- Futuras herramientas de escaneo de vulns (p. ej. `Nuclei` en modo scanner) deben usar `Escaneo/Vulnerabilidades`.
- **No afecta a ninguna `.base`**: todas filtran por `Area`, no por este tag.
