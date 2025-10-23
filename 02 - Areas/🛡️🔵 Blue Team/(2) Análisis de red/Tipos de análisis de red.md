# Análisis descriptivo
El análisis descriptivo es un paso esencial en cualquier análisis de datos. Sirve para describir un conjunto de datos basado en características individuales. Ayuda a detectar posibles errores en la recopilación de datos y/o valores atípicos en el conjunto de datos.
1. `What is the issue?`
    - ¿Sospecha de infracción? ¿Problema de red?
2. `Define our scope and the goal. (what are we looking for? which time period?)`
    - Objetivo: varios hosts que potencialmente descargan un archivo malicioso desde bad.example.com
    - Cuándo: dentro de las últimas 48 horas + dentro de 2 horas.
    - Información de respaldo: nombres/tipos de archivos 'superbad.exe' 'new-crypto-miner.exe'
3. `Define our target(s) (net / host(s) / protocol)`
    - Alcance: red 192.168.100.0/24, los protocolos utilizados fueron HTTP y FTP.

Utilizando nuestro flujo de trabajo, determinaremos nuestro problema, qué estamos buscando, cuándo y dónde encontrarlo. El análisis descriptivo cubre estos conceptos críticos para nuestro análisis.

---

# Análisis diagnóstico
El análisis diagnóstico aclara las causas, los efectos y las interacciones de las afecciones. Al hacerlo, proporciona información que se obtiene a través de correlaciones e interpretación. Lo característico aquí es una visión retrospectiva, como en el análisis descriptivo estrechamente relacionado, con la sutil diferencia de que intenta encontrar razones para eventos y desarrollos.
1. `Capture network traffic`
    - Conéctese a un enlace con acceso a la red 192.168.100.0/24 para capturar tráfico en vivo e intentar capturar uno de los ejecutables en transferencia. Vea si un administrador puede extraer datos PCAP y/o netflow de nuestro SIEM para obtener datos históricos.
2. `Identification of required network traffic components (filtering)`
    - Una vez que tengamos tráfico, filtre cualquier paquete que no sea necesario para que esta investigación lo incluya; cualquier tráfico que coincida con nuestra línea base común y mantenga todo lo relevante para el alcance de la investigación. Por ejemplo, HTTP y FTP desde la subred, cualquier cosa que transfiera o contenga una solicitud GET para los archivos ejecutables sospechosos.
3. `An understanding of captured network traffic`
    - Una vez que hayamos filtrado el ruido, es hora de buscar nuestros objetivos—filtrar cosas como `ftp-data` para encontrar cualquier archivo transferido y reconstruirlo. Para HTTP, podemos filtrar por `http.request.method == "GET"` para ver cualquier solicitud GET que coincida con los nombres de archivos que estamos buscando. Esto puede mostrarnos quién ha adquirido los archivos y potencialmente otras transferencias internas a la red en los mismos protocolos.

Al capturar el tráfico alrededor de la fuente de nuestro problema, borrar todos los datos buenos conocidos y luego tomarnos el tiempo para inspeccionar y comprender lo que queda, podemos determinar si es la causa de nuestro problema. Para ello simplemente realizamos un análisis diagnóstico. Estamos validando la causa de nuestros problemas y examinando los acontecimientos que los rodean.

---

# Análisis predictivo
Al evaluar datos históricos y actuales, el análisis predictivo crea un modelo predictivo de probabilidades futuras. Basado en los resultados de análisis descriptivos y diagnósticos, este método de análisis de datos permite identificar tendencias, detectar desviaciones de los valores esperados en una etapa temprana y predecir sucesos futuros con la mayor precisión posible.

1. `Note-taking and mind mapping of the found results`
    - Anotar todo lo que hacemos, vemos o encontramos a lo largo de la investigación es crucial. Asegúrese de tomar abundantes notas, entre ellas:
    - Plazos durante los cuales capturamos el tráfico.
    - Host sospechosos dentro de la red.
    - Conversaciones que contienen los archivos en cuestión. (para incluir marcas de tiempo y números de paquetes)
2. `Summary of the analysis (what did we find?)`
    - Finalmente, resuma lo que hemos encontrado explicando los detalles relevantes para que los superiores puedan decidir poner en cuarentena a los huéspedes afectados o realizar una respuesta al incidente más significativa.
    - Nuestro análisis afectará las decisiones tomadas, por lo que es fundamental ser lo más claro y conciso posible.

Al realizar una evaluación de los datos que hemos encontrado, comparándolos con nuestro tráfico de referencia y datos erróneos conocidos, como marcadores de infiltración o explotación (como firmas de virus y otras herramientas de piratería), estamos realizando un análisis predictivo. En este proceso, pintamos un panorama claro para que se puedan tomar las medidas adecuadas en respuesta.

---

# Análisis prescriptivo
El análisis prescriptivo tiene como objetivo limitar qué acciones tomar para eliminar o prevenir un problema futuro o desencadenar una actividad o proceso específico. Utilizando los resultados de nuestro flujo de trabajo, podemos tomar decisiones acertadas sobre qué acciones son necesarias para resolver el problema y evitar que vuelva a suceder. Prescribir una solución es la culminación de este flujo de trabajo. Una vez hecho esto y resuelto el problema, es prudente reflexionar sobre todo el proceso y desarrollar las lecciones aprendidas. Estas lecciones, cuando se documenten, nos permitirán fortalecer nuestros procesos—documentar qué se hizo correctamente, qué acciones no ayudaron y qué podría mejorar.

Este flujo de trabajo es un ejemplo de cómo comenzar el proceso de análisis del tráfico capturado. Arriba lo dividimos en sus partes para explicar dónde encajan dentro del proceso de análisis y a qué tipo de análisis pertenece. Lo incluimos aquí nuevamente en su conjunto para que pueda servir como plantilla.
1. `What is the issue?`
    - ¿Sospecha de infracción? ¿Problema de red?
2. `Define our scope and the goal (what are we looking for? which time period?)`
    - Objetivo: varios hosts que potencialmente descargan un archivo malicioso desde bad.example.com
    - cuándo: dentro de las últimas 48 horas + dentro de 2 horas.
    - Información de soporte: nombres/tipos de archivos 'superbad.exe' 'new-crypto-miner.exe'
3. `Define our target(s) (net / host(s) / protocol)`
    - Alcance: 192.168.100.0/24 Los protocolos de red utilizados fueron HTTP y FTP.
4. `Capture network traffic`
    - conéctese a un enlace con acceso a la red 192.168.100.0/24 para capturar tráfico en vivo e intentar capturar uno de los ejecutables en transferencia. Vea si un administrador puede extraer datos PCAP y/o netflow de nuestro SIEM para obtener los datos históricos.
5. `Identification of required network traffic components (filtering)`
    - una vez que tengamos tráfico, filtre cualquier tráfico que no sea necesario para que esta investigación incluya; cualquier tráfico que coincida con nuestra línea de base común y mantenga todo lo relevante para el alcance. `HTTP y FTP desde la subred, cualquier cosa que transfiera o contenga una solicitud GET para los archivos ejecutables sospechosos.
6. `An understanding of captured network traffic`
    - Una vez que hayamos filtrado el ruido, es hora de buscar nuestros objetivos—filtrar cosas como `ftp-data` para encontrar cualquier archivo transferido y reconstruirlo. Para HTTP, podemos filtrar por `http.request.method == "GET"` para ver cualquier solicitud GET que coincida con los nombres de archivos que estamos buscando. Esto puede mostrarnos quién ha adquirido los archivos y otras posibles transferencias internas a la red en los mismos protocolos.
7. `Note-taking and mind mapping of the found results.`
    - Anotar todo lo que hacemos, vemos o encontramos a lo largo de la investigación es crucial. Asegúrese de tomar abundantes notas, entre ellas:
    - Plazos durante los cuales capturamos el tráfico.
    - Host sospechosos dentro de la red.
    - Conversaciones que contienen los archivos en cuestión. (para incluir marcas de tiempo y números de paquetes)
8. `Summary of the analysis (what did we find?)`
    - Finalmente, resuma lo encontrado, explicando los detalles relevantes para que los superiores puedan tomar una decisión informada de poner en cuarentena a los huéspedes afectados o realizar una respuesta al incidente más significativa.
    - Nuestro análisis afectará las decisiones tomadas, por lo que es fundamental ser lo más claro y conciso posible.

A menudo, este proceso no es algo que se realiza una sola vez. Generalmente es cíclico y necesitaremos volver a ejecutar pasos basados en nuestro análisis de la captura original para construir un panorama más amplio. Este podría haber sido un ataque mucho mayor que el que se muestra en los ejemplos. Supongamos que se considera necesaria una respuesta a incidentes a gran escala. En ese caso, es posible que tengamos que volver a analizar el PCAP capturado previamente para ver cualquier conversación que involucre a los hosts afectados dentro de varios minutos de la transferencia ejecutable para asegurarnos de que no se haya extendido a otra ruta, por ejemplo.

---

# Componentes clave de un análisis eficaz
## 1. Conoce tu entorno
Hay varios componentes clave para realizar análisis de tráfico de forma eficaz. Primero, conozca el medio ambiente. Si no estamos seguros de si un host pertenece a la red, ¿cómo podemos determinar si es fraudulento o no? Mantener inventarios de activos y mapas de red es vital. Estos ayudarán en el proceso de análisis.

## 2. La ubicación es clave
A continuación, la ubicación de nuestro host para capturar tráfico es algo fundamental. Lo más cercano a la fuente del problema es la ubicación ideal de nuestra herramienta de captura. Si el tráfico en cuestión proviene de Internet, escuchar los enlaces entrantes es una excelente manera de ver el panorama completo. Es lo más cerca de la fuente que nosotros, los administradores, podemos llegar. Si el problema parece estar aislado de un host en nuestra red interna, intente colocar las herramientas de captura en el mismo segmento que el host problemático y vea qué tráfico está sucediendo dentro del segmento.

## 3. Persistencia
La persistencia es el siguiente componente crítico para nosotros. El problema no siempre será fácil de detectar. Puede que ni siquiera sea un evento frecuente en la red. Por ejemplo, el servidor de Comando y Control de un atacante que se comunica con las computadoras de la víctima solo puede ocurrir en un intervalo de tiempo de una vez cada varias horas, o incluso una vez al día o menos. Esto significa que si no lo detectamos la primera vez, podría pasar un tiempo antes de que aparezca en nuestros registros. No pierdas el impulso para encontrar el problema. Podría significar la diferencia entre detener al atacante y una violación a gran escala como un ataque de ransomware.

---

# Enfoque de análisis
1. Empezar con `standard protocols first` y abrirnos camino hacia el `austere and specific` sólo a la organización. La mayoría de los ataques provendrán de Internet, por lo que tendrá que acceder a la red interna de alguna manera. Esto significa que se generará tráfico y se escribirán registros al respecto. [[HTTP]]/[[HTTPS]], [[📂🔄 FTP]], correo electrónico y tráfico TCP y UDP básico serán las cosas más comunes que se verán provenientes del mundo. Comience por esto y aclare todo lo que no sea necesario para la investigación. Después de esto, verifique los protocolos estándar que permiten comunicaciones entre redes, como [[SSH]], [[RDP]] o Telnet. Al buscar este tipo de anomalías, tenga en cuenta la política de seguridad de la red. ¿El plan de seguridad y las implementaciones de nuestra organización permiten sesiones [[RDP]] que se inician fuera de la empresa? ¿Qué pasa con el uso de Telnet?

2. Buscar `patterns`. ¿Un host específico o un conjunto de hosts se registra en algo en Internet a la misma hora todos los días? Esta es una configuración típica de perfil de Comando y Control que se puede detectar fácilmente buscando patrones en nuestros datos de tráfico.

3. Comprueba cualquier cosa `host to host` dentro de nuestra red. En una configuración estándar, los hosts del usuario rara vez se comunicarán entre sí. Así que desconfíe de cualquier tráfico que aparezca así. Normalmente, los hosts se comunicarán con la infraestructura para arrendar direcciones IP, solicitudes de DNS, servicios empresariales y para encontrar su ruta de salida. También veremos hosts hablando con servidores web locales, recursos compartidos de archivos y otra infraestructura crítica para que el entorno funcione, como controladores de dominio y aplicaciones de autenticación.

4. Buscar `unique` eventos. Es curioso que un anfitrión que normalmente visita un sitio específico diez veces al día cambie su patrón y solo lo haga una vez. Ver una cadena de agente de usuario diferente que no coincide con nuestras aplicaciones o hosts que se comunican con un servidor en Internet también es algo de lo que debemos preocuparnos. También es de destacar que un puerto aleatorio solo se vincula una o dos veces a un host. Esto podría ser una oportunidad para cosas como devoluciones de llamadas C2, alguien que abre un puerto para hacer algo no estándar o una aplicación que muestra un comportamiento anormal. En entornos grandes, se esperan patrones, por lo que cualquier cosa que sobresalga merece una mirada.

5. `Don't be afraid to ask for help.`Esto puede parecer exagerado y obvio, pero después de un tiempo de mirar las capturas de paquetes, las cosas pueden mezclarse y es posible que no veamos el panorama completo. Tener un segundo par de ojos en los datos puede ser de gran ayuda para detectar cosas que pueden pasarse por alto.