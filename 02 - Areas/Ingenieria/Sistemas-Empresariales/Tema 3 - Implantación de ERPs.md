---
tags:
  - SIE/Tema3
  - SIE/ERP
  - SIE
Fecha de actualización: 2026-05-25
Nota previa: "[[Tema 2 - Soluciones de negocio]]"
Nota siguiente: ""
Area: "[[Sistemas-Empresariales.base|Sistemas-Empresariales]]"
---
---

# Tema 3 — Implantación de ERPs

## 1. Ciclo de vida de implantación y fases posteriores

Según *Rodríguez*/*Joana*, el ciclo se compone de <mark style="background: #ADCCFFA6;">cuatro fases básicas más dos procesos continuos</mark>:

1. <mark style="background: #FFB8EBA6;">Adopción</mark>: decisión de comprar un sistema integrado paquetizado frente a alternativas (desarrollo a medida).
2. <mark style="background: #FFB8EBA6;">Selección</mark>: elegir qué ERP concreto, qué módulos y qué partes requieren adaptación.
3. <mark style="background: #FFB8EBA6;">Implantación</mark>: parametrización del sistema, desarrollos específicos e integración con sistemas heredados.
4. <mark style="background: #FFB8EBA6;">Puesta en marcha</mark>: arranque, estabilización, corrección de errores y adopción efectiva.

<mark style="background: #ADCCFFA6;">Procesos transversales</mark>: 
1. **Gestión del cambio** (adaptación de organización, procesos y personas a la nueva tecnología).
2. **Gestión del proyecto** (planificar, organizar, dirigir y administrar).

**Fases posteriores** (Pastor y Esteves, 1999): mantenimiento (correctivo y evolutivo), evolución (*patches* y *releases*), migración a nueva versión, adquisición de nuevos módulos.

## 2. Razones para adoptar un ERP

Según las encuestas entre directivos:

- <mark style="background: #FFB8EBA6;">Mejorar la exactitud y disponibilidad de la información</mark>.
- <mark style="background: #FFB8EBA6;">Mejorar la información para la toma de decisiones directivas</mark>.
- <mark style="background: #FFB8EBA6;">Reducir costes y mejorar la eficiencia</mark>.

Desde IT, eliminar silos de información y reducir costes de mantenimiento. Estas razones son la otra cara de los **beneficios** del [[Tema 2 - Soluciones de negocio]] §4.

## 3. Decisión de adoptar y papel del departamento de informática

<mark style="background: #FFB86CA6;">La decisión de adoptar un ERP no es tecnológica sino directiva</mark>: cuanto mayor sea la dimensión estratégica, organizativa, de alcance y coste, más directiva debe ser. IT **instruye** a los directivos sobre cómo funciona el ERP, las diferencias respecto a la forma actual de trabajar, las consecuencias y el esfuerzo requerido, y gestiona después la selección del ERP concreto.

## 4. Los siete aspectos de la selección de un ERP

1. <mark style="background: #FFB8EBA6;">Estrategia de la empresa</mark>: decisión estratégica de difícil marcha atrás; identificar beneficios buscados (costes, fondos, servicio).
2. <mark style="background: #FFB8EBA6;">Funcionamiento de la empresa</mark>: organización, procesos, datos, información de gestión, requerimientos legales del sector.
3. <mark style="background: #FFB8EBA6;">Cobertura de los requerimientos funcionales</mark>: cada uno clasificado como imprescindible, importante o deseable; mínimo del **80% de cobertura** para que tenga sentido la solución estándar.
4. <mark style="background: #FFB8EBA6;">Costes asociados</mark>: licencias, hardware, implantación, transición, operación y mantenimiento — el **coste total de propiedad (TCO)**.
5. <mark style="background: #FFB8EBA6;">Garantías de la solución</mark>: solvencia del fabricante, continuidad del producto, referencias, satisfacción de clientes. Apoyarse en analistas (Gartner).
6. <mark style="background: #FFB8EBA6;">Predisposición al cambio</mark>: flexibilidad y adaptabilidad de la empresa. <mark style="background: #FF5582A6;">La mayoría de los fracasos están relacionados con la gestión del cambio</mark>; las empresas dedican el 20-50% del coste a este aspecto. Se conecta con el componente «personas» del [[Tema 1 - Introducción a los SI Empresariales]] §11.
7. <mark style="background: #FFB8EBA6;">Consultoría para la implantación</mark>: el «partner» externo (conocimiento del producto y sector, rediseño de procesos, gestión del cambio y del proyecto).

## 5. Fase de implantación

Consiste en la <mark style="background: #ADCCFFA6;">personalización (parametrización) o adaptación del sistema a las necesidades de la organización</mark>. Es la fase de **mayor tiempo, complejidad y consumo de recursos** de todo el ciclo. Parametrizar = elegir entre opciones programadas (idioma, divisas, longitud de cuentas, modos de cálculo…) mediante una **guía de parametrización**, módulo a módulo, respetando las relaciones entre ellos.

## 6. Las seis etapas de la implantación

1. <mark style="background: #FFB8EBA6;">Iniciación y definición del proyecto</mark>: confirmar objetivos, alcance y riesgos.
2. <mark style="background: #FFB8EBA6;">Planificación y lanzamiento</mark>: planificación detallada, equipo, formación, *kick-off*.
3. <mark style="background: #FFB8EBA6;">Análisis de la situación actual</mark>: estado actual de organización, procesos y sistemas.
4. <mark style="background: #FFB8EBA6;">Definición de la situación objetivo</mark>: cómo será el nuevo sistema y qué estrategias se desplegarán.
5. <mark style="background: #FFB8EBA6;">Construcción y test del prototipo</mark>: probar el grueso de la funcionalidad en condiciones cercanas a la real.
6. <mark style="background: #FFB8EBA6;">Construcción del sistema</mark>: confirmar parametrización, desarrollos complementarios, integración, conversión de datos, formación y planificación del arranque.

> [!info]+
> En **Accelerated SAP (ASAP)** las fases se llaman: *project preparation*, *business blueprint*, *realization*, *final preparation* y *go live*. El prototipado no aparece como fase separada en ASAP.

## 7. Análisis de la situación actual

Debe cubrir: <mark style="background: #FFB8EBA6;">estructura organizativa, procesos, datos maestros, mapa de interfases, estrategia de conversión de datos, información de gestión crítica</mark> (decisiones, medida del rendimiento), <mark style="background: #FFB8EBA6;">predisposición al cambio de cada directivo afectado e infraestructura tecnológica disponible</mark>.

A diferencia de los proyectos clásicos, en ERP el análisis del «as-is» es **ligero**: sirve para identificar prácticas o usuarios críticos y fijar el punto de partida frente al cual medir los beneficios.

## 8. Documentos de la definición de la situación objetivo

Se generan: jerarquía organizativa del sistema (estructura de la empresa traducida a entidades del paquete — instancia, mandante, plan de cuentas, centro de beneficio…), procesos objetivo y cobertura, relación de principales informes, mapa de interfases, estrategia de conversión de datos, relación de desarrollos a medida y criticidad, impacto organizativo, estrategia de formación, contenido del prototipo, confirmación de beneficios, confirmación de alcance y plazos, y actualización del plan de gestión del cambio.

## 9. Factores de éxito en la puesta en marcha

Según Esteves y Pastor (2004):

- <mark style="background: #ADCCFFA6;">El papel del jefe de proyecto</mark>.
- <mark style="background: #ADCCFFA6;">La comunicación efectiva</mark>.
- <mark style="background: #ADCCFFA6;">La anticipación preventiva de problemas</mark>.
- <mark style="background: #ADCCFFA6;">El apoyo continuado de la alta dirección</mark>.

## 10. Tres aspectos de una buena puesta en marcha desde el usuario

1. <mark style="background: #FFB8EBA6;">Buen soporte a usuarios</mark>, cercano (personas del mismo departamento), con criterios claros de **escalado** de incidencias.
2. <mark style="background: #FFB8EBA6;">Procedimiento ágil de resolución y seguimiento de incidencias</mark>.
3. <mark style="background: #FFB8EBA6;">Procedimiento de monitorización del arranque</mark> y gestión de la comunicación de éxitos y problemas.

## 11. Roles más importantes en un proyecto de implantación

1. <mark style="background: #ADCCFFA6;">Patrocinador (*sponsor*)</mark>: directivo que conoce los objetivos y su impacto en el negocio. Toma decisiones principales de alcance y asegura los recursos. Suele ser un directivo funcional del módulo implantado (director comercial para CRM, financiero para ERP financiero).
2. <mark style="background: #ADCCFFA6;">Jefe de proyecto</mark>: responsabilidad máxima de dirigir la ejecución y asegurar los objetivos; autoridad sobre el equipo. Designado por el patrocinador. Cliente y proveedor externo aportan cada uno su jefe de proyecto que trabajan juntos.
3. <mark style="background: #ADCCFFA6;">Miembros del equipo</mark>: usuarios y personal del implantador (consultores, analistas, programadores). Se establece la figura del **usuario clave** o **superusuario** que diseña/prueba prototipos y actúa como formador.

Se formalizan en una matriz **RACE/RACI**. Sobre ellos se montan los **órganos colegiados**: comité de dirección (patrocinador), comité operativo (jefe de proyecto) y comité de usuarios (proyectos grandes).

## 12. Metodologías de los proveedores líderes

- <mark style="background: #FFB8EBA6;">SAP Activate</mark> (sucesora de ASAP, para S/4HANA y cloud): combina *waterfall* + sprints ágiles con enfoque **fit-to-standard**. Seis fases: **Discover, Prepare, Explore, Realize, Deploy, Run**.
- <mark style="background: #FFB8EBA6;">Oracle True Cloud Method (TCM)</mark> (para Oracle Cloud, Fusion, NetSuite): enfoque ágil, iterativo e incremental. Fases típicas: **Plan → Discover → Refine → Configure & Test → Enable → Live-Operate**. Énfasis en *validación* y *feedback loops* tempranos.
- <mark style="background: #FFB8EBA6;">Microsoft Success by Design</mark> (para Dynamics 365, deriva de FastTrack): se superpone a Agile/Waterfall como guardarrail de buenas prácticas. Cinco fases: **Strategize, Initiate, Implement, Prepare, Operate**. Microsoft reporta >80% de éxito en *go-live*.

Los implantadores certificados (Accenture, Deloitte, Capgemini, Big Four, y partners locales como Seidor o Avanade) adaptan estas metodologías con sus propias prácticas de gestión del proyecto y del cambio.
