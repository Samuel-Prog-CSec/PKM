# 1. Seguridad de los Datos
La seguridad de los datos ==implica la planificación, desarrollo y ejecución de políticas y procedimientos== para **garantizar la** **autenticación, autorización, acceso y auditoría** adecuados. Su objetivo es *proteger los datos de problemas* como accesos no autorizados, datos falsos, fallos en la criptografía o ingeniería social.

## 1.1. Desafíos de la Seguridad: El Triángulo CIA
La seguridad de los datos busca *preservar tres características clave* (conocido como el triángulo CIA):
* **Confidencialidad:** Asegurar que la ==información solo esté disponible para personas autorizadas==.
* **Integridad:** Mantener los ==datos libres de modificaciones no autorizadas==.
* **Disponibilidad:** Garantizar que los ==datos sean accesibles cuando se requieran==.

## 1.2. Términos Clave
* **Vulnerabilidad:** Una *debilidad en un sistema* que ==puede ser explotada==.
* **Amenaza:** Una *acción ofensiva potencial* (interna o externa) que puede ==aprovechar una vulnerabilidad==.
* **Riesgo:** La *probabilidad de que una amenaza explote una vulnerabilidad*, causando una pérdida. Se mide ==considerando la probabilidad, el daño potencial y los costes==.

## 1.3. Requisitos de Seguridad de los Datos
Las necesidades de seguridad *provienen de diversas fuentes*:
* **Stakeholders:** ==Necesidades de privacidad y confidencialidad== de clientes, pacientes, etc.
* **Regulaciones gubernamentales:** ==Leyes== como el `GDPR` (*RGPD*) o la `LOPD`.
* **Activos de datos (`Assets`):** *Datos exclusivos* que ==dan una ventaja competitiva== a la empresa.
* **Necesidades de acceso legítimo:** Necesidad de que los ==empleados accedan a los datos para su trabajo==.
* **Obligaciones contractuales:** ==Acuerdos que exigen ciertos niveles== de protección (ej. estándar PCI para tarjetas de crédito).

## 1.4. Proceso General de Gestión de la Seguridad
1.  **Identificar y clasificar** los *activos de datos* sensibles.
2.  **Localizar** *dónde se almacenan* esos datos en la empresa. Una cantidad significativa de datos sensibles en un sola ubicación representa un alto riesgo.
3.  **Determinar las medidas de protección** adecuadas *para cada activo*.
4.  **Analizar la interacción** de los *datos con los procesos* de negocio (qué acceso se permite y en qué condiciones).

## 1.5. Roles y Responsabilidades
* **CISO (Chief Information Security Officer):** *Máximo responsable* de ==asegurar la información y definir los procesos de seguridad==. También, define ==criterios de confidencialidad a nivel de metadatos==.
* **CDO (Chief Data Officer):** Gestiona el *movimiento de los datos* y la ==aplicación de requisitos regulatorios==.
* **DPO (Data Protection Officer):** *garantizar privacidad y clasificación* de datos sensibles, definir ==criterios de privacidad de metadatos asociados==.
* **DPD (Delegado de Protección de Datos):** *coordinar cumplimiento* del `RGPD`.

## 1.6. Seguridad en Entornos Específicos
* **Nube:** Implica un modelo de **responsabilidad compartida** *entre el proveedor y el cliente* (==cadena de custodia, derechos de propiedad==).
* **Subcontratación:** *Aumenta los riesgos*. Es ==crucial definir las responsabilidades== en los contratos (`SLA`).

---

# 2. Técnicas de Seguridad de Datos
## 2.1. Las 4 As de la Seguridad
* **Autenticación:** ==Validar la identidad== del usuario.
* **Autorización:** ==Otorgar privilegios según roles==, para *acceder a vistas especificas* de los datos.
* **Acceso:** ==Permitir la conexión== a los sistemas (a *personas con autorización*).
* **Auditoría:** ==Revisar periódicamente las acciones de seguridad y la actividad== del usuario.

## 2.2. Matriz CRUDE
Una **herramienta para mapear las necesidades de acceso** a los datos y ==definir permisos basados en las acciones==: **C**reate (*Crear*), **R**ead (*Leer*), **U**pdate (*Actualizar*), **D**elete (*Eliminar*), **E**xecute (*Ejecutar*).

## 2.3. Data Masking (Enmascaramiento u ofuscación de Datos)
**Consiste en ocultar datos sensibles (con contenido modificado)** para *proteger la información original*, especialmente en entornos de prueba o desarrollo.
* **Tipos:**
    * *Persistente:* ==altera datos permanentemente== para entornos de prueba. Requiere hacer una ==copia de la base real y luego enmascarar la copia==.
    * *Dinámico:* ==cambia apariencia de datos sin modificar los originales==, es decir, ==la base es la misma y en tiempo real==, cuando se piden datos a ella, los da enmascarados.
* **Métodos:** *sustitución*, *barajado*, *desviación temporal*, *anulación o eliminación*, *aleatorización* y *pseudo-anonimización*.

## 2.4. Cifrado de Datos (Encriptación)
**Proceso de traducir un texto simple en códigos complejo**. Los *cifrados de datos no pueden ser leídos sin la clave*, que se almacena por separado.
* **Función Hash:** ==Convierte datos en una representación matemática== (`hash`) para verificar la **integridad** (==asegura que no han sido modificados==). Los algoritmos usados (y el orden de aplicación) son necesarios para revertir el proceso.
* **Cifrado Simétrico:** Utiliza ==una única clave privada== para cifrar y descifrar.
* **Cifrado Asimétrico:** ==Emplea un par de claves==: una **pública** (para cifrar, emisor) y una **privada** (para descifrar, receptor).

---

# 3. Ética de los Datos
La ética de datos **evalúa el impacto que el uso de los datos puede tener en las personas y la sociedad**. Los profesionales tienen la ==responsabilidad de gestionar datos con calidad y reducir riesgos de mal uso.==

## 3.1. Actividades para crear impacto
1. **Administración de datos**: *recopilarlos*, *mantenerlos* y *compartirlos*. 
2. **Crear información a partir de esos datos** (productos, servicios, análisis, visualizaciones). 
3. **Decidir qué hacer**, ==informado por los datos== junto con experiencia y comprensión.

## 3.2. Escenarios problemáticos
* **"Campo petrolero":** 
	* *Organizaciones acumulan datos* con modelos comerciales inapropiados.
	* ==Valor concentrado en monopolios de datos==, *aumentando desigualdad*. 
	* Efectos secundarios negativos como *riesgos de privacidad y seguridad*. 
	* Los ==datos se tratan como petróleo==: pocas organizaciones obtienen el valor.
* **"Páramo":** 
	* *Temores no abordados impiden obtener beneficios de los datos*. 
	* ==Datos no se recopilan o utilizan plenamente== (ej: retiro de consentimiento). 
	* Falta de datos *limita usos potenciales*. 
	* **Solución**: ==prácticas éticas==, ==equidad en acceso/beneficios==, ==compromiso== con afectados.

## 3.3. Riesgos de prácticas poco Éticas
* **Sincronización:** ==Definiciones poco claras==, ==comparaciones no válidas== o ==visualizaciones engañosas==.
* **Sesgo (Bias):** *Datos que reflejan distorsiones de la realidad*, ya sea por una recolección equivocada o por muestras no representativas. La ==solución es recolectar datos mejores y más limpios==.

## 3.4. Principio del doble efecto
Permite **justificar moralmente una acción que tiene efectos buenos y malos** *si se cumplen 4 condiciones*:
1. La ==acción en sí es moralmente buena o indiferente==.
2. El ==efecto malo no es el medio para lograr el efecto bueno==.
3. La *intención* es únicamente ==lograr el efecto bueno==.
4. Hay *proporcionalidad* entre el ==bien perseguido y el mal tolerado==.
* **Ejemplo: Detección de enfermedades** 
    * *Accion*: Usar historiales médicos para entrenar una IA de detección de enfermedades.
    * *Efecto bueno:* Diagnóstico precoz y mejora de la salud pública.
    * *Efecto malo:* Riesgo de exposición de datos sensibles.
    * *Evaluación:* La acción es aceptable si se aplican medidas de seguridad rigurosas.

## 3.5. Marco Regulatorio: GDPR (RGPD)
Reglamento de **legislación sobre la protección de datos y la privacidad**. ==Dar control a las personas sobre sus datos personales==. *Datos sobre mi :luc_equal_not:  mis datos*. Establece 7 principios clave:
1. **Legalidad, equidad y transparencia.** 
2. **Limitación de la finalidad.**
3. **Minimización de los datos.**
4. **Exactitud.**
5. **Limitación del almacenamiento.**
6. **Integridad y confidencialidad.**
7. **Responsabilidad proactiva.**

---

# 4. Monetización de los Datos
Los **datos se consideran la materia prima de la "revolución de la información"**. Los activos intangibles (como los datos) ==representan hoy una parte masiva del valor de las grandes empresas== (el 90% del valor del S&P 500, frente al 17% en 1975).

## 4.1. Modelos de monetización
* **Esfuerzos Internos:** Usar datos para *mejorar el negocio actual*, *optimizar procesos* y *reducir costes*.
	* *Mecanismos*: ==mejorar datos para el negocio principal==, generar nuevos insights.
* **Enriquecer Productos Existentes:** Usar datos para *retener clientes* y *mejorar sus productos*.
	* *Mecanismos*: ==capacidades e infraestructura== white-label.
* **Esfuerzos Externos:** Generar *nuevos flujos de ingresos*.
	* *Mecanismos*: crear ==nuevos datos u ofertas==.

## 4.2. Intercambio de valor
El valor de los datos depende de:
* **Tipo de datos:**
    1. *Self-reported:* ==Información proporcionada voluntariamente== (email, historial).
    2. *Digital Exhaust:* La ==huella digital== que dejamos (ubicación, navegación).
    3. *Profiling Data:* ==Perfiles predictivos creados== al combinar datos.
* **Uso de los datos:**
    1. *Mejorar* un producto o servicio.
    2. *Facilitar* ==marketing o publicidad== dirigida.
    3. *Generar ingresos* mediante la ==reventa a terceros==.