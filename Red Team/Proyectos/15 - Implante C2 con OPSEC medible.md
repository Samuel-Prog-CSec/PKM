---
tags:
  - Proyectos
  - Go
  - Command-and-Control
  - Evasion
  - Tipo/Proyecto
Descripción: "Un implante C2 para engagements autorizados cuya característica diferenciadora es que mide su propia huella y reporta su detectabilidad, en vez de afirmar su OPSEC por fe"
Fecha de actualización: 2026-08-04
Nota previa: "[[14 - Orquestador de operación]]"
Nota siguiente: ""
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 5
Esfuerzo: 6-8 semanas
---
---

**Nombre propuesto**: `lowprofile`

El área de Desarrollo ofensivo ya construyó un RAT en Go ([[02 - Implante, admin y endurecer el RAT]]). Este proyecto no construye otro C2 —los hay excelentes y *open source*: Sliver, Mythic, Havoc— sino que responde la pregunta que decide si un implante sobrevive a un engagement contra un cliente con EDR maduro: <mark style="background: #FFB86CA6;">¿cuál es tu huella, y cómo sabes que es baja?</mark>. La OPSEC de un implante se suele afirmar por fe —"uso *jitter*, voy por HTTPS"— y `lowprofile` la convierte en una propiedad **medida**.

Antes de nada: esto es una herramienta para engagements **autorizados**, sin capacidades destructivas, y su contribución es la observabilidad de la propia huella, no más potencia ofensiva.

# El problema que resuelve

Un implante deja huella en dos planos. En la **red**: cómo se ve su tráfico —su `JA4`, su perfil temporal, la regularidad de su *beacon*—. En el **sistema**: qué de su comportamiento ven los sensores del host. El operador suele diseñar su OPSEC a ciegas: añade *jitter*, cifra el canal y da por hecho que con eso basta. Pero <mark style="background: #ADCCFFA6;">un *beacon* con *jitter* "aleatorio" que resulta estadísticamente regular se detecta igual</mark> —el `mirror` (02) lo caza por la periodicidad—, y un canal cifrado con un `JA4` que grita "esto no es un navegador" se marca solo. <mark style="background: #8000E1A6;">La OPSEC afirmada no es OPSEC medida</mark>, y esa diferencia es la que quema implantes.

# Alcance del proyecto

Un implante C2 mínimo en Go para engagements autorizados, cuya característica diferenciadora es que **instrumenta y mide su propia huella**. No es un framework completo: es un *beacon* con el bucle de retroalimentación de la detección incorporado. Propiedades de diseño:

- **Canal sobre protocolo de capa de aplicación legítimo** (HTTPS o DoH), cifrado.
- **Beacon con *jitter* cuya distribución se valida** contra la de tráfico legítimo, no un "aleatorio" ingenuo que un test de periodicidad desenmascara.
- **Perfil de tráfico configurable** —tamaño, cadencia, forma—, en la línea del concepto de *malleable profile*.
- **Auto-auditoría.** El implante valida su propia huella de red contra el motor del `mirror` (02) —¿mi `JA4` es coherente?, ¿mi *timing* parece humano?— y contrasta qué de su comportamiento vería un `blindspot` (11). <mark style="background: #FF5582A6;">Reporta su propia detectabilidad</mark>, que es la característica que ningún C2 trae de serie.
- **Teardown fiable**: se retira sin dejar artefactos y lleva la cuenta de lo que tocó.
- **Sin capacidades destructivas**: es un canal de control y un banco de pruebas de OPSEC, no un arma.

# Funcionalidades principales

| Funcionalidad | Por qué importa |
| --- | --- |
| Canal cifrado sobre HTTPS/DoH | Se mezcla con tráfico que el perímetro ya deja salir |
| *Jitter* validado estadísticamente | Evita la periodicidad que delata a un *beacon* ingenuo |
| Auto-auditoría de `JA4` y *timing* | El implante se mira al espejo del `mirror` (02) y reporta si se distingue |
| Informe de detectabilidad propia | Convierte la OPSEC de fe en dato: "esto es lo que de mí se ve" |
| Teardown con inventario | Cada artefacto desplegado se registra y se retira; nada olvidado |
| Sin destrucción, por diseño | La frontera que lo hace una herramienta de engagement y no otra cosa |

# Qué existe ya y dónde se queda corto

**Sliver** (Bishop Fox), **Mythic** y **Havoc** son C2 *open source* maduros, con perfiles de tráfico y múltiples transportes; el RAT del vault (nota 13) es la base didáctica en Go; y el concepto de *malleable profile* de Cobalt Strike es el precedente de moldear el tráfico. Todos permiten configurar la OPSEC. <mark style="background: #FFB8EBA6;">Lo que ninguno hace de serie es medir su propia huella y reportar su detectabilidad</mark>: en esos frameworks la OPSEC es un conjunto de opciones que el operador ajusta por criterio y esperanza. `lowprofile` cierra el bucle midiendo el resultado —un C2 que se auto-audita—. La contribución no es más capacidad ofensiva, sino observabilidad de la huella, que sirve por igual al operador (saber si le ven) y al equipo azul (un banco de pruebas de detección con la verdad-terreno del propio implante).

# Cosas a tener en cuenta

> [!warning]+ Herramienta de engagement autorizado, no de uso libre
> Un implante C2 fuera de una autorización escrita es una intrusión, y punto. <mark style="background: #FF5582A6;">La herramienta debe operar atada a un identificador de engagement, sin capacidades destructivas y con *teardown* obligatorio</mark>. El propósito —y lo único que la hace defendible en un portfolio— es medir y controlar la huella, no maximizar el impacto. Un C2 que añade *wiping*, *ransomware* o sabotaje deja de ser este proyecto.

- **OPSEC medida supera a OPSEC afirmada, pero se mide contra tu modelo.** El `mirror` compara contra una base de perfiles de navegador; si esa base caduca, tu "coherente" miente con confianza. La auto-auditoría hereda la fecha de caducidad del `mirror` (02), y hay que tratarla como tal.
- **La mejor huella no siempre es la más oculta.** En un ejercicio no evasivo, un implante honesto y reconocible es la decisión correcta —y el equipo azul lo agradece—. La herramienta debe servir igual para parecerse a tráfico normal que para ser deliberadamente identificable como el pentester autorizado.
- **Un C2 propio es un pasivo de seguridad.** Si el implante tiene un fallo de autenticación en su canal, le has entregado al mundo una puerta trasera. Endurecer el canal —lo que ya trata la nota 13— es parte del proyecto, no un adorno posterior.
- **No competir en capacidades con Sliver o Mythic.** El día que intentas igualar su cobertura de transportes y funciones, has perdido el foco. El proyecto es la OPSEC medible; todo lo demás es de esos frameworks, y está bien que lo sea.

# Fuera de alcance

No es un framework de post-explotación completo ni compite con Sliver/Mythic en capacidades. **Sin capacidades destructivas de ningún tipo.** No incluye exploits ni técnicas concretas de evasión de EDR: mide la huella, no la esconde a la fuerza. El acceso inicial es otro problema —esto asume ejecución ya lograda dentro de un engagement autorizado— y la ejecución del ataque no es su cometido.

# Criterio de terminado

Cuando el implante mantiene un canal de control estable sobre HTTPS/DoH en un laboratorio, se auto-audita reportando su `JA4` y la regularidad de su *beacon*, y —puesto frente al `mirror` (02)— este no lo distingue de tráfico legítimo por las señales groseras; y cuando el *teardown* deja el host sin artefactos y con el inventario de lo desplegado a cero.

# Conexiones en el vault

La base técnica es el RAT de [[02 - Implante, admin y endurecer el RAT]], con su [[01 - El servidor C2 - proxy con channels]] y su [[00 - Diseñar la API C2 con gRPC y Protobuf]]; el endurecimiento del binario, [[02 - OPSEC del binario Go]]. La auto-auditoría de red se apoya en el [[02 - Espejo de huella del atacante]] y la de sistema en el [[11 - Auditor de visibilidad de EDR]] —este proyecto es, en cierto modo, lo que se pone **frente** a esos dos espejos—. Por qué la huella importa y hasta qué peldaño persigue el defensor, en [[01 - Frameworks de threat intelligence y la Pyramid of Pain]].

> [!info]+ Fuentes
> - Bishop Fox, [`Sliver`](https://github.com/BishopFox/sliver) — C2 *open source* de referencia en Go; el estado del arte de perfiles y transportes que `lowprofile` **no** intenta igualar (consultado 2026-08-04).
> - MITRE ATT&CK, [*Application Layer Protocol* (T1071)](https://attack.mitre.org/techniques/T1071/) — la técnica de canal que el implante emula, y la telemetría que el defensor busca.
> - FoxIO, [especificación de JA4+](https://github.com/FoxIO-LLC/ja4) — el fingerprint de red que la auto-auditoría calcula sobre el propio tráfico, compartido con el `mirror` (02).
