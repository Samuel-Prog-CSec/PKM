---
tags:
  - SIE/Tema5
  - SIE/BPM
  - SIE
Descripción: "Marco común para que usuarios técnicos y empresariales puedan modelar, implementar, desplegar, ejecutar, medir y mejorar procesos de negocio"
Fecha de actualización: 2026-05-30
Nota previa: "[[Tema 5 - Parte I - Inteligencia de negocio]]"
Nota siguiente: ""
Area: "[[Sistemas-Empresariales.base|Sistemas-Empresariales]]"
---
---

# Tema 5 — Parte II — Gestión de procesos de negocio (BPM)

## 1. Objetivo de BPM

<mark style="background: #ADCCFFA6;">Marco común para que usuarios técnicos y empresariales puedan **modelar, implementar, desplegar, ejecutar, medir y mejorar** procesos de negocio</mark>. Da visibilidad a los usuarios empresariales y les permite dirigir el cambio.

## 2. Proceso de negocio y proceso ejecutable

- **Proceso de negocio**: conjunto de tareas coordinadas, realizadas por personas o sistemas, que pretende conseguir un objetivo del negocio. Puede modelarse y medirse (gestión de pedidos, vacaciones, compras…).
- **Proceso de negocio ejecutable**: proceso cuyas tareas pueden orquestarse en una plataforma software, combinando tareas automatizadas y tareas de personas.

## 3. Ciclo de vida de un proceso de negocio y perfil del usuario por fase

| **Fase**                                                                                                                                                                                    | **Perfil de usuario**   |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| <mark style="background: #FFB86CA6;">Modelar</mark>                                                                                                                                         | *Técnico y empresarial* |
| <mark style="background: #FFB86CA6;">Implementar</mark>                                                                                                                                     | *Técnico*               |
| <mark style="background: #FFB86CA6;">Desplegar</mark>                                                                                                                                       | *Técnico y empresarial* |
| <mark style="background: #FFB86CA6;">Ejecutar</mark> + <mark style="background: #FFB86CA6;">Medir</mark> + <mark style="background: #FFB86CA6;">Mejorar</mark> (KPI en el centro del ciclo) | *Técnico y empresarial* |

<mark style="background: #ADCCFFA6;">KPI</mark> (*Key Performance Indicators*): factores clave del negocio que se miden tras la ejecución para alimentar el ciclo continuo de mejora.

## 4. BPM y usuarios empresariales

BPM da un **marco común** para comunicar técnicos y empresariales, **rapidez** por programación visual, sincronía entre especificación y código, y tableros de mando.

## 5. Estándares BPM

| Estándar | Función | Organismo |
| - | - | - |
| <mark style="background: #ADCCFFA6;">**BPMN**</mark> | <mark style="background: #FFB8EBA6;">Diseño</mark> — notación gráfica visual de procesos | OMG (BPMI) |
| <mark style="background: #ADCCFFA6;">**XPDL**</mark> | <mark style="background: #FFB8EBA6;">Intercambio</mark> — formato XML para intercambiar modelos BPMN | WfMC |
| <mark style="background: #ADCCFFA6;">**BPEL**</mark> | <mark style="background: #FFB8EBA6;">Ejecución</mark> — representación XML ejecutable del proceso | OASIS |

**BPMN** (representación visual con traducción automática a BPEL) usa: **actividades**/tareas, **secuencia/paralelo/gateways** (AND, OR), **participantes** en *swimlanes* y **mensajes**. Ámbito: modelado.

**XPDL** = *XML Process Definition Language*: formato de intercambio de modelos BPMN entre herramientas.

## 6. BPEL

<mark style="background: #ADCCFFA6;">BPEL (*Business Process Execution Language*) permite la **orquestación** de servicios web</mark> en un proceso de negocio ejecutable. Define orden, control de flujo (secuencia, bucles, ramificaciones, paralelo), gestión del estado en procesos largos y tratamiento de excepciones. Necesita un **motor de ejecución**.

### BPEL y servicios web

- <mark style="background: #FFB8EBA6;">Los **usa** (invoca)</mark>: cada paso del proceso es una llamada a un servicio externo (vía SOAP, conocido por su interfaz WSDL).
- <mark style="background: #FFB8EBA6;">Los **crea** (expone)</mark>: el propio proceso BPEL, una vez definido, se expone como un nuevo servicio web reutilizable por otros sistemas.

### Ventaja e inconveniente de BPEL

- <mark style="background: #FFB8EBA6;">Ventaja</mark>: transformación automática de BPMN a BPEL.
- <mark style="background: #FFB8EBA6;">Inconveniente</mark>: modela exclusivamente la interacción entre servicios web; no contempla la interacción usuario–proceso.

### BPEL4People

<mark style="background: #FFB8EBA6;">Extensión de BPEL que integra tareas de usuario humanas</mark> en el flujo automatizado (asignación, escalado, ciclo de vida de la tarea). Se usa cuando el proceso requiere juicio o autorización humana: aprobaciones financieras, gestión de incidencias, procesos de RRHH.

## 7. BPMS — Categorías de características

<mark style="background: #ADCCFFA6;">BPMS</mark> = software que soporta el ciclo de vida del proceso. **Cinco categorías**:

1. <mark style="background: #FFB8EBA6;">Diseño</mark>: soporte BPMN, descubrimiento de servicios web (*drag & drop*), formularios, reusabilidad, reglas de negocio, manipulación de datos, definición de KPI.
2. <mark style="background: #FFB8EBA6;">Simulación</mark>: técnica (conectividad, tiempos, excepciones) y empresarial (datos simulados, impacto de cambios).
3. <mark style="background: #FFB8EBA6;">Empaquetado y desplegado</mark>: empaquetar proceso + formularios + BAM + código + configuración; desplegar y adaptar a distintos entornos/roles/sedes.
4. <mark style="background: #FFB8EBA6;">Ejecución</mark>: soporte BPEL, escalabilidad, tolerancia a fallos, gestión de excepciones, conectividad SOAP/HTTP, *debugger*.
5. <mark style="background: #FFB8EBA6;">Monitorización</mark>: consola, API de queries (histórico y tiempo real), tableros BAM (*Business Activity Monitoring*).

## 8. BPM y SOA complementarse

<mark style="background: #FFB86CA6;">BPM y SOA son complementarios, no excluyentes</mark>:

- <mark style="background: #ADCCFFA6;">BPM (top-down, empresarial)</mark>: define **qué** procesos hay que implementar y qué servicios se necesitan.
- <mark style="background: #ADCCFFA6;">SOA (bottom-up, técnico)</mark>: implementa **cómo** se construyen y exponen esos servicios.

Analogía: SOA = músicos e instrumentos; BPM = partitura. Sin SOA, BPM no encuentra servicios reutilizables; sin BPM, SOA es una colección de servicios sin propósito. La integración ideal: plataformas que combinan ambos (ej. IBM WebSphere Process Server).
