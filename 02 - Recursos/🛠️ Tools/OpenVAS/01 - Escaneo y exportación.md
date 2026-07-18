---
tags:
  - Pentesting/Vulnerabilidad
  - Escaneo
Fecha de actualización: 2026-07-18
Nota previa: "[[00 - Introducción a OpenVAS]]"
Nota siguiente:
Area: "[[OpenVAS.base|OpenVAS]]"
---
---

# Configurar y lanzar un escaneo

Todo se gestiona desde la pestaña **`Scans`** del Greenbone Security Assistant. El escaneo se estructura en dos piezas:

- **Target** — el objetivo (IP, rango o lista de hosts), con opciones de puertos y **credenciales** para escaneo autenticado.
- **Task** — la tarea que asocia un *target* con una **scan configuration** (el perfil de escaneo: `Full and fast` es el habitual, hay variantes más o menos intensas).

<mark style="background: #FFB86CA6;">La lógica es la misma que en Nessus</mark>: defines objetivo + perfil, y lanzas. Igual que allí, un escaneo completo puede tardar **1-2 horas**; conviene ir revisando vulnerabilidades a medida que aparecen en vez de esperar al final.

# Ver y exportar resultados

Terminada la tarea, se abre el **report** desde `Scans`. El informe muestra, en pestañas, las vulnerabilidades con su severidad, el SO detectado, puertos y servicios.

<mark style="background: #ADCCFFA6;">OpenVAS exporta en `XML`, `CSV`, `PDF`, `ITG` y `TXT`</mark>:

- **`PDF`** — informe presentable para el cliente (ver [[06 - Reporting]]).
- **`XML`/`CSV`** — datos crudos para procesar, filtrar o pasar a otras herramientas.

# OpenVAS vs Nessus (cuándo cada uno)

<mark style="background: #8000E1A6;">Mismo trabajo, distinto presupuesto</mark>:

- **OpenVAS** — gratis y open-source; ideal cuando no hay licencia de Nessus, para labs, o para tener un **segundo escáner** (contrastar resultados y cubrir puntos ciegos).
- **Nessus** — más pulido, más rápido y con mejor reporting/soporte; el estándar comercial.

En un VA profesional, usar **ambos** y cruzar hallazgos es buena práctica: ningún escáner detecta todo, y las diferencias entre ellos suelen ser reveladoras. El arsenal completo de escáneres está en [[05 - Escaneo de vulnerabilidades#Arsenal de escáneres (2026)|la nota de escaneo]].
