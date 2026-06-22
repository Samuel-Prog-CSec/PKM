---
tags:
  - Introduccion
  - Linux
  - Pentesting
Fecha de actualización: 2025-11-13
Nota previa:
Nota siguiente: "[[👨‍💻 MSFconsole]]"
Area: "[[3️⃣ Explotación]]"
---
---

El **proyecto Metasploit** es una <mark style="background: #ADCCFFA6;">plataforma modular de pruebas de penetración</mark> basada en **Ruby** que permite <mark style="background: #FFB86CA6;">escribir, probar y ejecutar el código de explotación</mark>. Este código de explotación puede ser personalizado por el usuario o puede tomarse de una base de datos que contenga los últimos exploits ya descubiertos y modularizados. 

El **framework Metasploit** incluye un conjunto de herramientas que se pueden utilizar para probar vulnerabilidades de seguridad, enumerar redes, ejecutar ataques y evadir la detección. 

Los **módulos**, son <mark style="background: #ADCCFFA6;">pruebas de concepto de explotación reales que ya se han desarrollado y probado en la práctica</mark> y se han integrado en el framework para proporcionar a los pentesters un acceso sencillo a diferentes vectores de ataque para diferentes plataformas y servicios. 

El punto fuerte de *Metasploit* es que <mark style="background: #FFB8EBA6;">proporciona una gran cantidad de objetivos y versiones disponibles</mark>.  Estos, combinados con un **exploit hecho a medida** para esas versiones vulnerables y con un <mark style="background: #FFB86CA6;">**payload** que se envía después del exploit, que nos dará acceso real al sistema</mark>, nos proporcionan una forma sencilla y automatizada de cambiar entre conexiones de destino durante nuestras aventuras post-explotación.


# Metasploit Pro
La **versión Metasploit Pro** es diferente de la versión *Metasploit Framework* con algunas características adicionales: 
- Cadenas de tareas Ingeniería social. 
- Validaciones de vulnerabilidades. 
- GUI. 
- Asistentes de inicio rápido. 
- Integración con **Nexpose**.
> [!recomendacion]+
> La versión *Pro* también contiene su propia consola, muy similar a **msfconsole**.

---

# Arquitectura
De forma predeterminada, todos los archivos básicos relacionados con *Metasploit Framework* se pueden encontrar en: **/usr/share/metasploit-framework** (en la distribución de seguridad *ParrotOS*).


## Datos, documentación, biblioteca
Estos son los archivos base del marco. Los datos y la biblioteca son las **partes funcionales** de la interfaz de [[👨‍💻 MSFconsole]], mientras que la carpeta `Documentación` contiene todos los **detalles técnicos** sobre el proyecto.


## Módulos
Los [[Módulos]] **se dividen en categorías** independientes en esta carpeta. Se encuentran en las siguientes carpetas:
```shell
ls /usr/share/metasploit-framework/modules

auxiliary  encoders  evasion  exploits  nops  payloads  post
```


## Plugins
Los plugins <mark style="background: #ADCCFFA6;">ofrecen al pentester más flexibilidad al usar *msfconsole*</mark>, ya que pueden cargarse fácilmente de forma manual o automática según sea necesario para **proporcionar funcionalidad adicional y automatización** durante nuestra evaluación.
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
Funcionalidad de [[Meterpreter]] y otros scripts útiles.
```shell
ls /usr/share/metasploit-framework/scripts/

meterpreter  ps  resource  shell
```


## Herramientas
**Utilidades de línea de comandos** que se pueden llamar directamente desde el menú *msfconsole*.
```shell
ls /usr/share/metasploit-framework/tools/

context  docs     hardware  modules   payloads
dev      exploit  memdump   password  recon
```