---
tags: 
Fecha de actualización: 
Nota previa: 
Nota siguiente: 
Area: 
SO relacionado:
---
---

Tanto las pruebas de penetración como las evaluaciones de vulnerabilidad deben cumplir con estándares específicos para ser acreditadas y aceptadas por los gobiernos y las autoridades legales. Estas normas ayudan a garantizar que la evaluación se lleve a cabo exhaustivamente de una manera generalmente acordada para aumentar la eficiencia de estas evaluaciones y reducir la probabilidad de un ataque a la organización.

---

## Normas de cumplimiento

Cada organismo de cumplimiento normativo tiene sus propios estándares de seguridad de la información que las organizaciones deben cumplir para mantener su acreditación. Los grandes actores del cumplimiento en seguridad de la información son `PCI`, `HIPAA`, `FISMA`, y `ISO 27001`.

Estas acreditaciones son necesarias porque certifican que una organización ha hecho que un proveedor externo evalúe su entorno. Las organizaciones también dependen de estas acreditaciones para operaciones comerciales, ya que algunas empresas no harán negocios sin acreditaciones específicas de las organizaciones.

#### Estándar de seguridad de datos de la industria de tarjetas de pago (PCI DSS)

El [Estándar de seguridad de datos de la industria de tarjetas de pago (PCI DSS)](https://www.pcisecuritystandards.org/pci_security/) es un estándar comúnmente conocido en seguridad de la información que implementa requisitos para las organizaciones que manejan tarjetas de crédito. Si bien no es una regulación gubernamental, las organizaciones que almacenan, procesan o transmiten datos de los titulares de tarjetas aún deben implementar las pautas PCI DSS. Esto incluiría bancos o tiendas en línea que manejan sus propias soluciones de pago (por ejemplo, Amazon).

Los requisitos de PCI DSS incluyen el escaneo interno y externo de activos. Por ejemplo, cualquier dato de tarjeta de crédito que se esté procesando o transmitiendo debe realizarse en un entorno de datos del titular de la tarjeta (CDE). El entorno CDE debe estar adecuadamente segmentado de los activos normales. Los entornos CDE están segmentados del entorno habitual de una organización para proteger cualquier dato del titular de la tarjeta de verse comprometido durante un ataque y limitar el acceso interno a los datos.

![Objetivos de PCI DSS: construir y mantener una red segura, proteger los datos de los titulares de tarjetas, mantener un programa de gestión de vulnerabilidades, implementar fuertes medidas de control de acceso, monitorear y probar redes periódicamente y mantener una política de seguridad de la información.](https://academy.hackthebox.com/storage/modules/108/graphics/PCI-DSS-Goals.png) [Fuente](https://adktechs.com/wp-content/uploads/2019/06/PCI-DSS-Goals.png)

#### Ley de Portabilidad y Responsabilidad del Seguro Médico (HIPAA)

`HIPAA` es el [Ley de Portabilidad y Responsabilidad del Seguro Médico](https://www.hhs.gov/programs/hipaa/index.html), que se utiliza para proteger los datos de los pacientes. HIPAA no requiere necesariamente escaneos o evaluaciones de vulnerabilidad; sin embargo, se requiere una evaluación de riesgos y una identificación de vulnerabilidad para mantener la acreditación HIPAA.

### Ley Federal de Gestión de la Seguridad de la Información (FISMA)

El [Ley Federal de Gestión de la Seguridad de la Información (FISMA)](https://www.cisa.gov/federal-information-security-modernization-act) es un conjunto de estándares y directrices utilizados para salvaguardar las operaciones y la información del gobierno. La ley requiere que una organización proporcione documentación y prueba de un programa de gestión de vulnerabilidades para mantener la disponibilidad, confidencialidad e integridad adecuadas de los sistemas de tecnología de la información.

#### ISO 27001

`ISO 27001` es un estándar utilizado mundialmente para gestionar la seguridad de la información. [ISO 27001](https://www.iso.org/isoiec-27001-information-security.html) requiere que las organizaciones realicen escaneos externos e internos trimestrales.

Si bien el cumplimiento es esencial, no debería impulsar un programa de gestión de vulnerabilidades. La gestión de vulnerabilidades debe considerar la singularidad de un entorno y el apetito de riesgo asociado a una organización.

El `International Organization for Standardization` (`ISO`) mantiene estándares técnicos para prácticamente cualquier cosa que puedas imaginar. El [ISO 27001](https://www.iso.org/isoiec-27001-information-security.html) La norma se ocupa de la seguridad de la información. El cumplimiento de la norma ISO 27001 depende del mantenimiento de un sistema de gestión de seguridad de la información eficaz. Para garantizar el cumplimiento, las organizaciones pueden realizar pruebas de penetración de una manera cuidadosamente diseñada.

---

## Estándares de pruebas de penetración

Las pruebas de penetración no deben realizarse sin ninguna `rules` o `guidelines`. Siempre debe haber un alcance específicamente definido para un pentest, y el propietario de una red debe tener un `signed legal contract` con pentesters que describen lo que se les permite hacer y lo que no se les permite hacer. Las pruebas pentest también deben realizarse de tal manera que se cause un daño mínimo a las computadoras y redes de una empresa. Los evaluadores de penetración deben evitar realizar cambios siempre que sea posible (como cambiar la contraseña de una cuenta) y limitar la cantidad de datos eliminados de la red de un cliente. Por ejemplo, en lugar de eliminar documentos confidenciales de un archivo compartido, una captura de pantalla de los nombres de las carpetas debería ser suficiente para demostrar el riesgo.

Además del alcance y los aspectos legales, también existen varios estándares de pentesting, dependiendo del tipo de sistema informático que se esté evaluando. Estos son algunos de los estándares más comunes que puedes utilizar como pentester.

#### PTES

El [Estándar de ejecución de pruebas de penetración](http://www.pentest-standard.org/index.php/Main_Page) (`PTES`) se puede aplicar a todo tipo de pruebas de penetración. Describe las fases de una prueba de penetración y cómo deben realizarse. Estas son las secciones del PTES:

- Interacciones previas al compromiso
- Recopilación de inteligencia
- Modelado de amenazas
- Análisis de vulnerabilidades
- Explotación
- Post explotación
- Informes

#### OSSTMM

`OSSTMM` es el `Open Source Security Testing Methodology Manual`, otro conjunto de pautas que los pentesters pueden utilizar para asegurarse de que están haciendo su trabajo correctamente. Se puede utilizar junto con otros estándares pentest.

[OSSTMM](https://www.isecom.org/OSSTMM.3.pdf) se divide en cinco canales diferentes para cinco áreas diferentes de pentesting:

1. Seguridad humana (los seres humanos están sujetos a hazañas de ingeniería social)
2. Seguridad física
3. Comunicaciones inalámbricas (incluidas, entre otras, tecnologías como WiFi y Bluetooth)
4. Telecomunicaciones
5. Redes de datos

#### NIST

El `NIST` (`National Institute of Standards and Technology`) es bien conocido por su [Marco de ciberseguridad del NIST](https://www.nist.gov/cyberframework), un sistema para diseñar políticas y procedimientos de respuesta a incidentes. El NIST también tiene un marco de pruebas de penetración. Las fases del marco del NIST incluyen:

- Planificación
- Descubrimiento
- Ataque
- Informes

#### OWASP

`OWASP` significa el [Proyecto de seguridad de aplicaciones web abiertas](https://owasp.org/). Por lo general, son la organización a la que se recurre para definir estándares de prueba y clasificar riesgos para las aplicaciones web.

OWASP mantiene algunos estándares diferentes y guías útiles para evaluar diversas tecnologías:

- [Guía de pruebas de seguridad web (WSTG)](https://owasp.org/www-project-web-security-testing-guide/)
- [Guía de pruebas de seguridad móvil (MSTG)](https://owasp.org/www-project-mobile-security-testing-guide/)
- [Metodología de prueba de seguridad de firmware](https://github.com/scriptingxss/owasp-fstm)