---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Fuzzing
  - Introduccion
Fecha de actualización: 2026-06-02
Nota previa: "[[14 - Automatización del recon]]"
Nota siguiente: "[[16 - Herramientas de fuzzing]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

<mark style="background: #ADCCFFA6;">El `web fuzzing` prueba automáticamente entradas inesperadas o masivas contra una aplicación web para descubrir lo que no enlaza ni revela por sí sola</mark>. Es la evolución activa del [[14 - Automatización del recon|reconocimiento]]: donde el crawling sigue enlaces existentes, el fuzzing **fuerza** al servidor a confirmar la existencia de directorios, archivos, parámetros, *vhosts* y endpoints ocultos probándolos uno a uno.

# Fuzzing vs brute-forcing

Los términos se usan como sinónimos y, para empezar, no pasa nada por tratarlos igual. La distinción fina:

- **Fuzzing**: lanza una red amplia. Alimenta la aplicación con entradas inesperadas —datos mal formados, caracteres inválidos, combinaciones sin sentido— para ver cómo reacciona y destapar fallos en el manejo de datos.
- **Brute-forcing**: enfoque dirigido. Prueba sistemáticamente muchas posibilidades para **un** valor concreto (una contraseña, un ID) usando diccionarios predefinidos.

> [!example]+ La analogía de la puerta
> Imagina que intentas abrir una puerta cerrada. El **fuzzing** sería lanzarle todo lo que encuentres —llaves, destornilladores, hasta un pato de goma— a ver si algo la abre. El **brute-force** sería probar cada combinación de un llavero hasta dar con la que encaja.

> [!important]+ Qué "fuzzing" cubre este tema (y por qué importa la distinción)
> Lo que este módulo —y la mayoría del fuzzing web cotidiano— llama "fuzzing" es en realidad <mark style="background: #FFB8EBA6;">`content discovery`: brute-force con `wordlists` para descubrir rutas, parámetros y hosts</mark> mediante `ffuf`. No confundir con el *fuzzing de mutación* clásico (estilo `AFL`), que envía entradas aleatorias/malformadas a un programa para provocar *crashes* o estados inesperados. Ambos son "fuzzing", pero aquí la posición de fuzzing (`FUZZ`) recorre una lista de candidatos y analizamos la **respuesta HTTP** de cada uno. Tenerlo claro evita esperar de `ffuf` lo que hace un fuzzer de protocolo.

# Por qué fuzzear aplicaciones web

Las apps web manejan datos sensibles y son objetivo prioritario. El testing manual llega hasta cierto punto; el fuzzing aporta:

- **Descubrir lo oculto**: <mark style="background: #FFB86CA6;">bombardear la app con entradas que no espera destapa contenido y comportamientos que el testing tradicional pasa por alto</mark> — paneles, backups, endpoints sin documentar.
- **Automatización**: genera y envía las pruebas por ti, liberándote para analizar los resultados.
- **Simular ataques reales**: imita las técnicas del atacante para encontrar debilidades antes que él.
- **Reforzar la validación de entrada**: identifica huecos en la validación, base de `SQLi`, `XSS` y otras inyecciones.
- **Seguridad continua**: integrable en el `SDLC` y en pipelines `CI/CD` para detectar problemas pronto.

# Conceptos esenciales

| Concepto | Descripción | Ejemplo |
| - | - | - |
| `Wordlist` | Diccionario de palabras, rutas, nombres o valores usados como entrada | Genérica: `admin`, `login`, `backup` · Específica: `productID`, `checkout` |
| `Payload` | El dato concreto que se envía a la app | `' OR 1=1 --` (para SQLi) |
| `Response Analysis` | Examinar las respuestas (códigos, errores, tamaño) para detectar anomalías | Normal: `200 OK` · Sospechoso: `500` con error de BD |
| `Fuzzer` | Herramienta que automatiza el envío de payloads y el análisis de respuestas | `ffuf`, `wfuzz`, Burp Intruder |
| `False Positive` | Resultado marcado como hallazgo que no lo es | Un *soft-404* (`200` con página de "no encontrado") tomado como ruta válida |
| `False Negative` | Vulnerabilidad real que el fuzzer no detecta | Un fallo lógico sutil en el pago |
| `Fuzzing Scope` | Las partes de la app a las que diriges el fuzzing | Solo el login, o un endpoint de API concreto |

<mark style="background: #FF5582A6;">El análisis de respuestas es el verdadero arte del fuzzing</mark>: lanzar miles de peticiones es trivial; distinguir la respuesta que importa del ruido de falsos positivos es donde se gana o se pierde. Esa disciplina la desarrollamos en [[21 - Filtrado de la salida de fuzzing]] y [[22 - Validación de hallazgos]].

La herramienta que vertebra todo el tema es `ffuf`. La preparamos en [[16 - Herramientas de fuzzing]].
