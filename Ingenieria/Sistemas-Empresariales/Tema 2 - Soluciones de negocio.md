---
tags:
  - SIE/Tema2
  - SIE/ERP
  - SIE/SCM
  - SIE/CRM
  - SIE
Descripción: "Surgen como respuesta a la fragmentación de los SI departamentales del modelo vertical: cada área tenía su propio software, con duplicación de datos y visión parcial del negocio"
Fecha de actualización: 2026-05-25
Nota previa: "[[Tema 1 - Introducción a los SI Empresariales]]"
Nota siguiente: "[[Tema 3 - Implantación de ERPs]]"
Area: "[[Sistemas-Empresariales.base|Sistemas-Empresariales]]"
---
---

# Tema 2 — Soluciones de negocio basadas en SI (ERP, SCM, CRM)

## Parte 1 — ERP (Enterprise Resource Planning)

### 1. Origen del ERP

<mark style="background: #FFB86CA6;">Surgen como respuesta a la fragmentación de los SI departamentales</mark> del [[Tema 1 - Introducción a los SI Empresariales#7. Modelos estructurales de empresa|modelo vertical]]: cada área tenía su propio software, con <mark style="background: #FFB8EBA6;">duplicación de datos y visión parcial del negocio.</mark> La <mark style="background: #8000E1A6;">demanda de soluciones integradas</mark> y los modelos de negocio basados en paquetes estándar impulsaron su expansión.

### 2. Definición de ERP

*Nah (2001)*: «un **ERP** es un <mark style="background: #ADCCFFA6;">sistema de información que permite a la organización gestionar sus recursos de forma eficiente y eficaz</mark>, ofreciendo una <mark style="background: #FFB86CA6;">solución total e integrada</mark> que cubre las necesidades de procesamiento de información que fluye a lo largo de la organización, soportando una <mark style="background: #FFB8EBA6;">visión orientada a los procesos</mark>». 

*Davenport*: paquete que <mark style="background: #ADCCFFA6;">integra toda la información que fluye por la empresa</mark>.

### 3. Características del ERP

- <mark style="background: #ADCCFFA6;">Modularidad</mark>: dividido en módulos por funcionalidad; la empresa instala sólo los que necesita.
- <mark style="background: #ADCCFFA6;">Integración</mark>: base de datos centralizada única; los datos se introducen una sola vez y están disponibles en tiempo real para todos los departamentos, evitando duplicidad.
- <mark style="background: #ADCCFFA6;">Adaptabilidad</mark>: software estándar configurable mediante **parametrización** a la estructura, políticas y requerimientos de cada empresa.

### 4. Beneficios del ERP

- Control y visión global de la actividad de todos los departamentos.
- Mejora de procesos al adoptar las *best practices* del estándar.
- Reducción de inventario por mejor planificación.
- Bases para el comercio electrónico.
- Explicitación del conocimiento al documentar procesos y reglas.
- Reducción del tiempo de ciclo (transacciones, cierre financiero, entrega).
- Toma de decisiones más rápida; ventaja competitiva o alineamiento con la competencia.

### 5. Riesgos del ERP

- <mark style="background: #FF5582A6;">Inflexibilidad</mark>: cualquier cambio en un proceso implica modificar el sistema.
- Periodos largos de implementación frente a un entorno cambiante.
- Pérdida de beneficios estratégicos al abandonar procesos propios por los del estándar.
- Centralización que puede chocar con la cultura organizativa.
- Costes indirectos altos (licencias anuales, mantenimiento, deshacer la implantación).
- Resistencia al cambio y a compartir información entre departamentos.

> [!warning]+
> La mayoría de los fracasos de implantación de ERP vienen de los riesgos «blandos» (gestión del cambio), no de problemas técnicos — ver [[Tema 3 - Implantación de ERPs]] §7.

### 6. Evolución histórica: MRP → MRP-II → ERP → ERP-II

- <mark style="background: #FFB8EBA6;">MRP</mark> (años 70, *material requirements planning*): planificación de materiales en producción para reducir inventario y costes de compra.
- <mark style="background: #FFB8EBA6;">MRP-II</mark> (años 80, *manufacturing resources planning*): extiende a planta y distribución; aparecen las bases de datos.
- <mark style="background: #FFB8EBA6;">ERP</mark> (años 90): integra todos los departamentos (finanzas, RRHH, ventas, producción…) con base de datos centralizada y arquitectura cliente/servidor.
- <mark style="background: #FFB8EBA6;">ERP-II</mark> (años 2000): extiende al exterior conectando con clientes (CRM) y proveedores (SCM); arquitectura basada en Internet.

### 7. Arquitectura tecnológica — 3 capas

Arquitectura cliente/servidor en tres capas:

- <mark style="background: #FFB8EBA6;">Presentación</mark>: GUI o navegador.
- <mark style="background: #FFB8EBA6;">Aplicación</mark>: reglas de negocio, lógica y programas.
- <mark style="background: #FFB8EBA6;">Datos</mark>: gestión de datos y metadatos (RDBMS con SQL).

Debe ser **abierta, flexible, escalable e integrable**.

### 8. Visión tradicional vs visión por procesos

- <mark style="background: #FFB8EBA6;">Tradicional</mark>: cada departamento con software propio aislado; visión parcial. Equivale al modelo **vertical** de [[Tema 1 - Introducción a los SI Empresariales#7. Modelos estructurales de empresa]].
- <mark style="background: #FFB8EBA6;">Por procesos</mark>: secuencias coordinadas de actividades que atraviesan varios departamentos. El ERP es la materialización tecnológica de la **empresa-red** de Castells.

### 9. Módulos funcionales del ERP

Principales: <mark style="background: #ADCCFFA6;">finanzas, producción, compras, recursos humanos, ventas y distribución, marketing, gestión de materiales, mantenimiento de planta, gestión de calidad</mark>. Existen **soluciones verticales** específicas por sector (sanidad, banca, retail). El módulo de finanzas suele implantarse el primero.

### 10. Proveedores de ERP

<mark style="background: #FFB8EBA6;">Oracle, SAP y Microsoft</mark> concentran **más del 70%** del mercado. Ingresos ERP 2024 (AppsRunTheWorld):

- **Oracle** (NetSuite + Fusion Cloud): ≈ 8,7 mil M$ — superó a SAP por primera vez en 2024.
- **SAP**: ≈ 8,6 mil M$.
- **Microsoft** (Dynamics 365): ≈ 5,4 mil M$.

Otros: Workday, Infor, Intuit. Software libre: Odoo, Openbravo, ERPNext. En 2025 el **56% de las nuevas implantaciones son cloud-native**; mercado global ≈ 147 mil M$.

## Parte 2 — SCM (Supply Chain Management)

### 11. Cadena de suministro

<mark style="background: #ADCCFFA6;">Serie de procesos de intercambio o flujo de materiales e información dentro y fuera de la organización, con sus proveedores y clientes.</mark> Empieza con la compra de materias primas y termina con la entrega al cliente final; <mark style="background: #FFB86CA6;">existe también un flujo inverso</mark> (*devoluciones*).

### 12. Elementos de la cadena de suministro tradicional

**Cinco conexiones**: <mark style="background: #FFB8EBA6;">proveedores → producción → distribución → vendedores → clientes</mark>.

### 13. Solución SCM

<mark style="background: #ADCCFFA6;">Sistema informático de apoyo a la estrategia de gestión de la cadena de suministro</mark>, orientado a planificar, minimizar costes y controlar la entrega al cliente a partir de productos obtenidos de proveedores. <mark style="background: #FF5582A6;">No es un SI independiente</mark>: es un <mark style="background: #FFB86CA6;">componente de un modelo de negocio</mark> que <mark style="background: #FFB8EBA6;">requiere estructura</mark>, <mark style="background: #FFB8EBA6;">procesos y acuerdos</mark> con proveedores y clientes.

### 14. Funcionalidades de una solución SCM

- <mark style="background: #ADCCFFA6;">Previsiones de demanda</mark> y <mark style="background: #FFB8EBA6;">planes de abastecimiento/fabricación</mark>.
- <mark style="background: #ADCCFFA6;">Decisiones operativas</mark> (cantidades a fabricar, niveles de inventario).
- <mark style="background: #ADCCFFA6;">Dónde almacenar</mark> los productos terminados.
- Identificar el <mark style="background: #FFB86CA6;">transporte óptimo</mark>.
- <mark style="background: #FFB86CA6;">Gestión del flujo de productos</mark> por centros de distribución.
- <mark style="background: #FFB8EBA6;">Seguimiento físico de mercancías</mark> y <mark style="background: #8000E1A6;">operaciones de almacén</mark>.

### 15. Beneficios del sistema SCM

- <mark style="background: #ADCCFFA6;">Mejora del servicio al cliente</mark>.
- **Reducción** de <mark style="background: #FFB86CA6;">ventas perdidas</mark>.
- **Reducción** de <mark style="background: #FFB86CA6;">costes de mantenimiento</mark>.
- **Reducción** de la <mark style="background: #8000E1A6;">depreciación del inventario</mark>.
- **Reducción** del <mark style="background: #FFB8EBA6;">coste de tratamiento de pedidos urgentes</mark>.
- **Reducción** de <mark style="background: #FFB8EBA6;">coste por obsolescencia</mark>.

## Parte 3 — CRM (Customer Relationship Management)

### 16. Definición de CRM

*Doble perspectiva*:

- <mark style="background: #ADCCFFA6;">Empresarial</mark>: **estrategia de negocio centrada en el cliente** para <mark style="background: #FFB86CA6;">construir relaciones duraderas</mark>, identificando, comprendiendo y <mark style="background: #FFB8EBA6;">satisfaciendo sus necesidades</mark>.
- <mark style="background: #ADCCFFA6;">Tecnológica</mark>: **sistema informático que aporta la tecnología** para implantar ese modelo, integrando funciones administrativas, logística, producción y RRHH con el cliente en posición central.

### 17. Áreas relacionadas con CRM

<mark style="background: #ADCCFFA6;">Departamentos comerciales, marketing y atención al cliente</mark>; luego <mark style="background: #FFB8EBA6;">se extiende al resto por alineación</mark>.

### 18. Objetivos principales del CRM

Satisfacción del cliente, fidelización a largo plazo, incremento de ingresos e incremento del margen de beneficio.

### 19. Funcionalidades del CRM

<mark style="background: #ADCCFFA6;">Operacional</mark> (operativa diaria) y <mark style="background: #ADCCFFA6;">analítica</mark> (análisis de los datos generados).

### 20. CRM operacional

Desde la identificación de clientes potenciales hasta el servicio posventa:

- <mark style="background: #FFB8EBA6;">Automatización de la fuerza de ventas</mark>: información de mercado, competencia, productos y clientes; coordinación del equipo comercial.
- <mark style="background: #FFB8EBA6;">Automatización de marketing</mark>: planificación y ejecución de campañas.
- <mark style="background: #FFB8EBA6;">Help desk</mark> y gestión de áreas de soporte.
- <mark style="background: #FFB8EBA6;">Gestión del servicio al cliente</mark>.
- Call center, gestión de incentivos, gestión de socios, gestión de calidad y métricas CRM.

### 21. CRM analítico

<mark style="background: #ADCCFFA6;">Analiza la información del CRM operacional para entender el comportamiento del cliente</mark>, diseñar estrategias de marketing y predecir ventas. Usa **minería de datos** y herramientas de **BI** ([[BI]]) para segmentación, scoring, análisis de campañas y predicción de *churn*.

### 22. Proveedores de CRM

<mark style="background: #FFB8EBA6;">Salesforce domina el mercado</mark>: 20,7% cuota mundial y 21,6 mil M$ en 2024, **líder por 12.º año consecutivo según IDC**. Le siguen Microsoft (Dynamics 365, ≈5,45 mil M$, 4× menos), Oracle (incluido Siebel), Adobe (subió a 4.º en 2024) y SAP (cayó a 5.º). Los cinco primeros concentran el 55-60% del mercado; **Salesforce factura más que los cuatro siguientes juntos**. Otros con gran base instalada: HubSpot y Zoho. Tendencia: cloud SaaS con integración nativa a redes sociales, marketing automation e IA generativa.
