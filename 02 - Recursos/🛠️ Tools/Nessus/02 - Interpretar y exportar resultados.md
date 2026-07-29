---
tags:
  - Pentesting/Vulnerabilidad
  - Escaneo/Vulnerabilidades
Descripción: "Un escaneo solo vale por lo que sacas de él"
Fecha de actualización: 2026-07-18
Nota previa: "[[01 - Escaneo y configuración avanzada]]"
Nota siguiente: "[[03 - Problemas de escaneo]]"
Area: "[[Nessus.base|Nessus]]"
---
---

Un escaneo solo vale por lo que sacas de él. Nessus exporta en formatos para humanos y para máquinas.

# Informes para el cliente

Con el escaneo terminado, se exporta como **`.pdf`**, **`.html`** o **`.csv`**. Los PDF/HTML permiten elegir entre un **Executive Summary** (resumen de alto nivel, ver [[06 - Reporting]]) o un informe personalizado y detallado. El `.csv` es cómodo para filtrar y manipular hallazgos en masa.

# Exportar los resultados crudos (`.nessus`)

<mark style="background: #FFB86CA6;">Además del informe, se pueden exportar los resultados crudos en formato `.nessus` (XML)</mark> para archivarlos o **pasarlos a otras herramientas**. El caso clásico:

- **`EyeWitness`** — toma capturas de todas las aplicaciones web que Nessus identificó, acelerando enormemente el triaje visual.
- Import en **[[Metasploit.base|Metasploit]]** (`db_import`) para cruzar hallazgos con módulos de explotación.
- Archivado para comparativas entre escaneos sucesivos (ver qué se corrigió).

# Interpretar (el paso que no es automático)

<mark style="background: #8000E1A6;">Nessus prioriza por severidad ([[03 - CVSS|CVSS]]), pero la validación es humana</mark>: no todo lo que marca es real. Antes de reportar:

- **Valida los críticos/altos** manualmente (descarta falsos positivos).
- **Reprioriza** con contexto de negocio, `EPSS` y `CISA KEV` — no reportes 200 "críticos" sin criterio.
- Agrupa hallazgos repetidos y filtra el ruido informativo.

Un informe lleno de falsos positivos destruye la credibilidad de todo el trabajo (ver [[06 - Reporting]]). Antes de escanear en serio, conviene conocer sus riesgos: [[03 - Problemas de escaneo]].
