---
tags:
  - "#Ingenieria"
  - "#Datos"
Fecha de actualización: 2025-09-24
Nota previa:
Nota siguiente: "[[Tema 2]]"
Area: "[[Inteligencia del negocio.base|Inteligencia del negocio]]"
---
---

# 1. El dato como activo
## 1.1. ¿Qué es un dato?
**Dato:** cualquier secuencia de símbolos a la que se le asigna significado por interpretación. En esta asignatura nos centramos en los **datos digitales relevantes** para la actividad de negocio.

## 1.2. ¿Por qué el dato es un activo?
El dato aporta **valor** porque permite: comprensión del negocio, mejora de procesos, toma de decisiones informada, innovación y ventaja competitiva.

**Fórmula útil (conceptual):**
```
Valor de los datos = MAX(Valor de mercado, Valor interno)

Valor añadido por la gestión = Valor interno − Valor de mercado
```

Si el valor añadido por la gestión es positivo, la gestión interna está creando valor sobre el dato crudo.

## 1.3. Factores que incrementan el valor interno de los datos
- **Volumen** (pero con foco en relevancia; lo importante no es tanto tener más sino tener los correctos).  
- **Calidad**: completitud, vigencia, exactitud, precisión y consistencia.  
- **Casos de uso y utilidad**: número de usuarios, impacto en procesos y alcance del uso.  
- **Relevancia estratégica**: impacto directo sobre KPIs del negocio.

> **Consejo práctico:** al redactar un caso de uso en la universidad o examen, conecta la métrica a un **KPI** (por ejemplo: “Incremento ventas → KPI: % crecimiento mensual”).

## 1.4. Problema típico: *silos de datos*
**Definición**: datos departamentalizados que impiden compartir información y colaboración. Generan redundancia de datos, divergencias en la versión de la verdad y bloqueos para análisis integrados.

---

# 2. Gobierno y gestión de datos
## 2.1. ¿Qué es gobernanza de datos?
Enfoque que define políticas, roles, procesos y controles para gestionar datos durante todo su ciclo de vida: captura, almacenamiento, uso, intercambio, archivado y eliminación.

**Beneficios**: datos fiables, una versión única de la verdad, cumplimiento normativo y reducción de costes.

## 2.2. Pilares de la gobernanza
- **Calidad de datos** (procesos de control y mejora).  
- **Administración de datos** (responsabilidades: data owners, data stewards).  
- **Protección y cumplimiento** (seguridad, privacidad, acceso).  
- **Gestión operativa** (puntos de integración, pipelines, catálogo).

## 2.3. Normativa (menciones clave aplicables en España/Entorno EU)
Existen normas y guías que ayudan a estructurar el gobierno del dato: marcos nacionales e internacionales que describen procesos, atributos y niveles de madurez.

## 2.4. Marcos internacionales
- **COBIT**: marco de gobernanza TI con recomendaciones que afectan al dato.  
- **DAMA-DMBOK**: guía de buenas prácticas en gestión de datos (áreas de conocimiento).  
- **ISO/IEC**: familias de normas que pueden aplicarse a la gestión y gobierno del dato.

## 2.5. Madurez y evaluación
Modelos de madurez (niveles 0–5) que permiten evaluar la capacidad de los procesos de gestión y gobierno. La evaluación se hace mediante procesos definidos y atributos medibles.

---

# 3. Ciencia, ingeniería y análisis de datos (paradigmas)
> Resumen y proceso operativo — fases prácticas y roles.

## 3.1. Ciencia de datos
**Objetivo:** extraer conocimiento y valor a partir de datos estructurados y no estructurados.
**Tipos de análisis:**
  - **Descriptivo:** qué ha pasado / está pasando.  
  - **Diagnóstico:** por qué pasó (minería, correlaciones).  
  - **Predictivo:** prever futuros (machine learning, forecasting).  
  - **Prescriptivo:** recomendar acciones (optimización, simulación).

## 3.2. Proceso típico (pipeline de Data Science)
1. **Obtener** datos (fuentes internas/externas).  
2. **Depurar / limpiar** (normalización, imputación).  
3. **Explorar** (EDA: estadística descriptiva, visualizaciones).  
4. **Modelar** (selección de features, algoritmos).  
5. **Evaluar** (métricas, validación).  
6. **Interpretar y comunicar** (gráficos, dashboards).

## 3.3. Ingeniería de datos
**Responsable** de que los datos estén listos para consumo analítico: ingestion, ETL/ELT, pipelines, catalogación, integridad y disponibilidad.

## 3.4. Análisis de datos (DA)
Técnicas y herramientas: OLAP, data mining, big data, visualización. Importancia de representar resultados para la toma de decisiones.

## 3.5. Smart Data
Uso de IA/ML para transformar datos crudos en **datos inteligentes** (vistas ya procesadas, enriquecidas y accionables).

---

# 4. Fundamentos de Business Intelligence (BI)
## 4.1. Definición y objetivos
**BI**: conjunto de procesos y herramientas para consolidar, analizar y dar acceso a datos con el objetivo de extraer conocimiento y apoyar la toma de decisiones.

## 4.2. Proceso BI (fases)
1. **Dirigir y planear**: definir preguntas de negocio y requerimientos.  
2. **Recolección**: extraer datos de fuentes internas y externas.  
3. **Procesamiento**: ETL/ELT, integración y carga.  
4. **Análisis y producción**: modelado, agregados, minería y cuadros de mando.  
5. **Difusión**: entrega de dashboards, informes y accesos a usuarios.

## 4.3. Data Warehouse (DW)
**DW**: repositorio centralizado de datos integrados, orientado a negocio, con variación temporal y no volátil, optimizado para consulta analítica.

### DW vs BD operativa
**DW** orientado a agregados, historia e informes; **BD operativa** orientada a transacciones y consistencia en tiempo real.

### Componentes clave de un DW
Almacenamiento histórico de hechos y dimensiones; motores de consulta; vistas y cubos para análisis.

## 4.4. Modelo dimensional
- **Tablas de hechos**: medidas numéricas (ventas, coste).  
- **Tablas de dimensiones**: contexto (fecha, producto, cliente).  
- **Esquemas**: estrella, copo de nieve (snowflake), constelación.

> **Ejemplo práctico:** tabla Hechos (Venta) con dimensiones Tiempo, Producto y Tienda — permite agregar ventas por mes/producto/tienda.

## 4.5. OLAP (Online Analytical Processing)
Tecnología para consultas multidimensionales: soporta operaciones como drill-up, drill-down, slice, dice y pivot.
### Operadores OLAP comunes
- **Drill-down / Drill-up** (detalle ↔ agregado).  
- **Slice / Dice** (filtros por dimensión / subcubo).  
- **Roll-up** (agregación por jerarquía).  
- **Pivot** (reorientar la vista de dimensiones vs medidas).

## 4.6. OLAP vs Data Mining
- **OLAP:** consulta, agregación y análisis histórico (¿cuánto? ¿cuándo?).  
- **Data Mining:** búsqueda de patrones y modelos predictivos (¿por qué? ¿qué se puede predecir?).

---

# 5. Tecnología BI y herramientas
## 5.1. Tipos de herramientas
Herramientas que cubren ETL, almacenamiento, OLAP, reporting y visualización. Algunas focos: ETL, DW, OLAP, reporting, visualización y catalogación.

## 5.2. Ejemplos representativos
- **Propietarias populares:** Power BI, Tableau, IBM Cognos, SAP BI, MicroStrategy, Qlik.  
- **Open-source / soluciones completas:** Pentaho (Kettle, Mondrian), JasperReports, SpagoBI.  
- **ETL/Orquestación:** Talend (Open Studio), Apache NiFi, Airflow (orquestación).  
- **DW / Cloud:** Azure Synapse, Google BigQuery, AWS Redshift, Snowflake.

> **Sugerencia práctica:** para prácticas universitarias, combina Power BI (o Tableau) + SQL (Postgres) + un pequeño DW (esquema estrella) y cubre los requisitos fundamentales.

---

# 6. Añadidos y clarificaciones útiles (imprescindibles para examen/prácticas)
## 6.1. Roles en gobernanza/BI
- **Chief Data Officer (CDO)** → responsable estratégico del dato.  
- **Data Owner** → responsable del dominio y decisiones sobre un conjunto de datos.  
- **Data Steward** → encargado de la calidad y reglas operativas del dato.  
- **Data Engineer** → desarrolla pipelines y mantiene infraestructuras de datos.  
- **Data Analyst / Data Scientist** → explota los datos y genera modelos o dashboards.

## 6.2. Conceptos prácticos
- **ETL vs ELT:** ETL = extraer-transformar-cargar; ELT = extraer-cargar-transformar (útil en arquitecturas cloud).  
- **Data Lake vs Data Warehouse:** Data Lake almacena datos crudos en múltiples formatos; DW almacena datos estructurados y optimizados para análisis.  
- **Data Catalog / Metadata Management:** inventario y diccionario de datos; esencial en organizaciones grandes.  
- **MDM (Master Data Management):** gestión y coherencia de entidades maestras (clientes, productos).  
- **DataOps:** prácticas ágiles y automatizadas para pipelines de datos y despliegue.

## 6.3. Calidad de dato — dimensiones
- Dimensiones a conocer: completitud, exactitud, consistencia, unicidad, vigencia (timeliness), validez.  
- Herramientas y técnicas: profiling, reglas de validación, dashboards de calidad y pipelines de corrección.

## 6.4. Ejemplo breve de flujo ETL (pasos)
1. **Extraer** desde ERP/DB/APIs/logs.  
2. **Validar** esquema y tipos.  
3. **Limpiar** (eliminar duplicados, imputar, normalizar).  
4. **Transformar** (agregaciones, enriquecimiento, normalización de dimensiones).  
5. **Cargar** en staging → DW (hechos/dimensiones).  
6. **Construir** vistas materializadas / cubos OLAP / modelos semánticos para reporting.

## 6.5. Métricas/KPIs — cómo justificarlas en un examen
- Siempre **vincula KPI ⇄ objetivo estratégico**.  
- Ejemplo: “Objetivo: aumentar facturación online → KPI: % crecimiento mensual de ventas online (cohortes)”.

---

# 7. Resumen ejecutivo (versión para examen)
El dato es un activo que, bien gobernado y gestionado, aporta ventaja competitiva. Para ello necesitamos gobernanza, ingeniería y analítica. Un Data Warehouse + OLAP + herramientas BI conforman la pila clásica para convertir datos en conocimiento y acciones. Marcos y normas (marcos de buena práctica) proporcionan el marco de madurez y control para asegurar calidad, cumplimiento y valor.