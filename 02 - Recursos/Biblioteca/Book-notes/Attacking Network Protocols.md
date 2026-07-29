---
tags:
  - Biblioteca
  - Protocolos
  - Redes
Fecha de actualización: 2026-07-22
Autores:
  - James Forshaw
Editorial: No Starch Press
Año: 2018
ISBN: 978-1-59327-750-5
Portada: https://covers.openlibrary.org/b/isbn/9781593277505-L.jpg
PDF: "[[attackingnetworkprotocols.pdf]]"
Estado: Aceptada
Rating:
Area: "[[Librería.base|Librería]]"
---
---

# Attacking Network Protocols

![Portada de Attacking Network Protocols](https://covers.openlibrary.org/b/isbn/9781593277505-L.jpg)

**A Hacker's Guide to Capture, Analysis, and Exploitation** — prólogo de Katie Moussouris (fundadora de Luta Security, ex-responsable del programa de *bug bounty* de Microsoft).

## Sinopsis

Guía de James Forshaw (investigador de Google Project Zero, poseedor de la mayor recompensa jamás pagada por Microsoft — 100.000$ — y antiguo #1 del ranking público del MSRC) sobre cómo auditar la seguridad de un protocolo de red desde cero, sin depender de documentación oficial ni de herramientas ya construidas para ese protocolo concreto. Forshaw es también el creador de `Canape`, la herramienta de análisis de protocolos que usa como hilo conductor en varios capítulos.

Arranca por la base — captura de tráfico de aplicación con `Wireshark` y desarrollo de proxies/interceptores a medida — y escala en dificultad hacia el análisis estático y dinámico de la estructura del protocolo (formatos binarios, texto plano, TLV, serialización tipo `ASN.1`) y la ingeniería inversa de la propia aplicación que lo implementa cuando no queda otra que leer el binario.

La segunda mitad se centra en encontrar y explotar vulnerabilidades: modelado de amenazas específico para protocolos de red, las causas raíz más habituales (corrupción de memoria, *bypass* de autenticación, denegación de servicio) y cómo automatizar su descubrimiento con *fuzzing* dirigido y depuración. Cierra con un apéndice-*toolkit* de herramientas de análisis de protocolos.

Publicado en 2018: `Canape` lleva años sin mantenimiento activo y algunas referencias de *tooling* han quedado desfasadas (`Wireshark`, `Scapy` y `mitmproxy` siguen siendo el estándar actual para la captura/manipulación descrita en los primeros capítulos), pero la metodología de análisis y explotación de protocolos —el grueso real del libro— sigue vigente como referencia.

## Qué cubre el libro

- Fundamentos de *networking* aplicados a la perspectiva de un atacante (capas, sockets, tráfico cliente-servidor).
- Captura de tráfico de aplicación con `Wireshark` y desarrollo de proxies/interceptores propios.
- Estructuras comunes de protocolos de red: formatos binarios, texto plano, TLV y serialización tipo `ASN.1`.
- Análisis estático y dinámico del protocolo, incluida ingeniería inversa de la aplicación que lo implementa.
- Criptografía aplicada a protocolos: dónde se implementa mal y cómo detectarlo.
- Modelado de amenazas y causas raíz de vulnerabilidades: corrupción de memoria, *bypass* de autenticación, denegación de servicio.
- *Fuzzing* dirigido y depuración para automatizar el descubrimiento de vulnerabilidades.
- Apéndice con un *toolkit* completo de herramientas de análisis de protocolos de red.

## Enlace

[[attackingnetworkprotocols.pdf|Abrir PDF]]

## Notas propias

