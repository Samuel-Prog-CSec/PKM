---
tags:
  - Proyectos
  - Go
  - Web/Red-Team
  - Modern-Exploitation
  - Tipo/Proyecto
Descripción: "Siembra marcadores únicos en cada entrada y los busca por toda la superficie de salida — informes, correos, exports, otras cuentas — para cazar el second-order que los DAST no ven"
Fecha de actualización: 2026-08-04
Nota previa: "[[02 - Espejo de huella del atacante]]"
Nota siguiente: "[[04 - Planificador de spraying con modelo de bloqueo]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 3
Esfuerzo: 3-4 semanas
---
---

**Nombre propuesto**: `dyetrace`

Un escáner web clásico funciona con un bucle cerrado: manda un payload, mira la respuesta, decide. Ese bucle es <mark style="background: #FFB86CA6;">estructuralmente incapaz de ver un fallo de segundo orden</mark>, porque la entrada y la salida ocurren en peticiones distintas, a veces en interfaces distintas y a veces con días de diferencia. El dato entra por el formulario de perfil, se guarda, y sale semanas después en el PDF de facturación que genera un servicio interno con otro motor de plantillas y otros privilegios.

Ahí es donde viven los hallazgos que valen dinero en bug bounty, y donde ningún automatismo te ayuda hoy.

# El problema que resuelve

El pentester acaba haciendo esto a mano: escribe `test123` en cada campo y luego navega la aplicación buscando dónde reaparece. Funciona a pequeña escala y se rompe en cuanto la aplicación tiene cincuenta campos y seis canales de salida. Y sobre todo, <mark style="background: #ADCCFFA6;">se rompe porque `test123` no es único: cuando lo encuentras, no sabes de qué campo vino</mark>.

La idea es sustituir esa exploración manual por trazadores: cada campo recibe un marcador irrepetible, y lo que se automatiza no es la inyección sino la **búsqueda del marcador por toda la superficie de salida**.

# Alcance del proyecto

Tres fases desacopladas, que es lo que permite que la tercera corra durante días.

**Siembra.** Recorre la aplicación y escribe en cada punto de entrada un marcador con estructura propia, del estilo `Dy7a3f9k` — corto, alfanumérico, sin caracteres que disparen validación o codificación. La estructura importa: el marcador debe sobrevivir a HTML-encoding, a URL-encoding, a un `strip_tags` y a una normalización a mayúsculas. Un mapa local asocia cada marcador con su origen: URL, método, parámetro, cuenta usada y momento.

**Cosecha.** Rastrea la superficie de salida buscando marcadores. Y aquí está el valor real del proyecto: la superficie no es solo el HTML de respuesta.

| Canal de salida | Por qué importa |
| --- | --- |
| Respuestas HTML y JSON | El caso base, ya cubierto por los DAST |
| Documentos generados | Facturas y reportes en PDF, XLSX o DOCX. Motor de plantillas distinto → superficie de `SSTI` distinta |
| Correo saliente | Notificaciones y confirmaciones; el marcador viaja a un buzón que controlas |
| Exportaciones a CSV | Superficie clásica de `CSV injection` que casi nadie prueba |
| Vista de otro usuario | Un marcador sembrado por la cuenta A que aparece en la sesión de B es un `IDOR` o una fuga entre inquilinos |
| Panel de administración | Donde acaba el `XSS` que se dispara sobre el que más privilegios tiene |
| Logs y trazas accesibles | Interfaces de observabilidad expuestas donde el dato aparece sin escapar |

**Escalado.** Cuando un marcador reaparece, se sabe exactamente qué campo alimenta qué sumidero, y solo entonces se prueba el payload que corresponde a ese contexto. <mark style="background: #8000E1A6;">Se invierte el orden habitual: primero se descubre el flujo, después se ataca el sumidero</mark> — que es como razona un humano y no como funciona un escáner.

# Funcionalidades principales

- **Alfabeto de marcadores resistente a transformaciones**, con variantes que sobreviven a `urlencode`, entidades HTML, truncado por longitud y cambio de caja. Si un campo trunca a 8 caracteres, el marcador tiene que seguir siendo identificable.
- **Correlación multi-identidad**: siembra con la cuenta A y cosecha con la B y con la de administración. Es lo que convierte el rastreo en detección de `IDOR` de segundo orden y de fugas entre inquilinos.
- **Cosecha diferida y reanudable**: el estado vive en disco, y una pasada de cosecha semanas después contra la misma base de marcadores es una operación normal, no un caso raro.
- **Receptor de correo integrado**, un `SMTP` mínimo que acepta cualquier destinatario y busca marcadores en el cuerpo, en el asunto y en los adjuntos.
- **Extracción de texto de documentos** para buscar dentro de PDF, XLSX y DOCX generados.
- **Grafo de flujo** como salida principal: `entrada → sumidero`, con el contexto de cada sumidero (¿HTML? ¿atributo? ¿plantilla? ¿celda de hoja de cálculo?), que es lo que dicta el payload de la fase tres.

# Qué existe ya y dónde se queda corto

El antecedente académico serio es **Black Widow** (Chalmers, 2021), que introduce exactamente esta idea: inyectar un *taint token* después de fuzzear el parámetro y rastrear su aparición para modelar el flujo entre peticiones. Es un buen artículo y una prueba de concepto, no una herramienta operativa: se limita al HTML y no contempla canales fuera de la respuesta.

En el lado comercial, las **colaboraciones fuera de banda** (el `Collaborator` de Burp y equivalentes) cubren un problema hermano pero distinto: detectan la interacción *de red* que provoca un payload, no el **viaje del dato** por dentro de la aplicación. Y los DAST de mercado siguen puntuando mal en detección de inyección almacenada, algo que la literatura lleva quince años midiendo sin que cambie mucho.

# Cosas a tener en cuenta

> [!warning]+ Sembrar marcadores es escribir en la aplicación del cliente
> Esto no es una prueba pasiva: deja registros, correos enviados a direcciones que controlas y basura en la base de datos del cliente. <mark style="background: #FF5582A6;">Tiene que estar autorizado explícitamente en las reglas de compromiso</mark>, y la herramienta debe llevar un modo de limpieza que revierta lo que pueda revertirse y liste lo que no. Enviar correo desde la infraestructura del cliente hacia fuera puede además afectar a su reputación de dominio.

- **La colisión de marcadores destruye el resultado.** Si dos campos comparten marcador, el grafo miente. Con longitud suficiente el riesgo es despreciable, pero conviene verificar unicidad contra el mapa antes de sembrar, no confiar solo en el generador.
- **El marcador puede no sobrevivir intacto.** Aparecerá partido, con caracteres intercalados o normalizado. La cosecha necesita búsqueda difusa además de exacta, y ahí es donde la mayoría de implementaciones ingenuas fallan en silencio.
- **La aplicación puede tener limpieza asíncrona.** Un trabajo nocturno que purga datos de prueba borra tus marcadores antes de la cosecha. Merece la pena sembrar en dos tandas separadas por un día para detectarlo.
- **Ojo con el ruido en producción.** Marcadores en campos visibles para usuarios reales son un incidente de imagen para el cliente. En entornos con usuarios reales, restringir la siembra a campos no públicos y decirlo en el informe.

# Fuera de alcance

No es un crawler de propósito general —conviene consumir la salida de uno existente— ni un motor de explotación. Termina en el grafo de flujo y en la lista de sumideros con su contexto. Lo que se hace con eso es trabajo del pentester y del arsenal que ya está en el vault.

# Criterio de terminado

Cuando en un laboratorio con `IDOR` de segundo orden y `SSTI` en un PDF generado, la herramienta produce el grafo `campo → sumidero` sin intervención manual, y cuando la cosecha diferida a los siete días recupera correctamente el estado de la siembra.

# Conexiones en el vault

La teoría del ataque está en [[06 - Introducción a los ataques de segundo orden]] y sus variantes concretas en [[08 - Second-Order IDOR (blackbox)]], [[09 - Second-Order LFI]] y [[10 - Second-Order Command Injection]]; la contraparte defensiva, en [[11 - Detección, herramientas y prevención de ataques de segundo orden]]. La metodología de caza que enmarca todo esto vive en el bloque de bug bounty del área web.

> [!info]+ Fuentes
> - Eriksson, Pellegrino & Sabelfeld, [*Black Widow — Blackbox Data-driven Web Scanning*](https://www.cse.chalmers.se/~andrei/bw21.pdf), IEEE S&P 2021 — el modelo de *taint token* entre peticiones y por qué el orden de inyección importa.
> - OWASP WSTG, sección de *Testing for Stored Injection* — metodología manual que este proyecto automatiza.
