---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-08-01
Estado: Aceptada
---
---

## Contexto

El arranque del path **CWPE** (*Wi-Fi Penetration Tester*, id 421 — 10 módulos, 170 secciones) se encontró con `Red Team/Hacking Wi-Fi/` ya existente pero vacío de contenido útil: una nota (`001 - Introducción/Fundamentos.md`) que era una traducción automática cruda de las secciones 1-3 del módulo 222 ("marcos de balizas", "Cuadros IEEE", "el marco MAC"), un `Referencias.md` con dos URLs sueltas sin frontmatter, y un `Wi-Fi Pentesting.base` configurado como **Level 2**.

Con 10 módulos por delante había que decidir tres cosas antes de escribir la primera nota: dónde viven los fundamentos del estándar, cómo se agrupan las herramientas y qué taxonomía de tags se fija — las tres son caras de revertir una vez hay 130 notas.

## Decisión

**1 · Reparto en tres áreas.** Fundamentos del estándar 802.11 (generaciones, bandas y canales, arquitectura BSS/ESS, anatomía de la trama MAC) → `Redes/Protocolos/Wi-Fi (802.11)/`, indexado por `Protocolos de red.base` como cualquier otro protocolo. Contenido ofensivo → `Red Team/Hacking Wi-Fi/`. Herramientas → `02 - Recursos/🛠️ Tools/`.

**2 · `Wi-Fi Pentesting.base` pasa de Level 2 a Level 1**, con un Level 2 por módulo (`Fundamentos Wi-Fi.base`, `WPS.base`, `WEP.base`, …). Con 10 módulos el área agrupa sub-temas, que es la definición de Level 1 de la ADR 009.

**3 · Herramientas WPS agrupadas en `Tools/Reaver/`** — reaver+wash, bully, pixiewps y OneShot en una sola carpeta con un `.base`.

**4 · Taxonomía `Wi-Fi/…`** siguiendo el patrón `IA/…`: `Wi-Fi` como paraguas y `Wi-Fi/802.11`, `Wi-Fi/WEP`, `Wi-Fi/WPS` como hijos. Se retira `Pentesting/Wi-Fi`.

**5 · Legacy borrado**: `001 - Introducción/Fundamentos.md` y `Referencias.md` eliminados, su contenido rehecho desde cero y las dos URLs integradas como fuentes citadas.

## Alternativas descartadas

- **Todo el 802.11 dentro de `Hacking Wi-Fi/`** — menos saltos al estudiar el path, pero rompe la regla *fundamentos ≠ ofensiva* del CLAUDE.md y deja `Redes/` sin la capa 1/2 inalámbrica, que Blue Team necesitará para análisis de tráfico wireless. Descartada por coherencia con el precedente Footprinting ↔ `Redes/Protocolos` y SQLi ↔ `Ingenieria/Bases de Datos`.
- **Una carpeta de Tools por herramienta WPS** (`Reaver/`, `Bully/`, `Pixiewps/`, `OneShot/`) — respeta a rajatabla el precedente John/Hashcat y Nessus/OpenVAS, pero mete cuatro `.base` de una nota en `Tools.base`. Descartada porque las cuatro herramientas son intercambiables y están técnicamente acopladas: `wash` se distribuye con reaver, `bully` es una reimplementación suya y `pixiewps` lo invocan ambas internamente (`reaver -K`, `bully -d`).
- **Tag `Wi-Fi` plano** — más simple, pero con 10 módulos y ~130 notas deja de servir para filtrar, el mismo problema que tiene `Pentesting` con 54 usos.
- **Mantener `Pentesting/Wi-Fi`** — cero tags nuevos, pero perpetúa una mezcla de ejes: en el resto del vault `Pentesting/…` es el eje de **fase** (Enumeracion, Explotacion, Post-Explotacion, Movimiento-Lateral, Reporting), no de área.
- **Conservar la nota legacy y ampliarla** — descartada: la traducción automática no cumplía ningún estándar del vault (sin marks, sin callouts, terminología inventada) y reescribirla costaba más que rehacerla.

## Consecuencias

- `Red-Team.base` gana una rama en su fórmula `certificación` (`Hacking Wi-Fi` → `CWPE`) y `Tools.base` una categoría `8 · Wi-Fi y 802.11`. El Level 0 recoge el área nueva sin tocar nada más, gracias al filtro por regex de profundidad de la ADR 009.
- `Wi-Fi Pentesting.base` incorpora una fórmula `módulo` que mapea cada carpeta numerada a su módulo del path — el mismo patrón de familia que usa `Web Pentesting.base`.
- Las notas de `Redes/Protocolos/Wi-Fi (802.11)/` van **sin cadena Zettelkasten**, como el resto de fichas de protocolo de esa carpeta.
- Los siete módulos restantes de CWPE (282, 291, 304, 299, 312, 298, 305) encajan como Level 2 hermanos bajo `Hacking Wi-Fi/`, con numeración `03`–`09` ya reservada en la tabla de `CLAUDE.md` y en el temario.
- Queda una asimetría asumida: `Tools/Reaver/` agrupa cuatro herramientas mientras `Tools/MDK4/` tiene una sola. Se aceptó porque MDK4 no es específico de WPS —se reutilizará en evil twin, deauth y WIDS confusion— y merece identidad propia.
