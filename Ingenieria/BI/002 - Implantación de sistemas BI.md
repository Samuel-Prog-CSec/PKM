---
tags:
  - Ingenieria
  - Datos
Descripción: "Definir el conjunto de requisitos que serán usados para diseñar, construir e implementar la solución BI dentro del plazo y presupuestos fijados"
Fecha de actualización: 2026-01-19
Nota previa: "[[001 - El dato como activo y fundamentos de BI]]"
Nota siguiente: "[[003 - Modelado dimensional]]"
Area: "[[Inteligencia del negocio.base|Inteligencia del negocio]]"
---
---

# 1. FASE I: CAPTURA DE REQUISITOS (Dirigir y Planificar)
<mark style="background: #ADCCFFA6;">Definir el conjunto de requisitos que serán usados</mark> para <mark style="background: #FFB8EBA6;">diseñar, construir e implementar la solución BI</mark> dentro del plazo y presupuestos fijados.

## 1.1 Roles Principales
- **Analista de Negocio:** <mark style="background: #ADCCFFA6;">Puente entre TI y Negocio</mark>. Responsable de <mark style="background: #FFB86CA6;">recabar requisitos</mark>. Debe tener "*bilingüismo*" (hablar técnico y de negocios).
- **Usuarios de Negocio:** Sponsors, Stakeholders.
- **Roles Técnicos:** Arquitecto de datos, Modelador, Diseñador ETL, etc.

## 1.2 Tipos de Requisitos
Es fundamental diferenciar qué se pide:
1. **De Negocio:** *¿Qué se quiere hacer con la solución?* <mark style="background: #ADCCFFA6;">Definición de KPIs y métricas</mark>.
2. **De Datos:** <mark style="background: #ADCCFFA6;">Identificar las fuentes</mark> (**SOR** - Systems of Record), <mark style="background: #FFB86CA6;">calidad de datos y dónde</mark> residen.
3. **Funcionales:** Describen el <mark style="background: #ADCCFFA6;">proceso de análisis</mark>.
    - *BI Use Cases*: <mark style="background: #FFB86CA6;">Quién, por qué y cómo</mark> usará el sistema.
4. **Reglamentarios/Legales:** <mark style="background: #ADCCFFA6;">Privacidad, seguridad, cumplimiento</mark> (ej. *GDPR*), datos fiscales.
5. **Técnicos:** ¿Cloud u On-premise? <mark style="background: #ADCCFFA6;">Hardware, software</mark>, localización de centros de datos.
6. **De Reemplazo:**
    - Detectar si existen **"Data Shadow Systems"** o **"Spreadmarts"** (Sistemas en la sombra, generalmente <mark style="background: #FFB8EBA6;">excels complejos hechos a mano por usuarios</mark>) que hay que <mark style="background: #FFB86CA6;">sustituir e integrar profesionalmente</mark>.

## 1.3 Técnicas y Herramientas (Ampliación Teórica)
Para extraer esta información <mark style="background: #FF5582A6;">no basta con preguntar</mark>, se usan herramientas visuales:
- **Entrevistas y Brainstorming.**
- **Mock-ups:** <mark style="background: #ADCCFFA6;">Bocetos</mark> de cómo se verán las pantallas finales.
- **Storyboards:** <mark style="background: #ADCCFFA6;">Flujos que muestran la interacción</mark> del usuario paso a paso (ej. Clientes -> Proveedores -> Facturas).
- **Mapas Conceptuales (Concept Mappings):** <mark style="background: #ADCCFFA6;">Representación visual de relaciones</mark>.
    - *Spider Maps*: <mark style="background: #FFB8EBA6;">Concepto central y temas ramificados</mark>.
    - *Hierarchy Maps*: Estructura de <mark style="background: #FFB8EBA6;">rango</mark> (<mark style="background: #8000E1A6;">arriba general</mark>, abajo detalle).
    - *System Maps*: Relaciones complejas <mark style="background: #FFB8EBA6;">sin jerarquía estricta</mark>.
    - *Flowcharts*: Diagramas de <mark style="background: #FFB8EBA6;">flujo de trabajo</mark>.

> **💡 Consejo (Tip):** Es mejor enseñar un Dashboard parcial funcional rápido (MVP) que esperar meses para una solución completa. Evitar "documentos inacabables que nadie lee".

---

# 2. FASE II: FUENTES DE DATOS Y ARQUITECTURA
**Objetivo:** <mark style="background: #ADCCFFA6;">Identificar fuentes, prepararlas y definir dónde se guardarán</mark>.

## 2.1 Problemática de las fuentes (SORs)
- Los datos origen (OLTP) están <mark style="background: #ADCCFFA6;">diseñados para registrar operaciones</mark>, <mark style="background: #FF5582A6;">no para analizar</mark>.
- Los diferentes SORs identificados pueden estar bien estructurados, pero <mark style="background: #FFB86CA6;">no lo están para el propósito del análisis que queremos conseguir</mark> con el BI.
- Suelen ser <mark style="background: #ADCCFFA6;">inconsistentes entre distintos sistemas</mark> (diferente codificación de un mismo cliente).
- **Calidad:** Los <mark style="background: #FFB8EBA6;">errores se suelen descubrir al integrar (*ETL*), no en el origen</mark>.

## 2.2 Proceso de Preparación Lógica
1. **Recopilar/Extraer**.
2. **Reformatear**: los datos de los sistemas de origen deben <mark style="background: #FFB86CA6;">convertirse a un formato común para alimentar el DW</mark>.
3. **Consolidar/Estandarizar**: proporcionar una <mark style="background: #ADCCFFA6;">definición única y coherente</mark> de los datos.
4. **Transformar**: <mark style="background: #FFB86CA6;">convertir los datos en información</mark> empresarial.
5. **Limpieza**: implica un análisis más sofisticado de los datos, más allá de la verificación registro por registro que ya se ha llevado a cabo.
6. **Almacenamiento**.

## 2.3 Modelos de Arquitectura de Datos (MUY IMPORTANTE)
La **arquitectura de datos** <mark style="background: #ADCCFFA6;">define los datos junto con los esquemas, integración, transformaciones, almacenamiento y el flujo de trabajo</mark> necesarios para permitir los requisitos analíticos de la arquitectura de la información. Existen varias topologías:
1. **EDW (Enterprise Data Warehouse):** Un <mark style="background: #ADCCFFA6;">único almacén centralizado</mark> con toda la información de la <mark style="background: #FFB86CA6;">empresa integrada</mark>.
2. **Data Mart Independent:** Crear <mark style="background: #ADCCFFA6;">pequeños almacenes</mark> (Data Marts) <mark style="background: #FFB86CA6;">independientes por departamento</mark> (ej. uno para Marketing, uno para Ventas). *Problema*: <mark style="background: #FF5582A6;">silos de información y mantenimiento complejo</mark> de múltiples ETLs.
3. **Data Marts desde EDW (Híbrido/Hub and Spoke):** Un <mark style="background: #FFB8EBA6;">EDW central alimenta a pequeños Data Marts</mark>. <mark style="background: #ADCCFFA6;">Combina la integración total con la especificidad departamental.</mark>
4. **ODS (Operational Data Store):** <mark style="background: #ADCCFFA6;">Área temporal intermedia</mark>. Sirve para <mark style="background: #FFB8EBA6;">integración rápida y reporting operativo en tiempo casi real</mark> ("mientras ocurren las operaciones"), antes de pasar al DW histórico.
5. **Federado (FDW):** <mark style="background: #FFB86CA6;">Almacén lógico virtual</mark> que <mark style="background: #ADCCFFA6;">conecta datos físicamente dispersos</mark>.

---

# 3. FASE III: INTEGRACIÓN DE DATOS (ETL)
**Objetivo:** <mark style="background: #ADCCFFA6;">Mover los datos</mark> del origen (*OLTP*) al destino (*DW/Data Mart*).

## 3.1 Extract (Extracción)
<mark style="background: #ADCCFFA6;">Sacar datos de fuentes diversas</mark>. Se guardan en un **Staging Area** (*área intermedia*) <mark style="background: #FFB8EBA6;">para no saturar los sistemas origen</mark>.
- **Tipos de Extracción:**
    - *Full Extract*: <mark style="background: #FFB8EBA6;">Barrer la tabla completa</mark> (millones de registros).
    - *Incremental Extract*: Solo lo <mark style="background: #FFB8EBA6;">nuevo/modificado</mark>.
    - *Update Notification*: El<mark style="background: #FFB8EBA6;"> origen avisa cuando hay cambios</mark>.
- **CDC (Change Data Capture):** Patrones de software clave para <mark style="background: #FFB86CA6;">detectar qué ha cambiado y extraer solo eso</mark>. <mark style="background: #8000E1A6;">Minimiza el impacto</mark>.

## 3.2 Transform (Transformación)
<mark style="background: #ADCCFFA6;">Hacer los datos compatibles y útiles</mark>.
- **Conciliación:** <mark style="background: #FFB86CA6;">Estandarizar formatos</mark> (Fechas, Monedas, Unificar "M/F" con "Hombre/Mujer").
- **Limpieza (Data Cleansing):**
    - *Outliers (Atípicos)*: <mark style="background: #FFB8EBA6;">Valores extremos</mark>. Se pueden <mark style="background: #8000E1A6;">filtrar, ignorar o discretizar</mark> (agrupar en rangos "alto/medio/bajo").
    - *Missing Values (Faltantes)*: <mark style="background: #FFB8EBA6;">Nulos</mark>. Se pueden <mark style="background: #8000E1A6;">eliminar</mark> la columna/fila, <mark style="background: #8000E1A6;">reemplazar</mark> por una media o <mark style="background: #8000E1A6;">valor por defecto</mark>.

## 3.3 Load (Carga)
<mark style="background: #ADCCFFA6;">Poblar el DW</mark>.
- **Carga Inicial**: <mark style="background: #FFB86CA6;">Histórico completo</mark> (<mark style="background: #FFB8EBA6;">lenta y pesada</mark>).
- **Carga Periódica (Refresco)**: Se <mark style="background: #FFB86CA6;">añade lo nuevo</mark> según granularidad.
- **Conceptos Avanzados de Carga:**
    - *Claves Subrogadas (Surrogate Keys)*: Inventar un <mark style="background: #FFB86CA6;">ID propio para el DW en lugar de usar el ID del sistema origen</mark> (por si cambia o se repite).
    - *Slowly Changing Dimensions (Dimensiones lentamente cambiantes)*: ¿Qué hacemos si un cliente cambia de dirección? ¿Sobrescribimos (perdemos historia) o creamos registro nuevo (mantenemos historia)?

---

# 4. FASE IV: ANÁLISIS DE DATOS
**Objetivo:** <mark style="background: #ADCCFFA6;">Generar conocimiento</mark>. Aquí entra la **ingeniería de la estructura de datos**.

## 4.1 Tipos de Análisis
- **OLAP (On-Line Analytical Processing):** Definido en [[005 - Análisis de datos#3. Análisis con OLAP]]
- **Data Mining:** Definido en [[005 - Análisis de datos#4. Data Mining (Minería de Datos)]]
- **Big Data:** Definido en [[005 - Análisis de datos#5. Big Data]]

## 4.2 Tipos de Implementación OLAP
Definido en [[005 - Análisis de datos#Tipos de Implementación (ROLAP vs MOLAP)]]

## 4.3 Modelado Dimensional (Esquemas de Base de Datos)
Definidos en [[003 - Modelado dimensional]]

### 4.3.1 Tipos de Esquemas
Definidos en [[003 - Modelado dimensional#4. Esquemas de modelado]]

## 4.4 Operadores OLAP (El manejo del Cubo)
Definidos en [[005 - Análisis de datos#Operaciones OLAP (Navegación)]]

---

# 5. FASE V: VISUALIZACIÓN Y DIFUSIÓN
**Objetivo:** <mark style="background: #ADCCFFA6;">Hacer la información usable y comprensible</mark> (atractiva, interactiva, personalizable).

## 5.1 Herramientas Clave
1. **Dashboard (Cuadro de Mando Operativo):** <mark style="background: #FFB86CA6;">Monitoriza el estado actual</mark>, KPIs a corto plazo. <mark style="background: #FFB8EBA6;">Muy visual</mark>.
2. **Balanced Scorecard (Cuadro de Mando Integral - CMI):**
    - <mark style="background: #FFB86CA6;">Más estratégico</mark>. <mark style="background: #FFB8EBA6;">Enlaza objetivos a largo plazo con métricas</mark>.
    - Permite ver la <mark style="background: #8000E1A6;">evolución de la estrategia de la empresa</mark>.
3. **Mapas Geoespaciales:** Uso de <mark style="background: #FFB8EBA6;">Tooltips y capas geográficas</mark>.