---
tags:
  - Introduccion
  - Pentesting/Wi-Fi
  - Seguridad/Autenticacion
Fecha de actualización: 2025-10-30
Nota previa:
Nota siguiente:
Area: "[[Wi-Fi Pentesting.base|Wi-Fi Pentesting]]"
---
---

# Tipos de autenticación de Wi-Fi
Los tipos de autenticación WiFi son cruciales para proteger las redes inalámbricas y proteger los datos del acceso no autorizado. Los tipos principales incluyen WEP, WPA, WPA2 y WPA3, cada uno de los cuales mejora progresivamente los estándares de seguridad.
![Diagrama de flujo de seguridad WiFi que muestra los tipos de autenticación: WEP, WPA, WPA2 y WPA3. WPA2 se divide en Personal y Enterprise, y Enterprise se divide a su vez en EAP-TTLS/PAP y PEAP-MSCHAPv2. WPA3 se divide en Personal y Enterprise, y Enterprise conduce a EAP-TLS, que culmina en Autenticación basada en certificados (CBA).](https://academy.hackthebox.com/storage/modules/222/Wifi_auth_types.png)
- `WEP (Wired Equivalent Privacy)`: El protocolo de seguridad WiFi original, WEP, proporciona cifrado básico, pero ahora se considera obsoleto e inseguro debido a vulnerabilidades que facilitan su violación.
- `WPA (WiFi Protected Access)`: Introducido como una mejora provisional con respecto a WEP, WPA ofrece un mejor cifrado a través de TKIP (Protocolo de integridad de clave temporal), pero aún es menos seguro que los estándares más nuevos.
- `WPA2 (WiFi Protected Access II)`: Un avance significativo con respecto a WPA, WPA2 utiliza AES (estándar de cifrado avanzado) para una seguridad sólida. Ha sido el estándar durante muchos años y proporciona una fuerte protección para la mayoría de las redes.
- `WPA3 (WiFi Protected Access III)`: El último estándar, WPA3, mejora la seguridad con funciones como cifrado de datos individualizado y autenticación basada en contraseña más sólida, lo que la convierte en la opción más segura disponible actualmente.

Cuando buscamos comenzar nuestro camino para convertirnos en probadores de penetración inalámbrica, siempre debemos considerar las habilidades fundamentales necesarias para tener éxito. Conocer estas habilidades puede garantizar que no nos perdamos en el camino cuando exploramos muchos mecanismos y protecciones de autenticación diferentes. Después de todo, aunque el wifi es una de las áreas de seguridad perimetral más disponibles para nuestra explotación, presenta dificultades incluso para algunos de los veteranos más experimentados.

Una prueba de penetración de Wi-Fi consta de los siguientes cuatro componentes clave:
1. `Evaluating Passphrases`: Esto implica evaluar la solidez y seguridad de las contraseñas o frases de contraseña de la red WiFi. Los pentesters emplean diversas técnicas, como ataques de diccionario, ataques de fuerza bruta y herramientas de descifrado de contraseñas, para evaluar la resistencia de las frases de contraseña contra el acceso no autorizado.
2. `Evaluating Configuration`: Pentesters analiza la configuración de los enrutadores WiFi y los puntos de acceso para identificar posibles vulnerabilidades de seguridad. Esto incluye examinar los protocolos de cifrado, los métodos de autenticación, la segmentación de la red y otros parámetros de configuración para garantizar que cumplan con las mejores prácticas de seguridad.
3. `Testing the Infrastructure`: Esta fase se centra en investigar la robustez de la infraestructura de la red WiFi. Los pentesters realizan evaluaciones exhaustivas para descubrir debilidades en la arquitectura de red, configuraciones de dispositivos, versiones de firmware y fallas de implementación que los atacantes podrían aprovechar para comprometer la red.
4. `Testing the Clients`: Los pentesters evalúan la postura de seguridad de los clientes WiFi, como computadoras portátiles, teléfonos inteligentes y dispositivos IoT, que se conectan a la red. Esto implica realizar pruebas de vulnerabilidades en el software del cliente, los sistemas operativos, los controladores inalámbricos y las implementaciones de la pila de red para identificar posibles puntos de entrada para los atacantes.

Nota: Después del spawn, espere `3`-`4` minutos antes de conectarse al objetivo(s).

---

# 802.11 Marcos y tipos
Para comprender mejor el tráfico 802.11, podemos profundizar en la construcción, los tipos y los subtipos de marcos. En las comunicaciones 802.11, hay algunos tipos de marcos diferentes utilizados para diferentes acciones. Todas estas acciones son parte del ciclo de conexión y de las comunicaciones estándar para estas redes inalámbricas. Muchos de nuestros ataques utilizan técnicas de creación/forja de paquetes. Buscamos forjar estos mismos marcos para realizar acciones como desconectar un dispositivo cliente de la red con una solicitud de desautenticación/disociación.

## El marco MAC IEEE 802.11
Todos los marcos 802.11 utilizan el marco MAC. Este marco es la base de todos los demás campos y acciones que se realizan entre el cliente y el punto de acceso, e incluso en redes ad hoc. El marco de datos MAC consta de 9 campos.

| Campo                     | Descripción                                                                                                                                                                                                                                              |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Control de marco**      | Este campo contiene toneladas de información como tipo, subtipo, versión del protocolo, a ds (sistema de distribución), desde DS, Pedido, etcétera.                                                                                                      |
| **Duración/ID**           | Esta identificación aclara la cantidad de tiempo en el que está ocupado el medio inalámbrico.                                                                                                                                                            |
| **Dirección 1, 2, 3 y 4** | Estos campos aclaran las direcciones MAC involucradas en la comunicación, pero podrían significar cosas diferentes dependiendo del origen de la trama. Estos tienden a incluir el BSSID del punto de acceso y la dirección MAC del cliente, entre otros. |
| **SC**                    | El campo de control de secuencia permite capacidades adicionales para evitar fotogramas duplicados.                                                                                                                                                      |
| **Datos**                 | En pocas palabras, este campo es responsable de los datos que se transmiten del remitente al receptor.                                                                                                                                                   |
| **CRC**                   | La verificación de redundancia cíclica contiene una suma de verificación de 32 bits para la detección de errores.                                                                                                                                        |

## Tipos de cuadros IEEE 802.11
Los marcos IEEE se pueden clasificar en diferentes categorías según lo que hacen y en qué acciones participan. En términos generales, tenemos los siguientes tipos entre algunos otros. Estos códigos pueden ayudarnos a la hora de filtrar el tráfico de Wireshark.
1. `Management (00):`Estos marcos se utilizan para la gestión y el control, y permiten que el punto de acceso y el cliente controlen la conexión activa.
2. `Control (01):`Las tramas de control se utilizan para gestionar la transmisión y recepción de tramas de datos dentro de redes wifi. Podemos considerarlos como una sensación de control de calidad.
3. `Data (10):`Los marcos de datos se utilizan para contener datos para su transmisión.

## Subtipos del marco de gestión
Principalmente, para las pruebas de penetración de Wi-Fi, nos centramos en los marcos de gestión. Después de todo, estos marcos se utilizan para controlar la conexión entre el punto de acceso y el cliente. De esta manera podemos profundizar en cada uno de ellos y en de qué son responsables.

Si buscamos filtrarlos en Wireshark, especificaríamos el tipo `00` y subtipos como los siguientes.

1. `Beacon Frames (1000)`
2. `Probe Request (0100) and Probe Response (0101)`
3. `Authentication Request and Response (1011)`
4. `Association/Reassociation Request and Responses (0000, 0001, 0010, 0011)`
5. `Disassociation/Deauthentication (1010, 1100)`

### 1. Marcos de balizas
Los marcos de baliza son utilizados principalmente por el punto de acceso para comunicar su presencia al cliente o estación. Incluye información como cifrados compatibles, tipos de autenticación, su SSID y velocidades de datos compatibles, entre otros.

### 2. Solicitudes y respuestas a la investigación
El proceso de solicitud y respuesta de la sonda existe para permitir al cliente descubrir puntos de acceso cercanos. En pocas palabras, si una red está oculta o no, un cliente enviará una solicitud de sondeo con el SSID del punto de acceso. El punto de acceso responderá entonces con información sobre sí mismo para el cliente.

### 3. Solicitud y respuesta de autenticación
Las solicitudes de autenticación son enviadas por el cliente al punto de acceso para iniciar el proceso de conexión. Estos marcos se utilizan principalmente para identificar al cliente en el punto de acceso.

### 4. Solicitudes de asociación/reasociación
Después de enviar una solicitud de autenticación y someterse al proceso de autenticación, el cliente envía una solicitud de asociación al punto de acceso. Luego, el punto de acceso responde con una respuesta de asociación para indicar si el cliente puede asociarse con él o no.

### 5. Marcos de disociación/desautenticación
Los marcos de disociación y desautenticación se envían desde el punto de acceso al cliente. Al igual que sus marcos inversos (asociación y autenticación), están diseñados para finalizar la conexión entre el punto de acceso y el cliente. Estos marcos contienen además lo que se conoce como código de motivo. Este código de motivo indica por qué se desconecta el cliente del punto de acceso. Utilizamos la creación de estos marcos para muchas capturas de protocolo de enlace y ataques basados en denegación de servicio durante los esfuerzos de pruebas de penetración de Wi-Fi.

---

# El ciclo de conexión
Ahora que se han revisado los tipos de marcos IEEE 802.11 y los subtipos de marcos de administración, examinemos el proceso de conexión típico entre clientes y puntos de acceso, conocido como `connection cycle`. Nos centraremos en la autenticación WPA2 básica, aunque este proceso puede variar dependiendo del estándar Wi-Fi en uso. Sin embargo, el ciclo de conexión general sigue esta secuencia.
1. `Beacon Frames`
2. `Probe Request and Response`
3. `Authentication Request and Response`
4. `Association Request and Response`
5. `Some form of handshake or other security mechanism`
6. `Disassociation/Deauthentication`

Para comprender mejor este proceso, el tráfico de red sin procesar se puede examinar en Wireshark. Después de capturar con éxito un protocolo de enlace válido, el archivo de captura se puede abrir en Wireshark para un análisis detallado.

Los marcos de balizas del punto de acceso se pueden identificar utilizando el siguiente filtro Wireshark:
`(wlan.fc.type == 0) && (wlan.fc.type_subtype == 8)`
![Captura de Wireshark que muestra múltiples tramas de baliza 802.11 desde la fuente 'Cisco-Li_82:b2:55' hasta 'Broadcast', con SSID 'Coherer'.](https://academy.hackthebox.com/storage/modules/222/001_beacon.PNG)

Los marcos de solicitud de sonda del cliente se pueden identificar utilizando el siguiente filtro Wireshark:
`(wlan.fc.type == 0) && (wlan.fc.type_subtype == 4)`
![Captura de Wireshark que muestra solicitudes de sonda 802.11 desde la fuente 'Apple_82:36:3a' a 'Broadcast', con SSID 'Coherer'.](https://academy.hackthebox.com/storage/modules/222/002_probe_request.PNG)

Los marcos de respuesta de la sonda desde el punto de acceso se pueden identificar utilizando el siguiente filtro Wireshark:
`(wlan.fc.type == 0) && (wlan.fc.type_subtype == 5)`
![Captura de Wireshark que muestra respuestas de sonda 802.11 desde la fuente 'Cisco-Li_82:b2:55' al destino 'Apple_82:36:3a', con SSID 'Coherer'.](https://academy.hackthebox.com/storage/modules/222/003_probe_response.PNG)

El proceso de autenticación entre el cliente y el punto de acceso se puede observar utilizando el siguiente filtro Wireshark:
`(wlan.fc.type == 0) && (wlan.fc.type_subtype == 11)`
![Captura de Wireshark que muestra marcos de autenticación 802.11 entre 'Apple_82:36:3a' y 'Cisco-Li_82:b2:55'.](https://academy.hackthebox.com/storage/modules/222/004_authentication.PNG)

Una vez completado el proceso de autenticación, la solicitud de asociación de la estación se puede ver utilizando el siguiente filtro Wireshark:
`(wlan.fc.type == 0) && (wlan.fc.type_subtype == 0)`
![Captura de Wireshark que muestra la respuesta de asociación 802.11 de 'Cisco-Li_82:b2:55' a 'Apple_82:36:3a', con SSID 'Coherer'.](https://academy.hackthebox.com/storage/modules/222/005_association_request.PNG)

La respuesta de asociación del punto de acceso se puede ver utilizando el siguiente filtro Wireshark:
`(wlan.fc.type == 0) && (wlan.fc.type_subtype == 1)`
![Captura de Wireshark que muestra la respuesta de asociación 802.11 de 'Cisco-Li_82:b2:55' a 'Apple_82:36:3a'.](https://academy.hackthebox.com/storage/modules/222/006_association_response.PNG)

Si la red de ejemplo usa WPA2, los marcos EAPOL (apretón de manos) se pueden ver usando el siguiente filtro Wireshark:
`eapol`
![Captura de Wireshark que muestra el intercambio de claves EAPOL entre 'Cisco-Li_82:b2:55' y 'Apple_82:36:3a', con los mensajes 1 a 4 de 4.](https://academy.hackthebox.com/storage/modules/222/007_handshake.PNG)

Una vez completado el proceso de conexión, se puede ver la terminación de la conexión identificando qué parte (cliente o punto de acceso) inició la desconexión. Esto se puede hacer utilizando el siguiente filtro Wireshark para capturar marcos de disociación (10) o marcos de desautenticación (12).
`(wlan.fc.type == 0) && (wlan.fc.type_subtype == 12) or (wlan.fc.type_subtype == 10)`
![Captura de Wireshark que muestra 802.11 Desasociar trama de 'Apple_82:36:3a' a 'Cisco-Li_82:b2:55'.](https://academy.hackthebox.com/storage/modules/222/008_Disassociation.PNG)

Ahora que sabemos un poco sobre los tipos de marcos, en la siguiente sección exploraremos los diferentes métodos de autenticación y cubriremos el ciclo de conexión básico entre el cliente y el punto de acceso.