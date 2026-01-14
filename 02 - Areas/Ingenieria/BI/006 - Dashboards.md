---
tags:
  - Ingenieria
  - Análisis/Datos
  - Visualización/Datos
Fecha de actualización: 2026-01-12
Nota previa: "[[005 - Análisis de datos]]"
Nota siguiente:
Area: "[[Inteligencia del negocio.base|Inteligencia del negocio]]"
---
---

# 1. Principios de la Visualización
## 1.1. Conceptos y Tipos
Una visualización de datos es una <mark style="background: #ADCCFFA6;">representación visual deseada con el propósito de transmitir el significado de los datos y las percepciones que se han podido obtener del proceso de análisis realizado</mark>. El diseño depende del **público objetivo**. Se agrupan en tres bloques:
- **Data Storytelling (Narración):** Para _Decision Makers_. Diseñar visualizaciones <mark style="background: #ADCCFFA6;">para un público menos técnico</mark> en cuanto al proceso de análisis, pero que son los <mark style="background: #FFB86CA6;">responsables de la toma de decisiones en el negocio</mark>, ofrecer la información de manera <mark style="background: #FFB8EBA6;">clara y entendible</mark>. Formato: Imágenes estáticas o dashboards interactivos simples.
- **Data Showcasing (Exhibición):** Para _Analistas_. Visualizaciones abiertas para <mark style="background: #ADCCFFA6;">explorar datos y sacar conclusiones propias</mark>. Formato: Dashboards dinámicos e interactivos.
- **Data Art (Arte):** Para _Público General_. Busca <mark style="background: #ADCCFFA6;">entretener o provocar</mark>, para <mark style="background: #FFB86CA6;">atraer fuertemente la atención de la audiencia</mark>. <mark style="background: #FFB8EBA6;">Poca narrativa analítica</mark>, pero datos precisos.

### 1.1.1. Pasos para un diseño funcional
1. <mark style="background: #FFB8EBA6;">Conocer al público</mark> objetivo (necesidades, rol, conocimientos).
2. Definir el <mark style="background: #FFB8EBA6;">propósito</mark> (¿informar, explorar, persuadir?).
3. Elegir la <mark style="background: #FFB8EBA6;">visualización adecuada</mark> (en base al público objetivo y al propósito).

## 1.2. Semántica de la visualización
El objetivo de toda visualización es <mark style="background: #ADCCFFA6;">encontrar una forma adecuada de expresar la información que permita entender y percibir en forma efectiva un conjunto de datos y las posibles relaciones</mark> entre ellos.

`Semántica de la visualización == cómo se debe representar la información para darle el contexto y el sentido que la audiencia espera obtener`

- **Tablas (Cuadrículas numéricas):** Cuando la audiencia necesita conocer los **números precisos**.
- **Gráficos:** Cuando el objetivo es explorar **relaciones o tendencias**. Es <mark style="background: #FFB86CA6;">más fácil ver un punto de equilibrio ("`break-even point`") en un gráfico que en una tabla</mark>.
- **Colores y Formas:** <mark style="background: #FFB8EBA6;">Funcionan como números visuales</mark>.
    - _Ejemplo:_ En un mapa, el color indica el valor independientemente de la ubicación.
    - _Gráficos dirigidos:_ <mark style="background: #FFB8EBA6;">Uso de flechas en mapas</mark> para <mark style="background: #8000E1A6;">indicar dirección</mark> (envíos) y <mark style="background: #8000E1A6;">grosor para volumen</mark> (tonelaje).

---

# 2. Diseños Visuales
## 2.1. Consideraciones de diseño
- Si la **audiencia es técnica/analítica** $\rightarrow$ *Diseño simple y claro* (`Data Storytelling/Showcasing`). Las visualizaciones para el análisis de datos a audiencia con perfiles técnicos están destinadas a comunicar de forma clara y directa.
- Si la **audiencia es general/persuasión** $\rightarrow$ *Diseño emocional* (`Data Art`). Crear diseños que provoquen una respuesta emocional al público objetivo

### 2.1.1. Cómo añadir contexto (4 formas)
Añadir contexto a los elementos gráficos ayuda a la audiencia a comprender el valor y el significado de la información que se está visualizando. Si se ha optado por elegir un paradigma de diseño data art, no es adecuado agregar contexto ya que se perdería el objetivo que se pretende conseguir.
1. **Mediante datos:** Añadir métricas relevantes de apoyo (ej. tasa de abandono).
2. **Mediante anotaciones:** Encabezados y descripciones breves.
3. **Mediante elementos gráficos:** Líneas de tendencia, puntos de referencia, iconos.
4. **Mediante títulos y subtítulos:** La forma más sencilla de orientar al lector.

## 2.2. Selección del gráfico adecuado
Probablemente habrá que representar muchas facetas diferentes de la información, por lo que ser· necesario usar diferentes tipos de gráficos dentro de la misma visualización. Se clasifican en cuatro grupos según su complejidad y objetivo:

### A) Gráficos Estándar (Audiencia no puramente analítica)
- **Área:** Comparar valores y ver volumen acumulado.
- **Barras:** Comparar valores de una misma categoría.
- **Líneas:** Cambios en el tiempo o relaciones entre parámetros. Muy versátiles.
- **Circular (Pie chart):** Comparar partes de un todo. **Advertencia:** Evitar si la audiencia es experta/analítica (demasiada simplicidad).

### B) Gráficos Comparativos (Audiencia con cierta capacidad analítica)
Muestran el valor relativo de múltiples parámetros en una categoría, o la relación entre parámetros dentro de múltiples categorías compartidas. La principal diferencia con los gráficos estándar es que los comparativos ofrecen una forma de comparar simultáneamente más de un parámetro y categoría, a diferencia de los estándares en los que solo se puede apreciar la diferencia entre un parámetro de cualquier categoría.
- **Burbujas (Bubble):** Variante de dispersión donde el tamaño del círculo es una tercera dimensión. Útil para ver "huecos" o _outliers_.
- **Mapas de árbol (Tree maps):** Rectángulos anidados. El tamaño del área indica el valor relativo respecto al total.
- **Círculos rellenos (Packed circle):** Similar al Tree map pero con círculos agrupados.
- **Columnas apiladas:** Comparar múltiples atributos en una misma categoría. _Consejo:_ No incluir demasiados atributos para no saturar.

### C) Gráficos Estadísticos (Audiencia experta)
- **Histograma:** Distribución de frecuencia de una variable (barras).
- **Dispersión (Scatter plot):** Relación (x,y) para ver patrones, tendencias y valores atípicos.
- **Matriz de dispersión:** Serie de diagramas para ver correlaciones entre múltiples variables.

### D) Mapas (Datos espaciales)
- **Choropleth:** Áreas coloreadas/sombreadas según una variable (ej. Renta por estado).
- **Mapas de puntos:** Puntos en ubicaciones específicas. Pueden variar en tamaño/color.
- **Raster surface:** Datos sobre imágenes reales (satélite, fotografías).

## 2.3. Buenas prácticas de diseño
- **Consistencia > Elegancia:** Usar plantillas estándar (mismos fondos, ubicación de títulos) para que el usuario se centre en el análisis, no en aprender a usar el dashboard.
- **Diseños simples:** No temer a los espacios en blanco. Evitar el desorden ("clutter").
- **Localización:** Datos importantes arriba a la izquierda. Flujo de lectura: izquierda a derecha, arriba a abajo.
- **Uso del color:**
    - Limitar número de colores y paletas (máx 2 paletas).
    - Usar contraste, no tonos similares.
    - Usar convenciones semánticas (Verde = bueno, Rojo = malo/pérdidas).
    - Diseñar pensando en múltiples plataformas (móvil, tablet, PC).
- **Filtros y Slicers:** Aplicar a todas las visualizaciones a la vez. Usar barras deslizantes para rangos numéricos.
- **Leyendas:** Solo si son necesarias. Si se usan, que sean visibles en todas partes.
- **Limitar visualizaciones:** Máximo **4 o 5 gráficos** por dashboard.
- **Resaltar Outliers:** Usar colores o iconos para marcar la excepción.
- **Etiquetas:** Mejor horizontales que verticales.
- **Evitar barras de desplazamiento (scroll):** Si hay muchos datos, mejor paginar o usar otra pantalla.

## 2.4. Errores de diseño comunes
1. **Orden incorrecto:** Mostrar dimensiones no relacionadas jerárquicamente en un orden que insinúa una relación o tendencia falsa (ej. mezclar tiendas y semanas aleatoriamente en el eje X).
2. **Distorsión de área:** Usar iconos que al aumentar de altura también aumentan de anchura, cuadruplicando el área visual cuando el dato solo se ha duplicado (ej. el gráfico de las manzanas).

---

# 3. Tipos de Gráficos según el Análisis (Guía de uso)

| **Tipo de Análisis** | **Objetivo**                            | **Gráficos Recomendados**                                                                                                                                  | **Consejos**                                                                      |
| -------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| **Comparativo**      | Clasificar y comparar magnitudes.       | **Barras** (Simples o Apiladas).<br><br>Barras **Horizontales**: Para cualquier nº de elementos.<br><br>Barras **Verticales**: Solo si hay < 12 elementos. | Usar un único color si es simple.                                                 |
| **Tendencias**       | Ver evolución temporal.                 | **Líneas** y **Áreas**.                                                                                                                                    | Tiempo en el eje X. Usar distintos tipos de líneas/colores para segmentos.        |
| **Contribución**     | Ver la parte respecto al todo (%).      | **Tree Map** (muchos valores).<br><br>**Circular** (pocos valores).                                                                                        | Circular solo si hay < 10 elementos. Tree map usa degradados para enfatizar peso. |
| **Correlación**      | Identificar relaciones entre variables. | **Dispersión** (Scatter).                                                                                                                                  | Combinar con líneas/barras. Validar que la correlación implica causalidad.        |
| **Geográfico**       | Datos por ubicación.                    | **Mapas**.                                                                                                                                                 | Emparejar con gráficos adicionales (líneas/tablas) para dar detalle.              |
| **Distribución**     | Ver el rango, promedio y dispersión.    | **Box Plots** (Caja) e **Histogramas**.                                                                                                                    | Box Plot muestra cuartiles (Q1, Q2, Q3) y outliners.                              |

---

# 4. Herramientas de diseño de Dashboards
El equipo de BI debe diseñar un prototipo previo (boceto basado en las especificaciones del negocio y siguiendo los estándares de interfaz de usuario y de política corporativa) antes de construir nada. Se usan 4 técnicas, de menor a mayor detalle:
1. **Sketch (Boceto):** Dibujo rápido (papel/pizarra). Para _brainstorming_ y discutir ideas iniciales. Muy bajo coste de descarte.
2. **Wireframe:** Estructura visual ("esqueleto"). Muestra ubicación de gráficos, filtros y menús, pero sin diseño gráfico ni funcionalidad. Blanco y negro/grises.
3. **Storyboard:** Define la **acción** y el flujo. Muestra cómo el usuario interactúa paso a paso con la aplicación para realizar un análisis (secuencia de pantallas).
4. **Mock-up (Maqueta):** Representación visual **estática** del diseño final. Incluye colores, iconos, tipografía real. Parece la app final pero no funciona. _Nota:_ Muchas herramientas BI modernas saltan este paso y crean directamente un prototipo funcional.