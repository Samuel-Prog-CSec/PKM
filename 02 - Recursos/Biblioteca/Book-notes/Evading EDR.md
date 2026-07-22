---
tags:
  - Biblioteca
  - Evasion
Fecha de actualización: 2026-07-22
Autores:
  - Matt Hand
Editorial: No Starch Press
Año: 2024
ISBN: "978-1-7185-0334-2"
Portada: "03 - Archivos/Images/Biblioteca/Evading EDR.jpg"
PDF: "[[evadingedr.pdf]]"
Estado: Pendiente
Rating:
Area: "[[Librería.base|Librería]]"
---
---

# Evading EDR

![Portada de Evading EDR](03 - Archivos/Images/Biblioteca/Evading EDR.jpg)

**The Definitive Guide to Defeating Endpoint Detection Systems** — escrito por Matt Hand (operador de *red team* en SpecterOps), con Joe Desimone (ex-Elastic Security Labs) como revisor técnico.

## Sinopsis

Diseca, componente a componente, cómo funciona un `EDR` moderno por dentro (agente, telemetría, sensores, motor de detecciones) para luego atacar cada pieza: no es una colección de *bypasses* sueltos, sino un manual de cómo razonar sobre qué sensor genera qué evento y qué hueco deja cada técnica de evasión concreta.

Recorre, sensor a sensor, los mecanismos con los que Windows y el propio `EDR` observan un sistema: *function hooking* en `ntdll.dll`, notificaciones de creación de procesos/hilos a nivel de kernel, notificaciones de objetos (duplicación de *handles*), notificaciones de *image-load* y de registro, `minifilters` de sistema de archivos, filtros de red (`WFP`), `Event Tracing for Windows` (`ETW`), escáneres basados en firmas (`YARA`), `AMSI`, controladores `ELAM` y el proveedor `Microsoft-Windows-Threat-Intelligence` (`ETWti`) — este último, el sensor más difícil de evadir sin dejar rastro.

Para cada sensor sigue el mismo patrón: cómo funciona, cómo detecta actividad adversaria y cómo evadirlo, con pruebas de concepto en C y `PowerShell`. Cierra con un caso de estudio completo —acceso inicial, persistencia, reconocimiento, escalada de privilegios, movimiento lateral y exfiltración— ejecutado íntegramente contra un `EDR` real y siendo consciente de la detección en cada paso.

## Qué cubre el libro

- Arquitectura interna de un `EDR`: agente, telemetría, sensores y motor de detecciones.
- Evasión de *function hooking* en DLLs (*syscalls* directas, resolución dinámica de números de *syscall*, remapeo de `ntdll.dll`).
- Notificaciones de creación de procesos/hilos: *PPID spoofing*, manipulación de línea de comandos, modificación de la imagen de proceso.
- Notificaciones de objetos, *image-load* y de registro, incluida inyección vía `KAPC`.
- `Minifilters` de *filesystem* y filtros de red (`WFP`) para telemetría de archivos y tráfico.
- `Event Tracing for Windows` (`ETW`) y su evasión, incluido el proveedor `Microsoft-Windows-Threat-Intelligence`.
- Escáneres basados en firmas (`YARA`), `AMSI` y controladores `ELAM` de arranque temprano.
- Caso de estudio *end-to-end* de un ataque consciente de la detección, de principio a fin.

## Enlace

[[evadingedr.pdf|Abrir PDF]]

## Notas propias

