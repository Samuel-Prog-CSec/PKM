El **proyecto Metasploit** es una plataforma modular de pruebas de penetración basada en **Ruby** que ==permite escribir, probar y ejecutar el código de explotación==. Este código de explotación puede ser personalizado por el usuario o puede tomarse de una base de datos que contenga los últimos exploits ya descubiertos y modularizados. 

El **framework Metasploit** incluye un conjunto de herramientas que se pueden utilizar para probar vulnerabilidades de seguridad, enumerar redes, ejecutar ataques y evadir la detección. 

Los **módulos**, son ==pruebas de concepto de explotación reales que ya se han desarrollado y probado== en la práctica y se han integrado en el framework para proporcionar a los pentesters un acceso sencillo a diferentes vectores de ataque para diferentes plataformas y servicios. 

El punto fuerte de Metasploit es que ==proporciona una gran cantidad de objetivos y versiones disponibles==, todos a unos pocos comandos de distancia de un punto de apoyo exitoso.  Estos, combinados con un **exploit hecho a medida** para esas versiones vulnerables y con un **payload** que se envía después del exploit, que ==nos dará acceso real al sistema==, nos proporcionan una forma sencilla y automatizada de cambiar entre conexiones de destino durante nuestras aventuras post-explotación.


# Índice
- [[Ⓜ️🧨 Metasploit]]
- [[👨‍💻 MSFconsole]]


# Metasploit Pro
La **versión Metasploit Pro** es diferente de la versión Metasploit Framework con algunas características adicionales: 
- Cadenas de tareas Ingeniería social. 
- Validaciones de vulnerabilidades. 
- GUI. 
- Asistentes de inicio rápido. 
- Integración con **Nexpose**.

La versión Pro ==también contiene su propia consola==, muy similar a **msfconsole**. Para tener una idea general de lo que pueden lograr las características más nuevas de Metasploit Pro, consulta la lista a continuación:


# Consola de Metasploit Framework
La **msfconsole** es probablemente la ==interfaz más popular== de **Metasploit Framework (MSF)**. Proporciona una consola centralizada "todo en uno" y le permite un ==acceso eficiente a prácticamente todas las opciones disponibles en MSF==. Las características que generalmente ofrece msfconsole son las siguientes:
- Es la única forma compatible de acceder a la mayoría de las funciones dentro de Metasploit.
- Proporciona una interfaz basada en consola para el Framework.
- Contiene la mayoría de las funciones y es la interfaz de MSF más estable.
- Compatibilidad total con readline, tabulación y finalización de comandos.
- Ejecución de comandos externos en msfconsole.


# Arquitectura
De forma predeterminada, todos los archivos básicos relacionados con Metasploit Framework se pueden encontrar en: **/usr/share/metasploit-framework** (en la distribución de seguridad ParrotOS de HTB Academy).


## Datos, documentación, biblioteca
Estos son los archivos base del marco. Los datos y la biblioteca son las **partes funcionales** de la interfaz de msfconsole, mientras que la carpeta `Documentación` contiene todos los **detalles técnicos** sobre el proyecto.


## Módulos
Los módulos **se dividen en categorías** independientes en esta carpeta. Se encuentran en las siguientes carpetas:

```shell
ls /usr/share/metasploit-framework/modules

auxiliary  encoders  evasion  exploits  nops  payloads  post
```


## Plugins
Los plugins ofrecen al pentester más flexibilidad al usar msfconsole, ya que pueden cargarse fácilmente de forma manual o automática según sea necesario para **proporcionar funcionalidad adicional y automatización** durante nuestra evaluación.

```shell
ls /usr/share/metasploit-framework/plugins/

aggregator.rb      ips_filter.rb  openvas.rb           sounds.rb
alias.rb           komand.rb      pcap_log.rb          sqlmap.rb
auto_add_route.rb  lab.rb         request.rb           thread.rb
beholder.rb        libnotify.rb   rssfeed.rb           token_adduser.rb
db_credcollect.rb  msfd.rb        sample.rb            token_hunter.rb
db_tracker.rb      msgrpc.rb      session_notifier.rb  wiki.rb
event_tester.rb    nessus.rb      session_tagger.rb    wmap.rb
ffautoregen.rb     nexpose.rb     socket_logger.rb
```


## Scripts
Funcionalidad de **Meterpreter** y otros ==scripts útiles==.

```shell
ls /usr/share/metasploit-framework/scripts/

meterpreter  ps  resource  shell
```


## Herramientas
**Utilidades de línea de comandos** que se pueden llamar directamente desde el menú msfconsole.

```shel
ls /usr/share/metasploit-framework/tools/

context  docs     hardware  modules   payloads
dev      exploit  memdump   password  recon
```