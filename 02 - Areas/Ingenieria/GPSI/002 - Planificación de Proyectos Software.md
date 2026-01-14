# 1. Conceptos Fundamentales (¡No confundir!)
Es <mark style="background: #ADCCFFA6;">vital distinguir</mark> entre **Proyecto** y **Operación**, ya que <mark style="background: #FFB8EBA6;">se gestionan diferente</mark>.

| **Concepto**  | **Definición**                                                     | **Ejemplo**                                  |
| ------------- | ------------------------------------------------------------------ | -------------------------------------------- |
| **Proyecto**  | *Esfuerzo* **temporal** para crear un producto/servicio **único**. | Desarrollar una App.                         |
| **Operación** | *Función* **permanente** y repetitiva de la organización.          | Mantenimiento de servidores, soporte diario. |

**Gestión de Proyectos:** Es <mark style="background: #FFB86CA6;">equilibrar demandas concurrentes</mark> (el famoso "*triángulo de hierro*" ampliado): <mark style="background: #ADCCFFA6;">Alcance</mark>, <mark style="background: #ADCCFFA6;">Tiempo</mark>, <mark style="background: #ADCCFFA6;">Costes</mark>, <mark style="background: #ADCCFFA6;">Calidad</mark>, <mark style="background: #ADCCFFA6;">Recursos</mark> y <mark style="background: #ADCCFFA6;">Riesgos</mark>. <mark style="background: #FF5582A6;">Si tocas uno, afectas a los otros.</mark>

---

# 2. Naturaleza del Software (El Informe CHAOS)
El <mark style="background: #ADCCFFA6;">software es complejo, abstracto y cambiante</mark>.
- **Informe CHAOS (Standish Group):** Dice que la <mark style="background: #FFB8EBA6;">tasa de éxito es baja</mark> (32% en 2009).
- **La Crítica:** <mark style="background: #FF5582A6;">Se critica este informe</mark> porque <mark style="background: #8000E1A6;">define "éxito" solo como cumplir tiempo/coste/requisitos</mark>, <mark style="background: #FFB86CA6;">ignorando la calidad o la satisfacción del cliente</mark>. Además, a menudo se cita el dato de 1994 (el peor) para ser sensacionalista.

---

# 3. PMBOK 6: El "Monstruo" de los Procesos
El `PMBOK 6` se organiza en **5 Grupos de Procesos** y **10 Áreas de Conocimiento**.

## A. Grupo de INICIO (2 procesos)
Es <mark style="background: #ADCCFFA6;">formalizar que el proyecto existe</mark>.
1. **Desarrollar el Acta de Constitución (Project Charter):** <mark style="background: #FFB8EBA6;">Documento corto</mark> (1-2 págs) que <mark style="background: #FFB86CA6;">autoriza formalmente el proyecto</mark> y da <mark style="background: #8000E1A6;">autoridad al director</mark>. Define el "*qué*" y el "*por qué*" a alto nivel.
2. **Identificar a los Interesados (Stakeholders):** Es lo **primero** que hace el director <mark style="background: #CACFD9A6;">tras ser nombrado</mark>. <mark style="background: #FFB8EBA6;">Identifica a cualquiera </mark>(interno/externo, a favor/en contra)<mark style="background: #FFB8EBA6;"> que pueda influir</mark>.

## B. Grupo de PLANIFICACIÓN (El más grande)
<mark style="background: #FF5582A6;">No es lineal</mark>, es **iterativo**.
- **Plan de Dirección:** <mark style="background: #FFB86CA6;">Integra todos los planes subsidiarios</mark> (riesgos, calidad, etc.).
- **Alcance:**
    - _Recopilar Requisitos:_ <mark style="background: #ADCCFFA6;">Base del alcance</mark>.
    - _Crear la EDT (WBS):_ Descomposición **jerárquica** del trabajo. Clave <mark style="background: #8000E1A6;">para no olvidar nada.</mark>
- **Tiempo (Cronograma):**
    - _Definir Actividades_ -> _Secuenciar_ (dependencias) -> _Estimar Recursos_ -> _Estimar Duración_ -> **Desarrollar Cronograma** (Fechas inicio/fin).
- **Costes:**
    - _Determinar Presupuesto:_ Crea la **Línea Base de Costes** <mark style="background: #FFB8EBA6;">para medir el desempeño después</mark>.
- **Riesgos:**
    - _Planificar Respuesta:_ Asignar un **"propietario"** (<mark style="background: #FFB86CA6;">responsable</mark>) <mark style="background: #CACFD9A6;">para cada riesgo</mark>. Busca <mark style="background: #ADCCFFA6;">reducir amenazas y aumentar oportunidades</mark>.

## C. Grupo de EJECUCIÓN (Hacer el trabajo)
Aquí es <mark style="background: #ADCCFFA6;">donde se gasta la mayor parte del presupuesto y recursos</mark>.
- **Dirigir y gestionar el trabajo:** <mark style="background: #8000E1A6;">Implementar lo planificado</mark> y los cambios aprobados.
- **Gestionar el conocimiento:** <mark style="background: #FFB86CA6;">Usar lecciones aprendidas pasadas</mark> y generar nuevas para el futuro.
- **Calidad:** _Gestionar la calidad_ (<mark style="background: #FFB86CA6;">Auditorías</mark>) se hace aquí para <mark style="background: #CACFD9A6;">asegurar que se siguen los procesos</mark>.
- **Adquisiciones:** Efectuar adquisiciones es <mark style="background: #FFB86CA6;">seleccionar proveedores y firmar contratos</mark>.

## D. Grupo de MONITOREO Y CONTROL
Se <mark style="background: #ADCCFFA6;">compara el plan (*línea base*) con la realidad</mark>.
- **Control Integrado de Cambios:** <mark style="background: #FF5582A6;">¡Muy importante! Analizar y aprobar/rechazar cambios</mark>. <mark style="background: #FFB8EBA6;">Nada se cambia sin pasar por aquí</mark>.
- **Diferencia clave de examen (Alcance):**
    - **Controlar el Alcance:** <mark style="background: #FFB86CA6;">Evitar la "corrupción del alcance"</mark> (cambios no controlados).
    - **Validar el Alcance:** Conseguir la **aceptación formal** <mark style="background: #8000E1A6;">del cliente sobre los entregables terminados</mark>. <mark style="background: #FF5582A6;">Ojo</mark>: _No es testear_ (eso es calidad), es <mark style="background: #FFB86CA6;">que el cliente firme el OK</mark>.
- **Controlar las Adquisiciones:** Cerrar o modificar contratos. <mark style="background: #FFB8EBA6;">Solo el administrador de contratos puede autorizar cambios legales</mark>.

## E. Grupo de CIERRE
- **Cerrar proyecto o fase:** Incluye <mark style="background: #ADCCFFA6;">verificar entregables</mark>, <mark style="background: #ADCCFFA6;">aceptación formal final</mark>, <mark style="background: #FFB86CA6;">lecciones aprendidas</mark> y <mark style="background: #FFB8EBA6;">archivar información</mark> histórica. <mark style="background: #FF5582A6;">No te puedes saltar esto aunque el proyecto se cancele</mark>.

---

# 4. PMBOK 7: Cambio de Paradigma
El PMBOK 7 cambia de "Procesos" a **"Principios"** y **"Dominios de Desempeño"**. Se centra en la **Entrega de Valor**.

**Los 12 Principios (Debes que te suenen):**
1. **Administración (Stewardship):** Ética y cumplimiento.
2. **Equipo:** Colaboración y respeto.
3. **Interesados:** Involucrarlos, no solo gestionarlos.
4. **Valor:** El objetivo final.
5. **Pensamiento Holístico:** Ver el proyecto como un sistema conectado.
6. **Liderazgo:** Motivar e influir.
7. **Tailoring (Adaptación):** "No hay talla única", adapta el método al proyecto.
8. **Calidad:** En proceso y producto.
9. **Complejidad:** Gestionarla.
10. **Riesgo:** Minimizar amenazas, maximizar oportunidades.
11. **Adaptabilidad y Resiliencia:** Responder al cambio.
12. **Cambio:** Facilitar la transición futura.

---

# 5. Técnicas Específicas de Gestión Software
## Estimación (El Cono de Incertidumbre)
La <mark style="background: #ADCCFFA6;">estimación tiene 3 etapas</mark>: <mark style="background: #FFB86CA6;">Tamaño</mark> -> <mark style="background: #FFB8EBA6;">Esfuerzo</mark> -> <mark style="background: #8000E1A6;">Calendario</mark>.
- **Concepto Clave:** Al <mark style="background: #FFB86CA6;">inicio la incertidumbre es enorme</mark> (oscilación de *1 a 16*). A medida que avanza el proyecto, <mark style="background: #ADCCFFA6;">el margen de error se reduce</mark> (`Cono de Incertidumbre`).

## Desarrollo Global de Software (DGS)
*Reto*: <mark style="background: #FFB8EBA6;">Equipos distribuidos mundialmente</mark>.
- **Solución (Las 3 C):** <mark style="background: #ADCCFFA6;">Comunicación</mark>, <mark style="background: #ADCCFFA6;">Coordinación</mark> y <mark style="background: #ADCCFFA6;">Control</mark>.

## Calidad Software
Se divide en <mark style="background: #ADCCFFA6;">dos ramas</mark>:
1. **Calidad de Proceso:** <mark style="background: #FFB86CA6;">CMMI</mark>, <mark style="background: #FFB86CA6;">ISO 33000</mark>.
2. **Calidad de Producto:** <mark style="background: #FFB86CA6;">ISO 25000</mark>.

---

# 💡 Pistas para el examen (basadas en las diapositivas de preguntas)
- Si te preguntan <mark style="background: #ADCCFFA6;">qué es lo SIGUIENTE tras hacer el cronograma inicial</mark>: **Determinar requisitos de comunicación** (<mark style="background: #FFB8EBA6;">antes que riesgos o diagramas finales</mark>).
- <mark style="background: #ADCCFFA6;">¿Qué consume más recursos?</mark> La **Ejecución**.
- <mark style="background: #ADCCFFA6;">¿Quién gestiona los contratos?</mark> <mark style="background: #FF5582A6;">Solo</mark> el **administrador de contratos** (<mark style="background: #FFB86CA6;">especializado</mark>), <mark style="background: #FFB8EBA6;">no cualquiera</mark> del equipo.
- Las **Lecciones Aprendidas** sirven sobre todo como **registros históricos** <mark style="background: #ADCCFFA6;">para no repetir errores en futuros proyectos</mark>.