---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-08-04
Estado: Aceptada
---
---

## Contexto

HTB —y el material de pentest en general— usa **Nmap para todo** el descubrimiento (hosts, puertos, servicios) y trata la evasión de perímetro con el capítulo clásico de Nmap *«Firewall and IDS/IPS Evasion»*, que describe un mundo de ~1999: fragmentación, *decoys*, `--badsum`. Contra un perímetro de 2026 —firewall con estado, NGFW con App-ID, NDR conductual, DPI, inspección TLS, *flow logs* en la nube— casi todo eso está muerto. Para bug bounty y pentest **real** faltaban dos cosas: (a) arsenal de herramientas profesionales más allá de Nmap, y (b) una **metodología de evasión de perímetro moderna** con detección y evasión, como exige el estándar de los 3 ejes del vault.

El vault ya tenía `Red Team/Evasión de defensas/` como área de **evasión de endpoint** (EDR, hooks userland, callbacks de kernel), arrancada y en pausa. No tenía nada de evasión de **perímetro de red** — el paso que en un ataque real va **antes** de toparse con el EDR.

## Decisión

Dos piezas coordinadas.

**1 · Bloque de metodología `00 - Evasión de perímetro de red`** como **Level-2 al frente** de `Red Team/Evasión de defensas/` (10 notas 00-09 + `Evasión de perímetro.base`), renumerando el contenido de endpoint **+1** para hacerle sitio:

| Antes | Después |
| - | - |
| `00 - Fundamentos` | `01 - Fundamentos` |
| `01 - Hooking en espacio de usuario` | `02 - Hooking en espacio de usuario` |
| `02 - Callbacks de kernel` | `03 - Callbacks de kernel` |
| `03..08` (bases huérfanos) | `04..09` |

Las 10 notas del bloque: perímetro moderno · perfilar antes de escanear · descubrir la política de filtrado · egress filtering · fragmentación (por qué murió) · DPI/TLS/blending · rotación de origen · low-and-slow · cómo te ve el defensor · arsenal. Con `Tipo/Introduccion` (00), `Tipo/Deteccion` (08) y `Tipo/Arsenal` (09) para las vistas transversales del Level 0.

**2 · Arsenal de escaneo profesional a `02 - Recursos/🛠️ Tools/`** (cada herramienta su Level-2 propio, regla del vault «las herramientas siempre a Tools/»): **Masscan** (6), **RustScan** (3), **ZMap** (5), **sx** (3), **Smap** (2), **ProjectDiscovery** (suite, 10), y **Firewalk** rehecho de stub a 3 notas. **Nmap** ampliado con 2 notas net-new (`08 - Detección de escaneos y evasión moderna`, `09 - Arsenal de herramientas de escaneo`).

Regla de altitud: <mark>las notas de perímetro son metodología, no re-explican la herramienta</mark> — cross-linkean a `Tools/` (el *cómo* de cada una) y a `Redes/Protocolos/` (el *cómo funciona*), y desarrollan la política de evasión y la detección.

## Alternativas descartadas

- **Perímetro bajo `Pentesting/`** (es recon/escaneo). Descartada: el tema es *evadir defensas*, que es el remit de `Evasión de defensas/`. Perímetro (red) y endpoint (EDR) son las **dos mitades de la cadena de evasión**, en ese orden — atraviesas el perímetro para *llegar* al EDR. La nota 00 hace explícito ese encuadre.
- **Área nueva de primer nivel `Evasión de red/`**, separada de la de endpoint. Descartada: partiría en dos un arco conceptual único y dejaría dos áreas pequeñas. Se resuelve como **Level-2 hermanos** dentro de una sola área (patrón `04`/`05` de AI Hacking, ADR 011).
- **Meter las herramientas bajo el bloque de perímetro.** Descartada: viola la regla «herramientas siempre a `Tools/`». `masscan`/`naabu`/`RustScan` se usan también en recon normal, no solo en evasión — viven en `Tools/` y la metodología las enlaza.
- **Duplicar / re-explicar la evasión de Nmap en las notas de perímetro.** Descartada: genera redundancia y *drift*. Nmap 07/08/09 quedan *tool-scoped*; el bloque de perímetro es la capa de método que las cita.
- **Solo enriquecer el capítulo 07 de Nmap** en su sitio. Descartada: la realidad moderna (NGFW, NDR, DPI, fingerprinting TLS, nube) es un tema de **metodología** mayor que los flags de una herramienta; merece bloque propio, y Nmap conserva su ámbito.

## Consecuencias

- **MOCs sin tocar**: el Level-1 `Evasión de defensas.base` filtra por `file.folder.startsWith("Red Team/Evasión de defensas")` — **sobrevive al renumerado** y recoge el nuevo Level-2 solo. El Level-0 `Red-Team.base` lo recoge por su regex de profundidad, y las vistas transversales por los tags `Tipo/`. El Level-2 `Evasión de perímetro.base` se creó en la sesión previa; su filtro `Area == link(...)` casa con las 10 notas.
- **Cadena Zettelkasten** del bloque: cabeza (00, `prev` vacío) → cola (09, `next` vacío), invariante `X.next=Y ⇒ Y.prev=X` correcta, verificado con script. 0 wikilinks rotos en las 10 notas tras la pasada.
- **Link heredado roto corregido**: las notas 01 y 02 apuntaban a `[[10 - Documentación y reporting]]` (una **carpeta**, no una nota — el patrón de colisión que avisa el `CLAUDE.md`). Redirigidos a `Documentación y reporting.base` y a `06 - Cómo redactar un hallazgo`.
- **`Tools.base`**: su fórmula `categoría` es una lista `containsAny` hardcodeada; se añadieron las 7 herramientas nuevas a la rama «1 · Recon y escaneo» (deuda estructural conocida desde ADR 019 — cada herramienta nueva obliga a tocar la fórmula a mano).
- **Deuda EDR intacta**: la cola del bloque de endpoint (`09 - Manipulación de la imagen de proceso`) sigue con `next` a `[[10 - Object callbacks y robo de handles]]`, nota **fantasma** del proyecto EDR en pausa. No la toca este trabajo; es un TODO deliberado de ese bloque.
- **Firewalk deja de ser stub**: ADR 019 lo dejó sin `.base` *«por ser stub»*; ahora tiene 3 notas y `.base` Level-2. Conserva el nombre con emoji (`👣🏰`) por los backlinks, inconsistencia consciente como `🔨📦 Scapy` (ADR 017).
- **La limitación «todo con Nmap» queda resuelta**: el vault ya distingue *velocidad* (masscan/naabu/RustScan), *precisión* (Nmap), *pasivo* (Smap/uncover/Shodan) y *evasión de perímetro* (bloque nuevo), con la matriz de decisión en `09 - Arsenal de herramientas de escaneo` y `01 - Perfilar el perímetro antes de escanear`.
- **`CLAUDE.md`**: sección nueva para el área `Evasión de defensas` (mapeo + notas operativas) y filas de las herramientas nuevas.
