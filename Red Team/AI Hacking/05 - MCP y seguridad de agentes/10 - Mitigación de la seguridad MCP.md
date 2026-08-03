---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Reporting
  - Tipo/Defensa
Descripción: "La defensa de MCP se reparte entre quien implementa un servidor y quien conecta un cliente a servidores de terceros, y ambos lados tienen requisitos concretos de la spec oficial"
Fecha de actualización: 2026-07-29
Nota previa: "[[09 - CVEs y ataques reales de MCP]]"
Nota siguiente: "[[11 - Detección y evasión en MCP]]"
Area: "[[MCP.base|MCP]]"
---
---

<mark style="background: #ADCCFFA6;">La defensa de MCP se reparte en dos roles con problemas distintos: quien **implementa** un servidor y quien **conecta** un cliente a servidores de terceros.</mark> HTB da recomendaciones genéricas correctas; esta nota las organiza por rol y las ancla en los requisitos concretos de la spec oficial, que es lo que se cita en un informe.

# Si implementas un servidor MCP

## Seguir la especificación al pie de la letra

Un protocolo mal implementado genera bugs explotables. La spec tiene requisitos de seguridad **verificables**, no opcionales:

- **Validar la cabecera `Origin`** en `Streamable HTTP` (HTTP 403 si es inválida) para cortar [[04 - DNS Rebinding para bypass de Same-Origin Policy|DNS rebinding]]. Especialmente crítico en servidores locales alcanzables desde el navegador.
- **No implementar el protocolo a mano.** Usar un SDK probado y mantenido — pero manteniéndolo actualizado, porque los propios SDKs tienen [[09 - CVEs y ataques reales de MCP|CVEs]].
- **Verificar autorización en toda petición** (modelo stateless), sin tratar un `state handle` como autenticación. Handles no deterministas ligados al usuario.

## Configurar de forma restrictiva

- **Exponer lo mínimo.** El servidor accesible solo localmente o en la interfaz estrictamente necesaria, nunca en `0.0.0.0` por defecto.
- **Autenticación** propia si aplica, y **TLS/HTTPS obligatorio** al exponer a sistemas externos — MCP no cifra ni protege integridad por sí mismo, así que sin TLS hay `man-in-the-middle`.

## Tratar todo argumento como no confiable

El error de fondo de casi todos los servidores vulnerables: creer que el cliente LLM filtra. **No filtra, y además cualquiera con acceso de red llama a las capacidades directamente.**

- Validación y saneado en cada capacidad → corta [[04 - Inyecciones en servidores MCP|SQLi, command injection, SSRF]].
- Consultas parametrizadas, sin `shell`, validación de URL con lista blanca.
- Manejo exhaustivo de excepciones → corta la [[05 - Divulgación de información y broken authorization|divulgación de información]].
- **Mínimo privilegio del proceso** y de la credencial del servidor → limita el impacto de cualquier inyección que se cuele y elimina el `IDOR` de raíz.

## Reforzar con defensa en profundidad

Rol y permisos granulares, monitorización, `rate limiting`, y `sandboxing` de las capacidades que ejecutan código. [Herramientas como mcp-scan](https://github.com/invariantlabs-ai/mcp-scan) ayudan a identificar vulnerabilidades en el propio servidor antes de desplegarlo — ver [[00 - Qué es mcp-scan y qué detecta|su ficha]].

# Si conectas un cliente a servidores de terceros

Aquí el riesgo se invierte: el peligro es el **servidor**, no tu código.

## Verificar antes de conectar

- **Origen y URL del servidor.** Un servidor MCP es código de terceros con acceso a tu contexto; conectarse a uno de origen no verificado puede costar una fuga de datos. Verificar la fuente y la corrección de la URL de destino.
- **Escanear las descripciones de herramientas** —crudas, no las renderizadas— buscando instrucciones ocultas antes de integrarlas. Es la defensa contra [[06 - Tool poisoning y prompt injection vía descripción|tool poisoning]] y su ocultación con caracteres invisibles.

## Contener lo que el servidor puede hacer

- **No compartir con el LLM lo que no quieras que vea el servidor.** Nada de contraseñas ni API keys en un contexto con servidores MCP no confiables.
- **Tool pinning con hash** para detectar [[07 - Rug pull y tool shadowing|rug pulls]]: fijar la definición aprobada y rechazar cambios.
- **Aislar servidores de distinto nivel de confianza** en agentes o sesiones separadas, para cortar el `tool shadowing`.
- **Re-validar** las definiciones en cada uso, no solo al aprobar — la lección de [[09 - CVEs y ataques reales de MCP|MCPoison]].

## Vigilar la cadena de suministro

Un servidor MCP es una dependencia (`ASI04`). Como demostró [[09 - CVEs y ataques reales de MCP|postmark-mcp]], puede empezar limpio y envenenarse en una actualización:

- **Fijar versiones** y revisar los `diffs` de cada actualización, sobre todo de servidores con acceso sensible.
- **SBOM y escaneo** del ecosistema de servidores MCP como cualquier dependencia.
- **Preferir servidores auditados** y de mantenedores reputados; tratar los oscuros como código no confiable.

# El punto que engloba todo

<mark style="background: #8000E1A6;">La raíz de la mayoría de los problemas de MCP es una frontera de confianza mal trazada:</mark> el servidor cree que el cliente es de fiar, el cliente cree que el servidor es de fiar, y el host mezcla en un mismo `prompt` capacidades de fuentes con distinto nivel de confianza sin aislarlas. Ninguna recomendación puntual arregla eso; lo arreglan los [[13 - Defensas modernas contra prompt injection|patrones de defensa por diseño]] —CaMeL, dual-LLM, mínimo privilegio por capacidad— aplicados al ecosistema de agentes.

> [!important]+ Lo que se reporta al cliente
> Un informe de seguridad de un despliegue MCP no se queda en "el servidor X tiene SQLi". Cubre los dos roles: **como operador de servidores** (validación, exposición, privilegios, versión del SDK) y **como consumidor de servidores de terceros** (verificación de origen, pinning, aislamiento, gestión de la cadena de suministro). El segundo bloque es el que casi nadie tiene cubierto y el que más valor aporta señalar, porque es donde están los incidentes reales de 2025-2026.
