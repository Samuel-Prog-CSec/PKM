---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-08-03
Estado: Aceptada
---
---

## Contexto

*Attacking Network Protocols* (Forshaw, No Starch Press, 2018) cubre un hueco que el vault no tocaba: **atacar protocolos binarios propietarios** — el ERP a medida, el agente de backup, el PLC, el *backend* de una app — donde no hay RFC, ni disector de Wireshark, ni herramienta dedicada.

Auditoría previa (`grep` sobre el vault, 2026-08-03): cero cobertura de análisis de protocolo desconocido, estructuras binarias (TLV, endianness, longitud variable), MITM de capa 2/3, disectores Lua, reversing de binarios, fuzzing, triaje de crashes y explotación de memoria. El vault es fuertemente **web-céntrico**: cubre a fondo inyección, autenticación y lógica en HTTP, y prácticamente nada de servicios binarios en C.

## Decisión

Área **Level-1 nueva** en `Red Team/Hacking de protocolos/`, con `.base` Level 1 y **6 Level-2** (49 notas):

| Sub-tema | Notas | Origen |
| - | - | - |
| `00 - Metodología de análisis` | 10 | Caps. 1, 2, 5 |
| `01 - Estructuras de protocolo` | 7 | Cap. 3 |
| `02 - MITM a nivel de red` | 7 | Cap. 4 + IPv6 net-new |
| `03 - Reversing de la implementación` | 5 | Cap. 6 |
| `04 - Causas raíz de vulnerabilidades` | 10 | Cap. 9 |
| `05 - Fuzzing y explotación` | 10 | Cap. 10 |

Decisiones concretas dentro de eso:

- **El cap. 7 (criptografía y TLS) NO se duplica.** Ya está cubierto por `26 - HTTPs-TLS` (12 notas). Se enriqueció en su sitio, con la actualización post-cuántica de 2026.
- **Tools net-new**: `mitmproxy`, `Frida`, `Ghidra`, `AFL++`, `bettercap`, cada uno con su `.base` Level 2. `Scapy` se rellenó (era un stub de 0 bytes) y recibió `.base`.
- **Tags nuevos**: `MITM`, `Reversing`, `Corrupcion-Memoria` (verificados como inexistentes antes de crearlos).
- **Modernización explícita**: todo lo que el libro da por bueno y ha muerto se señala en la nota, con la fecha de verificación y el sustituto.

## Alternativas descartadas

- **Repartir en áreas existentes** (captura/MITM → `Pentesting/`, estructuras → `Redes/`, reversing+explotación → `Desarrollo ofensivo/`). Descartada: rompe la unidad metodológica del libro —que es su mayor valor— y `Desarrollo ofensivo/` es hoy «programar herramientas ofensivas en Go», no ingeniería inversa. El contenido quedaría inencontrable.
- **Dos áreas separadas**, `Hacking de protocolos` (caps. 1-8) + `Explotación de binarios` (caps. 9-10). Descartada: dejaría dos áreas pequeñas y desconectadas cuando el flujo real es continuo (analizas el protocolo *para* encontrar el fallo, y encuentras el fallo *porque* entendiste el protocolo). Se resuelve como Level-2 hermanos dentro de una sola área, patrón ya usado en `04`/`05` de AI Hacking (ADR 011).
- **Meter las estructuras binarias en `Redes/`** por la regla *fundamentos ≠ ofensiva*. Descartada: `Redes/` responde «cómo funciona un protocolo documentado»; el cap. 3 responde «cómo reconozco estas estructuras en tráfico que no entiendo», que es una actividad ofensiva. Se cross-linkea desde `Introducción a los protocolos de red`.
- **Un área dedicada de Reversing** (`Red Team/Reversing/` completa: PE/ELF/Mach-O, ofuscación, Android…). Descartada **por ahora**: se sale del alcance del libro y multiplicaría el trabajo. Se cubrió el cap. 6 como bloque compacto de 5 notas orientado a *localizar el protocolo en un binario*. Queda como candidata a área futura si aparece más material.
- **Traducir el libro tal cual.** Descartada por política del vault: `Canape` (su herramienta central) lleva sin mantenimiento desde 2017, `IDA Free 5` y `PEiD` están obsoletos, y el cap. 10 se queda en las mitigaciones de ~2010. Traducirlo produciría notas que enseñan a usar cosas muertas.

## Consecuencias

- **Level 0 sin tocar**: `Red-Team.base` recoge la nueva área sola por su regex de profundidad (`/^Red Team\/[^\/]+$/`). La fórmula `certificación` la clasifica como «Sin certificación asociada», que es correcto — es un libro, no un path.
- **`Tools.base`**: hubo que ampliar la fórmula `categoría` a mano (es una lista `containsAny` hardcodeada) con tres categorías nuevas: `10 · Interceptación y MITM`, `11 · Reversing e instrumentación`, `12 · Fuzzing`. **Cada herramienta nueva obliga a tocar esa fórmula** — deuda conocida.
- **ADR 009 parcialmente revisado**: descartó `.base` para `Scapy` y `Firewalk` *«por ser stubs de 0 y 0,1 KB»*. Al rellenar Scapy, la condición deja de aplicar y se creó su `.base`. **`Firewalk` sigue siendo un stub** y sigue sin `.base`.
- **Nombres con emoji conservados**: `🔨📦 Scapy.md` mantiene su nombre pese a la convención actual sin emoji (ADR 017), para no romper los backlinks desde `MDK4` y el arsenal Wi-Fi. Inconsistencia consciente.
- **Verificación**: 0 wikilinks rotos y las 6 cadenas Zettelkasten con invariante `X.next=Y ⇒ Y.prev=X` correcta, comprobado con script.
- **`CLAUDE.md`**: fila nueva en «Módulos extra» + sub-sección de notas operativas con el desfase del *tooling* verificado.
- **Pasada de revisión el mismo día**: se auditaron las 58 notas y se corrigieron 7 clases de error **propio** (salida de consola inventada, API de Wireshark mal usada, escapado roto, prosa incoherente con el código, dos cifras falsas, atribución vaga y densidad de marcas insuficiente). El detalle está en `CLAUDE.md` § «Pasada de revisión». **Lección para futuras ingestas: el riesgo no está en el libro, está en lo que uno redacta sin ejecutar** — toda salida de comando debe calcularse, y toda API debe contrastarse con su referencia antes de escribir el ejemplo.
