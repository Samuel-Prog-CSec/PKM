---
tags:
  - Pentesting/Explotacion
  - Metasploit
Descripción: "Metasploit trae miles de exploits, pero un CVE recién publicado o un 0day no están todavía en el framework"
Fecha de actualización: 2026-07-18
Nota previa: "[[09 - Meterpreter]]"
Nota siguiente: "[[11 - MSFvenom]]"
Area: "[[Metasploit.base|Metasploit]]"
---
---

Metasploit trae miles de exploits, pero <mark style="background: #FFB8EBA6;">un CVE recién publicado o un 0day no están todavía en el framework</mark>. Adaptar un exploit público al formato de MSF —o importarlo— te da toda su maquinaria (handlers, payloads, sesiones, base de datos) sobre tu propio código.

# La anatomía de un módulo

Un módulo es una clase Ruby que hereda de un tipo (`Msf::Exploit::Remote`, `Msf::Auxiliary`…), incluye los [[07 - Plugins y Mixins|mixins]] que necesita y define su comportamiento:

```ruby
class MetasploitModule < Msf::Exploit::Remote
  Rank = ExcellentRanking
  include Msf::Exploit::Remote::HttpClient      # mixin: cliente HTTP

  def initialize(info = {})
    super(update_info(info,
      'Name'        => 'Ejemplo RCE en AppX',
      'Description'  => 'RCE no autenticado vía parámetro X',
      'Author'       => ['tu_alias'],
      'References'    => [['CVE', '2024-XXXXX']],
      'DisclosureDate' => '2024-01-01',
      'Platform'     => 'linux',
      'Targets'      => [['Automatic', {}]],
      'DefaultOptions' => { 'PAYLOAD' => 'linux/x64/meterpreter/reverse_tcp' }
    ))
  end

  def check                    # ¿es vulnerable? (sin explotar)
    # ...devuelve Exploit::CheckCode
  end

  def exploit                  # entrega el payload
    # ...
  end
end
```

Las partes clave:

| Elemento | Papel |
| --- | --- |
| `include <Mixin>` | Reutiliza lógica de protocolo ([[07 - Plugins y Mixins\|Tcp, HttpClient, SMB]]) |
| `initialize` | Metadatos: nombre, refs (**CVE**), targets, opciones |
| `check` | Comprueba vulnerabilidad **sin** explotar — buena práctica y educado con el cliente |
| `exploit` / `run` | La lógica que entrega el payload (exploit) o hace la tarea (auxiliary) |

<mark style="background: #8000E1A6;">Escribir un módulo es, en gran parte, elegir los mixins correctos y rellenar `check` y `exploit`</mark> — la fontanería (sockets, payloads, sesiones) la pone el framework.

# Importar un módulo externo

No hace falta tocar los directorios del sistema: MSF carga módulos del usuario desde `~/.msf4/modules/`, **replicando la estructura de carpetas** oficial:

```shell-session
$ mkdir -p ~/.msf4/modules/exploits/linux/http/
$ cp myexploit.rb ~/.msf4/modules/exploits/linux/http/
$ msfconsole -q
msf6 > reload_all                              # recarga todos los módulos
msf6 > use exploit/linux/http/myexploit
```

`reload_all` re-lee los módulos sin reiniciar la consola — imprescindible al iterar sobre un módulo propio. Alternativa puntual: `loadpath /ruta/a/modulos`.

# Adaptar un exploit público

El flujo típico en un engagement: encuentras un PoC en [Exploit-DB](https://www.exploit-db.com) o un advisory para el CVE que afecta al objetivo, y lo **envuelves** en un módulo MSF para ganar payloads y handler:

1. Identifica el protocolo (HTTP, TCP, SMB…) y elige el mixin correspondiente.
2. Traslada la lógica del PoC a `exploit`, usando los métodos del mixin (`send_request_cgi`, `connect`/`sock.put`…).
3. Rellena `check` con una comprobación no intrusiva de la versión/vulnerabilidad.
4. Prueba con `reload_all` → `check` → `exploit`.

> [!info]+ check antes que exploit
> <mark style="background: #FFB86CA6;">Correr `check` antes de `exploit` es OPSEC y profesionalidad</mark>: confirma que el objetivo es vulnerable **sin** lanzar el payload, evitando ruido y el riesgo de tumbar un servicio no vulnerable. En el informe, "confirmado vulnerable vía check" es más limpio que "lo intenté y falló".

Para generar los payloads que estos módulos entregan —o para usarlos fuera de un exploit—, está [[11 - MSFvenom|MSFvenom]].
