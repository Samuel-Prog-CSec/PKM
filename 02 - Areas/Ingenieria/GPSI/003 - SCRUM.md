# 1. Introducción y Filosofía
<mark style="background: #ADCCFFA6;">Scrum no se basa en seguir un plan rígido</mark>, sino en el **control empírico** (basado en la experiencia) y la <mark style="background: #FFB86CA6;">adaptación continua</mark>.

## El Manifiesto Ágil (Valores Clave)
Es vital recordar que en Scrum <mark style="background: #FFB8EBA6;">se valora más lo de la izquierda que lo de la derecha</mark>:
- **Individuos e interacciones** > sobre procesos y herramientas.
- **Software funcionando** > sobre documentación extensiva.
- **Colaboración con el cliente** > sobre negociación contractual.
- **Respuesta ante el cambio** > sobre seguir un plan.

## Pilares del funcionamiento
- **Desarrollo Incremental:** Al final de cada iteración (*Sprint*) <mark style="background: #FFB8EBA6;">se entrega una parte operativa del producto</mark>.
- **Desarrollo Evolutivo:** Se <mark style="background: #FFB86CA6;">acepta la inestabilidad</mark> como premisa.
- **Auto-organización:** Los <mark style="background: #ADCCFFA6;">equipos deciden _cómo_ hacer el trabajo</mark> (<mark style="background: #FF5582A6;">no son auto-dirigidos</mark>, sino auto-organizados).

---

# 2. Roles en Scrum (La Metáfora del Cerdo y la Gallina)
En tus diapositivas se usa esta metáfora clásica para distinguir el nivel de implicación.
> [!info]+
> **La Metáfora:** En un plato de huevos con jamón, la <mark style="background: #FFB86CA6;">gallina</mark> está **involucrada** (<mark style="background: #FFB8EBA6;">pone el huevo</mark>), pero el <mark style="background: #FFB86CA6;">cerdo</mark> está **comprometido** (<mark style="background: #FFB8EBA6;">se deja la piel</mark>).

## A. Roles Comprometidos ("Cerdos")
Son los que <mark style="background: #ADCCFFA6;">construyen el producto</mark>.
1. **Propietario del Producto (Product Owner - PO):**
    - **Representa** a la <mark style="background: #FFB86CA6;">voz del cliente y los interesados</mark>.
    - **Responsabilidad clave:** <mark style="background: #8000E1A6;">Maximizar el valor </mark>del producto y el **Retorno de la Inversión (ROI)**.
    - **Tareas:** Gestiona la <mark style="background: #FFB8EBA6;">financiación</mark>, <mark style="background: #FFB8EBA6;">decide la funcionalidad</mark>, prioriza la Pila del Producto y <mark style="background: #FFB8EBA6;">acepta/rechaza el trabajo</mark>. Es una **sola persona**.
2. **Equipo de Desarrollo (Team):**
    - **Responsabilidad:** <mark style="background: #FFB86CA6;">Transformar la pila en un incremento funcional</mark>.
    - **Características:** <mark style="background: #FFB8EBA6;">Auto-gestionado</mark>, <mark style="background: #FFB8EBA6;">auto-organizado</mark> y **multifuncional** (tienen todas las habilidades necesarias).
    - Nadie les dice cómo convertir los requisitos en código.
3. **Scrum Manager (Scrum Master):**
    - **Responsabilidad:** <mark style="background: #FFB86CA6;">Asegurar que Scrum se entiende y se aplica</mark>. Es un "líder al servicio".
    - **Tareas:** <mark style="background: #FFB8EBA6;">Elimina impedimentos</mark> (trabas), <mark style="background: #FFB8EBA6;">facilita reuniones</mark>, <mark style="background: #FFB8EBA6;">protege al equipo</mark> de interrupciones externas y hace _coaching_.

## B. Roles Involucrados ("Gallinas")
1. **Interesados (Stakeholders):** <mark style="background: #FFB86CA6;">Clientes</mark>, <mark style="background: #FFB86CA6;">usuarios</mark>, <mark style="background: #FFB86CA6;">comerciales</mark>. <mark style="background: #ADCCFFA6;">Aportan feedback y deseos</mark>, pero <mark style="background: #FF5582A6;">no intervienen en el día a día</mark> del Sprint.

---

# 3. Artefactos (Componentes)
## 3.1. Pila de Producto (Product Backlog)
Es el <mark style="background: #ADCCFFA6;">inventario de **todo** lo que podría necesitar el producto</mark> (funcionalidades, mejoras, parches).
- **Propiedad:** Dueño y señor absoluto: **Product Owner**.
- **Características:**
    - Es un **documento vivo**: <mark style="background: #FFB86CA6;">Nunca se cierra</mark>, evoluciona constantemente.
    - Está **priorizada** por valor de negocio.
- **Campos de cada ítem:** <mark style="background: #FFB8EBA6;">Identificador</mark>, <mark style="background: #FFB8EBA6;">Descripción</mark>, <mark style="background: #FFB8EBA6;">Prioridad</mark> y <mark style="background: #FFB8EBA6;">Estimación</mark>. (Puede incluir también: Criterios de validación, Observaciones, etc.).

## 3.2. Pila del Sprint (Sprint Backlog)
Es el <mark style="background: #ADCCFFA6;">subconjunto de la Pila de Producto seleccionado para _ese_ Sprint concreto</mark>, más el plan para entregarlo.
- **Propiedad:** **Equipo de Desarrollo**.
- **Detalle:** Se <mark style="background: #FFB86CA6;">desglosa en tareas técnicas</mark> concretas de entre **2 y 16 horas**.
- **Regla de oro:** <mark style="background: #FF5582A6;">Solo el equipo puede modificarla durante el Sprint</mark>.

## 3.3. Incremento
La <mark style="background: #ADCCFFA6;">suma de todos los elementos de la Pila de Producto completados durante un Sprint</mark> y el valor de los incrementos de todos los Sprints anteriores. Debe estar **"Terminado"** (usar), operativo e inspeccionable.

---

# 4. Eventos (Reuniones)
## 4.1. Planificación del Sprint (Sprint Planning)
Se realiza <mark style="background: #FFB86CA6;">al inicio</mark>. Se divide en dos partes claras:
- **Parte 1 (El QUÉ):** El **Product Owner** presenta los <mark style="background: #ADCCFFA6;">ítems prioritarios y el equipo pregunta dudas</mark>. Se define el **Objetivo del Sprint**.
- **Parte 2 (El CÓMO):** El **Equipo** desglosa los ítems en <mark style="background: #ADCCFFA6;">tareas técnicas y estima tiempos</mark>. Se <mark style="background: #8000E1A6;">auto-asignan las tareas</mark>.
    - _Nota:_ El **Scrum Manager** actúa <mark style="background: #FFB8EBA6;">solo como moderador</mark>.

## 4.2. Reunión Diaria (Daily Scrum)
<mark style="background: #ADCCFFA6;">Reunión breve (máx. 15 min) para sincronizarse</mark>. Cada miembro <mark style="background: #FFB8EBA6;">responde a 3 preguntas</mark>:
1. ¿Qué hice ayer?
2. ¿Qué haré hoy?
3. ¿Tengo algún impedimento?

## 4.3. Seguimiento del Sprint (Burndown Chart)
Es un <mark style="background: #ADCCFFA6;">gráfico</mark> que muestra el **trabajo pendiente vs. tiempo**.
- **Eje Y**: *Esfuerzo* restante.
- **Eje X**: *Días* del Sprint.
- Sirve <mark style="background: #8000E1A6;">para ver si llegamos a tiempo</mark>. Es una herramienta de _seguimiento diario_.

## 4.4. Revisión del Sprint (Sprint Review)
<mark style="background: #FFB86CA6;">Al final del Sprint</mark>. El **equipo** <mark style="background: #ADCCFFA6;">presenta (*demo*) el incremento al **PO** y a los interesados</mark>. Se revisa <mark style="background: #FFB8EBA6;">qué se ha hecho y qué no</mark>.

---

# 5. Técnica de Estimación: Planning Poker
Es una *adaptación* del **método Delphi** para <mark style="background: #ADCCFFA6;">estimar en grupo y evitar sesgos</mark>. **Procedimiento:**
1. El **PO** explica una <mark style="background: #FFB86CA6;">historia de usuario</mark>.
2. El **equipo** <mark style="background: #FFB86CA6;">discute dudas</mark>.
3. <mark style="background: #FFB8EBA6;">Cada miembro selecciona una carta</mark> (con números tipo serie de *Fibonacci*: 1, 2, 3, 5, 8...) que representa el esfuerzo, **boca abajo**.
4. Se voltean todas a la vez.
5. <mark style="background: #FFB8EBA6;">Si hay consenso, esa es la estimación</mark>. Si hay dispersión (ej. uno saca un 3 y otro un 20), <mark style="background: #FFB86CA6;">discuten los extremos y repiten la votación</mark>.

> [!important]+
> **Cartas especiales**:
> - **? (Interrogación):** <mark style="background: #CACFD9A6;">Falta información</mark>, no puedo estimar.
> - **Taza de café:** Necesito un <mark style="background: #CACFD9A6;">descanso</mark>.

---

# ⚠️ Ojo para el examen (Detalles de tus diapositivas):
- **Duración de tareas:** En la Pila del Sprint, las tareas deben desglosarse para durar entre **2 y 16 horas**. Si una tarea dura más, debe dividirse.
- **Responsabilidad compartida:** En el equipo Scrum, no hay "mi tarea", el objetivo del Sprint es responsabilidad conjunta de todo el equipo.
- **Scrum Manager vs Master:** Tus diapositivas usan el término **"Scrum Manager"**. Aunque en la industria se usa "Master", en el examen usa el término de tus apuntes.