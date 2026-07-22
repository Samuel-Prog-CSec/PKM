---
tags:
  - Biblioteca
  - Reverse-Engineering
  - Herramientas
Fecha de actualización: 2026-07-22
Autores:
  - Chris Eagle
  - Kara Nance
Editorial: No Starch Press
Año: 2020
ISBN: "978-1-71850-102-7"
Portada: "https://covers.openlibrary.org/b/isbn/9781718501027-L.jpg"
PDF: "[[ghidrabook.pdf]]"
Estado: Pendiente
Rating:
Area: "[[Librería.base|Librería]]"
---
---

# The Ghidra Book

![Portada de The Ghidra Book](https://covers.openlibrary.org/b/isbn/9781718501027-L.jpg)

**The Definitive Guide** — de Chris Eagle (también autor de *The IDA Pro Book*, No Starch Press) y Kara Nance.

## Sinopsis

`Ghidra` es la suite de ingeniería inversa que la NSA desarrolló durante más de una década para sus propios problemas de análisis, liberada como código abierto en 2019. Este libro es la guía de referencia de sus propios autores para dominarla: desde la navegación básica de un disassembly hasta la extensión del propio framework para soportar arquitecturas nuevas.

El enfoque práctico cubre primero el uso diario de la herramienta —displays de datos, manipulación del disassembly, tipos de datos y estructuras, cross-references y grafos de flujo— y luego entra en lo que diferencia a `Ghidra` de otras suites: un `descompilador` integrado sin coste adicional (a diferencia de IDA Pro, donde el descompilador es un módulo de pago aparte) y capacidad de **SRE colaborativo** vía Ghidra Server, donde varios analistas trabajan sobre el mismo proyecto en tiempo real.

La segunda mitad del libro entra en la extensibilidad real de la plataforma: scripting con la Ghidra Scripting API (Java y Python vía Jython), desarrollo de plugins con Eclipse/GhidraDev, creación de `loaders` para formatos de fichero no soportados y de `processors` para instruction sets nuevos mediante el lenguaje `Sleigh`, y automatización en modo headless para pipelines de triage de malware a escala. Cierra con casos reales: análisis de binarios ofuscados, parcheo y diffing/version tracking entre binarios (el equivalente nativo a BinDiff o Diaphora), y un apéndice de transición para quien viene de IDA Pro.

## Qué cubre el libro

- Navegación de disassembly, Program Trees, Symbol Tree y Data Type Manager.
- Uso del `descompilador` integrado para acelerar el análisis frente al disassembly puro.
- Manipulación de disassembly: renombrado, tipado de datos, estructuras, cross-references y grafos.
- SRE colaborativo con Ghidra Server (múltiples analistas sobre un mismo proyecto).
- Scripting en Java/Python (Ghidra Scripting API) y desarrollo de plugins con Eclipse/GhidraDev.
- Extensión de Ghidra: nuevos `loaders` (formatos de fichero) y nuevos `processors`/instruction sets vía `Sleigh`.
- Modo headless para automatizar análisis en pipelines (CI, triage de malware masivo).
- Análisis de código ofuscado, parcheo de binarios y binary diffing/version tracking.
- Guía de transición "Ghidra for IDA Users" para quien migra desde IDA Pro.

## Enlace

[[ghidrabook.pdf|Abrir PDF]]

## Notas propias

