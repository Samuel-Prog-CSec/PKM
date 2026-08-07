---
tags:
  - Proyectos
  - Go
  - Pentesting
  - Tipo/Proyecto
Descripción: "Une el guardián de alcance, el registro de operación y el cartógrafo de red en un plano de control único que correlaciona cada acción con su alcance y su ruta"
Fecha de actualización: 2026-08-04
Nota previa: "[[13 - Explotador de condiciones de carrera]]"
Nota siguiente: "[[15 - Implante C2 con OPSEC medible]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 5
Esfuerzo: 6-8 semanas
---
---

**Nombre propuesto**: `overwatch`

Los proyectos 00, 01 y 06 resuelven por separado tres problemas de todo engagement: no salirte del alcance, no perder el registro de lo que hiciste, y no operar a ciegas por la red interna. Pero en un engagement real <mark style="background: #ADCCFFA6;">esos tres no son independientes</mark>: cada acción ocurre **desde** un punto de la red, **contra** un destino, y queda **registrada**. Tenerlos en tres herramientas que no comparten estado es tener tres cuadernos que no se hablan, y hacer la correlación entre ellos —a mano, en la cabeza del operador— hasta que el engagement termina y ese conocimiento se pierde. Este es el proyecto que los une en un solo plano de control.

# El problema que resuelve

Un operador maneja media docena de herramientas sin estado común: el alcance vive en un PDF firmado, el registro en el *scrollback* de una terminal, el mapa de la red en capturas sueltas. La pregunta que importa —<mark style="background: #FFB86CA6;">¿esta acción registrada estaba en alcance, desde qué pivote salió, hacia qué segmento fue?</mark>— no la responde ninguna herramienta: la ensambla el operador mentalmente y se evapora al cerrar el portátil.

Las plataformas que existen resuelven la colaboración y el reporting, pero <mark style="background: #8000E1A6;">están construidas alrededor del C2 y la post-explotación</mark>, no hacen cumplir el alcance como control técnico, y no modelan la red. El hueco es un plano de gobernanza que sí lo haga.

# Alcance del proyecto

Un plano de control que une los tres controles técnicos del catálogo y expone una consola única. No reimplementa ninguno: los orquesta.

- **Alcance en línea** (`scopeguard`, 00): el guardián como servicio central por el que salen todas las herramientas.
- **Registro con integridad** (`flightrec`, 01): el *oplog* automático y encadenado que alimenta el plano sin que nadie lo escriba a mano.
- **Grafo de red** (`reachmap`, 06): el mapa de alcanzabilidad, vivo y consultable.
- **Correlación.** Cada entrada del registro se cruza con el alcance (¿dentro o fuera?) y con el grafo (¿desde qué agente, hacia qué segmento?). <mark style="background: #FF5582A6;">Esa correlación es lo que ninguna herramienta suelta puede producir</mark>, porque requiere las tres fuentes a la vez.
- **Consola.** El estado de la operación de un vistazo —qué está en alcance, qué se ha tocado, dónde estás en la red, qué denegó el guardián—, exportable hacia la plataforma de reporting (Ghostwriter, SysReptor).

# Funcionalidades principales

| Funcionalidad | Por qué importa |
| --- | --- |
| Guardián de alcance como servicio central | El alcance deja de ser un dato y pasa a ser el control por el que fluye todo |
| *Oplog* correlacionado con alcance y grafo | Cada acción sabe si estaba autorizada y desde dónde se lanzó |
| Estado de operación en tiempo real | El operador ve la foto completa sin reconstruirla de memoria |
| Exportación a reporting | La línea temporal sale hacia Ghostwriter/SysReptor sin trabajo manual |
| Custodia unificada | Un solo punto de cifrado y destrucción para todo lo sensible del engagement |
| Binario único | Corre en la máquina de salto del cliente sin desplegar una plataforma entera |

# Qué existe ya y dónde se queda corto

**Ghostwriter** (SpecterOps), con su **Oplog**, automatiza el registro de comandos vía API e integra con los C2 (Mythic, Cobalt Strike); gestiona además el proyecto y el reporting. El **team server** de Cobalt Strike da colaboración y *logging* centrados en el C2, y **RedEye** visualiza los *logs* de esa actividad. Son plataformas maduras.

Pero todas comparten el mismo centro de gravedad —la post-explotación y el C2— y <mark style="background: #FFB8EBA6;">ninguna hace cumplir el alcance como control técnico ni modela la topología de la red</mark>. `overwatch` no compite con Ghostwriter como plataforma de reporting: **exporta hacia ella**. Lo que añade es la capa de gobernanza que le falta —el alcance como enforcement en línea, no como campo de formulario, y la correlación con el grafo de red—, empaquetada en un plano ligero para el operador que no despliega un *team server* completo. El valor del proyecto no es una técnica: es <mark style="background: #8000E1A6;">demostrar que sabes diseñar un sistema coherente a partir de piezas propias</mark>.

# Cosas a tener en cuenta

> [!warning]+ El plano de control concentra todo lo sensible del engagement
> Alcance, credenciales del *oplog* y topología de la red del cliente, en un solo sitio. <mark style="background: #FF5582A6;">Es el objetivo más valioso que un adversario podría querer, y su compromiso es el peor desenlace posible del engagement</mark>. Cifrado en reposo, autenticación fuerte entre agentes y consola, y destrucción tras la retención acordada —heredado de los proyectos 01 y 06, y aquí multiplicado porque todo converge—.

- **Es un integrador; su valor depende de lo integrado.** Si `scopeguard`, `flightrec` o `reachmap` no están sólidos, `overwatch` amplifica sus fallos en vez de taparlos. Se construye **después** de los tres, nunca antes —es, literalmente, el último proyecto que tiene sentido abordar—.
- **No debe convertirse en un C2.** La tentación de añadir ejecución de comandos o *tasking* de agentes lo transforma en un framework de post-explotación, con otro perfil de riesgo y otra conversación legal. `overwatch` **gobierna y observa; no ejecuta el ataque**. Esa frontera es el diseño.
- **La consola es superficie de ataque nueva.** Un *dashboard* web mal hecho es una vulnerabilidad que te expone durante el propio engagement. Minimalismo y binario único, no una SPA con cincuenta dependencias que auditar.
- **Correlación no es certeza.** Que el *oplog* diga "acción X desde el agente Y" y el grafo diga "Y alcanza Z" no prueba que X tocara Z. La correlación se hace por datos reales —el destino efectivo de la conexión—, no por inferencia sobre el grafo, o se convierte en una conjetura con aspecto de hecho.

# Fuera de alcance

No es un C2 y no ejecuta el ataque. No es una plataforma de reporting: exporta hacia las que existen. No reimplementa `scopeguard`, `flightrec` ni `reachmap` —los orquesta—. Es el pegamento con criterio, no un sustituto de sus piezas.

# Criterio de terminado

Cuando, en un engagement simulado con los tres componentes activos, la consola muestra en tiempo real qué está en alcance, qué se ha tocado y desde qué punto de la red; una denegación del guardián aparece correlacionada con el intento exacto que la provocó; y el *export* produce la línea temporal de la operación lista para el informe sin una sola línea escrita a mano.

# Conexiones en el vault

Los tres proyectos que integra son [[00 - Guardián de alcance para engagements]], [[01 - Registro de operación a prueba de manipulación]] y [[06 - Cartógrafo de pivoting y alcanzabilidad]]. El RoE que alimenta el alcance está en [[04 - Pre-engagement II - RoE y kick-off]]; la exigencia de evidencia por nivel de evasividad, en [[12 - Niveles de evasividad y testing dirigido por amenazas (TLPT)]]; el arsenal de la fase, en [[13 - Arsenal de gestión del engagement]]. La salida alimenta [[02 - Evidencias, capturas y redacción]] y las plataformas de [[08 - Arsenal de herramientas de documentación y reporting]].

> [!info]+ Fuentes
> - SpecterOps, [*Updates to Ghostwriter — UI and Operation Logs*](https://posts.specterops.io/updates-to-ghostwriter-ui-and-operation-logs-d6b3bc3d3fbd) — el modelo de *oplog* automático vía API hacia el que `overwatch` exporta (consultado 2026-08-04).
> - Ghostwriter, [*Setting up Automated Logging*](https://www.ghostwriter.wiki/features/operation-logs/setting-up-automated-logging) — cómo se alimenta un *oplog* desde las herramientas, el precedente de integración.
> - CISA, [`RedEye`](https://github.com/cisagov/RedEye) — visualización de la actividad de una operación, la cara de *dashboard* que `overwatch` cubre sin depender de un C2.
