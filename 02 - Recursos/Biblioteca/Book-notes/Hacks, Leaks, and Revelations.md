---
tags:
  - Biblioteca
  - OSINT
  - Análisis/Datos
Fecha de actualización: 2026-07-22
Autores:
  - Micah Lee
Editorial: No Starch Press
Año: 2024
ISBN: "978-1-7185-0312-0"
Portada: "https://covers.openlibrary.org/b/isbn/9781718503120-L.jpg"
PDF: "[[hacksleaksandrevelations.pdf]]"
Estado: Pendiente
Rating:
Area: "[[Librería.base|Librería]]"
---
---

# Hacks, Leaks, and Revelations

![Portada de Hacks, Leaks, and Revelations](https://covers.openlibrary.org/b/isbn/9781718503120-L.jpg)

**The Art of Analyzing Hacked and Leaked Data** — de Micah Lee, director de seguridad de la información en *The Intercept*, cofundador de Distributed Denial of Secrets (`DDoSecrets`) y quien ayudó a asegurar las comunicaciones de Edward Snowden durante la filtración de la NSA.

## Sinopsis

Los grandes leaks (BlueLeaks, Parler, Epik, Oath Keepers, Heritage Foundation) dejan sobre la mesa datasets de cientos de gigabytes en formatos heterogéneos — CSV, JSON, volcados SQL, correo en EML/MBOX/PST — que la mayoría de periodistas e investigadores no saben ni por dónde abrir. Este libro construye ese pipeline de principio a fin: cómo recibir un dataset filtrado de forma segura, verificarlo, y extraer de él una historia sin comprometer a la fuente ni al propio investigador.

Arranca por la parte que casi ningún manual técnico cubre: protección operativa — comunicación cifrada con fuentes (`Signal`, `PGP`, `Tor`, `OnionShare`), cifrado de disco, apertura segura de documentos potencialmente maliciosos con `Dangerzone`, y criterios de qué publicar y qué redactar antes de sacar nada a la luz. A partir de ahí construye el stack técnico desde cero: línea de comandos, `Python` para automatizar la exploración de datasets masivos, y `Docker` + `Aleph` para indexar y hacer buscable lo que no tiene ni estructura ni metadatos limpios.

La segunda mitad son casos reales resueltos con ese stack: `BlueLeaks` (los fusion centers de la policía estadounidense y su vigilancia de Black Lives Matter) trabajado en CSV y con una herramienta propia (`BlueLeaks Explorer`); los metadatos de vídeo de `Parler` durante el asalto al Capitolio del 6 de enero, en JSON con coordenadas GPS extraídas y volcadas a KML para visualizar en Google Earth; el hackeo del registrador de dominios `Epik` reconstruido con consultas SQL; y análisis de desinformación de la pandemia de COVID-19 y de salas de chat neonazis. Es el manual de referencia actual para bug hunters y OSINT que necesiten convertir un dump filtrado en inteligencia accionable, no solo en ruido.

## Qué cubre el libro

- Protección de fuentes: `Signal`, `PGP`, `Tor`/`OnionShare`, cifrado de disco y apertura segura de documentos con `Dangerzone`.
- Adquisición y autenticación de datasets filtrados (BitTorrent, `Distributed Denial of Secrets`, verificación de integridad).
- Línea de comandos y `Python` para explorar datasets masivos sin ahogarse en volumen.
- `Docker` + `Aleph` para indexar y hacer buscables datasets no estructurados (documentos, PDFs, correo).
- Lectura de volcados de correo (`EML`/`MBOX`/`PST`) con Thunderbird y Aleph.
- Formatos estructurados: `CSV` (BlueLeaks), `JSON` (metadatos de vídeo, coordenadas GPS) y bases `SQL` (Epik).
- Casos reales completos: BlueLeaks/BLM, Parler y el 6 de enero, el hackeo de Epik, desinformación COVID, chats neonazis.
- Ética y legalidad de la publicación: qué redactar, cómo pedir comentarios a los implicados antes de publicar.

## Enlace

[[hacksleaksandrevelations.pdf|Abrir PDF]]

## Notas propias

