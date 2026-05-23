---
tags:
  - SIE/Tema2
  - SIE/ERP
  - SIE/SCM
  - SIE/CRM
  - SIE
Fecha de actualización: 2026-05-23
Nota previa: "[[Tema 1 - Introducción a los SI Empresariales]]"
Nota siguiente: ""
Area: "[[Sistemas-Empresariales.base|Sistemas-Empresariales]]"
---
---

# Tema 2 — Soluciones de negocio basadas en SI (ERP, SCM, CRM)

## Parte 1 — ERP (Enterprise Resource Planning)

### 1. Origen del ERP

Los ERP surgen como respuesta a la <mark style="background: #FFB86CA6;">fragmentación de los SI departamentales</mark> del modelo vertical: cada área tenía su propio software incomunicado, lo que producía duplicación de datos, errores y visión parcial del negocio. La demanda creciente de soluciones integradas, las nuevas técnicas de ingeniería del software y la aparición de modelos de negocio rentables basados en paquetes estándar (años 90) impulsaron su expansión. El cambio de dígito del año 2000 y la introducción del euro dispararon su adopción masiva.

### 2. Definición de ERP

Varias definiciones complementarias. La más relevante para el temario es la de <mark style="background: #ADCCFFA6;">**Nah (2001)**: «un ERP es un sistema de información que permite a la organización gestionar sus recursos de forma eficiente y eficaz, ofreciendo una solución total e integrada que cubre las necesidades de procesamiento de información que fluye a lo largo de la organización, soportando una visión orientada a los procesos»</mark>. Davenport (2000): paquete software que integra toda la información que fluye por la empresa. Laudon: SI que integra los procesos clave del negocio mejorando la coordinación y la toma de decisiones.

### 3. Características del ERP

Tres rasgos básicos:

- <mark style="background: #ADCCFFA6;">Modularidad</mark>: el sistema se divide en módulos por funcionalidad. Cada módulo es una unidad que realiza una tarea concreta y puede comunicarse con los demás. La empresa instala sólo los módulos que necesita.
- <mark style="background: #ADCCFFA6;">Integración</mark>: todos los módulos comparten una base de datos centralizada única. Los datos se introducen una sola vez y están disponibles en tiempo real para todos los departamentos, evitando duplicidad y redundancia.
- <mark style="background: #ADCCFFA6;">Adaptabilidad</mark>: aunque el ERP es software estándar, se configura mediante **parametrización** para ajustarse a la estructura organizativa, las políticas y los requerimientos funcionales de cada empresa (hasta ciertos límites).

### 4. Beneficios del ERP

- Control sobre la actividad de todos los departamentos con visión global del funcionamiento.
- Mejora de procesos al adoptar las *best practices* del estándar.
- Reducción de inventario por mejor planificación.
- Bases para el comercio electrónico.
- Explicitación del conocimiento al documentar procesos y reglas.
- Reducción del tiempo de ciclo (transacciones, cierre financiero, entrega).
- Toma de decisiones más rápida.
- Ventaja competitiva o, al menos, alineamiento con la competencia.

### 5. Riesgos del ERP

- <mark style="background: #FF5582A6;">Inflexibilidad</mark>: cualquier cambio en un proceso implica modificar el sistema.
- Periodos largos de implementación frente a un entorno cambiante.
- Pérdida de beneficios estratégicos al abandonar procesos propios por los del estándar.
- Estructura jerárquica: la centralización puede chocar con la cultura organizativa.
- Costes indirectos altos (licencias anuales, mantenimiento, deshacer la implantación).
- Resistencia al cambio de los usuarios y a compartir información entre departamentos.

### 6. Evolución histórica: MRP → MRP-II → ERP → ERP-II

- <mark style="background: #FFB8EBA6;">MRP</mark> (años 70, *material requirements planning*): planificación de materiales necesarios en producción para reducir inventario y costes de compra. Sólo cubría aprovisionamiento.
- <mark style="background: #FFB8EBA6;">MRP-II</mark> (años 80, *manufacturing resources planning*): extiende el MRP a la planta de producción y la distribución; optimiza todo el sistema de producción. Aparecen las bases de datos.
- <mark style="background: #FFB8EBA6;">ERP</mark> (años 90): integra todos los departamentos de la empresa (finanzas, RRHH, ventas, producción, distribución…) con base de datos centralizada y arquitectura cliente/servidor.
- <mark style="background: #FFB8EBA6;">ERP-II</mark> (años 2000): extiende el ERP al exterior, conectando con clientes (CRM) y proveedores (SCM). Arquitectura basada en Internet.

### 7. Arquitectura tecnológica — 3 capas

El ERP usa <mark style="background: #ADCCFFA6;">arquitectura cliente/servidor en tres capas</mark>:

- <mark style="background: #FFB8EBA6;">Presentación</mark>: interfaz gráfica de usuario (GUI) o navegador para introducir datos y acceder a funciones.
- <mark style="background: #FFB8EBA6;">Aplicación</mark>: reglas de negocio, lógica y programas que operan sobre los datos.
- <mark style="background: #FFB8EBA6;">Datos</mark>: gestión de datos operativos y metadatos (típicamente RDBMS con SQL).

Esta arquitectura debe ser **abierta, flexible, escalable e integrable**.

### 8. Visión tradicional vs visión por procesos

- <mark style="background: #FFB8EBA6;">Visión tradicional</mark>: cada departamento trabaja con software propio aislado del resto. Visión parcial, fragmentación, comunicación deficiente entre áreas.
- <mark style="background: #FFB8EBA6;">Visión por procesos</mark>: el funcionamiento se entiende como secuencias coordinadas de actividades con entradas y salidas, atravesando varios departamentos. El ERP nace precisamente para soportar esta visión orientada a la cadena de valor y al cliente final.

### 9. Módulos funcionales del ERP

Principales módulos: <mark style="background: #ADCCFFA6;">finanzas, producción, compras, recursos humanos, ventas y distribución, marketing, gestión de materiales, mantenimiento de planta, gestión de calidad</mark>. También existen módulos sectoriales o **soluciones verticales** específicas (sanidad, banca, retail). El módulo de finanzas suele implantarse el primero.

### 10. Proveedores de ERP

Los líderes históricos del mercado son <mark style="background: #FFB8EBA6;">SAP, Oracle y Microsoft Dynamics</mark> en software propietario; en software libre destacan Openbravo, Adempiere y OpenERP/Odoo. SAP mantiene la cuota mayoritaria mundial seguido por Oracle. Las nuevas tendencias incluyen el modelo SaaS (software como servicio) y soluciones cloud para PYME.

## Parte 2 — SCM (Supply Chain Management)

### 11. Cadena de suministro

<mark style="background: #ADCCFFA6;">Serie de procesos de intercambio o flujo de materiales e información dentro y fuera de la organización, con sus proveedores y clientes.</mark> Empieza con la compra de materias primas y termina con la entrega al cliente final; existe también un flujo inverso (devoluciones, información del comprador al vendedor).

### 12. Elementos de la cadena de suministro tradicional

Cinco conexiones principales: <mark style="background: #FFB8EBA6;">proveedores → producción → distribución → vendedores → clientes</mark>. Los proveedores aportan materias primas; producción las transforma en producto final; distribución hace llegar el producto (red de almacenes, transportistas, comercios minoristas — esto se llama también logística); el cliente cierra la cadena.

### 13. Solución SCM

<mark style="background: #ADCCFFA6;">Sistema informático de apoyo a la estrategia de gestión de la cadena de suministro</mark>, orientado a planificar, implantar, minimizar costes y controlar la entrega de bienes y servicios al cliente, a partir de productos obtenidos de proveedores. No es un SI independiente: es un componente de un modelo de negocio que requiere también estructura, procesos y acuerdos con proveedores/clientes.

### 14. Funcionalidades de una solución SCM

- Generar previsiones de demanda y planes de abastecimiento/fabricación.
- Ayudar a tomar mejores decisiones operativas (cantidades a fabricar, niveles de inventario).
- Determinar dónde almacenar los productos terminados.
- Identificar el transporte óptimo para la entrega.
- Planificación de la demanda y gestión del flujo de productos por centros de distribución.
- Seguimiento físico de mercancías y operaciones de almacén.

### 15. Beneficios del sistema SCM

- Mejora del servicio al cliente.
- Reducción de ventas perdidas.
- Reducción de costes de mantenimiento.
- Reducción de la depreciación del inventario.
- Reducción del coste de tratamiento de pedidos urgentes.
- Reducción de coste por obsolescencia.

## Parte 2 — CRM (Customer Relationship Management)

### 16. Definición de CRM

Doble perspectiva:

- <mark style="background: #ADCCFFA6;">Empresarial</mark>: **estrategia de negocio centrada en el cliente** para construir relaciones duraderas, identificando, comprendiendo y satisfaciendo sus necesidades.
- <mark style="background: #ADCCFFA6;">Tecnológica</mark>: **sistema informático que aporta la tecnología** para implantar ese modelo organizativo, integrando funciones administrativas, logística, producción y RRHH situando al cliente en posición central.

Kotler: «proceso de construcción y conservación de relaciones rentables con los clientes mediante la entrega de un valor superior y mayor satisfacción».

### 17. Áreas de la empresa relacionadas con CRM

Las áreas más idóneas para iniciar una estrategia CRM son los <mark style="background: #FFB8EBA6;">departamentos comerciales, el área de marketing y la atención al cliente</mark>; posteriormente se extiende al resto de la organización por necesidad de alineación.

### 18. Objetivos principales del CRM

- Satisfacción del cliente.
- Fidelización a largo plazo.
- Incremento de los ingresos.
- Incremento del margen de beneficio.

### 19. Funcionalidades del CRM

Dos grandes bloques: <mark style="background: #ADCCFFA6;">operacional</mark> (mejora la operativa diaria de relación con el cliente) y <mark style="background: #ADCCFFA6;">analítica</mark> (análisis avanzado de los datos generados).

### 20. CRM operacional

Es la parte más técnica, desde la identificación de clientes potenciales hasta el servicio posventa. Tareas:

- <mark style="background: #FFB8EBA6;">Automatización de la fuerza de ventas</mark>: gestión de información del mercado, competencia, productos y clientes; coordinación del equipo comercial; informes de operaciones.
- <mark style="background: #FFB8EBA6;">Automatización de marketing</mark>: planificación, ejecución y mejora en tiempo real de campañas.
- <mark style="background: #FFB8EBA6;">Help desk y gestión de soporte</mark>: incidencias técnicas sobre el producto.
- <mark style="background: #FFB8EBA6;">Gestión del servicio al cliente</mark>.
- Call center, gestión de incentivos, gestión de relaciones con socios, gestión de calidad, métricas CRM.

### 21. CRM analítico

<mark style="background: #ADCCFFA6;">Analiza la información del CRM operacional para entender el comportamiento del cliente</mark>, diseñar estrategias de marketing y predecir ventas. Utiliza técnicas de **minería de datos** y se apoya en herramientas de **BI** ([[BI]]). Permite segmentación de clientes, scoring, análisis de campañas y predicción de churn.

### 22. Proveedores de CRM

Líderes del mercado: <mark style="background: #FFB8EBA6;">Salesforce</mark> (cuota dominante mundial), seguido por Microsoft Dynamics CRM, Oracle (incluido Siebel adquirido), SAP y Adobe. Se sitúan en el Cuadrante Mágico de Gartner como referentes anuales. La tendencia es cloud y SaaS con integración nativa a redes sociales y marketing automation.

## Referencias

- Previa: [[Tema 1 - Introducción a los SI Empresariales]] — Conceptos base de SI sobre los que se asientan ERP, SCM y CRM.
- MOC del curso: [[Sistemas-Empresariales.base]].
