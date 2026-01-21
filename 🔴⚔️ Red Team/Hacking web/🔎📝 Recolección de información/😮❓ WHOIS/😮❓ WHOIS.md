**WHOIS** es un **protocolo de consulta y respuesta** ampliamente utilizado diseñado para ==acceder a bases de datos que almacenan información sobre recursos de Internet registrados==. Principalmente **asociado con nombres de dominio** ([[🧭 DNS]]), `WHOIS` también ==puede proporcionar detalles sobre bloques de direcciones IP y sistemas autónomos==. Sería como una guía telefónica gigante para Internet, que permite buscar quién posee o es responsable de varios activos en línea.
```bash
whois inlanefreight.com

[...]
Domain Name: inlanefreight.com
Registry Domain ID: 2420436757_DOMAIN_COM-VRSN
Registrar WHOIS Server: whois.registrar.amazon
Registrar URL: https://registrar.amazon.com
Updated Date: 2023-07-03T01:11:15Z
Creation Date: 2019-08-05T22:43:09Z
[...]
```

Cada registro de **WHOIS** generalmente contiene la siguiente información:
- **Domain Name**: el nombre de dominio en sí (por ejemplo, example.com).
- **Registrar**: la ==empresa donde se registró el dominio== (por ejemplo, GoDaddy, Namecheap).
- **Registrant Contact**: la persona u organización que registró el dominio.
- **Administrative Contact**: la persona responsable de administrar el dominio.
- **Technical Contact**: la persona que maneja problemas técnicos relacionados con el dominio.
- **Creation and Expiration Dates**: cuando se registró el dominio y cuando está configurado para caducar.
- **Name Servers**: servidores que traducen el nombre de dominio a una dirección IP.


# Historia de WHOIS
La historia de `WHOIS` está intrínsecamente ligada a la visión y dedicación de [Elizabeth Feinler](https://en.wikipedia.org/wiki/Elizabeth_J._Feinler), un informático que jugó un papel fundamental en la configuración de la Internet temprana.

En la década de 1970, Feinler y su equipo en el Centro de Información de Red (NIC) del Instituto de Investigación de Stanford reconocieron la necesidad de un sistema para rastrear y administrar el creciente número de recursos de red en ARPANET, el precursor de la Internet moderna. Su solución fue la creación del directorio WHOIS, una base de datos rudimentaria pero innovadora que almacenaba información sobre usuarios de red, nombres de host y nombres de dominio.


# Por qué WHOIS importa para Web Recon
Los datos de `WHOIS` sirven como un tesoro de información para los *pentesters* durante la fase de reconocimiento de una evaluación. Ofrece información valiosa sobre la huella digital de la organización objetivo y las posibles vulnerabilidades:
- **Identifying Key Personnel**: los registros de `WHOIS` a menudo revelan los nombres, direcciones de correo electrónico y números de teléfono de las personas responsables de administrar el dominio. Esta información ==se puede aprovechar para ataques de ingeniería social o para identificar objetivos potenciales== para campañas de phishing.
- **Discovering Network Infrastructure**: los detalles técnicos como los servidores de nombres y las direcciones IP proporcionan pistas sobre la infraestructura de red del objetivo. Esto puede ayudar a los pentesters a ==identificar posibles puntos de entrada o configuraciones erróneas==.
- **Historical Data Analysis**: acceso a registros históricos de `WHOIS` a través de servicios como [WhoisFreaks](https://whoisfreaks.com/) puede revelar cambios en la propiedad, información de contacto o detalles técnicos a lo largo del tiempo. Esto puede ser útil para ==rastrear la evolución de la presencia digital del objetivo==.