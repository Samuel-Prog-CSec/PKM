---
tags:
  - PKM/Decisiones
Fecha de actualización: 2026-08-04
Estado: Aceptada
---
---

## Contexto

Los módulos **312 (Wi-Fi Password Cracking Techniques)** y **305 (Attacking Corporate Wi-Fi Networks)** se extrajeron **saltándose el orden del path**: son el 8.º y el 10.º de CWPE, y los módulos 4-7 y 9 siguen pendientes. Eso planteó dos problemas que no había tenido ninguna ingesta anterior.

El primero es de **reparto**: sólo un ~40 % del módulo 312 trata de Wi-Fi. El resto es mecánica de `hashcat` (CPU/GPU, reglas, máscaras, combinator, híbridos, nube) y una sección entera sobre contraseñas de dispositivos Cisco, que no es inalámbrica en absoluto.

El segundo es de **dependencias**: el 305 es un capstone que encadena técnicas —evil twin, MANA, downgrade de WPA3, portal cautivo— cuyos módulos propios (282, 291, 304, 299) todavía no están extraídos. Escribirlo como playbook puro, al estilo del capstone de CPTS (ADR 014), lo habría dejado lleno de enlaces a notas inexistentes.

## Decisión

**Reparto del 312 en tres destinos**, aplicando la regla ya establecida de *herramientas siempre a `Tools/`*:

- Lo específicamente inalámbrico → `Hacking Wi-Fi/07 - Cracking de contraseñas Wi-Fi/` (12 notas).
- La mecánica de la herramienta → **`Tools/Hashcat/` ampliado de 2 a 6 notas**. El módulo fue la ocasión para saldar una deuda: Hashcat tenía dos notas muy flacas para el estándar del vault.
- Los fundamentos de protocolo que ambos módulos dan por sabidos → `Redes/Protocolos/Wi-Fi (802.11)/`, dos notas net-new sobre RSN/4-way handshake y WPA3/SAE/OWE.

**La sección de contraseñas Cisco se queda en `Hacking Wi-Fi/07`**, no se mueve a `Pentesting/05 - Ataques a contraseñas/`.

**El 305 se escribe en modo playbook, pero explicando de forma compacta las técnicas prestadas** de módulos aún no extraídos, con mención explícita del módulo que las desarrollará. Cuando lleguen 282/291/304/299, esas secciones se recortan a enlace.

**La numeración de carpetas deja huecos**: `07` y `09`, con `03`-`06` y `08` libres para los módulos pendientes. El Level 1 `Wi-Fi Pentesting.base` ya tenía esas ramas mapeadas en sus fórmulas, así que no hubo que tocarlo.

## Alternativas descartadas

- **Meter toda la mecánica de hashcat en las notas de Wi-Fi** — habría duplicado contenido que sirve igual para NTLM, Kerberos o KeePass, y contradice la regla de que el *cómo funciona* de una herramienta vive en `Tools/`.
- **Mover la nota de Cisco a `Pentesting/05 - Ataques a contraseñas/`** — es su hogar temático natural, pero exigía insertarla en mitad de una cadena Zettelkasten de 19 notas, renumerando dos ficheros y recosiendo sus enlaces entrantes. Decisión del usuario: el coste no compensaba, y la nota tiene un anclaje real en el módulo 305, donde una configuración Cisco encontrada en un recurso compartido es el pivote hacia el dominio.
- **Escribir el 305 como playbook puro con enlaces fantasma** — habría dejado un sub-tema inutilizable hasta que se extrajeran cuatro módulos más.
- **Extraer antes los módulos 4-7 para no romper el orden** — descartado por decisión del usuario sobre qué estudiar primero; el vault no exige orden de path.
- **Renumerar las carpetas al orden real de extracción** — habría desalineado los números respecto al path, que es la referencia que usan las tablas de `CLAUDE.md` y las fórmulas del Level 1.

## Consecuencias

- `Hacking Wi-Fi/` queda con huecos de numeración visibles (`03`-`06`, `08`). Es intencionado y está documentado; el Level 1 los recoge solos cuando aparezcan.
- **Deuda concreta**: las secciones compactas del 305 sobre evil twin, MANA, downgrade WPA3 y portales cautivos habrá que **recortarlas a enlace** al extraer 282/291/304/299. Están señaladas en el cuerpo de cada nota.
- `Tools.base` necesitó tocar su fórmula `categoría` (hardcodeada) para las cinco herramientas nuevas — la misma deuda que señaló la ADR 019.
- `Tools/Hashcat/` pasa a ser una referencia real de la herramienta y no un apunte; las notas de cracking de otras áreas pueden enlazarla en vez de repetir la sintaxis de máscaras y reglas.
- Los fundamentos de WPA2/WPA3 en `Redes/` **adelantan trabajo** de los módulos 282 y 304, que ya sólo tendrán que aportar la parte ofensiva.
