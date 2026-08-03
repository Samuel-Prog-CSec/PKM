---
tags:
  - Blue-Team
  - Threat-Modeling
  - Tipo/Introduccion
Descripción: "Modelar amenazas antes de que ocurran con DFD y STRIDE, y el 'guarding' de McCarty frente a la sexta función que el NIST CSF 2.0 sí añadió"
Fecha de actualización: 2026-08-03
Nota previa: ""
Nota siguiente: "[[01 - Sensores defensivos - tipos y colocación]]"
Area: "[[Doctrina defensiva.base|Doctrina defensiva]]"
---
---

Esta área es la cara defensiva de la doctrina de *Cyberjutsu*: donde [[00 - El mindset del atacante persistente|Doctrina pentesting]] lee los pergaminos ninja como el atacante que evade, aquí se leen como el ingeniero de seguridad que <mark style="background: #ADCCFFA6;">diseña la defensa antes de que el ataque ocurra</mark>, en lugar de reaccionar a él. El punto de partida es el *threat modeling*: modelar sistemáticamente qué puede salir mal en un sistema, sin esperar a un incidente que lo demuestre.

# Data Flow Diagram: el mapa del que se parte

El *threat modeling* maduro arranca documentando un `Data Flow Diagram` (DFD): un diagrama que describe cómo fluyen los datos y los procesos dentro del sistema — entradas, procesamiento, salidas, almacenes y los límites de confianza que cruzan. Un [[00 - Principios y metodología de enumeración|mapa de red]] detallado sirve como sustituto aproximado. La ventaja del DFD es que <mark style="background: #8000E1A6;">permite analizar la superficie de ataque de forma estructurada sin necesidad de escanear, explotar ni esperar un incidente</mark>: se razona sobre el sistema documentado.

# STRIDE: qué puede fallar en cada punto

`STRIDE` es la metodología de Microsoft para enumerar amenazas. En cada punto del DFD donde hay entrada, procesamiento, salida o flujo de datos, se pregunta cómo un adversario podría violar seis propiedades:

| Amenaza | Propiedad violada |
| --- | --- |
| **S**poofing (suplantación) | Autenticación |
| **T**ampering (manipulación) | Integridad |
| **R**epudiation (repudio) | No repudio |
| **I**nformation disclosure (divulgación) | Confidencialidad |
| **D**enial of service | Disponibilidad |
| **E**levation of privilege | Autorización |

STRIDE sirve también como filtro de calidad: un modelo de amenaza mal planteado —"el malware compromete la integridad de las bases de datos internas"— no describe **cómo** se entrega el malware, **cómo** afecta la integridad (¿cifra, borra, corrompe?) ni **qué vector** lo permite. <mark style="background: #FFB86CA6;">Un modelo útil nombra el vector, el mecanismo y el control existente</mark>; si no, es una preocupación, no un modelo.

# El "guarding": el control humano que McCarty echaba en falta

El aporte propio de *Cyberjutsu* es el concepto de `guarding`: <mark style="background: #ADCCFFA6;">ejercer control protector sobre un activo mediante observación humana y acción preventiva en tiempo real</mark>, no solo con controles automáticos. La metáfora es el foso del castillo con un guardia que verifica cada paso, frente a un muro que solo puede estar o no estar.

McCarty argumentaba que las cinco funciones del NIST Cybersecurity Framework —Identify, Protect, Detect, Respond, Recover— saltan del *protect* automático al *detect* sin un paso intermedio de vigilancia humana sobre los vectores que **no se pueden parchear**. Su ejemplo del *jump box*: en vez de solo endurecerlo y monitorizar logs, un guardia podría desconectar físicamente el cable de red interno y reconectarlo solo tras verificar con el administrador que la sesión está autorizada, terminándola en cuanto observe algo malicioso.

> [!important]+ La modernización: el CSF sí creció, pero hacia la gobernanza
> *Cyberjutsu* es de 2021 y pedía una función que el marco no tenía. En febrero de 2024, el **NIST CSF 2.0** añadió efectivamente una **sexta función** — pero no fue "Guard", sino **Govern** (gobernanza): la que envuelve a las otras cinco con estrategia, roles, política y gestión de riesgo de la cadena de suministro. Las funciones hoy son **Govern, Identify, Protect, Detect, Respond, Recover**. La lección se mantiene: el control humano en tiempo real sobre vectores no parcheables sigue siendo un hueco que ninguna función automatiza, y por eso el `threat hunting` (búsqueda activa de indicadores de intrusión) es lo más cercano al *guarding* que existe hoy.

El *guarding* no es viable en todas partes —un humano no inspecciona 100.000 paquetes por segundo—, pero sí en los vectores que el threat modeling marca como críticos e imparcheables. Ahí es donde se insertan controles humanos con autoridad para detener la actividad.

# El anti-patrón: seguridad "atornillada"

Los pergaminos advierten sobre el `shinobi-gaeshi`: los pinchos que los defensores colocaban en los puntos vulnerables **le decían al atacante dónde estaban las debilidades**. Su equivalente moderno: <mark style="background: #FF5582A6;">un control de seguridad añadido como parche visible delata el punto flaco que intenta tapar</mark>. Pegamento en un puerto USB anuncia que no has resuelto la seguridad del USB — y se quita con alcohol isopropílico. El principio de diseño: eliminar la debilidad (una placa base sin puertos USB) es superior a taparla de forma que exhiba su existencia. Modela la amenaza, decide qué se puede diseñar fuera del sistema, y guarda solo lo que no se puede purgar.

Las notas siguientes desarrollan las herramientas de esta doctrina: los [[01 - Sensores defensivos - tipos y colocación|sensores]] que dan visibilidad, el [[02 - Zero-trust - bloquear lo sospechoso, no solo lo malicioso|zero-trust]] que reduce la superficie, la [[03 - Deception defensiva - honeypots, tiger traps y captura en vivo|deception]] que atrapa, y la [[04 - Cultura del SOC, complacencia y vigilancia|cultura]] que sostiene todo lo anterior.

> [!info]+ Fuentes
> - NIST, [*Cybersecurity Framework 2.0*](https://www.nist.gov/cyberframework) (feb. 2024) — añade la función **Govern**.
> - A. Shostack / Microsoft, metodología [STRIDE](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats) y *threat modeling* con DFD.
> - Ben McCarty, *Cyberjutsu*, cap. 2 ("Guarding with Special Care"), 2021.
