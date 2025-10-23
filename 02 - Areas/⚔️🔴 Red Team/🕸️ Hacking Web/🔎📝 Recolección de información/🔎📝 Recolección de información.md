**Web Reconnaissance** es la ==base de una evaluación de seguridad exhaustiva==. Este proceso implica ==recopilar sistemática y meticulosamente información sobre un sitio web== o aplicación web de destino. Es la fase preparatoria antes de profundizar en el análisis y la explotación potencial. Forma una parte crítica de la fase del **Proceso de Prueba de Penetración** "*`Infomation Gathering`*".
![[penetration_testing_process.png]]

Los objetivos principales del reconocimiento web incluyen:
- **Identifying Assets**: ==descubrir todos los componentes de acceso público== del objetivo, como páginas web, subdominios, direcciones IP y tecnologías utilizadas. Este paso proporciona una visión general completa de la presencia en línea del objetivo.
- **Discovering Hidden Information**: ==localización de información confidencial que podría estar expuesta== inadvertidamente, incluidos archivos de copia de seguridad, archivos de configuración o documentación interna. Estos hallazgos pueden revelar información valiosa y posibles puntos de entrada para los ataques.
- **Analysing the Attack Surface**: examinar la superficie de ataque del objetivo para ==identificar posibles vulnerabilidades y debilidades==. Esto implica evaluar las tecnologías utilizadas, las configuraciones y los posibles puntos de entrada para la explotación.
- **Gathering Intelligence:** ==recopilación de información que se puede aprovechar para una mayor explotación o ataques de ingeniería social==. Esto incluye identificar personal clave, direcciones de correo electrónico o patrones de comportamiento que podrían ser explotados.

Las **herramientas** que se tratan en este apartado son: `WHOIS`

# Índice
[[🔎📝 Recolección de información]]
**WHOIS**
- [[😮❓ WHOIS]]
- [[👍🙄 Utilizando WHOIS]]

**DNS & Subdominios**
- [[🧭 DNS]]


# Tipos de Reconocimiento
El reconocimiento web abarca dos metodologías fundamentales: **active** y **passive**. Cada enfoque ofrece distintas ventajas y desafíos, y comprender sus diferencias es crucial para la recopilación adecuada de información.


## Reconocimiento Activo
El **atacante interacciona directamente con el objetivo** para recopilar información. El reconocimiento activo ==proporciona una visión directa== y, a menudo, más completa de la infraestructura y la seguridad del objetivo. Sin embargo, también **conlleva un mayor riesgo de detección**, ya que las interacciones con el objetivo pueden desencadenar alertas o levantar sospechas. Esta interacción puede tomar varias formas:

| Técnica                  | Descripción                                                                                          | Ejemplo                                                                                                                                                        | Herramientas                                                 | Riesgo de Detección                                                                                                                        |
| ------------------------ | ---------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `Port Scanning`          | Identificar puertos y servicios abiertos que se ejecutan en el objetivo.                             | Usar Nmap para escanear un servidor web en busca de puertos abiertos como 80 (HTTP) y 443 (HTTPS).                                                             | Mapa, Masscan, Unicornscan                                   | Alto: La interacción directa con el objetivo puede desencadenar sistemas de detección de intrusiones (IDS) y firewalls.                    |
| `Vulnerability Scanning` | Probar el objetivo de vulnerabilidades conocidas, como software obsoleto o configuraciones erróneas. | Ejecutar Nessus contra una aplicación web para verificar si hay fallas de inyección SQL o vulnerabilidades de secuencias de comandos en sitios cruzados (XSS). | Nessus, OpenVAS, Nikto                                       | Alto: Los escáneres de vulnerabilidad envían cargas útiles de explotación que las soluciones de seguridad pueden detectar.                 |
| `Network Mapping`        | Mapeo de la topología de red del objetivo, incluidos los dispositivos conectados y sus relaciones.   | Usar traceroute para determinar la ruta que toman los paquetes para llegar al servidor de destino, revelando posibles saltos de red e infraestructura.         | Traceroute, Mapa                                             | Medio a Alto: El tráfico de red excesivo o inusual puede levantar sospechas.                                                               |
| `Banner Grabbing`        | Recuperar información de banners mostrados por servicios que se ejecutan en el objetivo.             | Conectarse a un servidor web en el puerto 80 y examinar el banner HTTP para identificar el software y la versión del servidor web.                             | Netcat, rizo                                                 | Bajo: El agarre de banner generalmente implica una interacción mínima, pero aún se puede registrar.                                        |
| `OS Fingerprinting`      | Identificar el sistema operativo que se ejecuta en el objetivo.                                      | Uso de las capacidades de detección de SO de Nmap (`-O`) para determinar si el objetivo está ejecutando Windows, Linux u otro sistema operativo.               | Mapa, Xprobe2                                                | Bajo: Las huellas dactilares del SO suelen ser pasivas, pero se pueden detectar algunas técnicas avanzadas.                                |
| `Service Enumeration`    | Determinar las versiones específicas de los servicios que se ejecutan en puertos abiertos.           | Uso de la detección de versiones de servicio de Nmap (`-sV`) para determinar si un servidor web está ejecutando Apache 2.4.50 o Nginx 1.18.0.                  | Mapa                                                         | Bajo: Similar al acaparamiento de banners, la enumeración del servicio se puede registrar, pero es menos probable que active alertas.      |
| `Web Spidering`          | Rastrear el sitio web de destino para identificar páginas web, directorios y archivos.               | Ejecutar un rastreador web como Burp Suite Spider o OWASP ZAP Spider para trazar la estructura de un sitio web y descubrir recursos ocultos.                   | Burp Suite Spider, OWASP ZAP Spider, Scrapy (personalizable) | De bajo a medio: Se puede detectar si el comportamiento del rastreador no está cuidadosamente configurado para imitar el tráfico legítimo. |


## Reconocimiento Pasivo
Implica **recopilar información sobre el objetivo sin interaccionar directamente con él**. Esto se basa en ==analizar la información y los recursos disponibles públicamente==, tales como:

|Técnica|Descripción|Ejemplo|Herramientas|Riesgo de Detección|
|---|---|---|---|---|
|`Search Engine Queries`|Utilizar motores de búsqueda para descubrir información sobre el objetivo, incluidos sitios web, perfiles de redes sociales y artículos de noticias.|Buscando en Google "`[Target Name] employees`"para encontrar información de los empleados o perfiles de redes sociales.|Google, DuckDuckGo, Bing y motores de búsqueda especializados (por ejemplo, Shodan)|Muy bajo: Las consultas de los motores de búsqueda son actividad normal de Internet y es poco probable que activen alertas.|
|`WHOIS Lookups`|Consultar bases de datos WHOIS para recuperar los detalles de registro de dominio.|Realizar una búsqueda de WHOIS en un dominio de destino para encontrar el nombre del registrante, la información de contacto y los servidores de nombres.|herramienta de línea de comandos de Whois, servicios de búsqueda de WHOIS en línea|Muy bajo: Las consultas de WHOIS son legítimas y no levantan sospechas.|
|`DNS`|Análisis de registros DNS para identificar subdominios, servidores de correo y otra infraestructura.|Usando `dig` para enumerar subdominios de un dominio de destino.|dig, nslookup, anfitrión, dnsenum, feroz, dnsrecon|Muy bajo: Las consultas DNS son esenciales para la navegación por Internet y generalmente no se marcan como sospechosas.|
|`Web Archive Analysis`|Examinar instantáneas históricas del sitio web del objetivo para identificar cambios, vulnerabilidades o información oculta.|Usar la Wayback Machine para ver versiones anteriores de un sitio web de destino para ver cómo ha cambiado con el tiempo.|Wayback Máquina|Muy bajo: Acceder a versiones archivadas de sitios web es una actividad normal.|
|`Social Media Analysis`|Recopilación de información de plataformas de redes sociales como LinkedIn, Twitter o Facebook.|Buscar en LinkedIn empleados de una organización objetivo para conocer sus roles, responsabilidades y posibles objetivos de ingeniería social.|LinkedIn, Twitter, Facebook, herramientas OSINT especializadas|Muy bajo: El acceso a los perfiles de redes sociales públicas no se considera intrusivo.|
|`Code Repositories`|Analizar repositorios de código de acceso público como GitHub para credenciales o vulnerabilidades expuestas.|Buscar en GitHub fragmentos de código o repositorios relacionados con el destino que puedan contener información confidencial o vulnerabilidades de código.|GitHub, GitLab|Muy bajo: Los repositorios de código están destinados al acceso público, y buscarlos no es sospechoso.|

>[!Nota]
>
>El reconocimiento pasivo **generalmente se considera más sigiloso y menos propenso a activar alarmas** que el reconocimiento activo. Sin embargo, puede producir ==información menos completa==, ya que se basa en lo que ya es de acceso público.