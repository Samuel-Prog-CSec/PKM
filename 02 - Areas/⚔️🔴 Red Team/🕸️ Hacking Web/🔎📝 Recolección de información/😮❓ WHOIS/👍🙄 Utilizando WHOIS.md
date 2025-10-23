Consideremos tres escenarios para ayudar a ilustrar el valor de los datos de [[😮❓ WHOIS]].


# Escenario 1: Investigación de Phishing
**Contexto**: una alerta marca un correo como peligroso. El correo electrónico afirma ser del banco de la compañía e insta a los destinatarios a hacer clic en un enlace para actualizar la información de su cuenta. Un analista de seguridad investiga el correo electrónico y comienza realizando una búsqueda de `WHOIS` en el dominio vinculado en el correo electrónico.

El registro de `WHOIS` revela lo siguiente:
- `Registration Date`: el dominio fue **registrado hace solo unos días**.
- `Registrant`: la **información del registrante está oculta** detrás de un servicio de privacidad.
- `Name Servers`: los **servidores de nombres están asociados con un proveedor de alojamiento a prueba de balas conocido** (*bulletproof hosting provider*) que a menudo se usa para actividades maliciosas.
>[!Aclaración]
>
>Un **"bulletproof hosting provider"** es un ==proveedor de servicios de alojamiento web que opera bajo políticas muy laxas o deliberadamente permisivas en cuanto a los contenidos o actividades que sus clientes alojan en sus servidores==. Estos servicios suelen ignorar o no responder adecuadamente a las denuncias de abuso, como hosting de malware, phishing, spam, sitios fraudulentos, actividades de hacking o distribución de contenido ilegal (como materiales con derechos de autor o incluso contenido criminal). Características principales:
> - **Políticas de tolerancia alta**: estos proveedores ==suelen proteger a sus clientes incluso si alojan contenidos ilícitos o realizan actividades maliciosa==s. Pueden operar en jurisdicciones donde las leyes son más permisivas o difíciles de aplicar.
> - **Ubicación estratégica**: a menudo están ==situados en países con regulaciones débiles en materia de ciberseguridad o cooperación internacional limitada==, lo que les permite evadir sanciones o presiones legales de otras naciones.
> - **Privacidad extrema**: pueden ==ofrecer anonimato a sus clientes, evitando recolectar o compartir datos personales==, incluso en casos de investigaciones legales.
> - **Resistencia a quejas**: ==ignoran, retrasan o bloquean las solicitudes de retirada de contenidos o las denuncias de abuso== de empresas de seguridad, organizaciones anti-spam, o autoridades legales.
> - **Servicios adicionales**: muchos incluyen medidas técnicas para proteger a sus clientes, como ==protección contra ataques DDoS, cifrado extremo, o herramientas para dificultar el rastreo de los responsables==.

Esta combinación de factores plantea importantes *red flags* para el analista. La fecha de registro reciente, la información oculta del registrante y el alojamiento sospechoso sugieren fuertemente una campaña de phishing. El analista alerta rápidamente al departamento de TI de la compañía para bloquear el dominio y advierte a los empleados sobre la estafa. Una investigación adicional sobre el proveedor de alojamiento y las direcciones IP asociadas puede descubrir dominios de phishing adicionales o infraestructura que utiliza el actor de amenazas.


# Escenario 2: Análisis de malware
**Contexto**: un investigador de seguridad está analizando una nueva cepa de malware que ha infectado varios sistemas dentro de una red. El malware se comunica con un servidor remoto para recibir comandos y filtrar datos robados. Para ==obtener información sobre la infraestructura del actor de amenazas==, el investigador realiza una búsqueda `WHOIS` en el dominio asociado con el **servidor de comando y control (Command-and-Control, C2)**.

El registro de `WHOIS` revela:
- `Registrant`: el dominio está registrado a un individuo utilizando un servicio de correo electrónico gratuito conocido por el anonimato.
- `Location`: la dirección del solicitante de registro se encuentra en un país con una alta prevalencia de delitos cibernéticos.
- `Registrar`: el dominio fue registrado a través de un registrador con un historial de políticas de abuso laxas.

Sobre la base de esta información, el investigador concluye que el servidor C2 probablemente esté alojado en un servidor comprometido o "a prueba de balas". Luego, el investigador utiliza los datos de WHOIS para identificar al proveedor de alojamiento y notificarle sobre la actividad maliciosa.


# Escenario 3: Informe de Inteligencia de Amenazas
**Contexto**: una firma de ciberseguridad rastrea las actividades de un sofisticado grupo de actores de amenazas conocido por atacar a instituciones financieras. Los analistas recopilan datos de `WHOIS` en múltiples dominios asociados con las campañas pasadas del grupo para compilar un informe completo de inteligencia de amenazas.

Al analizar los registros de `WHOIS`, los analistas descubren los siguientes patrones:
- `Registration Dates`: los ==dominios se registraron en grupos==, a menudo poco antes de los ataques importantes.
- `Registrants`: los solicitantes de registro utilizan varios ==alias e identidades falsas==.
- `Name Servers`: los dominios a menudo comparten los mismos servidores de nombre, lo que sugiere una ==infraestructura común==.
- `Takedown History`: muchos dominios han sido eliminados después de los ataques, lo que indica ==intervenciones previas de aplicación de la ley o de seguridad==.

Estas ideas permiten a los analistas **crear un perfil detallado de las tácticas, técnicas y procedimientos del actor de amenazas** (*TTP*). El informe incluye indicadores de compromiso (IOC) basados en los datos de `WHOIS`, que ==otras organizaciones pueden usar para detectar y bloquear futuros ataques==.


# Usando WHOIS
Si `whois` no está instalado, se puede instalar simplemente con:
```shell
sudo apt update
sudo apt install whois -y
```

Realicemos una **búsqueda** de `WHOIS` de `facebook.com`:
```shell
whois facebook.com

   Domain Name: FACEBOOK.COM
   Registry Domain ID: 2320948_DOMAIN_COM-VRSN
   Registrar WHOIS Server: whois.registrarsafe.com
   Registrar URL: http://www.registrarsafe.com
   Updated Date: 2024-04-24T19:06:12Z
   Creation Date: 1997-03-29T05:00:00Z
   Registry Expiry Date: 2033-03-30T04:00:00Z
   Registrar: RegistrarSafe, LLC
   Registrar IANA ID: 3237
   Registrar Abuse Contact Email: abusecomplaints@registrarsafe.com
   Registrar Abuse Contact Phone: +1-650-308-7004
   Domain Status: clientDeleteProhibited https://icann.org/epp#clientDeleteProhibited
   Domain Status: clientTransferProhibited https://icann.org/epp#clientTransferProhibited
   Domain Status: clientUpdateProhibited https://icann.org/epp#clientUpdateProhibited
   Domain Status: serverDeleteProhibited https://icann.org/epp#serverDeleteProhibited
   Domain Status: serverTransferProhibited https://icann.org/epp#serverTransferProhibited
   Domain Status: serverUpdateProhibited https://icann.org/epp#serverUpdateProhibited
   Name Server: A.NS.FACEBOOK.COM
   Name Server: B.NS.FACEBOOK.COM
   Name Server: C.NS.FACEBOOK.COM
   Name Server: D.NS.FACEBOOK.COM
   DNSSEC: unsigned
   URL of the ICANN Whois Inaccuracy Complaint Form: https://www.icann.org/wicf/
>>> Last update of whois database: 2024-06-01T11:24:10Z <<<

[...]
Registry Registrant ID:
Registrant Name: Domain Admin
Registrant Organization: Meta Platforms, Inc.
[...]
```

La salida de `WHOIS` para `facebook.com` revela **varios detalles clave**:
1. `Domain Registration`:
    - `Registrar`: RegistrarSafe, LLC
    - `Creation Date`: 1997-03-29
    - `Expiry Date`: 2033-03-30
	Estos detalles indican que el dominio está **registrado en** **RegistrarSafe, LLC**, y ha estado **activo durante un período considerable**, lo que ==sugiere su legitimidad y presencia en línea establecida==. La **fecha de caducidad distante** refuerza aún más su longevidad.
	
2. `Domain Owner`:
    - `Registrant/Admin/Tech Organization`: Meta Plataformas, Inc.
    - `Registrant/Admin/Tech Contact`: Administrador de Dominio
    Esta información identifica a **Meta Platforms, Inc. como la organización** detrás `facebook.com`y **Domain Admin** como ==punto de contacto para asuntos relacionados con el dominio==. Esto es consistente con la expectativa de que Facebook, una destacada plataforma de redes sociales, es propiedad de Meta Platforms, Inc.
    
3. `Domain Status`:
    - `clientDeleteProhibited`, `clientTransferProhibited`, `clientUpdateProhibited`, `serverDeleteProhibited`, `serverTransferProhibited`, y `serverUpdateProhibited`
    Estos estados **indican que el dominio está protegido contra cambios**, **transferencias** o **eliminaciones no autorizadas** tanto en el ==lado del cliente como en el del servidor==. Esto pone de relieve un fuerte énfasis en la seguridad y el control sobre el dominio.
    
4. `Name Servers`:
    - `A.NS.FACEBOOK.COM`, `B.NS.FACEBOOK.COM`, `C.NS.FACEBOOK.COM`, `D.NS.FACEBOOK.COM`
    Estos **servidores de nombres están todos dentro del** `facebook.com` **domain**, lo que sugiere que Meta Platforms, Inc. gestiona su infraestructura [[🧭 DNS]]. Es una ==práctica común que las grandes organizaciones mantengan el control y la confiabilidad sobre su resolución de DNS==.

>[!Conclusiones]
>
En general, el resultado de `WHOIS` para `facebook.com` se alinea con las expectativas de un dominio bien establecido y seguro propiedad de una gran organización como Meta Platforms, Inc.
Si bien el registro de `WHOIS` proporciona información de contacto para problemas relacionados con el dominio, es ==posible que no sea directamente útil para identificar empleados individuales o vulnerabilidades específicas==. Esto pone de relieve la **necesidad de combinar los datos de** `WHOIS` **con otras técnicas de reconocimiento para comprender la huella digital del objetivo de manera integral**.