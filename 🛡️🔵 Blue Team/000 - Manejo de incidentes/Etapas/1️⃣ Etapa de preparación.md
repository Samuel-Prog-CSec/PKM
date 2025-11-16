En el `preparation` etapa, tenemos dos objetivos separados. El primero es el establecimiento de capacidad de manejo de incidentes dentro de la organización. La segunda es la capacidad de proteger y prevenir incidentes de seguridad informática mediante la implementación de medidas de protección adecuadas. Estas medidas incluyen el fortalecimiento de los puntos finales y del servidor, la clasificación de directorios activos, la autenticación multifactor, la gestión de acceso privilegiado, etcétera. Si bien la protección contra incidentes no es responsabilidad del equipo de manejo de incidentes, esta actividad es fundamental para el éxito general de ese equipo.

---

## Requisitos previos de preparación
Durante la preparación, debemos asegurarnos de tener:
- Miembros capacitados del equipo de manejo de incidentes (los miembros del equipo de manejo de incidentes se pueden subcontratar, pero de todos modos es necesaria una capacidad básica y una comprensión del manejo de incidentes internamente)
- Fuerza laboral capacitada (en la medida de lo posible, a través de actividades de concientización sobre seguridad u otros medios de capacitación)
- Políticas y documentación claras
- Herramientas (software y hardware)

---

## Políticas y documentación claras
Algunas de las políticas y documentación escritas deben contener una versión actualizada de la siguiente información:
- Información de contacto y funciones de los miembros del equipo de manejo de incidentes
- Información de contacto del departamento legal y de cumplimiento, equipo de gestión, soporte de TI, departamento de comunicaciones y relaciones con los medios, aplicación de la ley, proveedores de servicios de Internet, gestión de instalaciones y equipo de respuesta a incidentes externos
- Política, plan y procedimientos de respuesta a incidentes
- Política y procedimientos de intercambio de información sobre incidentes
- Líneas de base de sistemas y redes, a partir de una imagen dorada y un entorno de estado limpio
- Diagramas de red
- Base de datos de gestión de activos de toda la organización
- Cuentas de usuario con privilegios excesivos que el equipo puede utilizar bajo demanda cuando sea necesario (también para sistemas críticos para el negocio, que se manejan con las habilidades necesarias para administrar ese sistema específico). Estas cuentas de usuario normalmente se habilitan cuando se confirma un incidente durante la investigación inicial y luego se deshabilitan una vez finalizado. También se realiza un restablecimiento obligatorio de contraseña al deshabilitar a los usuarios.
- Capacidad de adquirir hardware, software o un recurso externo sin un proceso de adquisición completo (compra urgente de hasta una determinada cantidad). Lo último que necesitas durante un incidente es esperar semanas para la aprobación de una herramienta de $500.
- Hojas de trucos forenses/de investigación

Algunos de los casos no graves pueden manejarse con relativa rapidez y sin demasiada fricción dentro o fuera de la organización. Otros casos pueden requerir notificación policial y comunicación externa a clientes y proveedores externos, especialmente en casos de preocupaciones legales derivadas del incidente. Por ejemplo, una violación de datos que involucre datos de clientes debe informarse a las autoridades dentro de un cierto umbral de tiempo de acuerdo con el RGPD. Puede haber muchos requisitos de cumplimiento dependiendo de la ubicación y/o sucursales donde ocurrió el incidente, por lo que la mejor manera de entenderlos es discutirlos con sus equipos legales y de cumplimiento por incidente (o de manera proactiva).

Si bien es vital contar con documentación, también es importante documentar el incidente mientras se investiga. Por lo tanto, durante esta etapa también tendrás que establecer una capacidad de presentación de informes eficaz. Los incidentes pueden ser extremadamente estresantes y resulta fácil olvidar esta parte a medida que se desarrolla el incidente, especialmente cuando estás concentrado y vas extremadamente rápido para resolverlo lo antes posible. Intente mantener la calma, tomar notas y asegurarse de que estas notas contengan marcas de tiempo, la actividad realizada, el resultado de la misma y quién la realizó. En general, debes buscar respuestas sobre quién, qué, cuándo, dónde, por qué y cómo.

---

## Herramientas (Software y Hardware)
En el futuro, también debemos asegurarnos de tener las herramientas adecuadas para realizar el trabajo. Estos incluyen, entre otros:
- Una computadora portátil adicional o una estación de trabajo forense para cada miembro del equipo de manejo de incidentes para preservar imágenes de disco y archivos de registro, realizar análisis de datos e investigar sin ninguna restricción (sabemos que aquí se probará malware, por lo que herramientas como el antivirus deben desactivarse). Estos dispositivos deben manejarse adecuadamente y no de una manera que introduzca riesgos para la organización.
- Herramientas de adquisición y análisis de imágenes forenses digitales
- Herramientas de captura y análisis de memoria
- Captura y análisis de respuestas en vivo
- Herramientas de análisis de registros
- Herramientas de captura y análisis de redes
- Cables y conmutadores de red
- Bloqueadores de escritura
- Discos duros para imágenes forenses
- Cables de alimentación
- Destornilladores, pinzas y otras herramientas relevantes para reparar o desmontar dispositivos de hardware si es necesario
- Creador del Indicador de Compromiso (IOC) y capacidad de buscar IOC en toda la organización
- Formularios de cadena de custodia
- Software de cifrado
- Sistema de seguimiento de billetes
- Instalación segura para almacenamiento e investigación
- Sistema de manejo de incidentes independiente de la infraestructura de su organización

Muchas de las herramientas mencionadas anteriormente serán parte de lo que se conoce como `jump bag` - siempre listo con las herramientas necesarias para ser recogido y salir inmediatamente. Sin esta bolsa preparada, reunir todas las herramientas necesarias sobre la marcha puede llevar días o semanas antes de que esté listo para responder.

Por último, queremos destacar la importancia de que su sistema de documentación sea completamente independiente de la infraestructura de su organización y esté adecuadamente protegido. Supongamos desde el principio que todo su dominio está comprometido y que todos los sistemas pueden dejar de estar disponibles. De manera similar, las comunicaciones sobre un incidente deben realizarse a través de canales que no forman parte de los sistemas de la organización; supongamos que los adversarios tienen control sobre todo y pueden leer canales de comunicación como el correo electrónico.

---

Otra parte del `preparation` La etapa es para proteger contra incidentes. Si bien la protección no es necesariamente responsabilidad de un equipo de manejo de incidentes, deben conocer cualquier actividad relacionada con la protección para comprender mejor el tipo y la sofisticación de un incidente y saber dónde buscar artefactos/pruebas que puedan ayudar en la investigación.

Veamos ahora algunas de las medidas de protección altamente recomendadas, que tienen un alto impacto de mitigación contra la mayoría de las amenazas.

---

## DMARC

[DMARC](https://dmarcly.com/blog/how-to-implement-dmarc-dkim-spf-to-stop-email-spoofing-phishing-the-definitive-guide#what-is-dmarc) es una protección de correo electrónico contra phishing construida sobre lo ya existente [FPS](https://dmarcly.com/blog/how-to-implement-dmarc-dkim-spf-to-stop-email-spoofing-phishing-the-definitive-guide#what-is-spf) y [DKIM](https://dmarcly.com/blog/how-to-implement-dmarc-dkim-spf-to-stop-email-spoofing-phishing-the-definitive-guide#what-is-dkim). La idea detrás de DMARC es rechazar correos electrónicos que “fingen” tener su origen en su organización. Por lo tanto, si un adversario falsifica un correo electrónico haciéndose pasar por un empleado que solicita el pago de una factura, el sistema rechazará el correo electrónico antes de que llegue al destinatario previsto. DMARC es fácil y económico de implementar, sin embargo, no puedo enfatizar lo suficiente que es obligatorio realizar pruebas exhaustivas; de lo contrario (y este suele ser el caso), corre el riesgo de bloquear correos electrónicos legítimos sin posibilidad de recuperarlos.

Con las reglas de filtrado de correo electrónico, es posible que pueda llevar DMARC al nivel 'siguiente' y aplicar protección adicional contra correos electrónicos que fallan en DMARC desde dominios que no son de su propiedad. Esto es posible porque algunos sistemas de correo electrónico realizarán una verificación DMARC e incluirán un encabezado que indique si DMARC pasó o falló en los encabezados de los mensajes. Si bien esto puede ser increíblemente poderoso para detectar correos electrónicos de phishing de cualquier dominio, requiere pruebas exhaustivas antes de poder introducirlo en un entorno de producción. Los falsos positivos altos aquí son correos electrónicos que se envían "en nombre de" a través de algún servicio de envío de correo electrónico, ya que tienden a fallar en DMARC debido a una falta de coincidencia de dominio.

---

## Endurecimiento del punto final (y EDR)

Los dispositivos de punto final (estaciones de trabajo, computadoras portátiles, etc.) son los puntos de entrada para la mayoría de los ataques que enfrentamos a diario. Si consideramos el hecho de que la mayoría de las amenazas se originarán en Internet y estarán dirigidas a usuarios que navegan por sitios web, abren archivos adjuntos o ejecutan ejecutables maliciosos, un porcentaje de esta actividad ocurrirá desde sus puntos finales corporativos.

Actualmente existen algunos estándares de fortalecimiento de puntos finales ampliamente reconocidos, siendo las líneas base de CIS y Microsoft las más populares, y estos deberían ser realmente los componentes básicos para las líneas base de fortalecimiento de su organización. Algunas acciones muy importantes (que realmente funcionan) a tener en cuenta y sobre las que hacer algo son:

- Deshabilitar LLMNR/NetBIOS
- Implementar LAPS y eliminar privilegios administrativos de los usuarios habituales
- Deshabilitar o configurar PowerShell en modo "Idioma restringido"
- Habilite las reglas de reducción de superficie de ataque (ASR) si utiliza Microsoft Defender
- Implementar listas blancas. Sabemos que esto es casi imposible de implementar. Considere al menos bloquear la ejecución desde carpetas escribibles por el usuario (Descargas, Escritorio, AppData, etc.). Estos son los lugares donde inicialmente se encontrarán los exploits y las cargas útiles maliciosas. Recuerde bloquear también tipos de scripts como .hta, .vbs, .cmd, .bat, .js y similares. Por favor preste atención a [Jajaja](https://lolbas-project.github.io/) archivos mientras se implementa la lista blanca. No los pase por alto; realmente se utilizan en la naturaleza como acceso inicial para evitar la inclusión en la lista blanca.
- Utilice firewalls basados en host. Como mínimo, bloquee la comunicación de estación de trabajo a estación de trabajo y bloquee el tráfico saliente a LOLBins
- Implemente un producto EDR. En este momento, [AMSI](https://learn.microsoft.com/en-us/windows/win32/amsi/how-amsi-helps) Proporciona una gran visibilidad de los scripts ofuscados para que los productos antimalware inspeccionen el contenido antes de ejecutarlo. Es muy recomendable que elijas únicamente productos que se integren con AMSI.

Cuando se trata de endurecimiento, `Don't let perfect be the enemy of good`.

---

## Protección de red

La segmentación de red es una técnica poderosa para evitar que una brecha se extienda a toda la organización. Los sistemas críticos para el negocio deben estar aislados y las conexiones deben permitirse sólo cuando el negocio lo requiera. En realidad, los recursos internos no deberían estar orientados directamente a Internet (a menos que se coloquen en una DMZ).

Además, cuando se habla de protección de red se deben considerar los sistemas IDS/IPS. Su poder realmente brilla cuando se realiza la interceptación SSL/TLS para que puedan identificar tráfico malicioso basándose en el contenido del cable y no en la reputación de las direcciones IP, que es una forma tradicional y muy ineficiente de detectar tráfico malicioso.

Además, asegúrese de que solo los dispositivos aprobados por la organización puedan ingresar a la red. Se pueden utilizar soluciones como 802.1x para reducir el riesgo de traer su propio dispositivo (BYOD) o dispositivos maliciosos que se conecten a la red corporativa. Si es una empresa que solo utiliza la nube y utiliza, por ejemplo, Azure/Azure AD, puede lograr una protección similar con políticas de acceso condicional que permitirán el acceso a los recursos de la organización solo si se conecta desde un dispositivo administrado por la empresa.

---

## Gestión de identidades privilegiadas / MFA / Contraseñas

En este momento, robar credenciales de usuario privilegiadas es la ruta de escalada más común en entornos de Active Directory. Además, un error común es que los usuarios administradores tienen una contraseña débil (pero a menudo compleja) o una contraseña compartida con su cuenta de usuario habitual (que se puede obtener a través de múltiples vectores de ataque, como el registro de teclas). Como referencia, una contraseña débil pero compleja es "¡Contraseña1!". Incluye mayúsculas, minúsculas, caracteres numéricos y especiales, pero a pesar de ello, es fácilmente predecible y se puede encontrar en muchas listas de contraseñas que los adversarios emplean en sus ataques. Se recomienda enseñar a los empleados a utilizar frases de contraseña porque son más difíciles de adivinar y difíciles de forzar. Un ejemplo de una frase con contraseña que es fácil de recordar pero larga y compleja es "me gusta mi café caliente".Si uno conoce un segundo idioma, puede mezclar palabras de varios idiomas para obtener protección adicional.

La autenticación multifactor (MFA) es otra solución de protección de identidad que debe implementarse al menos para cualquier tipo de acceso administrativo **TODOS** aplicaciones y dispositivos.

---

## Escaneo de vulnerabilidades

Realice escaneos continuos de vulnerabilidades de su entorno y solucione al menos las vulnerabilidades "altas" y "críticas" que se descubran. Si bien el escaneo se puede automatizar, las correcciones generalmente requieren participación manual. Si por alguna razón no puedes aplicar parches, ¡segmenta definitivamente los sistemas que son vulnerables!

---

## Capacitación para la concientización del usuario

Capacitar a los usuarios para que reconozcan comportamientos sospechosos y los denuncien cuando los descubran es una gran victoria para nosotros. Si bien es poco probable alcanzar el 100% de éxito en esta tarea, se sabe que estas capacitaciones reducen significativamente el número de compromisos exitosos. Las pruebas periódicas "sorpresa" también deberían formar parte de esta formación, incluyendo, por ejemplo, correos electrónicos de phishing mensuales, memorias USB caídas en el edificio de oficinas, etc.

---

## Evaluación de seguridad de Active Directory

La mejor manera de detectar configuraciones de seguridad incorrectas o vulnerabilidades críticas expuestas es buscarlas desde la perspectiva de un atacante. Realizar sus propias revisiones (o contratar a un tercero si falta el conjunto de habilidades en la organización) garantizará que cuando un dispositivo de punto final se vea comprometido, el atacante no tendrá una posibilidad de escalada en un solo paso a altos privilegios en la red. Cuantas más herramientas y actividad adicionales genere un atacante, mayor será la probabilidad de que las detectes, así que intenta eliminar las ganancias fáciles y las oportunidades más fáciles tanto como sea posible.

Active Directory tiene algunas rutas/errores de escalada conocidos y únicos. Con bastante frecuencia también se descubren otros nuevos. Las evaluaciones de seguridad de Active Directory son cruciales para la postura de seguridad del entorno en su conjunto. No asuma que los administradores de su sistema están al tanto de todos los errores descubiertos o publicados, porque en realidad probablemente no lo estén.

---

## Ejercicios del equipo morado
Necesitamos capacitar a los encargados de gestionar incidentes y mantenerlos comprometidos. De eso no hay duda y el mejor lugar para hacerlo es dentro del propio entorno de una organización. Los ejercicios del equipo morado son esencialmente evaluaciones de seguridad realizadas por un equipo rojo que informan continua o eventualmente al equipo azul sobre sus acciones, hallazgos, cualquier deficiencia de visibilidad/seguridad, etc. Dichos ejercicios ayudarán a identificar vulnerabilidades en una organización mientras prueban la capacidad defensiva del equipo azul en términos de registro, monitoreo, detección y capacidad de respuesta. Si una amenaza pasa desapercibida, existe la oportunidad de mejorar. Para aquellos que sean detectados, el equipo azul puede probar cualquier manual y procedimiento de manejo de incidentes para asegurarse de que sean sólidos y que se haya logrado el resultado esperado.