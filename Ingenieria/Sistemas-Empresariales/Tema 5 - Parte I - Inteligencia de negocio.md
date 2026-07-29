---
tags:
  - SIE/Tema5
  - SIE/BI
  - SIE
Descripción: "El BI convierte datos → información → conocimiento para mejorar la toma de decisiones"
Fecha de actualización: 2026-05-30
Nota previa: "[[Tema 3 - Implantación de ERPs]]"
Nota siguiente: "[[Tema 5 - Parte II - Gestión de procesos de negocio]]"
Area: "[[Sistemas-Empresariales.base|Sistemas-Empresariales]]"
---
---

# Tema 5 — Parte I — Inteligencia de negocio (BI + Data Mining)

## 1. Objetivo y definición de BI

El BI convierte <mark style="background: #ADCCFFA6;">datos → información → conocimiento</mark> para mejorar la toma de decisiones. Definición de Gartner
> [!NOTE] Definición de Gartner
> «**BI es un proceso interactivo para explorar y analizar información estructurada sobre un área (normalmente almacenada en un datawarehouse), para descubrir tendencias o patrones, a partir de los cuales derivar ideas y extraer conclusiones**». 

*Beneficios*: información disponible, mejor toma de decisiones, identificación de oportunidades y problemas, reducción de costes.

## 2. Componentes básicos de BI

Seis componentes (Cano):

1. **Problemática empresarial** a resolver.
2. **Equipo o personas** que llevan el análisis.
3. **Información de los sistemas internos** (transaccionales).
4. **Información externa**.
5. **Datawarehouse**.
6. **Aplicación de BI** (análisis y visualización).

## 3. Fuentes de información de BI

<mark style="background: #ADCCFFA6;">Tres tipos</mark>: **sistemas operacionales** (ERP, CRM, SCM), **SI departamentales** (previsiones, presupuestos) e **información externa** (estudios de mercado, datos poblacionales).

### Relación gráfica entre componentes

<mark style="background: #FFB86CA6;">Fuentes</mark> (op./dep./ext.) → <mark style="background: #FFB86CA6;">ETL</mark> → <mark style="background: #FFB86CA6;">Datawarehouse / Datamarts</mark> (+ Metadata) → <mark style="background: #FFB86CA6;">Herramientas</mark> (OLAP, *query & reporting*, minería de datos, dashboards) → <mark style="background: #FFB86CA6;">Usuario final</mark>.

## 4. Calidad de los datos y ETL

<mark style="background: #FF5582A6;">Datos de baja calidad → decisiones erróneas + costes elevados</mark>. Puntos de control en la fuente, durante el ETL y en el datawarehouse.

ETL (**Extract, Transform, Load**) es el <mark style="background: #FFB86CA6;">60-80% del esfuerzo de un proyecto BI</mark>. Subprocesos: **extracción** (datos en bruto) → **limpieza** (calidad) → **transformación** (consistentes y útiles) → **integración en el DW** → **actualización** periódica.

### Características de las herramientas ETL

<mark style="background: #FFB8EBA6;">Interfaz gráfica, gestión de metadatos, soporte para extracción/transformación/carga, acceso remoto a datos y administración</mark>.

## 5. Datawarehouse

<mark style="background: #ADCCFFA6;">**Colección de información creada para soportar las aplicaciones de toma de decisiones**</mark> (Watson).

### Características (Inmon)

- <mark style="background: #FFB8EBA6;">Orientado a problemas de negocio</mark>.
- <mark style="background: #FFB8EBA6;">Integrado</mark>: medidas, códigos y formatos comunes.
- <mark style="background: #FFB8EBA6;">Indexado al tiempo</mark>: mantiene **información histórica**.
- <mark style="background: #FFB8EBA6;">No volátil</mark>: se **actualiza periódicamente**, no en tiempo real.

## 6. Datamart y estrategias de construcción

<mark style="background: #FFB8EBA6;">Datamart</mark> = datawarehouse enfocado a un **área específica** del negocio. El DW corporativo cubre toda la organización; el datamart sólo un departamento.

**Dos estrategias**:

- <mark style="background: #FFB8EBA6;">Top-down</mark>: DW corporativo primero → datamarts.
- <mark style="background: #FFB8EBA6;">Bottom-up</mark>: datamarts → DW corporativo como suma.

## 7. Metadata

<mark style="background: #ADCCFFA6;">Repositorio de **información sobre la información**</mark>: significado y atributos de los datos, origen y responsables. Permite que el DW sea explorable y auditable.

## 8. Esquema estrella

Modelo analítico estándar en BI. <mark style="background: #ADCCFFA6;">Características</mark>:

- Una **tabla de hechos** central con métricas cuantitativas y claves foráneas.
- Varias **tablas de dimensiones** alrededor (cliente, producto, tiempo, tienda).
- Relación 1:N entre dimensión y hechos.
- **Desnormalizado** (redundancia controlada → consultas más rápidas).

**Estrella vs copo de nieve**: el copo de nieve normaliza las dimensiones en sub-tablas; ocupa menos espacio pero requiere más *joins* y es más lento. La estrella es el estándar de BI moderno.

## 9. Jerarquía en una dimensión

<mark style="background: #ADCCFFA6;">Estructura lógica que organiza una dimensión en niveles sucesivos de detalle</mark> (Geografía: Continente → País → Ciudad → Tienda; Tiempo: Año → Trimestre → Mes → Día). Permite **drill-down** y **roll-up** navegando los datos sin cambiar de informe.

## 10. Multidimensionalidad y cubo OLAP

<mark style="background: #FFB86CA6;">La multidimensionalidad</mark> permite analizar cruzando varias dimensiones simultáneamente.

<mark style="background: #ADCCFFA6;">**Cubo OLAP**: estructura multidimensional donde cada eje es una dimensión y el contenido son los hechos</mark>. Las herramientas OLAP analizan información a distintos niveles de agregación y sobre múltiples dimensiones.

### Operaciones sobre el cubo

- <mark style="background: #FFB8EBA6;">Pivoting (slicing)</mark>: rotar el cubo (cambiar el orden de las dimensiones).
- <mark style="background: #FFB8EBA6;">Dicing</mark>: seleccionar un subconjunto de celdas (filtrar).
- <mark style="background: #FFB8EBA6;">Roll-up</mark>: agregar al máximo nivel.
- <mark style="background: #FFB8EBA6;">Drill-down</mark>: bajar a más detalle por una jerarquía.

Tipos: **ROLAP** (BD relacional, sin límite de tamaño, más lento) y **MOLAP** (almacén multidimensional propio, más rápido pero limitado).

## 11. Herramientas de BI (panorama)

Generadores de informes, *query & reporting*, OLAP, cuadros de mando (*dashboards*) y minería de datos.

## 12. Minería de datos

<mark style="background: #ADCCFFA6;">Extracción de información oculta y predictiva de grandes bases de datos</mark> para predecir tendencias y tomar decisiones basadas en conocimiento.

### Dos características interesantes para la empresa (Thearling)

1. <mark style="background: #FFB8EBA6;">Predicción automatizada de tendencias y comportamientos</mark> (p. ej. *targeted marketing*).
2. <mark style="background: #FFB8EBA6;">Descubrimiento automatizado de patrones desconocidos</mark> (p. ej. productos comprados juntos, fraude).

### Modelización

<mark style="background: #ADCCFFA6;">Construir un modelo en una situación conocida y aplicarlo a una desconocida.</mark> Ejemplo: una telco usa datos de clientes actuales (demográficos + consumo) para predecir el consumo de prospectos a partir de sus datos demográficos.

### Validación del modelo

<mark style="background: #FFB8EBA6;">Aislar parte de los datos conocidos, construir el modelo con el resto y comprobar contra los aislados</mark> (técnica de *holdout*).

### Clasificación vs clustering

| | <mark style="background: #FFB8EBA6;">Clasificación</mark> | <mark style="background: #FFB8EBA6;">Clustering</mark> |
| - | - | - |
| Aprendizaje | Supervisado | No supervisado |
| Categorías | Conocidas (datos etiquetados) | Desconocidas; las descubre |
| Variables | Concretas predefinidas | Todas las disponibles |
| Ejemplo | Detección de *spam* | Segmentación de clientes |

