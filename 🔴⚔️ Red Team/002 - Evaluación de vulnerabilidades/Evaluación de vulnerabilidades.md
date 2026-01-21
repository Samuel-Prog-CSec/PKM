---
tags:
  - Pentesting/Vulnerabilidad
  - Pentesting
  - Escaneo
  - Introduccion
Fecha de actualización: 2025-09-02
Nota previa:
Nota siguiente: "[[Estándares de evaluación]]"
Area: "[[2️⃣ Búsqueda de vulnerabilidades]]"
---
---

Una evaluación de vulnerabilidad s**e basa en un estándar de seguridad particular y se analiza el cumplimiento de estos estándares** (por ejemplo, revisando una lista de verificación). 

El propósito de una evaluación de vulnerabilidades es comprender, identificar y categorizar el riesgo de los problemas más aparentes presentes en un entorno <mark style="background: #FFB8EBA6;">sin explotarlos realmente para obtener mayor acceso</mark>. Como ocurre con cualquier evaluación, es esencial **aclarar el alcance y la intención de la evaluación de vulnerabilidad antes de comenzar**. La gestión de vulnerabilidades es vital para ayudar a las organizaciones a identificar los puntos débiles de sus activos, comprender el nivel de riesgo y calcular y priorizar los esfuerzos de remediación.

Las evaluaciones de vulnerabilidad <mark style="background: #FFB86CA6;">se pueden realizar de forma independiente o junto con otras evaluaciones de seguridad</mark> dependiendo de la situación de una organización.

---

# Evaluaciones de vulnerabilidad vs pruebas de penetración
`Vulnerability Assessments` y las Pruebas de [[Pentesting]] son <mark style="background: #ADCCFFA6;">dos evaluaciones completamente diferentes</mark>. Las evaluaciones de vulnerabilidades <mark style="background: #FFB8EBA6;">buscan vulnerabilidades en las redes sin simular ataques cibernéticos</mark>. Todas las empresas deberían realizar evaluaciones de vulnerabilidad de vez en cuando. Se podría utilizar una amplia variedad de estándares de seguridad para una evaluación de vulnerabilidades, como el cumplimiento del *RGPD* o los estándares de seguridad de aplicaciones web [[OWASP]]. Una evaluación de vulnerabilidad pasa por una lista de verificación:
- **¿Cumplimos con este estándar?**
- **¿Tenemos esta configuración?**

Durante una evaluación de vulnerabilidad, el analista normalmente ejecutará <mark style="background: #FFB86CA6;">un análisis de vulnerabilidad y luego realizará una validación de vulnerabilidades críticas</mark>, de riesgo alto y medio. Esto significa que mostrarán evidencia de que la vulnerabilidad existe y <mark style="background: #FF5582A6;">no es un falso positivo</mark>, a menudo utilizando otras herramientas, pero no buscarán realizar escalada de privilegios, movimiento lateral, posexplotación, etc., si validan, por ejemplo, una vulnerabilidad de ejecución remota de código.

`Penetration tests`, dependiendo de su tipo, evaluar la seguridad de los diferentes activos y el impacto de los problemas presentes en el medio ambiente. Las pruebas de penetración **pueden incluir tácticas manuales y automatizadas para evaluar el estado de seguridad de una organización**. También suelen dar una mejor idea de <mark style="background: #ADCCFFA6;">qué tan seguros son los activos de una empresa desde una perspectiva de prueba</mark>. Un `pentest` es un <mark style="background: #FF5582A6;">ciberataque simulado</mark> para ver si se puede penetrar en la red y cómo. Independientemente del tamaño, la industria o el diseño de la red de una empresa, las pruebas de penetración solo deben realizarse después de que se hayan realizado con éxito algunas evaluaciones de vulnerabilidad y con correcciones. Una empresa puede realizar evaluaciones de vulnerabilidad y pruebas de penetración en el mismo año. <mark style="background: #8000E1A6;">Pueden complementarse entre sí</mark>. Pero son tipos muy diferentes de pruebas de seguridad que se utilizan en diferentes situaciones, y <mark style="background: #FF5582A6;">una no es "mejor"que el otro</mark>.

> [!attention]+
> Una organización puede beneficiarse más de una `vulnerability assessment` sobre una prueba de penetración si desean recibir una vista de problemas comúnmente conocidos mensual o trimestralmente de un proveedor externo. Sin embargo, una organización se beneficiaría más de una `penetration test` si están buscando un enfoque que utilice técnicas manuales y automatizadas para identificar problemas fuera de lo que un escáner de vulnerabilidades identificaría durante una evaluación de vulnerabilidad. Una prueba de penetración también podría ilustrar una cadena de ataques de la vida real que un atacante podría utilizar para acceder al entorno de una organización. Las personas que realizan pruebas de penetración tienen experiencia especializada en pruebas de redes, pruebas inalámbricas, ingeniería social, aplicaciones web y otras áreas.

> [!important]+
> Una evaluación de vulnerabilidad también proporciona pasos de remediación para solucionar los problemas.

---

# Metodología
A continuación se muestra un ejemplo de metodología de evaluación de vulnerabilidades que la mayoría de las organizaciones podrían seguir y con la que podrían tener éxito. <mark style="background: #ADCCFFA6;">Las metodologías pueden variar ligeramente de una organización a otra</mark>, pero <mark style="background: #FF5582A6;">este cuadro cubre los pasos principales</mark>, desde la identificación de activos hasta la creación de un plan de remediación. ![8 pasos para realizar una evaluación de vulnerabilidad de la red: 1. Realizar identificación y análisis de riesgos. 2. Desarrollar políticas de escaneo. 3. Identifique los tipos de escaneo. 4. Configurar el escaneo. 5. Realizar el escaneo. 6. Evaluar riesgos. 7. Interpretar resultados. 8. Crear un plan de remediación.](https://academy.hackthebox.com/storage/modules/108/graphics/VulnerabilityAssessment_Diagram_06a.png) _Adaptado del gráfico original encontrado [aquí](https://purplesec.us/wp-content/uploads/2019/07/8-steps-to-performing-a-network-vulnerability-assessment-infographic.png)._

---

# Comprender los términos clave
Identifiquemos algunos términos clave que cualquier profesional de TI o Infosec debería comprender y poder explicar con claridad.

## Vulnerabilidad
Una `Vulnerability` es una <mark style="background: #ADCCFFA6;">debilidad o error en el entorno de una organización, incluidas aplicaciones, redes e infraestructura, que abre la posibilidad de amenazas de actores externos</mark>. Las vulnerabilidades se pueden registrar a través de **MITRE** [Base de datos común de exposición a vulnerabilidades](https://cve.mitre.org/) y recibir un [Sistema común de puntuación de vulnerabilidades (CVSS)](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator) para determinar la gravedad. Este <mark style="background: #8000E1A6;">sistema de puntuación se utiliza con frecuencia como estándar para empresas y gobiernos que buscan calcular puntuaciones de gravedad precisas y consistentes para las vulnerabilidades de sus sistemas</mark>. Calificar las vulnerabilidades de esta manera ayuda a <mark style="background: #FFB8EBA6;">priorizar los recursos y determinar cómo responder a una amenaza determinada</mark>. Las puntuaciones se calculan utilizando métricas como el tipo de vector de ataque (red, adyacente, local, físico), la complejidad del ataque, los privilegios requeridos, si el ataque requiere o no la interacción del usuario y el impacto de la explotación exitosa en la confidencialidad, integridad y disponibilidad de los datos de una organización. **Las puntuaciones pueden variar de 0 a 10**, dependiendo de estas métricas.
![Amenaza más vulnerabilidad es igual a riesgo: una amenaza es un nuevo incidente con daño potencial. Una vulnerabilidad es una debilidad conocida. El riesgo es el daño potencial cuando una amenaza explota una vulnerabilidad.](https://academy.hackthebox.com/storage/modules/108/graphics/threat_vulnerability_risk.png)

## Amenaza
Una `Threat` es un <mark style="background: #ADCCFFA6;">proceso que amplifica el potencial de un evento adverso</mark>, como un actor de amenazas que explota una vulnerabilidad. Algunas vulnerabilidades plantean más preocupaciones de amenaza que otras debido a la probabilidad de que la vulnerabilidad sea explotada. Por ejemplo, cuanto mayor sea la recompensa del resultado y la facilidad de explotación, más probable será que el problema sea explotado por actores amenazantes.

## Exploits
Un `Exploit` es <mark style="background: #ADCCFFA6;">cualquier código o recurso que pueda utilizarse para aprovechar la debilidad de un activo</mark>. Muchos exploits están disponibles **a través de plataformas de código abierto** como [Base de datos de explotación](https://exploit-db.com/) o [Base de datos de vulnerabilidades y exploits de Rapid7](https://www.rapid7.com/db/). A menudo también veremos código de explotación alojado en sitios como *GitHub* y *GitLab*.

## Riesgo
`Risk`es la <mark style="background: #ADCCFFA6;">posibilidad de que activos o datos sean dañados o destruidos por actores amenazantes</mark>.
![El riesgo es el efecto de la incertidumbre sobre los objetivos, ISO 31000. Un efecto puede ser positivo (oportunidad) o negativo (amenaza). Sin objetivos, sin riesgos.](https://academy.hackthebox.com/storage/modules/108/graphics/whatisrisk.png)

---

# Gestión de activos
Cuando una organización de cualquier tipo, en cualquier industria y de cualquier tamaño necesita planificar su estrategia de ciberseguridad, debe comenzar por crear un inventario de sus `data assets`. Si quieres proteger algo, **¡primero debes saber qué estás protegiendo!** Una vez que se hayan inventariado los activos, podrá iniciar el proceso de `asset management`. Este es un concepto clave en la seguridad defensiva.

## Inventario de activos
`Asset inventory` es un <mark style="background: #ADCCFFA6;">componente crítico de la gestión de vulnerabilidades</mark>. Una organización necesita comprender qué activos hay en su red para brindar la protección adecuada y establecer defensas apropiadas. El inventario de activos debe incluir tecnología de la información, tecnología operativa, activos físicos, de software, móviles y de desarrollo. Las <mark style="background: #FFB8EBA6;">organizaciones pueden utilizar herramientas de gestión de activos para realizar un seguimiento de los activos</mark>. Los activos deben tener clasificaciones de datos para garantizar controles adecuados de seguridad y acceso.

## Inventario de aplicaciones y sistemas
Una organización debe crear un inventario exhaustivo y completo de activos de datos para una gestión adecuada de los activos para la seguridad defensiva. Los activos de datos incluyen:
- Todos los datos almacenados localmente. HDD y SSD en puntos finales (PC y dispositivos móviles), HDD y SSD en servidores, unidades externas en la red local, medios ópticos (DVD, discos Blu-ray, CD), medios flash (tarjetas USB, tarjetas SD). La tecnología heredada puede incluir disquetes, unidades ZIP (una reliquia de la década de 1990) y unidades de cinta.
- Todo el almacenamiento de datos que posee su proveedor de nube. [Servicios web de Amazon](https://aws.amazon.com/) (`AWS`), [Plataforma en la nube de Google](https://cloud.google.com/) (`GCP`), și [Microsoft Azure](https://azure.microsoft.com/en-us/) son algunos de los proveedores de nube más populares, pero hay muchos más. A veces, las redes corporativas son "multicloud", lo que significa que tienen más de un proveedor de nube. El proveedor de nube de una empresa proporcionará herramientas que se pueden utilizar para inventariar todos los datos almacenados por ese proveedor de nube en particular.
- Todos los datos almacenados en varios `Software-as-a-Service (SaaS)` aplicaciones. Estos datos también están "en la nube", pero es posible que no todos estén dentro del alcance de una cuenta de proveedor de nube corporativa. A menudo se trata de servicios al consumidor o de la versión "empresarial" de esos servicios. Piense en servicios en línea como `Google Drive`, `Dropbox`, `Microsoft Teams`, `Apple iCloud`, `Adobe Creative Suite`, `Microsoft Office 365`, `Google Docs`, y la lista continúa.
- Todas las aplicaciones que una empresa necesita utilizar para realizar sus operaciones y negocios habituales. Incluidas aplicaciones que se implementan localmente y aplicaciones que se implementan a través de la nube o que son de otro modo Software como servicio.
- Todos los dispositivos de redes informáticas locales de una empresa. Estos incluyen, entre otros: `routers`, `firewalls`, `hubs`, `switches`, dedicado `intrusion detection` y `prevention systems` (`IDS/IPS`), `data loss prevention` (`DLP`) sistemas, etc.

Todos estos activos son muy importantes. Un actor amenazante o cualquier otro tipo de riesgo para cualquiera de estos activos puede causar un daño significativo a la seguridad de la información de una empresa y a su capacidad para operar día a día. Una organización debe tomarse su tiempo para evaluar todo y tener cuidado de no perder ni un solo activo de datos, o no podrá protegerlo.

Las organizaciones frecuentemente agregan o eliminan computadoras, almacenamiento de datos, capacidad de servidores en la nube u otros activos de datos. Siempre que se agreguen o eliminen activos de datos, esto debe indicarse detalladamente en el `data asset inventory`.