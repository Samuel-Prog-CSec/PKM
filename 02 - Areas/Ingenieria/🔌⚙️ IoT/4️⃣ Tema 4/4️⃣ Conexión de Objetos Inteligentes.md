# IMPORTANCIA DE LA CONECTIVIDAD
No es suficiente con disponer de una conexión, sino de una ==conexión confiable que garantice totalmente las comunicaciones en aplicaciones críticas.== Un **retraso**, aunque sea pequeño, puede ser **decisivo** en entornos críticos.

Una característica intrínseca del IoT es la **habilidad de conectar objetos con otros objetos y/o con personas**. *No necesariamente a través de Internet*.
- Objetos que se comunican entre ellos y, eventualmente, a través de Internet para ==analizar datos y/o tomar decisiones==.
- Existen **sistemas complemente cerrados**: ==no hay necesidad de conexión a Internet==.

# CRITERIOS DE COMUNICACIÓN

## QUÉ TENER EN CUENTA AL CONECTAR OBJETOS
### Alcance
**Corto** alcance. **Medio** alcance. **Largo** alcance.

### Bandas de frecuencia
El ==espectro radioeléctrico está regulado por países y organizaciones==.
- Normalmente es considerado un **recurso crítico**.
- Se dividen entre *bandas con y sin licencia*:
	  - **Con licencia:** se aplica generalmente a las ==tecnologías de acceso== de **largo alcance**. Se asigna a infraestructuras de comunicaciones desplegadas por proveedores de servicios, servicios públicos, radiodifusores y empresas de servicios públicos.
	  - **Sin licencia:** ==no se ofrecen garantías ni protecciones== para las comunicaciones de los dispositivos. *Están reguladas,* por lo que los ==dispositivos deben cumplir parámetros== como la potencia de transmisión, el ancho de banda del canal, etc.
	  	  - Las más conocidas en IoT son: **2.4 GHz** (`IEEE 802.11b/g/n Wi-Fi`), `IEEE 802.15.1`, `Bluetooth`, `IEEE 802.15.4 WPAN`.
	  	  - **Más fácil de implantar** porque *no requiere un proveedor de servicios*.

### Consumo de energía
- **Dispositivos alimentados:**
	  - Tienen una ==conexión directa a una fuente de alimentación==. Las *comunicaciones no suelen estar limitadas por criterios de consumo de energía*.
- **Dispositivos con batería:**
	  - Proporcionan una ==mayor flexibilidad==. Caracterizados por sus *necesidades de bajo consumo y conectividad*.

### Topología
- Principales *topologías*: **estrella, malla y peer-to-peer**.
- La topología y el rol de cada nodo es ==determinante en dispositivos con batería==.
- En las ==tecnologías de largo y corto alcance== predomina la topología en **estrella**.
- En las ==tecnologías de medio alcance== predomina la topología en **malla**.
- *Tipos de nodos*:
	  - **Full Function Device (FFD)**
	  - **Reduced Function Device (RFD)**

### Limitaciones en los dispositivos
==RFC 7228 categoriza las diferentes clases de nodos== en función de:
- **Capacidad de cómputo**
- **Memoria**
- **Almacenamiento**
- **Consumo**

==Tienen recursos limitados== que afectan a su conjunto de características y sus capacidades de red.

# A TENER EN CUENTA EN LAS COMUNICACIONES INALÁMBRICAS
Las ==ondas electromagnéticas son imprescindibles== en el ámbito de la comunicación inalámbrica. Es importante conocer *cómo se comportan las ondas* electromagnéticas para comprender de qué formas nos beneficia una u otra tecnología al diseñar la red IoT.
- Se basan en *dos conceptos* clave: **frecuencia** y **longitud**.
- Se requieren ==sistemas que transformen la información a transmitir a ondas de radio== en el origen y el *proceso contrario en el destino*.
- **Frecuencia (Hz):** indican ==cuántas ondas se producen en un segundo==.
- **Longitud:** se refiere a la ==distancia entre una onda y la siguiente==.

> A **menores frecuencias** *->* **mayor alcance**
>
> A **mayores frecuencias** *->*
> 1. **mayor** ==ancho de banda==
> 2. **menor** ==capacidad atravesar paredes==

---

# TECNOLOGÍAS DE COMUNICACIÓN
## Visión general por alcance

- **Proximity (hasta 10m)**
	  - NFC
	  - RFID
- **PAN: Personal Area Network (hasta 100m)**
	  - Bluetooth
	  - ZigBee
	  - 6LoWPAN
	  - Thread
	  - Z-WAVE
	  - ANT+
	  - WAVE
- **LAN: Local Area Network (hasta 1000m)**
	  - Wi-Fi
- **MAN: Metropolitan Area Network (hasta 10km)**
	  - WiMAX
- **WAN: Wide Area Network (hasta 100km)**
	  - Lte
	  - SIGFOX
	  - LoRa

## PAN: PERSONAL AREA NETWORK
### BLUETOOTH
- Se creó con la finalidad de ==facilitar la comunicación entre dispositivos móviles, eliminando el cableado== y posibilitar la *creación de pequeñas redes de dispositivos personales*.
- En el ámbito del IoT tuvo mucho impacto la aparición del `Bluetooth Low Energy (BLE)` a partir de Bluetooth 4.0.
- Los dispositivos `Bluetooth` **se clasifican en diferentes clases dependiendo de su potencia de transmisión y de su cobertura** efectiva.

#### BLUETOOTH SMART
- **Bluetooth Smart:** *incorporan solo `BLE`*, por lo que son ==incompatibles con el Bluetooth clásico==.
- **Bluetooth SmartReady:** *incorporan* `BLE` y `Bluetooth` clásico.

#### Ventajas Bluetooth Low Energy (BLE)
- **Más topologías de red:**
  - ==Antes solo de punto a punto==.
  - Ahora ==se añaden posibilidades `broadcast`== (*uno a muchos)* y `malla` (*todos a todos*).
- **Mayor distancia** de comunicación.

#### Beacons Bluetooth
- Dispositivo *basado en* `BLE` que **está constantemente emitiendo una señal única**.
- Ésta puede ser ==recibida e interpretada por otros dispositivos cercanos==.
- Es necesario que el dispositivo *receptor tenga el Bluetooth activado* y disponga de una ==app específica para reconocer la señal==.

### RFID (RADIO FREQUENCY IDENTIFICATION)
- Permite que los **objetos puedan ser identificados inequívocamente**. ==Emplea tarjetas de identificación que se adhieren a los objetos deseados== y permite el envío y recepción de datos.
- *Comunicación en una sola dirección*.
- **Dos tipos:** *Semi-activas* y *Pasivas* (se diferencian por el uso de la energía).
- **Activas:** pueden ==contener sensores que almacenen y envíen datos a distancias mayores== y de forma más fiable. Son *mucho más caras*.

### NFC (NEAR FIELD COMMUNICATION)
- Especialización/**evolución de RFID**. ==Emplea radiofrecuencia== para el intercambio de datos entre dispositivos.
- Posibilidad de *dispositivos pasivos y activos*.
- Los dispositivos ==pueden actuar como lector y etiqueta==.
- **Corto alcance (hasta 10 cm):** diseñado para la *seguridad/confidencialidad de los datos*.

### IEEE 802.15.4
- ==Estándar== que define el funcionamiento de una *red inalámbrica* de **área personal de baja velocidad (LR-WPAN/LowRate-WPAN)**.
- Destinado a comunicaciones entre dispositivos a **corta distancia** con ==bajas necesidades de ancho de banda y consumo==.
- **Rango de acción variable:** depende de la potencia de transmisión y de la sensibilidad del receptor.
- Permite una **instalación sencilla** con una *pila de protocolos compacta* y, al mismo tiempo, ==sencilla y flexible==.
- **Capas OSI:** 1 (`Física`) y 2 (`Enlace de datos`).
- Varias pilas de comunicación de red (ZigBee, 6LoWPAN, Thread, etc.) aprovechan esta tecnología.
- **Aspectos destacados:**
  - Adecuación de su uso para **tiempo real**.
  - Soporte integrado a las **comunicaciones seguras**.
  - Incluye funciones de **control del consumo de energía**.
- **Define dos tipos de nodos de red:**
  - **Dispositivo de funcionalidad completa (full-function device, FFD):**
    - Puede funcionar como coordinador de una red PAN o como un nodo normal.
    - Implementa un modelo general de comunicación que le permite establecer un intercambio con cualquier otro dispositivo.
  - **Dispositivos de funcionalidad reducida (reduced-function device, RFD):**
    - Dispositivos muy sencillos con recursos y necesidades de comunicación muy limitadas.

---
## LAN: LOCAL AREA NETWORK
### ETHERNET
- **Tecnología de comunicación cableada** empleada también en redes MAN y WAN.
- **Capa 1** (`Física`) **y 2** (`Enlace de datos`) del modelo OSI.
- ==Gran fiabilidad, ancho de banda y baja latencia== en las comunicaciones.

### ESTÁNDARES WIFI 802.11
- **Capa 1** (`Física`) **y 2** (`Enlace de datos`) del modelo OSI.

#### WIFI 802.11AD
- Nació con el ==objetivo de reemplazar la tecnología `Ethernet Gigabit`==.
- Permite *trabajar con varias redes de forma dinámica*.
- **Frecuencia de 60GHz:** ==Corto alcance== (10m aprox.) pero ==gran ancho de banda== (7Gbps).

### PILAS DE COMUNICACIÓN SOBRE 802.15.4
#### ZIGBEE
- Basado en el estándar IEEE 802.15.4.
- Desarrollado por la ZigBee Alliance (2002) para definir **estándares abiertos**.
- **Características:**
	  - Comunicaciones con ==bajos requisitos de velocidad de transmisión==.
	  - *Prioriza la seguridad y el bajo consumo* eléctrico.
	  - ==Interconexión en forma de malla==.
- **Modelo OSI:**
	  - **Capa de red (capa 3):** proporciona ==mecanismos para la configuración de la red, el enrutamiento y la seguridad==.
	  - **Capa de aplicación (capa 7):** conecta la parte inferior de la pila con las aplicaciones de la capa superior.
- **Roles de un nodo ZigBee:**
	  - `Coordinador`
	  - `Router`
	  - `End Device`

#### Z-WAVE
- *Diseñado especialmente para la domótica*.
- **Diferencias con ZigBee:**
	  - **Fiabilidad:** Z-Wave funciona en el ==rango de frecuencias de 800-900 MHz==.
	  - **Interoperabilidad:** Z-Wave ==no es abierto==, pero su sistema de certificación es *más riguroso*.
	  - **Alcance de la señal**.
	  - **Uso de la energía**.

## WAN: WIDE AREA NETWORK
### LoRaWAN
- Protocolo **LPWAN (Low Power Wide Area Network)** diseñado para la ==interconexión de cosas a Internet en ámbitos geográficos amplios==.
- Ideal para *dispositivos de bajo consumo*, que operan en redes de alcance local, regional, nacionales o globales.
- La arquitectura de red típica es una red de **Redes en Estrella**: la ==primera estrella está formada por los dispositivos finales y las puertas de enlace==, y la ==segunda estrella está formada por las puertas de enlace y un servidor de red central==.
- **LoRa (Low Range)** es la *tecnología abierta* que ==permite comunicación==, mientras que **LoRaWAN** es el *protocolo* que ==se encarga de gestionar la comunicación==.

### SIGFOX
- Nombre de la empresa propietaria, su red y su protocolo (**propietario/cerrado**).
- Red **LPWAN** que usa *tecnología de transmisión* **UNB (Ultra Narrow Band)**.
	  - Opera en ==frecuencias extremadamente bajas para conseguir grandes distancias y consumos muy bajos==.
- **Estrategias:**
	  - ==Cada mensaje se envía por tres frecuencias distintas== a todas las antenas que estén a su alcance.
	  - *Todas las antenas que lo reciben las reenvían a la nube*.

---

# IP COMO CAPA DE RED IOT
Actualmente disponemos de sistemas IoT con una gran heterogeneidad. IP no sólo se prefiere en el ámbito TI, sino también para el entorno IoT.

**Ventajas:**
- Abierto y basado en normas
- Versátil
- Escabale
- Ubicuo
- Manejable y Seguro

## ¿ADAPTACIÓN O ADOPCIÓN?
- **Adaptación:** implica la implantación de pasarelas de capas de aplicación para garantizar la traducción entre las capas no IP e IP.
- **Adopción:** implica sustituir todas las capas no IP por sus homólogas de capa IP, lo que simplifica el modelo de despliegue y las operaciones.

Al igual que ocurrió en el ámbito IT, se está produciendo una transición similar en IoT para la implantación de IP en la última milla.

## NECESIDAD DE OPTIMIZACIÓN
1.  **Escenario 1:** dispositivos con recursos muy limitados, que pueden comunicarse con poca frecuencia para transmitir unos pocos bytes -> **Adaptación**.
2.  **Escenario 2:** dispositivos con potencia y capacidades suficientes para implementar una pila IP parcial o una pila no IP -> **Ambas**.
3.  **Escenario 3:** dispositivos similares a los PC genéricos en cuanto a recursos y potencia, pero con capacidades de red limitadas -> **Adopción**.

## SOLUCIONES POPULARES
### 6LoWPAN
- Se creó con la intención de aplicar IP incluso a los dispositivos más pequeños.
- Define la encapsulación, la compresión de cabeceras, el descubrimiento de vecinos y otros mecanismos que permiten que IPv6 funcione en redes basadas en IEEE802.15.4.

### ZIGBEE IP
- Sigue basado en IEEE 802.15.4, pero ahora los protocolos IP y TCP/UDP son compatibles en las capas de red y transporte.
- Ofrece una arquitectura escalable con redes IPv6 de extremo a extremo.
- Las capas específicas de ZigBee ahora se encuentran solo en la parte superior de la pila.

### THREAD
- Protocolo de red basado en IPv6 diseñado para dispositivos IoT de baja potencia de una red inalámbrica malla IEEE 802.15.4.
- Diseñado originalmente para domótica.
- **Ventajas:**
  - Una actualización de software relativamente sencilla permite a los usuarios utilizar Thread en dispositivos ya compatibles con IEEE 802.15.4.
  - Se basan en sistemas y plataformas completamente abiertos.
  - Las redes Thread son de baja latencia, se forman en malla para optimizar la conectividad y solucionar fallos.
- Utiliza 6LoWPAN como su capa de enlace de datos, pero agrega características adicionales para mejorar la seguridad, la escalabilidad y la interoperabilidad.

---

# PROTOCOLOS DE APLICACIÓN PARA EL IOT
## MQTT
- **Protocolo de comunicación abierto de dispositivo a dispositivo** (M2M).
- Ligero y fácil de implementar, ==ideal para dispositivos con recursos limitados==.
- Dispone de un **mecanismo de calidad de servicio** (`QoS`).
- Es *altamente escalable*.
- Se basa en un esquema de **publicación-suscripción**, donde los dispositivos *pueden publicar mensajes a un* "**tema**" (`topic`) específico.
- **MQTT-broker:** encargado de ==recibir y transmitir mensajes entre los dispositivos cliente conectados a él==. Los clientes se conectan, *se suscriben a temas*, y el broker *distribuye los mensajes publicados a los suscriptores* del tema.

## COAP (CONSTRAINED APPLICATION PROTOCOL)
- **Protocolo de comunicación de dispositivo a dispositivo** (M2M) ==para recursos limitados==.
- Utiliza el concepto de mensajes de **petición-respuesta**, similar a `HTTP`, pero con diferencias:
	  - COAP usa el protocolo **UDP** en lugar de TCP.
	  - Soporta un ==subconjunto de métodos==: `GET`, `PUT`, `POST` y `DELETE`.
	  - Utiliza *menos bytes para describir los mensajes*.
- Dispone de un **mecanismo de observación** para ==recibir notificaciones automáticas==.

## MATTER
- **Estándar** interoperable que *fomenta la adopción de tecnología* y reemplaza protocolos de propiedad para el hogar inteligente.
- *Opciones de conexión*: `Wi-Fi`, `Ethernet`, `BLE` o `Thread`.
- El objetivo de Matter es ==facilitar la configuración y la interconexión de dispositivos futuros==.
- **Admite el puente (bridge) de otras tecnologías** como Zigbee, Bluetooth Mesh y Z-Wave.

## PROTOCOLOS WEB GENÉRICOS
- **Websockets:** tecnología que proporciona un ==canal de comunicación bidireccional y full-duplex== *sobre un único socket TCP*.
- **DDS (Data Distribution Service):** diseñado para *sistemas en tiempo real*, ==middleware de tipo publish/subscribe en computación distribuida==.
- **XMPP (Extensible Messaging and Presence Protocol):** ==protocolo abierto y extensible basado en `XML`==, originalmente ideado para *mensajería instantánea*.