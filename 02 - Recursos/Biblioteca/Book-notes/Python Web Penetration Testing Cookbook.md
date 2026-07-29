---
tags:
  - Biblioteca
  - Pentesting
  - Web
  - Python
Fecha de actualización: 2026-07-22
Autores:
  - Cameron Buchanan
  - Terry Ip
  - Andrew Mabbitt
  - Benjamin May
  - Dave Mound
Editorial: Packt Publishing
Año: 2015
ISBN: 978-1-78439-293-2
Portada: 03 - Archivos/Images/Biblioteca/Python Web Penetration Testing Cookbook.jpg
PDF: "[[Python-Web-Penetration-Testing-Cookbook.pdf]]"
Estado: Completado
Rating:
Area: "[[Librería.base|Librería]]"
---
# Python Web Penetration Testing Cookbook

![Portada de Python Web Penetration Testing Cookbook](03 - Archivos/Images/Biblioteca/Python Web Penetration Testing Cookbook.jpg)

**Over 60 indispensable Python recipes to ensure you always have the right code on hand for web application testing.**

## Sinopsis

Formato *cookbook*: recetas cortas y autocontenidas (planteamiento → script → explicación línea a línea → variantes) para automatizar con `Python` cada fase de un pentest web, desde el OSINT inicial hasta el reporting final. No enseña `Python` desde cero — da por hecho manejo básico del lenguaje (`Python 2.7` en el original, ya en EOL; el criterio y la lógica de cada receta siguen siendo válidos, pero migrar a `Python 3` y a librerías modernas [`requests` en vez de `urllib2`, `httpx` para async] es trabajo obligado antes de reutilizar el código en 2026) y se centra en resolver problemas puntuales con scripts propios en vez de depender siempre de herramientas ya hechas.

Cubre terreno que la mayoría de libros de pentest web no toca: uso directo de APIs de OSINT (`Shodan`, `Google+`), manipulación de paquetes de bajo nivel con `Scapy`, esteganografía en imágenes como canal encubierto, y construcción de canales C2 propios sobre protocolos no convencionales (HTTP, FTP, incluso Twitter como transporte) — útil para entender cómo se detecta y evade tráfico C2 no estándar, más que como C2 de producción.

Los capítulos de **criptografía** (generación y cracking de hashes MD5/SHA, cifrados clásicos como ROT13/Atash, generadores congruenciales lineales) tienen valor más académico que ofensivo real: sirven para entender la mecánica interna de estos esquemas, no para atacar sistemas modernos.

## Qué cubre el libro

- OSINT: `Shodan`, `Google+ API`, capturas de pantalla masivas de sitios (`QtWebKit`), *spidering*.
- Enumeración: *ping sweep* y escaneo con `Scapy`, validación de usuarios, *brute forcing* de credenciales, generación de emails.
- Identificación de vulnerabilidades: *directory traversal*, XSS reflejado/basado en parámetros, *fuzzing* automatizado, comprobación de `Shellshock`.
- `SQL injection`: identificación, explotación booleana y ciega, *encoding* de payloads.
- Manipulación de cabeceras HTTP: *fingerprinting*, *clickjacking*, *session fixation*, *cookie flags* inseguras.
- Esteganografía: ocultar/extraer mensajes en LSB de imágenes, C2 sobre imágenes.
- Cifrado y *encoding*: hashes MD5/SHA/Bcrypt, Base64, ROT13, cifrados de sustitución y Atbash, ataques a *one-time pad* reutilizado.
- Payloads y shells: C2 sobre HTTP/FTP/Twitter, *reverse shell* simple con Netcat.
- Reporting: conversión Nmap XML → CSV, extracción a `Maltego`, generación de gráficos con `plot.ly`.

## Enlace

[[Python-Web-Penetration-Testing-Cookbook.pdf|Abrir PDF]]

## Notas propias

