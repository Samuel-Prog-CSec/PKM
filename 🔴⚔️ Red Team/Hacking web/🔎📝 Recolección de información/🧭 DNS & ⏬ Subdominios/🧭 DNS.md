El **Domain Name System** (`DNS`) actúa como el GPS de Internet, guiando el viaje en línea desde puntos de referencia (==nombres de dominio==) hasta coordenadas numéricas precisas (==Direcciones IP==). Al igual que el GPS traduce un nombre de destino en latitud y longitud para la navegación, DNS traduce nombres de dominio legibles por humanos (como `www.example.com`) en las direcciones IP numéricas (como `192.0.2.1`) que las computadoras usan para comunicarse.

DNS ==elimina complejidad al permitirnos usar nombres de dominio fáciles de recordar==. Cuando escribe un nombre de dominio en su navegador, DNS actúa como su navegador, encontrando rápidamente la dirección IP correspondiente y dirigiendo su solicitud al destino correcto en Internet.


# Cómo funciona DNS
Imagina que quieres visitar un sitio web como `www.example.com`. Escribe este nombre de dominio amigable en su navegador, pero su computadora no entiende las palabras – habla el idioma de los números, específicamente las direcciones IP. Entonces, ¿cómo encuentra su computadora la dirección IP del sitio web? Ingrese DNS, el traductor confiable de Internet. [La siguiente imagen ilustra el proceso de resolución DNS](proceso_resolucion_dns.md).
![[proceso_resolucion_dns.svg]]

1. `Your Computer Asks for Directions (DNS Query)`: Cuando ingresa el nombre de dominio, su computadora primero verifica su memoria (cache) para ver si recuerda la dirección IP de una visita anterior. De lo contrario, se acerca a un resolutor de DNS, generalmente proporcionado por su proveedor de servicios de Internet (ISP).
    
2. `The DNS Resolver Checks its Map (Recursive Lookup)`: El resolvedor también tiene una caché, y si no encuentra la dirección IP allí, comienza un viaje a través de la jerarquía DNS. Comienza preguntando a un servidor de nombres raíz, que es como el bibliotecario de Internet.
    
3. `Root Name Server Points the Way`: El servidor raíz no conoce la dirección exacta, pero sabe quién hace – el servidor de nombres de Dominio de Nivel Superior (TLD) responsable de la finalización del dominio (por ejemplo, .com, .org). Apunta al resolutor en la dirección correcta.
    
4. `TLD Name Server Narrows It Down`: El servidor de nombres TLD es como un mapa regional. Sabe qué servidor de nombres autorizado es responsable del dominio específico que está buscando (por ejemplo `example.com`) y envía el resolvedor allí.
    
5. `Authoritative Name Server Delivers the Address`: El servidor de nombres autorizado es la parada final. Es como la dirección del sitio web que desea. Contiene la dirección IP correcta y la envía de vuelta al resolutor.
    
6. `The DNS Resolver Returns the Information`: El resolutor recibe la dirección IP y se la da a su computadora. También lo recuerda por un tiempo (lo almacena en caché), en caso de que desee volver a visitar el sitio web pronto.
    
7. `Your Computer Connects`: Ahora que su computadora conoce la dirección IP, puede conectarse directamente al servidor web que aloja el sitio web y puede comenzar a navegar.


## El Archivo Hosts
El `hosts` el archivo es un archivo de texto simple que se utiliza para asignar nombres de host a direcciones IP, proporcionando un método manual de resolución de nombres de dominio que omite el proceso DNS. Mientras que DNS automatiza la traducción de nombres de dominio a direcciones IP, el `hosts` el archivo permite anulaciones directas y locales. Esto puede ser particularmente útil para el desarrollo, la solución de problemas o el bloqueo de sitios web.

El `hosts` el archivo se encuentra en `C:\Windows\System32\drivers\etc\hosts` en Windows y en `/etc/hosts` en Linux y MacOS. Cada línea en el archivo sigue el formato:

```txt
<IP Address>    <Hostname> [<Alias> ...]
```
Por ejemplo:
```txt
127.0.0.1       localhost
192.168.1.10    devserver.local
```

Para editar el `hosts` archivo, ábralo con un editor de texto utilizando privilegios administrativos/root. Agregue nuevas entradas según sea necesario y luego guarde el archivo. Los cambios surten efecto inmediatamente sin requerir un reinicio del sistema.

Los usos comunes incluyen redirigir un dominio a un servidor local para el desarrollo:

```txt
127.0.0.1       myapp.local
```

Prueba de conectividad especificando una dirección IP:

```txt
192.168.1.20    testserver.local
```

Bloquear sitios web no deseados redirigiendo sus dominios a una dirección IP inexistente:

```txt
0.0.0.0       unwanted-site.com
```


## Es como una carrera de retransmisión
Piense en el proceso de DNS como una carrera de relevos. Su computadora comienza con el nombre de dominio y lo pasa al resolutor. El resolvedor luego pasa la solicitud al servidor raíz, al servidor TLD y, finalmente, al servidor autorizado, cada uno se acerca al destino. Una vez que se encuentra la dirección IP, se retransmite de nuevo por la cadena a su computadora, lo que le permite acceder al sitio web.


# Conceptos clave DNS
En el `Domain Name System` (`DNS`), a `zone` es una parte distinta del espacio de nombres de dominio que administra una entidad o administrador específico. Piense en ello como un contenedor virtual para un conjunto de nombres de dominio. Por ejemplo, `example.com` y todos sus subdominios (como `mail.example.com` o `blog.example.com`) normalmente pertenecería a la misma zona DNS.

El archivo de zona, un archivo de texto que reside en un servidor DNS, define los registros de recursos (discutidos a continuación) dentro de esta zona, proporcionando información crucial para traducir nombres de dominio a direcciones IP.

Para ilustrar, aquí hay un ejemplo simplificado de para qué es un archivo de zona `example.com` podría parecer:

```dns-zone
$TTL 3600 ; Default Time-To-Live (1 hour)
@       IN SOA   ns1.example.com. admin.example.com. (
                2024060401 ; Serial number (YYYYMMDDNN)
                3600       ; Refresh interval
                900        ; Retry interval
                604800     ; Expire time
                86400 )    ; Minimum TTL

@       IN NS    ns1.example.com.
@       IN NS    ns2.example.com.
@       IN MX 10 mail.example.com.
www     IN A     192.0.2.1
mail    IN A     198.51.100.1
ftp     IN CNAME www.example.com.
```
Este archivo define los servidores de nombres autorizados (`NS` registros), servidor de correo (`MX` registro) y direcciones IP (`A` registros) para varios hosts dentro del `example.com` dominio.

Los servidores DNS almacenan varios registros de recursos, cada uno con un propósito específico en el proceso de resolución de nombres de dominio. Exploremos algunos de los conceptos de DNS más comunes:

| Concepto DNS                | Descripción                                                                                  | Ejemplo                                                                                                                                   |
| --------------------------- | -------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `Domain Name`               | Una etiqueta legible por humanos para un sitio web u otro recurso de Internet.               | `www.example.com`                                                                                                                         |
| `IP Address`                | Un identificador numérico único asignado a cada dispositivo conectado a Internet.            | `192.0.2.1`                                                                                                                               |
| `DNS Resolver`              | Un servidor que traduce nombres de dominio en direcciones IP.                                | El servidor DNS de su ISP o los resolutores públicos como Google DNS (`8.8.8.8`)                                                          |
| `Root Name Server`          | Los servidores de nivel superior en la jerarquía DNS.                                        | Hay 13 servidores raíz en todo el mundo, llamados A-M: `a.root-servers.net`                                                               |
| `TLD Name Server`           | Servidores responsables de dominios específicos de nivel superior (por ejemplo, .com, .org). | [Verisign](https://en.wikipedia.org/wiki/Verisign) para `.com`, [PIR](https://en.wikipedia.org/wiki/Public_Interest_Registry) para `.org` |
| `Authoritative Name Server` | El servidor que contiene la dirección IP real para un dominio.                               | A menudo administrado por proveedores de alojamiento o registradores de dominio.                                                          |
| `DNS Record Types`          | Diferentes tipos de información almacenada en DNS.                                           | A, AAAA, CNAME, MX, NS, TXT, etc.                                                                                                         |

Ahora que hemos explorado los conceptos fundamentales de DNS, profundicemos en los componentes básicos de la información de DNS – los diversos tipos de registros. Estos registros almacenan diferentes tipos de datos asociados con nombres de dominio, cada uno con un propósito específico:

|Tipo de Registro|Nombre Completo|Descripción|Ejemplo de Archivo de Zona|
|---|---|---|---|
|`A`|Registro de Dirección|Asigna un nombre de host a su dirección IPv4.|`www.example.com.`EN A `192.0.2.1`|
|`AAAA`|Registro de direcciones IPv6|Asigna un nombre de host a su dirección IPv6.|`www.example.com.`EN AAAA `2001:db8:85a3::8a2e:370:7334`|
|`CNAME`|Registro de Nombre Canónico|Crea un alias para un nombre de host, apuntándolo a otro nombre de host.|`blog.example.com.`EN CNAME `webserver.example.net.`|
|`MX`|Registro de Intercambio de Correo|Especifica el servidor de correo(s) responsable de manejar el correo electrónico para el dominio.|`example.com.`EN MX 10 `mail.example.com.`|
|`NS`|Nombre Registro del Servidor|Delega una zona DNS en un servidor de nombres autorizado específico.|`example.com.`EN NS `ns1.example.com.`|
|`TXT`|Registro de Texto|Almacena información de texto arbitraria, a menudo utilizada para la verificación de dominio o políticas de seguridad.|`example.com.` EN TXT `"v=spf1 mx -all"` (Récord SPF)|
|`SOA`|Inicio del Registro de Autoridad|Especifica información administrativa sobre una zona DNS, incluido el servidor de nombres principal, el correo electrónico de la persona responsable y otros parámetros.|`example.com.`EN SOA `ns1.example.com. admin.example.com. 2024060301 10800 3600 604800 86400`|
|`SRV`|Registro de Servicio|Define el nombre de host y el número de puerto para servicios específicos.|`_sip._udp.example.com.`EN SRV 10 5 5060 `sipserver.example.com.`|
|`PTR`|Registro de Puntero|Se utiliza para búsquedas DNS inversas, asignando una dirección IP a un nombre de host.|`1.2.0.192.in-addr.arpa.`EN PTR `www.example.com.`|

El "`IN`"en los ejemplos significa "Internet." Es un campo de clase en los registros DNS que especifica la familia de protocolos. En la mayoría de los casos, verás "`IN`"utilizado, ya que denota el conjunto de protocolos de Internet (IP) utilizado para la mayoría de los nombres de dominio. Existen otros valores de clase (por ejemplo `CH` para Chaosnet, `HS` para Hesíodo), pero rara vez se utilizan en configuraciones DNS modernas.

En esencia, "`IN`"es simplemente una convención que indica que el registro se aplica a los protocolos de Internet estándar que usamos hoy en día. Si bien puede parecer un detalle adicional, comprender su significado proporciona una comprensión más profunda de la estructura de registros DNS.

# Por qué DNS Importa para Web Recon
DNS no es simplemente un protocolo técnico para traducir nombres de dominio; es un componente crítico de la infraestructura de un objetivo que se puede aprovechar para descubrir vulnerabilidades y obtener acceso durante una prueba de penetración:

- `Uncovering Assets`: Los registros DNS pueden revelar una gran cantidad de información, incluidos subdominios, servidores de correo y registros de servidores de nombres. Por ejemplo, a `CNAME` registro que apunta a un servidor obsoleto (`dev.example.com` CNAME `oldserver.example.net`) podría conducir a un sistema vulnerable.
- `Mapping the Network Infrastructure`: Puede crear un mapa completo de la infraestructura de red del objetivo mediante el análisis de datos DNS. Por ejemplo, identificar los servidores de nombres (`NS` los registros) para un dominio pueden revelar el proveedor de alojamiento utilizado, mientras que un `A` registro para `loadbalancer.example.com` puede identificar un equilibrador de carga. Esto le ayuda a comprender cómo se conectan los diferentes sistemas, identificar el flujo de tráfico e identificar posibles puntos de estrangulamiento o debilidades que podrían explotarse durante una prueba de penetración.
- `Monitoring for Changes`: El monitoreo continuo de los registros DNS puede revelar cambios en la infraestructura del objetivo a lo largo del tiempo. Por ejemplo, la aparición repentina de un nuevo subdominio (`vpn.example.com`) podría indicar un nuevo punto de entrada en la red, mientras que a `TXT` registro que contiene un valor como `_1password=...` sugiere fuertemente que la organización está utilizando 1Password, que podría aprovecharse para ataques de ingeniería social o campañas de phishing dirigidas.