`Network Traffic Analysis (NTA)` puede describirse como el acto de examinar el tráfico de la red para caracterizar los puertos y protocolos comunes utilizados, establecer una línea de base para nuestro entorno, monitorear y responder a las amenazas y garantizar la mayor información posible sobre la red de nuestra organización.

Este proceso ayuda a los especialistas en seguridad a determinar anomalías, incluidas amenazas de seguridad en la red, y a identificar amenazas de forma temprana y eficaz. El análisis del tráfico de red también puede facilitar el proceso de cumplimiento de las pautas de seguridad. Los atacantes actualizan sus tácticas con frecuencia para evitar ser detectados y aprovechar credenciales legítimas con herramientas que la mayoría de las empresas permiten en sus redes, lo que dificulta la detección y, posteriormente, la respuesta de los defensores. En tales casos, el análisis del tráfico de red puede volver a resultar útil. Los casos de uso cotidianos de NTA incluyen:

| `Collecting`  | tráfico en tiempo real dentro de la red para analizar amenazas futuras.                                                                                                               |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Setting`     | una línea de base para las comunicaciones de red diarias.                                                                                                                             |
| `Identifying` | analizar el tráfico de puertos no estándar, hosts sospechosos y problemas con los protocolos de red, como errores HTTP, problemas con TCP u otras configuraciones incorrectas de red. |
| `Detecting`   | malware en el cable, como ransomware, exploits e interacciones no estándar.                                                                                                           |

> [!info]
> La NTA también es útil cuando se investigan incidentes pasados y durante la búsqueda de amenazas.

Intente imaginarse a un actor de amenazas apuntando e infiltrándose en nuestra red. Si desean violar la red, los atacantes inevitablemente deben interactuar y comunicarse con nuestra infraestructura. La comunicación de red se realiza a través de muchos puertos y protocolos diferentes, y todos ellos son utilizados simultáneamente por empleados, equipos y clientes. Para detectar tráfico malicioso, necesitaríamos utilizar nuestro conocimiento del tráfico de red típico dentro de nuestro enclave. Hacerlo limitará nuestra búsqueda y nos ayudará a encontrar e interrumpir rápidamente la comunicación adversaria.

Por ejemplo, si detectamos muchos `SYN` paquetes en puertos que nunca (o rara vez) utilizamos en nuestra red, podemos concluir que lo más probable es que se trate de alguien que intenta determinar qué puertos están abiertos en nuestros hosts. Acciones como ésta son marcadores típicos de una `portscan`. Realizar dicho análisis y llegar a tales conclusiones requiere habilidades y conocimientos específicos.

---

# Habilidades y conocimientos necesarios
## Pila TCP/IP y modelo OSI
Esta comprensión garantizará que comprendamos cómo interactúan el tráfico de red y las aplicaciones host.

## Conceptos básicos de red
Comprender qué tipos de tráfico veremos en cada nivel incluye comprender las capas individuales que componen el modelo TCP/IP y OSI y los conceptos de conmutación y enrutamiento. Si analizamos una red en un enlace troncal, veremos mucho más tráfico de lo habitual y será muy diferente de lo que encontramos al analizar un `switch` de oficina.

## Puertos comunes y protocolos
Identificar puertos y [[Protocolos de red]]] estándar rápidamente y tener una comprensión funcional de cómo se comunican garantizará que podamos identificar tráfico de red potencialmente malicioso o mal formado.

## Conceptos de paquetes IP y subcapas
El conocimiento fundamental de cómo se comunican TCP y UDP garantizará, como mínimo, que entendamos lo que vemos o buscamos. TCP, por ejemplo, está orientado a transmisiones y nos permite seguir una conversación entre hosts fácilmente. UDP es rápido pero no se preocupa por la integridad, por lo que sería más difícil recrear algo a partir de este tipo de paquete.

## Protocolo de encapsulación de transporte
Cada capa encapsulará la anterior. Poder leer o diseccionar cuándo cambia esta encapsulación nos ayudará a movernos a través de los datos más rápido. Es fácil ver sugerencias basadas en encabezados de encapsulación.

---

# Equipamiento
La siguiente lista contiene muchas herramientas y tipos de equipos diferentes que pueden utilizarse para realizar análisis del tráfico de red. Cada uno proporcionará una forma diferente de capturar o analizar el tráfico. Algunos ofrecen formas de copiar y capturar, mientras que otros leen e ingieren. Este módulo explorará sólo algunos de estos ([[Wireshark]] y [[Tcpdump]] principalmente). Tenga en cuenta que estas herramientas no están estrictamente diseñadas para administradores. Muchos de ellos también pueden utilizarse por motivos maliciosos.

## Herramientas comunes de análisis de tráfico

| **Her herramienta**                                  | **Descripción**                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [[Tcpdump]]                                          | [tcpdump](https://www.tcpdump.org/) es una utilidad de línea de comandos que, con la ayuda de LibPcap, captura e interpreta el tráfico de red desde una interfaz de red o un archivo de captura.                                                                                                                                                                                                                                                                      |
| [[Wireshark#Parámetros básicos de TShark \| TShark]] | [Tshark](https://www.wireshark.org/docs/man-pages/tshark.html) es un analizador de paquetes de red muy parecido a TCPDump. Capturará paquetes de una red en vivo o los leerá y decodificará desde un archivo. Es la variante de línea de comandos de Wireshark.                                                                                                                                                                                                       |
| [[Wireshark#GUI de Wireshark \| Wireshark]]          | [Cazador de cables](https://www.wireshark.org/) es un analizador gráfico de tráfico de red. Captura y decodifica fotogramas del cable y permite una mirada en profundidad al entorno. Puede ejecutar muchos disectores diferentes contra el tráfico para caracterizar los protocolos y las aplicaciones y proporcionar información sobre lo que está sucediendo.                                                                                                      |
| `NGrep`                                              | [NGrep](https://github.com/jpr5/ngrep) es una herramienta de coincidencia de patrones diseñada para cumplir una función similar a grep para distribuciones de Linux. La gran diferencia es que funciona con paquetes de tráfico de red. NGrep entiende cómo leer tráfico en vivo o tráfico desde un archivo PCAP y utilizar expresiones regulares y sintaxis BPF. Esta herramienta brilla mejor cuando se utiliza para depurar tráfico de protocolos como HTTP y FTP. |
| `tcpick`                                             | [tcpick](http://tcpick.sourceforge.net/index.php?p=home.inc) es un rastreador de paquetes de línea de comandos que se especializa en rastrear y reensamblar flujos TCP. La funcionalidad para leer una transmisión y volver a ensamblarla en un archivo con tcpick es excelente.                                                                                                                                                                                      |
| `Network Taps`                                       | Grifos ([Gigamón](https://www.gigamon.com/), [Grifos de Niágara](https://www.niagaranetworks.com/products/network-tap)) son dispositivos capaces de tomar copias del tráfico de la red y enviarlas a otro lugar para su análisis. Estos pueden estar en línea o fuera de banda. Pueden capturar y analizar activamente el tráfico de forma directa o pasiva volviendo a colocar el paquete original en el cable como si nada hubiera cambiado.                        |
| `Networking Span Ports`                              | [Puertos Span](https://en.wikipedia.org/wiki/Port_mirroring) son una forma de copiar marcos de dispositivos de red de capa dos o tres durante el procesamiento de entrada o salida y enviarlos a un punto de recopilación. A menudo se refleja un puerto para enviar esas copias a un servidor de registro.                                                                                                                                                           |
| `Elastic Stack`                                      | El [Pila elástica](https://www.elastic.co/elastic-stack) es la culminación de herramientas que pueden tomar datos de muchas fuentes, ingerirlos y visualizarlos, para permitir su búsqueda y análisis.                                                                                                                                                                                                                                                                |
| `SIEMS`                                              | `SIEMS` (como [Splunk](https://www.splunk.com/en_us)) son un punto central en el que se analizan y visualizan los datos. Las alertas, el análisis forense y los controles diarios del tráfico son casos de uso de un SIEM.                                                                                                                                                                                                                                            |

---

# Sintaxis BPF
Muchas de las herramientas mencionadas anteriormente tienen su sintaxis y comandos para utilizar, pero una que se comparte entre ellas es [Filtro de paquetes Berkeley (BPF)](https://en.wikipedia.org/wiki/Berkeley_Packet_Filter) sintaxis. Esta sintaxis es el método principal que utilizaremos. En esencia, BPF es una tecnología que permite que una interfaz sin formato lea y escriba desde la capa Data-Link. Con todo esto en mente, nos preocupamos por BPF por las capacidades de filtrado y decodificación que nos proporciona. Utilizaremos la sintaxis BPF a través del módulo, por lo que una comprensión básica de cómo está configurado un filtro BPF puede resultar útil. Para obtener más información sobre la sintaxis BPF, consulte esto [referencia](https://www.ibm.com/docs/en/qsip/7.4?topic=queries-berkeley-packet-filters).

---

# Realización de análisis de tráfico de red
Realizar análisis puede ser tan simple como ver el tráfico en vivo pasar en nuestra consola o tan complejo como capturar datos con un toque, enviarlos de regreso a un SIEM para su ingestión y analizar los datos de pcap en busca de firmas y alertas relacionadas con tácticas y técnicas comunes.

Como mínimo, para escuchar pasivamente, necesitamos estar conectados al segmento de red en el que deseamos escuchar. Esto es especialmente cierto en un entorno conmutado donde las VLAN y los puertos de conmutación no reenviarán tráfico fuera de su dominio de transmisión. Teniendo esto en cuenta, si deseamos capturar tráfico desde una VLAN específica, nuestro dispositivo de captura debe estar conectado a esa misma red. Dispositivos como tomas de red, configuraciones de conmutadores o enrutadores como puertos de intervalo y duplicación de puertos pueden permitirnos obtener una copia de todo el tráfico que atraviesa un enlace específico, independientemente del segmento de red o destino al que pertenezca.

## Flujo de trabajo de NTA
El análisis del tráfico no es una ciencia exacta. NTA puede ser un proceso muy dinámico y no es un bucle directo. Está muy influenciado por lo que buscamos (errores de red versus acciones maliciosas) y dónde tenemos visibilidad de nuestra red. La realización de análisis de tráfico puede reducirse a unos pocos inquilinos básicos.
![Diagrama de ciclo que muestra cuatro pasos: 1. Ingerir tráfico, 2. Reducir el ruido mediante filtrado, 3. Analizar y explorar, 4. Detectar y alertar.](https://academy.hackthebox.com/storage/modules/81/workflow.png)
### 1. Ingerir tráfico
Una vez que hayamos decidido nuestra ubicación, comencemos a capturar el tráfico. Utilice filtros de captura si ya tenemos una idea de lo que estamos buscando.

### 2. Reducir el ruido mediante filtrado
Capturar el tráfico de un enlace, especialmente uno en un entorno de producción, puede ser extremadamente ruidoso. Una vez que completamos la captura inicial, un intento de filtrar el tráfico innecesario de nuestra vista puede facilitar el análisis. (Tráfico de radiodifusión y multidifusión, por ejemplo)

### 3. Analizar y explorar
Ahora es el momento de empezar a recopilar datos pertinentes al problema que estamos investigando. Observe hosts específicos, protocolos e incluso cosas tan específicas como indicadores establecidos en el encabezado TCP. Las siguientes preguntas nos ayudarán:
1. ¿El tráfico está encriptado o es texto simple? ¿Debería serlo?
2. ¿Podemos ver a los usuarios intentando acceder a recursos a los que no deberían tener acceso?
3. ¿Están hablando entre sí diferentes anfitriones que normalmente no lo hacen?

### 4. Detectar y alertar
1. ¿Estamos viendo algún error? ¿Un dispositivo no responde como debería?
2. Utilice nuestro análisis para decidir si lo que vemos es benigno o potencialmente malicioso.
3. Otras herramientas como [[IDS-IPS]] pueden resultar útiles en este momento. Pueden ejecutar heurísticas y firmas contra el tráfico para determinar si algo en su interior es potencialmente malicioso.

### 5. Reparar y monitorear
La reparación y el monitoreo no son parte del bucle, pero deben incluirse en cualquier flujo de trabajo que realicemos. Si realizamos un cambio o solucionamos un problema, debemos continuar monitoreando la fuente durante un tiempo para determinar si el problema se ha resuelto.
