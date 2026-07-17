---
tags:
  - Web/Red-Team
  - Web-Services
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-17
Nota previa: "[[00 - Introducción a Web Services y APIs]]"
Nota siguiente: "[[02 - SOAPAction Spoofing]]"
Area: "[[Web Services.base|Web Services]]"
---
---

<mark style="background: #ADCCFFA6;">El WSDL (Web Service Description Language) es un fichero XML que describe un web service</mark>: qué **operaciones/métodos** ofrece, dónde residen y cómo invocarlos (parámetros, tipos, *bindings*). Es el **contrato** del servicio y, para un atacante, <mark style="background: #FF5582A6;">un mapa completo de la superficie de ataque</mark>: nombres de operaciones internas, parámetros ocultos, tipos esperados.

# Descubrir el WSDL

Un WSDL no siempre es público: por *security through obscurity*, muchos servicios lo ocultan o lo sirven en una ruta/parámetro poco común. Ahí entra el fuzzing.

Primero, fuzzing de directorios para localizar el *endpoint*:

```shell-session
$ dirb http://<TARGET>:3002
+ http://<TARGET>:3002/wsdl (CODE:200|SIZE:0)
```

`/wsdl` existe pero responde vacío (`SIZE:0`). El contenido suele estar tras un **parámetro**. Fuzzing de parámetros con `ffuf` (`-fs 0` filtra respuestas vacías, `-mc 200` matchea 200):

```shell-session
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt -u 'http://<TARGET>:3002/wsdl?FUZZ' -fs 0 -mc 200
wsdl  [Status: 200, Size: 4461, Words: 967, Lines: 186]
```

El parámetro es `wsdl` → `http://<TARGET>:3002/wsdl?wsdl` sirve el fichero.

> [!info]+ Formas del WSDL
> El WSDL aparece en muchas variantes: `/example.wsdl`, `?wsdl`, `/example.disco`, `?disco`, `.asmx?wsdl` (ASP.NET). **DISCO** es la tecnología de Microsoft para publicar/descubrir web services. Prueba todas antes de asumir que no hay contrato expuesto.

# Anatomía del WSDL

Un WSDL 1.1 se estructura en estos elementos (de dentro afuera):

| Elemento | Qué define |
| - | - |
| `definitions` | Raíz; nombre del servicio y todos los namespaces |
| `types` | Tipos de datos de los mensajes (el *schema* de los parámetros) |
| `message` | Mensajes de entrada/salida de cada operación |
| `portType` | Agrupa operaciones con sus mensajes in/out (en WSDL 2.0 → `interface`) |
| `operation` | Las **SOAP actions** disponibles + codificación |
| `binding` | Vincula operaciones a un *port type*; detalles de acceso (formato, protocolo) |
| `service` | Nombre y **ubicación** (`soap:address`) del servicio |

Lo jugoso para el atacante es el `types` + `operation`. En el lab, el WSDL delata dos operaciones:

```xml
<s:element name="ExecuteCommandRequest">
  <s:complexType><s:sequence>
    <s:element minOccurs="1" maxOccurs="1" name="cmd" type="s:string"/>
  </s:sequence></s:complexType>
</s:element>
...
<wsdl:operation name="ExecuteCommand">
  <soap:operation soapAction="ExecuteCommand" style="document"/>
</wsdl:operation>
```

<mark style="background: #FFB86CA6;">Una operación `ExecuteCommand` con un parámetro `cmd`</mark> — el WSDL acaba de regalarnos el nombre de la acción y su parámetro. Aunque esa operación esté restringida, saber que existe habilita el ataque de [[02 - SOAPAction Spoofing]].

> [!important]+ El WSDL es *information disclosure* de manual
> Exponer el WSDL revela operaciones administrativas o internas que el atacante no debería conocer (`ExecuteCommand`, `admin_*`, `debug_*`…). Aunque estén protegidas, el mapa completo de la API es el primer paso de cualquier ataque. Trátalo como el `swagger.json` de una API REST: si lo encuentras, ya tienes medio trabajo hecho.

Con el contrato en mano y las operaciones identificadas, el siguiente paso es interactuar con ellas — y abusar de cómo el servicio decide qué operación ejecutar: [[02 - SOAPAction Spoofing]].
