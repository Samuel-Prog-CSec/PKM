---
tags:
  - Pentesting/Explotacion
  - Metasploit
Fecha de actualización: 2026-07-18
Nota previa: "[[06 - Bases de datos y workspaces]]"
Nota siguiente: "[[08 - Sesiones y Jobs]]"
Area: "[[Metasploit.base|Metasploit]]"
---
---

`Plugins` y `mixins` suenan parecido pero son cosas distintas y para públicos distintos: <mark style="background: #ADCCFFA6;">los **plugins** extienden la consola para el usuario; los **mixins** reutilizan código para el desarrollador de módulos</mark>.

# Plugins: extender la consola

Un plugin añade **comandos nuevos** a `msfconsole` o automatiza tareas. Se cargan en caliente:

```shell-session
msf6 > load nessus          # integra Nessus dentro de msfconsole
msf6 > load openvas         # integra OpenVAS
msf6 > load pcap_log        # registra el tráfico generado
msf6 > load alias           # crear alias de comandos
msf6 > unload nessus        # descargar
```

<mark style="background: #FFB86CA6;">Los plugins de integración conectan MSF con otras herramientas del arsenal</mark>: `load nessus` permite lanzar escaneos de [[Nessus.base|Nessus]] y volcar los resultados a la [[06 - Bases de datos y workspaces|base de datos]] sin salir de la consola. Los plugins viven en `/usr/share/metasploit-framework/plugins/`.

> [!info]+ Plugins útiles
> Además de los de integración (`nessus`, `openvas`, `sqlmap`), hay plugins de calidad de vida: `pcap_log` (captura el tráfico de la sesión, útil para el informe y para depurar), `alias` (atajos), `session_notifier` (avisa de sesiones nuevas). Se pueden autocargar desde un [[01 - MSFconsole|resource script]].

# Mixins: los bloques del desarrollador

Un `mixin` es un concepto de **Ruby**: un módulo de código que se "mezcla" (*mix in*) dentro de una clase para darle métodos ya hechos. <mark style="background: #8000E1A6;">Los módulos de Metasploit no reinventan cómo hablar TCP o HTTP: heredan esa lógica de mixins</mark>.

```ruby
class MetasploitModule < Msf::Exploit::Remote
  include Msf::Exploit::Remote::Tcp          # métodos para sockets TCP
  include Msf::Exploit::Remote::HttpClient   # peticiones HTTP
  # ...
end
```

Mixins comunes:

| Mixin | Aporta |
| --- | --- |
| `Msf::Exploit::Remote::Tcp` | Conexión y E/S sobre TCP |
| `Msf::Exploit::Remote::HttpClient` | Cliente HTTP (peticiones, cookies) |
| `Msf::Exploit::Remote::SMB` | Diálogo con SMB |
| `Msf::Auxiliary::Scanner` | Bucle de escaneo sobre `RHOSTS` |
| `Msf::Auxiliary::Report` | Escribir hallazgos en la base de datos |

<mark style="background: #FFB8EBA6;">Entender los mixins es requisito para [[10 - Escritura e importación de módulos|escribir o adaptar módulos]]</mark>: casi todo el trabajo consiste en elegir los mixins correctos y rellenar la lógica específica.

# La diferencia, en una línea

| | Plugin | Mixin |
| --- | --- | --- |
| Para | El **usuario** de la consola | El **desarrollador** de módulos |
| Qué hace | Añade comandos/automatización a `msfconsole` | Aporta métodos reutilizables a un módulo Ruby |
| Cómo se usa | `load <plugin>` | `include <Mixin>` en el código |

Con el framework extendido, toca gestionar lo que producen los exploits: las [[08 - Sesiones y Jobs|sesiones y jobs]].
