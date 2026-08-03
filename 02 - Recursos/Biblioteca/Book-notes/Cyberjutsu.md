---
tags:
  - Biblioteca
  - Pentesting
Fecha de actualización: 2026-08-03
Autores:
  - Ben McCarty
Editorial: No Starch Press
Año: 2021
ISBN: 978-1-7185-0054-9
Portada: https://covers.openlibrary.org/b/isbn/9781718500549-L.jpg
PDF: "[[cyberjutsu.pdf]]"
Estado: Aceptada
Rating:
Area: "[[Librería.base|Librería]]"
---
---

# Cyberjutsu

![Portada de Cyberjutsu](https://covers.openlibrary.org/b/isbn/9781718500549-L.jpg)

**Cybersecurity for the Modern Ninja** — por Ben McCarty, exdesarrollador de la NSA y veterano del Ejército de EE. UU. como *Cyber Warfare Specialist* (35Q).

## Sinopsis

Traduce los **manuales ninja históricos** (los *Bansenshūkai* y *Shōninki*, tratados de `ninjutsu` de los siglos XVII-XVIII, antes clasificados/restringidos en su transmisión) a doctrina moderna de ciberseguridad. La tesis del libro: los principios que guiaban el espionaje y la infiltración física — reconocimiento exhaustivo antes de actuar, explotar la complacencia humana, moverse dentro del ruido normal en vez de destacar — son directamente aplicables a intrusión y defensa de redes, y de hecho mapean con sorprendente precisión sobre el framework **MITRE ATT&CK**.

Cada capítulo toma un principio o técnica ninja concreta (vigilancia de accesos, tácticas de infiltración por horario, gestión de herramientas y agentes, comunicación encubierta, uso de señuelos y distracción) y lo traslada a su equivalente en TTPs modernas: reconocimiento OSINT, ingeniería social, *living-off-the-land*, C2 encubierto, *anti-forensics*. No es un libro de comandos ni de PoCs — es un libro de **doctrina y modelo mental**, pensado para quien ya conoce las herramientas pero quiere razonar mejor sobre estrategia ofensiva y defensiva.

El enfoque histórico-táctico es su mayor fortaleza y su mayor límite: aporta un marco conceptual distinto (y memorable) para pensar en threat modeling, pero no sustituye una referencia técnica de TTPs actualizada — para eso, ATT&CK sigue siendo la fuente primaria, y este libro funciona mejor como lente complementaria sobre él.

## Qué cubre el libro

- Mapeo de principios de `ninjutsu` histórico a tácticas y técnicas de **MITRE ATT&CK**.
- Reconocimiento y mapeo de redes (equivalente moderno al reconocimiento previo a una infiltración).
- Ingeniería social y explotación de la complacencia humana (guardias, control de accesos).
- Tácticas de infiltración por horario/turno y gestión de "herramientas" (tooling ofensivo).
- Comunicación encubierta y *call signs* — equivalentes a C2 y canales encubiertos modernos.
- Uso de señuelos, distracción y ataques de "fuego" (equivalentes a *diversion attacks* y DoS como cortina de humo).
- Gestión de amenazas con enfoque *zero-trust* y comportamiento en puestos de control (guardhouse).
- Doctrina de contratación y gestión de operativos (*hiring shinobi*) aplicada a equipos de red team modernos.

## Enlace

[[cyberjutsu.pdf|Abrir PDF]]

## Notas propias

Ingerido en el vault como **doctrina bicéfala** (ver [[018 - Ingesta del libro Cyberjutsu como doctrina bicéfala|ADR 018]]): el mismo material se lee desde el lado ofensivo y el defensivo, con lo net-new modernizado a 2026 y lo ya cubierto enlazado en vez de duplicado.

- **Óptica ofensiva** ("cómo el atacante evade") → área [[Doctrina pentesting.base|Doctrina pentesting]] de Red Team:
	- [[00 - El mindset del atacante persistente]] · [[01 - Frameworks de threat intelligence y la Pyramid of Pain]] · [[02 - Atribución y operaciones de bandera falsa]] · [[03 - Coordinación de operadores y deconflicting]] · [[04 - Explotar y crear circunstancias]]
- **Óptica defensiva** ("cómo el ingeniero de seguridad defiende") → área [[Doctrina defensiva.base|Doctrina defensiva]] de Blue Team:
	- [[00 - Threat modeling, STRIDE y el concepto de guarding]] · [[01 - Sensores defensivos - tipos y colocación]] · [[02 - Zero-trust - bloquear lo sospechoso, no solo lo malicioso]] · [[03 - Deception defensiva - honeypots, tiger traps y captura en vivo]] · [[04 - Cultura del SOC, complacencia y vigilancia]]

**Enriquecimientos y net-new adicional**: Footprinting (el mapa del atacante), Evasividad (light/noise/litter + timing) y una nota net-new de [[14 - Canales encubiertos y salto de air-gap]] en Pivoting y túneles (cap. *Bridges & Ladders*, modernizado con RAMBO/PIXHELL 2024).

Capítulos descartados por bajo valor o fuera de scope: *Hiring Shinobi* (gestión/RRHH) y *Locks* (seguridad física). Los ya cubiertos por el vault (living-off-the-land, C2, supply chain, OPSEC) se enlazan desde las notas de doctrina en lugar de reexplicarse.
