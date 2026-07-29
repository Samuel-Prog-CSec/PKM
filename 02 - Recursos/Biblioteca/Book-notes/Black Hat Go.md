---
tags:
  - Biblioteca
  - Go
Fecha de actualización: 2026-07-22
Autores:
  - Tom Steele
  - Chris Patten
  - Dan Kottmann
Editorial: No Starch Press
Año: 2020
ISBN: 978-1-59327-865-6
Portada: https://covers.openlibrary.org/b/isbn/9781593278656-L.jpg
PDF: "[[blackhatgo.pdf]]"
Estado: Completado
Rating:
Area: "[[Librería.base|Librería]]"
---

# Black Hat Go

![Portada de Black Hat Go](https://covers.openlibrary.org/b/isbn/9781593278656-L.jpg)

**Go Programming for Hackers and Pentesters** — prólogo de HD Moore (fundador de Metasploit).

## Sinopsis

Explora el uso ofensivo de `Go`: por qué el lenguaje se ha vuelto habitual en tooling de seguridad (compilación estática sin dependencias, cross-compilation trivial entre SO/arquitecturas, concurrencia nativa con goroutines) y cómo aprovecharlo para construir herramientas propias en vez de depender solo de las ya existentes.

Arranca con la sintaxis y filosofía del lenguaje aplicadas a protocolos de red comunes (`HTTP`, `DNS`, `SMB`), y avanza hacia problemas reales de pentesting: exfiltración de datos, *packet sniffing*, desarrollo de exploits, herramientas *pluggable* mediante plugins/extensiones, criptografía ofensiva, ataques a Windows y esteganografía.

## Qué construye el libro

- Cliente HTTP/scraper de HTML arbitrario y servidor HTTP propio (`net/http`).
- Servidor y proxy DNS propios, con **DNS tunneling como canal C2** para salir de redes restrictivas.
- Fuzzer de vulnerabilidades para descubrir debilidades en una aplicación.
- Sistema de plug-ins/extensiones para herramientas extensibles.
- Brute-forcer de clave simétrica RC2.
- Esteganografía: ocultar datos dentro de una imagen PNG.

## Enlace

[[blackhatgo.pdf|Abrir PDF]]

## Curso derivado

Este libro se está transformando en un curso de **Go ofensivo** (modernizado a Go 1.26) en `🔴⚔️ Red Team/Desarrollo ofensivo`. Índice del curso: [[Desarrollo ofensivo.base|Desarrollo ofensivo]]. Bloque de fundamentos del lenguaje completo (14 notas 00-13): [[Fundamentos de Go.base|Fundamentos de Go]].

## Notas propias

