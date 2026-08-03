---
tags:
  - IA/Red-Team
  - IA
  - Pentesting/Explotacion
  - Web/Red-Team
Descripción: "Los servidores MCP guardan credenciales de los sistemas que integran y las filtran en errores verbosos y logs, y su control de acceso es tan bueno como el del servicio que hay detrás"
Fecha de actualización: 2026-07-29
Nota previa: "[[04 - Inyecciones en servidores MCP]]"
Nota siguiente: "[[06 - Tool poisoning y prompt injection vía descripción]]"
Area: "[[MCP.base|MCP]]"
---
---

<mark style="background: #ADCCFFA6;">Un servidor MCP es un intermediario con credenciales: guarda las claves de las APIs, tokens y accesos a los sistemas que integra.</mark> Esas credenciales se filtran por dos vías clásicas —errores verbosos y logs accesibles— y su control de acceso hereda las debilidades del servicio que hay detrás. Es la cara menos vistosa de la explotación de MCP y a menudo la más rentable, porque una API key filtrada abre un sistema entero.

# Divulgación por errores verbosos

La técnica de reconocimiento de [[03 - Reconocimiento de servidores MCP|provocar errores]] se convierte aquí en explotación. Un servidor que no maneja bien las excepciones vuelca en el mensaje de error todo el contexto de la operación que falló — incluidas las cabeceras de la petición HTTP que hizo internamente.

Un `resource` `quantity://{item}` que consulta una API externa. Se fuerza un error con un ítem inválido:

```python
try:
    r = await client.read_resource("quantity://asd!")
    print(r[0].text)
except Exception as e:
    print(f"[-] {e}")
```

```text
[-] Quantity API Error: Request details: 'http://quantityapi.local/api/item/asd!'
    {'Content-Type': 'application/json', 'User-Agent': 'MCP Server 1.0.0',
     'X-Api-Key': '7f1db571858da4cf0af43645812e1997'}
```

<mark style="background: #FF5582A6;">El mensaje de error contiene la `X-Api-Key` de la API interna.</mark> Con esa clave se accede directamente a la API que el servidor MCP protegía, saltándose el servidor por completo. Es el patrón más rentable del sub-tema: <mark style="background: #FFB86CA6;">el servidor MCP concentra credenciales de todos los sistemas que integra, y un solo error mal manejado las expone.</mark>

# Divulgación por logs

A veces el servidor maneja bien los errores de cara al cliente pero **escribe información sensible en sus logs**, y expone esos logs como recurso. Un `resource://logs` es un objetivo obvio, y su contenido es un mapa del servidor:

```text
2025-05-12 14:58:38: Getting price for item 'banana'
2025-05-12 14:58:57: Executing server command 'date'
2025-05-12 14:59:42: Executing server command 'whoami'
2025-05-13 08:48:54: Error fetching item quantity for 'watremelon': 'NoneType' object is not subscriptable
```

Los logs revelan:

- **Ítems válidos** (`banana`, `apple`) para afinar otros ataques.
- **Comandos que el servidor ejecuta** (`date`, `whoami`) — pista de [[04 - Inyecciones en servidores MCP#Command injection|command injection]].
- **Trazas de error internas** que delatan la implementación (`NoneType object is not subscriptable` → Python, manejo de nulos ausente).

> [!warning]+ El error se maneja, la información se filtra igual
> Que un servidor devuelva errores genéricos al cliente **no** significa que sea seguro: puede estar escribiendo la información sensible en un log que luego expone como recurso, o en un fichero que se alcanza por [[04 - Inyecciones en servidores MCP#El patrón, no los casos|traversal]]. Hay que buscar la información en las dos superficies: la respuesta de error y el almacenamiento de logs.

# Broken authorization (IDOR)

Cuando un servidor ofrece funcionalidad para distintos ámbitos de acceso, puede tener [[06 - Introducción a IDOR|IDOR]]. El caso típico es un `resource` `document://{doc_id}` que recupera documentos de almacenamiento en la nube: si el servidor no verifica que el cliente tiene acceso a ese `doc_id`, se accede a documentos de otros usuarios cambiando el identificador.

```python
# ¿responde con documentos que no son nuestros?
for i in range(1, 50):
    try:
        r = await client.read_resource(f"document://{i}")
        print(i, r[0].text[:60])
    except Exception:
        pass
```

## Por qué el IDOR es *menos* frecuente en MCP

Un matiz importante y contraintuitivo: <mark style="background: #8000E1A6;">el `broken authorization` es relativamente **raro** en servidores MCP</mark>, y la razón es estructural. El servidor MCP accede a los datos con **su propia** credencial (una API key, un token de servicio), y el ámbito de acceso lo define esa credencial. Si el servicio externo detrás ya impone autorización correcta, el servidor MCP hereda esa autorización sin tener que implementarla.

El IDOR aparece cuando el servidor MCP tiene una credencial **más amplia** que la que debería tener cada usuario, y usa un identificador del cliente para acotar el acceso sin verificar la propiedad. Es el mismo antipatrón de la [[03 - Componentes integrados inseguros#La variante peligrosa: autorización delegada al modelo|autorización delegada]]: la credencial da acceso a todo, y la única barrera es un parámetro que controla el atacante.

## El caso stateless: state handle hijacking

La versión 2026-07-28 introduce un vector de autorización nuevo. Al ser [[01 - El protocolo MCP - mensajes, transportes y ciclo de vida#El modelo stateless (2026-07-28 — el vigente)|stateless]], un servidor que necesita estado emite un `state handle` (ID de carrito, de flujo) que el cliente devuelve como argumento. Si el servidor trata la **posesión** del handle como prueba de identidad, adivinarlo o robarlo da acceso al estado de otro usuario.

> [!info]+ Fuente: [*MCP Security Best Practices — State Handle Hijacking*](https://modelcontextprotocol.io/specification/latest/basic/security_best_practices)
> La spec lo prohíbe explícitamente: los servidores **NO DEBEN** tratar la posesión de un `state handle` como autenticación, **DEBEN** verificar toda petición entrante, y **DEBERÍAN** usar handles no deterministas generados con un RNG seguro y ligados al usuario autenticado del lado del servidor (`<user_id>:<handle>`). Un servidor que use identificadores secuenciales o predecibles como handle es vulnerable. Detalle en [[08 - Seguridad de la autorización OAuth en MCP]].

# Mitigación

- **Manejo de excepciones exhaustivo.** Ninguna capacidad debe dejar escapar una excepción sin capturar. El cliente recibe un mensaje genérico; el detalle va a un log **no accesible** desde el propio MCP.
- **No exponer logs como recurso**, o si se hace, redactar credenciales y datos sensibles antes de escribirlos. Aplicar el mismo criterio de [[05 - Manejo excesivo de datos y almacenamiento inseguro|minimización y redacción]] que a las conversaciones.
- **Secretos fuera del código y del alcance del error.** Las API keys en un gestor de secretos, no en variables que acaben en un `repr` de la petición. Rotación periódica.
- **Verificar autorización en el servidor**, no confiar en el ámbito de la credencial ni en identificadores del cliente. Handles no deterministas y ligados al usuario.
- **Mínimo privilegio de la credencial del servidor.** Si el token del servidor MCP solo puede acceder a lo que el usuario actual puede ver, el IDOR desaparece de raíz.
