# 1. Conceptos Fundamentales
No confundir estos tres términos (suelen preguntar la diferencia):
- **Estimación:** Es una <mark style="background: #ADCCFFA6;">predicción</mark> (*basada en probabilidad*) <mark style="background: #FFB86CA6;">sobre el futuro</mark> (esfuerzo, tiempo, coste).
- **Medición:** Es una <mark style="background: #ADCCFFA6;">toma de datos real</mark> sobre <mark style="background: #FFB86CA6;">algo que ya ha ocurrido</mark> o existe (ej. medir líneas de código de un programa terminado).
- **Planificación:** Es la <mark style="background: #ADCCFFA6;">organización de tareas y recursos</mark>. **Primero estimas, luego planificas.**

## El Proceso de Estimación (Regla de Oro)
<mark style="background: #ADCCFFA6;">Nunca se estima el coste directamente</mark>. El <mark style="background: #FF5582A6;">orden obligatorio</mark> es:
1. Estimar el **Tamaño** (¿Qué tan grande es? Ej: Puntos de Función).
2. Estimar el **Esfuerzo** (¿Cuántas horas/personas costará? Ej: Personas-mes).
3. Estimar el **Tiempo/Coste** (¿Cuánto tardaremos y cuánto vale en euros?).

---

# 2. Leyes y Paradojas (Preguntas teóricas fijas)
- **Ley de los Grandes Números:** "Los errores hacia arriba se cancelan con los errores hacia abajo". Es mejor descomponer un proyecto grande en trozos pequeños para estimar, porque el error total será menor.
- **Ley de Parkinson:** "El trabajo se expande hasta llenar el tiempo disponible". Si das 2 semanas para una tarea de 1 día, tardarán 2 semanas.
- **Ley de Brooks:** "Añadir más personas a un proyecto de software retrasado, lo retrasará más" (debido a la curva de aprendizaje y la sobrecarga de comunicación).

---

# 3. Enfoques de Estimación

| **Enfoque**            | **Descripción**                                               | **Pros/Contras**                                                         |
| ---------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------ |
| **Top-Down (Analogy)** | Se estima el total basándose en proyectos similares pasados.  | ✅ Rápido.<br><br>  <br><br>❌ Poco preciso si el proyecto es novedoso.    |
| **Bottom-Up**          | Se descompone todo en tareas pequeñas, se estiman y se suman. | ✅ Más preciso (Ley Grandes Números).<br><br>  <br><br>❌ Lento y costoso. |

---

# 4. Puntos de Función - IFPUG (La parte práctica)
Este es el método estándar para medir el **tamaño funcional** (lo que el usuario ve y recibe), independientemente de la tecnología (Java, C#, etc.).

## A. Los 5 Componentes Funcionales
Se dividen en **Datos** (almacenamiento) y **Transacciones** (movimiento). Es vital saber distinguirlos para los ejercicios:

### 1. Funciones de Datos (Data Functions):
- **ILF (Internal Logical File - Fichero Lógico Interno):** Grupo de datos mantenidos **DENTRO** de la aplicación. (Ej: Tabla de Clientes que mi app crea y borra).
- **EIF (External Interface File - Fichero de Interfaz Externo):** Grupo de datos mantenidos por **OTRA** aplicación, pero que la nuestra solo **lee/referencia**.

### 2. Funciones Transaccionales (Transactional Functions):
- **EI (External Input - Entrada Externa):** Datos que entran desde fuera para mantener un ILF (Altas, Bajas, Modificaciones).
- **EO (External Output - Salida Externa):** Datos que salen al usuario. **REQUIERE cálculo matemático o lógica derivada.** (Ej: Un informe mensual con totales sumados).
- **EQ (External Query - Consulta Externa):** Datos que salen al usuario **SIN cálculo** complejo (recuperación directa). (Ej: Ver ficha de cliente).

## B. Cálculo de la Complejidad
Cada componente (ILF, EI, etc.) se clasifica como _Bajo, Medio o Alto_ según:
- **DET (Data Element Type):** Campos únicos (ej. Nombre, DNI, Edad = 3 DETs).
- **RET/FTR:** Subgrupos de datos o ficheros referenciados.

_(En el examen te darán tablas para saber cuántos puntos vale cada cosa, ej: un EI de complejidad Baja vale 3 puntos)._

---

# 5. Fórmulas de Puntos de Función (MEMORIZAR)
El proceso matemático tiene 3 pasos clave:

## Paso 1: Puntos de Función No Ajustados (UFPA)
Es la suma simple de todos los componentes multiplicados por su peso.
$$UFPA = \sum (Componentes \times Peso)$$

## Paso 2: Factor de Ajuste de Valor (VAF)
Se evalúan 14 Características Generales del Sistema (GSC) (como comunicación de datos, rendimiento, facilidad de uso...) puntuadas de 0 a 5. La suma se llama **TDI** (Total Degree of Influence).
$$VAF = (TDI \times 0.01) + 0.65$$

> _Nota:_ El VAF siempre estará entre 0.65 (muy simple) y 1.35 (muy complejo).

## Paso 3: Puntos de Función Ajustados (AFP)
Aquí está la trampa. La fórmula cambia según qué estemos midiendo (Proyecto de Desarrollo, de Mejora o Aplicación instalada).

### 1. Proyecto de Desarrollo (Nuevo Software):
$$DFP = (UFP + CFP) \times VAF$$

(Donde CFP son los puntos de conversión de datos, si los hay).

### 2. Proyecto de Mejora (Software existente):
Esta es la fórmula más compleja y probable en examen difícil:
$$EFP = [(ADD + CHGA + CFP) \times VAFA] + (DEL \times VAFB)$$

- **ADD:** Funciones añadidas.
- **CHGA:** Funciones cambiadas (tamaño DESPUÉS del cambio).
- **DEL:** Funciones borradas.
- **VAFA:** Factor de ajuste actual (After).
- **VAFB:** Factor de ajuste anterior (Before).

### 3. Aplicación (Total del sistema):
$$AFP = AFP_{inicial} + ADD + CHGA - (CHGB + DEL)$$

---

# 6. Otros Modelos de Estimación (Breve)
## COCOMO II (Constructive Cost Model)
Es un modelo paramétrico. Usa fórmulas logarítmicas.
- Entrada principal: **Líneas de Código (KSLOC)** o Puntos de Función.
- Usa "Conductores de Coste" (Cost Drivers) para ajustar la estimación (experiencia del equipo, complejidad del producto).

## Puntos de Casos de Uso (Use Case Points - UCP)
Similar a Puntos de Función pero basado en OO (Orientación a Objetos).
- Se basa en **Actores** (Simples/Complejos) y **Casos de Uso** (Simples/Complejos según número de transacciones).
- Fórmula final: $Esfuerzo = UCP \times 20$ (generalmente se asumen 20 horas por punto).

# 7. Anexo Práctico: Resolución Ejercicios Tema 4 (Diapositiva 41)
Estos ejercicios son **típicos de examen**. La clave está en saber qué sumar y qué ignorar según la fórmula.

_(Nota previa: Usamos los pesos estándar de IFPUG que seguramente tengas en otra tabla: EI Bajo=3, ILF Bajo=7, etc.)_

## Ejercicio 1: Proyecto de Desarrollo
>**Enunciado:** Un proyecto de desarrollo tiene:
> - 2 EI Baja (2x3 = 6)
> - 2 EI Media (2x4 = 8)
> - 2 EO Baja (2x4 = 8)
> - 2 EQ Alta (2x6 = 12)
> - 2 ILF Baja (2x7 = 14)
> - 1 EI Conversión Baja (1x3 = 3)
> 
> **¿Cuál es la cuenta de desarrollo (DFP)?**

**Solución**:
En un proyecto de desarrollo, se suma TODO, incluida la conversión (porque hay que programarla para migrar datos, aunque luego se tire).
$$Calculo = 6 + 8 + 8 + 12 + 14 + 3 = 51$$

✅ **Respuesta Correcta: C (51)**

---

## Ejercicio 2: Cuenta de Aplicación (Post-Instalación)
> **Enunciado:** Un proyecto de desarrollo tiene:
> - 5 EI Media (5x4 = 20)
> - 2 EI Alta (2x6 = 12)
> - 2 EO Media (2x5 = 10)
> - 2 EQ Media (2x4 = 8)
> - 1 EQ Alta (1x6 = 6)
> - 1 ILF Baja (1x7 = 7)
> - 1 ILF Alta (1x15 = 15)
> - 1 EIF Baja (1x5 = 5)
> - **1 EI Conversión Media (¡OJO AQUÍ!)**
> 
> **¿Cuál es la cuenta de la aplicación (AFP) final?**

**Solución**:
La cuenta de la aplicación mide el software que queda instalado y funcionando para el usuario.

La conversión de datos es un código que se usa una vez para cargar datos y luego desaparece; NO forma parte de la aplicación final. Por tanto, se ignora en esta suma.
$$Calculo = 20 + 12 + 10 + 8 + 6 + 7 + 15 + 5 = 83$$

✅ **Respuesta Correcta: D (83)**

---

## Ejercicio 3: Proyecto de Mejora

> **Enunciado:**
> - Tamaño antes de la mejora (AFPb) = 100.
> - La mejora **AÑADE**: 2 EI Baja (2x3 = 6).
> - La mejora **ELIMINA**: 1 EO Media (1x5 = 5).
> 
> **¿Cuál es el tamaño de la aplicación después (AFPa)?**

**Solución**:
Usamos la fórmula simplificada de aplicación post-mejora:
$$AFPa = (AFPb + AÑADIDAS) - BORRADAS$$
$$AFPa = (100 + 6) - 5 = 101$$

✅ **Respuesta Correcta: B (101)**

---

# 📝 "Chuleta" Final de Fórmulas (Para memorizar rápido)
Para cerrar tus apuntes, te recomiendo pegar esta tabla al final del todo para repasarla 5 minutos antes del examen:

|**Concepto**|**Fórmula Clave**|**Detalle Importante**|
|---|---|---|
|**PERT (Tiempo Esperado)**|$Te = \frac{Op + 4Mp + Pe}{6}$|Op=Optimista, Mp=Más probable, Pe=Pesimista.|
|**Desviación Estándar**|$\sigma = \frac{Pe - Op}{6}$|Cuanto mayor es $\sigma$, más riesgo.|
|**Holgura (Float)**|$LF - EF$ ó $LS - ES$|Si es 0, la tarea es CRÍTICA.|
|**Puntos Función (Desarrollo)**|$(UFP + CFP) \times VAF$|Se suma la conversión.|
|**Puntos Función (App)**|$\sum Funciones - Conversión$|**NO** se suma la conversión.|
|**Estimación Esfuerzo**|**1º** Tamaño $\to$ **2º** Esfuerzo $\to$ **3º** Tiempo/Coste|Nunca estimar el coste lo primero.|
