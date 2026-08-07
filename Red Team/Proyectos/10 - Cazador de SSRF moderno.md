---
tags:
  - Proyectos
  - Go
  - Web/Red-Team
  - Server-Side
  - Tipo/Proyecto
Descripción: "Cazador de SSRF que razona sobre la primitiva que controlas (método, cabeceras, esquema) para elegir bypasses y metadata cloud, con servidor OOB propio correlacionado por payload"
Fecha de actualización: 2026-08-04
Nota previa: "[[09 - Priorizador de superficie de ataque]]"
Nota siguiente: "[[11 - Auditor de visibilidad de EDR]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 4
Esfuerzo: 4 semanas
---
---

**Nombre propuesto**: `farside`

El SSRF es la vulnerabilidad que convierte "el servidor hace una petición por ti" en <mark style="background: #FFB86CA6;">"el servidor te abre su red interna y te presta las credenciales de su rol en la nube"</mark>. Pero encontrarlo y explotarlo en 2026 ya no es mandar `http://169.254.169.254/` y ver qué sale: los filtros han mejorado, IMDSv2 exige un *handshake* que un simple GET no puede hacer, y el caso más común —el SSRF ciego— no devuelve nada por el canal principal. La distancia entre "creo que hay un SSRF aquí" y "he confirmado qué alcanza" es donde se pierde el tiempo.

# El problema que resuelve

Los escáneres tratan el SSRF como una lista de URLs que disparar contra el parámetro y observar. El problema es que <mark style="background: #ADCCFFA6;">SSRF no es una vulnerabilidad, es una familia de primitivas distintas</mark>: a veces controlas solo la URL de destino, a veces el método HTTP, a veces las cabeceras, a veces el esquema, a veces si se siguen redirecciones. Y **lo que puedes conseguir depende por completo de cuál tengas**.

El ejemplo que lo resume es IMDSv2: exige un token que se pide con un `PUT` y una cabecera concreta, así que <mark style="background: #8000E1A6;">es una mitigación sólida si tu primitiva solo permite GET, y trivial si controlas método y cabeceras</mark> —como se demostró en el bloque de *webhooks* de Typebot.io en noviembre de 2025—. Lanzar todos los payloads contra todas las primitivas es ruido. Razonar sobre qué primitiva tienes delante es señal.

# Alcance del proyecto

Una navaja especializada en la clase SSRF —no un DAST generalista— con tres piezas:

- **Modelo de la primitiva.** Caracteriza qué controla el operador (destino, método, cabeceras, esquema, redirecciones seguidas) y de ahí deriva qué objetivos y qué bypasses son siquiera alcanzables. Es lo que evita disparar a ciegas y lo que hace que el veredicto "IMDSv2 no es alcanzable con esta primitiva" sea un resultado, no un silencio.
- **Motor de bypasses de filtro.** Genera las representaciones de una URL que explotan la divergencia entre el parser que *valida* y el que *hace la petición* —el corazón del trabajo de Orange Tsai sobre parsers de URL—: confusión de parser, formas IPv6, codificaciones alternativas de la IP, y DNS rebinding. Automatiza lo que hoy es una *cheat sheet* aplicada a mano.
- **Canal OOB propio.** Un servidor DNS + HTTP autoalojado que registra cada interacción entrante y <mark style="background: #FF5582A6;">la correlaciona con el payload exacto que la disparó</mark>. Para el SSRF ciego es la única confirmación posible, y hacerlo con infraestructura propia evita depender de un Collaborator de pago o de un `interactsh` público al que le mandas la prueba de la vulnerabilidad de tu cliente.

# Funcionalidades principales

| Funcionalidad | Por qué importa |
| --- | --- |
| Perfilado de la primitiva | Decide qué es alcanzable antes de disparar; menos tráfico, más señal, y un "no alcanzable" honesto |
| Cobertura cloud actualizada | AWS IMDSv1/v2 *method-aware*, GCP (`Metadata-Flavor`), Azure — cada uno con su requisito real, no una URL genérica |
| Bypasses por *parser differential* | Ataca la divergencia validador↔cliente, que es donde viven los filtros rotos de verdad |
| DNS rebinding integrado | Resolver propio con TTL corto para saltarse el filtro que valida el nombre y luego reconecta |
| OOB correlacionado por payload | Convierte el SSRF ciego en confirmado, y dice **qué** payload lo logró, no solo que "algo" llegó |
| Escaneo interno con presupuesto | Si la primitiva permite sondear puertos internos, con cadencia controlada — nunca un barrido a discreción |

# Qué existe ya y dónde se queda corto

- **SSRFmap** fue la referencia, pero es de 2018-2019 y su mantenimiento está parado; no conoce las mitigaciones cloud actuales.
- **SSRFKiller** es un framework reciente y capaz (bypass, cosecha de metadata, escaneo de puertos, `gopher`/`dict`/`ldap`), en la línea "lanza el catálogo completo".
- **interactsh** resuelve el OOB, pero su modo público manda la señal a infraestructura de terceros.
- **Gopherus** genera los payloads `gopher` para Redis/Memcached y similares.

Son buenas piezas y `farside` no reinventa el catálogo de payloads. <mark style="background: #FFB8EBA6;">El hueco es el enfoque</mark>: los frameworks disparan a discreción y asumen GET; `farside` razona sobre la primitiva para no malgastar ruido, trae el OOB autoalojado y correlacionado, y mantiene la cobertura cloud al día de las mitigaciones de 2026.

# Cosas a tener en cuenta

> [!warning]+ Confirmar un ciego puede tocar a terceros
> Un payload que resuelve a un dominio que controlas es limpio. Uno que aprovecha la primitiva para barrer los rangos internos del cliente es un escaneo interno con todas sus consecuencias —ruido, IDS, y potencialmente tocar sistemas fuera de alcance—. <mark style="background: #FF5582A6;">El escaneo por SSRF tiene que ser explícito, con presupuesto y registrado</mark>, nunca un efecto colateral de la confirmación.

- **IMDSv2 no es un reto a superar siempre.** Si la primitiva no da método y cabecera, no hay *handshake* posible, y forzarlo es perder el tiempo. Reportar la limitación es parte del trabajo; fingir que se intentó, no.
- **El OOB propio necesita infraestructura del pentester.** Un dominio y un DNS que controles, documentados como tuyos —igual que el receptor de correo del `dyetrace` (03)—, nunca montados sobre activos del cliente.
- **Los esquemas exóticos envejecen.** `gopher`, `dict` y `file` amplían el impacto, pero muchos clientes HTTP modernos ya no los siguen. Comprobar que el cliente objetivo los acepta antes de construir el payload sobre esa suposición.
- **La confusión de parser depende del backend.** El bypass que funciona contra el parser de un lenguaje falla contra otro. El motor tiene que saber —o probar— contra qué implementación juega, no asumir una universal.

# Fuera de alcance

No es un DAST ni un *crawler*: se le entrega el punto de inyección, no lo busca. No explota más allá de demostrar el alcance (leer un endpoint de metadata, confirmar la interacción OOB); el pivote posterior hacia la red interna es otro trabajo y otro proyecto ([[06 - Cartógrafo de pivoting y alcanzabilidad]]).

# Criterio de terminado

Cuando, en un laboratorio con SSRF filtrado y un endpoint de metadata IMDSv2, confirma el ciego mediante la interacción OOB correlacionada con su payload; completa el *handshake* IMDSv2 **si y solo si** la primitiva da método y cabecera; y, cuando no los da, lo declara en lugar de reportar un falso negativo silencioso.

# Conexiones en el vault

La base está en [[01 - Introducción a SSRF]] y el caso ciego en [[04 - Blind SSRF]]; los bypasses que sistematiza, en [[05 - Evasión de defensas SSRF]] y [[02 - Bypasses básicos de filtros SSRF]]; el rebinding, en [[03 - DNS Rebinding para bypass de filtros SSRF]] e [[01 - Introducción a DNS Rebinding]]. El arsenal del que parte, en [[07 - Arsenal de herramientas SSRF]]. El OOB correlacionado por payload es el mismo patrón de marcadores del [[03 - Rastreador de flujo de datos de caja negra]].

> [!info]+ Fuentes
> - Orange Tsai, [*A New Era of SSRF — Exploiting URL Parsers in Trending Programming Languages*](https://www.blackhat.com/docs/us-17/thursday/us-17-Tsai-A-New-Era-Of-SSRF-Exploiting-URL-Parser-In-Trending-Programming-Languages.pdf), Black Hat USA 2017 — la base de los bypasses por confusión de parser (consultado 2026-08-04).
> - YesWeHack, [*The ultimate Bug Bounty guide to exploiting SSRF vulnerabilities*](https://www.yeswehack.com/learn-bug-bounty/server-side-request-forgery-ssrf) — estado del arte de explotación 2026, incluido el *method-aware* de IMDSv2.
> - AWS, [documentación de IMDSv2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html) — el requisito real del token (`PUT` + cabecera) que define si la primitiva alcanza.
> - ProjectDiscovery, [`interactsh`](https://github.com/projectdiscovery/interactsh) — el modelo de OOB que `farside` autoaloja en vez de delegar en un tercero.
