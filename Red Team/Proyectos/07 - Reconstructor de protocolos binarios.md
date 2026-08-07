---
tags:
  - Proyectos
  - Go
  - Reversing
  - Tipo/Proyecto
Descripción: "Infiere la estructura de un protocolo binario propietario desde capturas y emite un dissector usable, cerrando el hueco entre los papers académicos y el arsenal del pentester"
Fecha de actualización: 2026-08-04
Nota previa: "[[06 - Cartógrafo de pivoting y alcanzabilidad]]"
Nota siguiente: "[[08 - Escáner de seguridad de servidores MCP]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 4
Esfuerzo: 4-5 semanas
---
---

**Nombre propuesto**: `protoforge`

Un protocolo binario propietario —el que habla un termostato con su nube, un cliente de trading con su bróker, una cámara con su NVR— es una caja negra sin RFC. Antes de fuzzearlo, interceptarlo o encontrarle un fallo, hay que entender su estructura, y hoy eso son horas mirando *hex dumps* en Wireshark buscando a ojo dónde está el campo de longitud y cuál es el checksum. <mark style="background: #FFB86CA6;">Ese trabajo manual es el peaje de entrada a todo lo demás</mark>, y es exactamente lo que el vault describe paso a paso en [[05 - Del hex dump a la estructura del protocolo]]. Este proyecto lo automatiza.

# El problema que resuelve

La inferencia de formato de protocolo lleva quince años resuelta en la academia y sin resolver en la práctica. Hay una línea de investigación sólida —Netzob, NEMESYS, NetPlier, DynPRE— que reconstruye la sintaxis de un protocolo a partir de sus mensajes. El problema no es la teoría: es que <mark style="background: #ADCCFFA6;">esas herramientas son artefactos de paper —Python, mantenimiento irregular, pensadas para producir una métrica de precisión sobre un dataset, no para usarse en un engagement</mark>. El pentester que se topa con un protocolo desconocido acaba abriendo Wireshark y contando bytes.

El objetivo de `protoforge` no es mejorar el F1 de identificación de campos. Es <mark style="background: #8000E1A6;">producir el artefacto que un pentester usa **después** de entender el protocolo</mark>: un *dissector* que enchufas al proxy y un modelo que alimenta al fuzzer.

# Alcance del proyecto

Consume capturas (`pcap`/`pcapng`) de un protocolo desconocido y produce un **modelo estructural** del mensaje: fronteras de campo, tipo inferido de cada campo (longitud, tipo/discriminador TLV, offset, checksum, secuencia, texto, *padding*, constante) y la separación cabecera fija ↔ cuerpo variable. Dos motores que se complementan:

- **Inferencia pasiva** sobre el corpus: alineamiento de secuencias entre mensajes del mismo tipo, más heurísticas de estructura (entropía por *offset* para separar campos estables de variables, correlación entre un valor numérico y la longitud real del mensaje para cazar el campo de tamaño).
- **Verificación activa opcional**, en la línea de DynPRE: sondea el servicio con variaciones controladas de un mensaje conocido y observa la respuesta. Es la única forma de <mark style="background: #FFB8EBA6;">desambiguar lo que la captura pasiva no puede</mark>: un byte que siempre vale `0x04` puede ser una constante o un campo de longitud que casualmente coincidió en todo el corpus; solo cambiándolo y viendo si el servidor se queja lo sabes.

La salida no es un informe de métricas, sino un artefacto: una especificación **Kaitai Struct** y/o un *dissector* de Wireshark en Lua, listos para consumir por el resto del arsenal.

# Funcionalidades principales

| Funcionalidad | Por qué importa |
| --- | --- |
| Detección del campo de longitud | Correlaciona cada campo numérico con el tamaño real del mensaje. Es el campo que más gobierna el parseo y el primero que hay que recalcular para fuzzear |
| Detección de checksum / CRC | El campo que varía de forma impredecible y cuya alteración rompe la respuesta del servidor. Sin identificarlo, cada paquete mutado se descarta y el fuzzing no avanza |
| Reconocimiento de TLV | Detecta el patrón tipo-longitud-valor y la multiplexación, que estructura la mayoría de protocolos binarios serios |
| Cabecera fija vs cuerpo variable | Separa lo que se repite en cada mensaje de lo que cambia por tipo — la base para clasificar mensajes |
| Inferencia de máquina de estados | El orden legal de los mensajes (handshake → datos → cierre), como hace NetPlier. Un fuzzer que no respeta el estado nunca pasa del primer mensaje |
| Exportación a Kaitai y a Lua | El resultado se abre en Wireshark y se reutiliza; no se queda en un JSON que nadie vuelve a mirar |

# Qué existe ya y dónde se queda corto

La genealogía académica es clara y conviene conocerla porque es de donde salen las heurísticas:

- **Netzob** (2012) introdujo el alineamiento de secuencias para inferir fronteras de campo alineando valores comunes entre mensajes.
- **NEMESYS** (WOOT 2018) trabaja la estructura intrínseca de cada mensaje individual con heurísticas sobre las características del dato.
- **NetPlier** (NDSS 2021) es el salto probabilístico: agrupa por tipo de mensaje, infiere formato **y** máquina de estados.
- **DynPRE** (NDSS 2024) es el estado del arte y el más relevante aquí: abandona el análisis puramente pasivo e **interactúa con el servidor** para inferir dinámicamente, que es justo lo que la captura estática no puede resolver.

La lista curada `techge/PRE-list` recoge decenas más. Todas comparten el mismo techo: <mark style="background: #FF5582A6;">terminan en "campos identificados con tal exactitud", no en un dissector que un operador enchufa al proxy</mark>. El hueco real no es un algoritmo mejor —los que hay bastan— sino una herramienta operativa, en un binario único, que produce el artefacto en vez de la métrica.

# Cosas a tener en cuenta

> [!warning]+ La inferencia pasiva miente con confianza
> Un campo que es constante en todo tu corpus parece un *magic number*, pero puede ser un *flag* que nunca se activó en tu captura, o un campo de versión con un solo valor observado. <mark style="background: #FFB8EBA6;">La confianza del modelo depende por completo de la diversidad del tráfico que le des</mark>. La herramienta debe reportar el tamaño y la variedad del corpus junto a cada inferencia, y bajar la confianza cuando un campo se apoya en pocas muestras — nunca presentar una conjetura como un hecho.

- **El sondeo activo es tráfico y es ruido.** Cambiar bytes y ver cómo responde el servicio genera paquetes anómalos y puede tumbar un servicio frágil. Es una capacidad para tu propio laboratorio o para un objetivo explícitamente autorizado, con la cadencia bajo control; nunca el modo por defecto.
- **El cifrado corta el análisis en seco.** Si el protocolo viaja sobre TLS, primero hay que estar en medio del canal (el terreno de [[07 - Modificar el protocolo en vuelo]] y el MITM de red); si el cifrado es a nivel de aplicación sobre el propio *payload*, la inferencia estructural no ve nada útil y hay que atacar antes la capa cripto.
- **Longitud y checksum no son campos cualesquiera.** Son precisamente los que un fuzzer tiene que recalcular en cada mutación o el objetivo descarta el paquete antes de procesarlo. Por eso la salida del reconstructor tiene que poder alimentar directamente el harness de [[01 - Construir el corpus y el harness]] — es la razón de ser de todo el proyecto.
- **"Campo que varía" no es "campo importante".** La entropía te dice dónde está el cambio, no dónde está el interés. Un *timestamp* varía en cada mensaje y rara vez lleva a nada; un discriminador de tipo con tres valores posibles es la puerta a tres parseadores distintos. El modelo debe priorizar por rol inferido, no por variabilidad.

# Fuera de alcance

No es un fuzzer ni un proxy: produce el modelo que ambos consumen. No rompe cifrado. Y no pretende certeza total sobre protocolos arbitrariamente complejos —los formatos con compresión o cifrado interno quedan fuera del primer alcance—; el objetivo es convertir horas de conteo manual de bytes en minutos de revisión de un modelo ya casi correcto.

# Criterio de terminado

Cuando, tomando un protocolo binario conocido como verdad-terreno (DNS o Modbus sirven: están documentados pero la herramienta no los conoce), reconstruye correctamente el campo de longitud, el discriminador de tipo y la estructura de cabecera sin información previa; y cuando el *dissector* Kaitai/Lua que genera abre y descompone bien una captura **nueva** del mismo protocolo dentro de Wireshark.

# Conexiones en el vault

El proceso manual que automatiza está en [[05 - Del hex dump a la estructura del protocolo]]; las estructuras que infiere, en [[00 - Anatomía de un protocolo binario]], [[01 - Datos de longitud variable]] y [[02 - El patrón TLV, multiplexación y fragmentación]]; el formato de salida, en [[06 - Identificación de estructuras con Kaitai Struct]]. La salida alimenta el fuzzing de [[01 - Construir el corpus y el harness]], y una vez se tiene la estructura, el terreno natural de caza son los [[09 - Conversión de codificaciones y parser differentials]].

> [!info]+ Fuentes
> - Ye et al., [*NetPlier — Probabilistic Network Protocol Reverse Engineering from Message Traces*](https://www.ndss-symposium.org/wp-content/uploads/ndss2021_4A-5_24531_paper.pdf), NDSS 2021 — inferencia de formato y de máquina de estados (consultado 2026-08-04).
> - Luo et al., [*DynPRE — Protocol Reverse Engineering via Dynamic Inference*](https://fouzhe.github.io/publications/paper/NDSS24-DynPRE.pdf), NDSS 2024 — la inferencia activa por interacción con el servicio, el estado del arte.
> - Kleber et al., [*NEMESYS — Network Message Syntax Reverse Engineering*](https://www.usenix.org/system/files/conference/woot18/woot18-paper-kleber.pdf), WOOT 2018 — heurísticas de estructura sobre el mensaje individual.
> - [`techge/PRE-list`](https://github.com/techge/PRE-list) — inventario curado de herramientas de *protocol reverse engineering*, útil para no reinventar heurísticas.
