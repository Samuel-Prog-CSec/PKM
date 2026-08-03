---
tags:
  - IA/Red-Team
  - IA
  - IA/LLM
  - Pentesting/Explotacion
Descripción: "Un modelo no consume recursos constantes: hay entradas del mismo tamaño que cuestan mil veces más de procesar, y eso convierte la inferencia en un vector de DoS"
Fecha de actualización: 2026-07-29
Nota previa: "[[01 - Model reverse engineering y robo de modelos]]"
Nota siguiente: "[[03 - Componentes integrados inseguros]]"
Area: "[[Aplicación y sistema.base|Aplicación y sistema]]"
---
---

<mark style="background: #ADCCFFA6;">Un modelo no consume recursos constantes: hay entradas del mismo tamaño que cuestan mil veces más de procesar que otras.</mark> Esa asimetría es lo que convierte la inferencia en un vector de denegación de servicio que ningún firewall de red detecta, porque el tráfico es indistinguible del legítimo: pocas peticiones, bien formadas, autenticadas.

El nombre de HTB para esto —*Model Denial of Service*— es la etiqueta del `OWASP LLM Top 10` **edición 2023**. En la edición 2025 vigente el riesgo se absorbió y amplió en `LLM10: Unbounded Consumption`, que cubre además el *Denial of Wallet* y la extracción de modelo por consumo de API (ver [[03 - OWASP Top 10 para aplicaciones LLM]]). Al redactar el informe se cita la numeración de 2025.

# La diferencia con un DoS clásico

Un DoS tradicional busca saturar ancho de banda o conexiones: muchas peticiones baratas. Un DoS sobre ML busca **maximizar el coste por petición**: pocas peticiones caras. La consecuencia práctica es que las contramedidas habituales fallan.

| Defensa clásica | Por qué falla contra DoS de ML |
| - | - |
| `Rate limiting` por peticiones/segundo | El atacante manda 5 peticiones. Cada una consume 200× lo normal |
| Límite de tamaño de petición | La entrada cabe en 50 caracteres. El coste está en la *salida* |
| Detección de anomalías de tráfico | El tráfico es normal: HTTPS autenticado, volumen bajo |
| Autoescalado | Escala, y con ello la factura. El ataque se convierte en económico |

<mark style="background: #8000E1A6;">En despliegues facturados por token, un DoS de ML rara vez tumba el servicio: lo que hace es multiplicar la factura</mark>. Es el *Denial of Wallet*, y para muchos clientes es peor que la caída porque no dispara ninguna alerta operativa hasta que llega el cargo.

# Sponge examples: el ataque fundacional

> [!info]+ Fuente: Shumailov et al., [*Sponge Examples: Energy-Latency Attacks on Neural Networks*](https://arxiv.org/abs/2006.03463) (IEEE EuroS&P 2021)
> Entradas diseñadas para maximizar consumo energético y latencia de inferencia **sin aumentar la dimensión de la entrada**. El matiz es esencial: una entrada más grande siempre cuesta más, pero eso se corta con un límite de tamaño. Un `sponge example` cuesta más *a igualdad de tamaño*, y por tanto sobrevive al límite.

Se generan de dos formas:

- **Caja blanca** — con acceso a arquitectura y parámetros. Poco realista contra un objetivo real, pero sirve para generarlos localmente contra un modelo propio de arquitectura similar y **transferirlos** al objetivo.
- **Caja negra** — solo hace falta consultar el modelo y medir la latencia. Como la latencia se mide con un cronómetro desde el cliente, esta variante es viable contra casi cualquier API pública.

La búsqueda se hace con **algoritmos genéticos**: se parte de una población aleatoria de entradas, se evalúa cada una midiendo su latencia (*fitness*), se seleccionan las peores para el servicio, se cruzan y se mutan, y se repite. Cada generación produce ejemplos más costosos. El código original está en [`iliaishacked/sponge_examples`](https://github.com/iliaishacked/sponge_examples).

## Por qué funcionan en modelos de texto

Dos factores dominan el coste de una inferencia de lenguaje:

1. **Longitud de la secuencia de salida.** Cada token generado es un `forward pass` completo. Alargar la respuesta multiplica el coste linealmente.
2. **Número de tokens de entrada.** El tokenizador está optimizado sobre el corpus de entrenamiento: las palabras frecuentes ocupan un token, las raras se fragmentan. <mark style="background: #FFB8EBA6;">Una entrada de la misma longitud en caracteres puede producir 3× más tokens si se elige mal el vocabulario</mark>.

Esto se comprueba en segundos con el tokenizador real del objetivo:

```python
from transformers import AutoTokenizer
import json

model = 'openai-community/gpt2'

while 1:
    text = input("> ")
    tokens = AutoTokenizer.from_pretrained(model).tokenize(text)
    print(f"Caracteres: {len(text)} | Tokens: {len(tokens)}")
    print(json.dumps(tokens, indent=2))
```

```shell-session
$ python3 sponge.py

> This is an example text
Caracteres: 23 | Tokens: 5

> Athazagoraphobia
Caracteres: 16 | Tokens: 7

> A/h/z/g/r/p/p/
Caracteres: 14 | Tokens: 14
```

La progresión es la receta: **palabras comunes → palabras raras → secuencias que no existen en ninguna lengua**. La última entrada consigue la ratio máxima de un token por carácter. Contra tokenizadores modernos con vocabularios grandes (`o200k_base`, `Llama 3`), las secuencias de símbolos poco frecuentes, caracteres de alfabetos minoritarios y emojis compuestos siguen dando ratios muy por encima de 1.

En el paper, con la entrada limitada a 50 caracteres por ética de la prueba, la latencia de un servicio real de traducción de Microsoft Azure pasó de **1 ms a unos 6 segundos**.

# El estado del arte 2025-2026

El paper original es de 2020 y precede a los LLMs de instrucción. La familia ha evolucionado y hoy hay técnicas mucho más eficientes, todas basadas en la misma idea: **retrasar el token `<EOS>`**.

## Engorgio — suprimir el fin de generación

> [!info]+ Fuente: [*An Engorgio Prompt Makes Large Language Model Babble on*](https://arxiv.org/abs/2412.19394) (ICLR 2025)
> Optimiza un `prompt` con dos funciones de pérdida: una *EOS escape loss* que suprime la aparición del token de fin de secuencia, y una *self-mentor loss* que mantiene la generación coherente para no disparar filtros. El `prompt` se optimiza sobre un modelo proxy local y se transfiere.
>
> Sobre 13 LLMs abiertos de 125M a 30B parámetros, las salidas resultan **2-13× más largas**, alcanzando más del 90 % del límite máximo de generación configurado.

Es el ataque de referencia hoy contra un LLM de generación: en vez de encarecer el procesado de la entrada, fuerza al modelo a **no callarse**.

## OverThink — el DoS indirecto contra modelos de razonamiento

> [!info]+ Fuente: [*OverThink: Slowdown Attacks on Reasoning LLMs*](https://arxiv.org/abs/2502.02542) (2025)
> Aprovecha que los modelos de razonamiento gastan tokens invisibles al usuario antes de responder. El atacante inyecta **problemas señuelo** —procesos de decisión de Markov, sudokus— en contenido público que el modelo recuperará en tiempo de inferencia (una página web, un documento de un RAG).
>
> Tres propiedades que lo hacen peligroso: el señuelo es **benigno**, así que ningún filtro de seguridad lo bloquea; el modelo **sigue respondiendo correctamente** a la pregunta original, así que el usuario no nota nada; y la ralentización **transfiere entre modelos**. Los autores demuestran además variantes multimodales con imágenes que disparan el razonamiento.

Esto convierte el DoS en un ataque de [[05 - Inyección indirecta en RAG, email y web|inyección indirecta]] contra terceros: el atacante no paga las consultas, las paga la víctima. `LoopLLM` ([arXiv 2511.07876](https://arxiv.org/abs/2511.07876), AAAI 2026) explota la misma superficie forzando generación repetitiva, con transferibilidad demostrada entre familias de modelos.

## Atacar el motor de servicio, no el modelo

La línea más reciente ignora el modelo y ataca al **planificador del servidor de inferencia** (`vLLM`, `TGI`, `SGLang`). Estos motores usan *continuous batching*, caché de prefijos y gestión paginada de la caché KV para exprimir la GPU; todas esas optimizaciones tienen casos peores explotables:

- **Agotamiento de la caché KV** — peticiones de contexto muy largo que reservan bloques y no los liberan, expulsando a las peticiones legítimas a la cola.
- **Envenenamiento de la caché de prefijos** — prefijos únicos por petición que anulan la reutilización, multiplicando el trabajo real de la GPU.
- **Decodificación restringida** — cuando el servicio ofrece salida estructurada (JSON Schema, gramáticas, regex), una gramática patológica dispara el coste de la máquina de estados que restringe cada token. Es el mismo principio que el [[00 - Introducción a ReDoS|ReDoS]] clásico, aplicado al muestreo de tokens.

<mark style="background: #FF5582A6;">En un pentest, comprobar si el endpoint acepta esquemas JSON o gramáticas arbitrarias del usuario es un check rápido con impacto alto</mark>, y prácticamente ningún despliegue lo tiene limitado.

# Mitigaciones que funcionan

El principio es acotar el **coste**, no el número de peticiones:

- **Tope de tokens de salida** (`max_tokens`) por petición, obligatorio y aplicado en servidor. Es la mitigación más barata y la que anula Engorgio y familia.
- **Presupuesto de razonamiento** en modelos con `thinking`: límite explícito de tokens de razonamiento, que es lo único que corta OverThink.
- **Timeout de inferencia** con respuesta de error controlada al superarlo. HTB propone un umbral de energía o tiempo; en la práctica se implementa como *deadline* por petición en el servidor de inferencia.
- **Cuotas por tokens, no por peticiones** — el `rate limiting` correcto para un servicio de IA se mide en tokens por minuto y por identidad, no en `requests/s`.
- **Control de admisión** en el motor de servicio: límite de contexto por petición, límite de bloques de caché KV por sesión, y prioridad para peticiones cortas.
- **Sanear el contexto recuperado** antes de inyectarlo en el `prompt`: truncado agresivo del contenido externo y detección de contenido anómalo, que es la defensa frente al vector indirecto.

> [!warning]+ Ética y alcance
> Los ataques de esta nota **degradan servicios reales** y generan coste económico directo al cliente. Los propios autores de los papers limitan la dimensión de sus entradas en las pruebas contra servicios en producción. En un engagement: solo con alcance por escrito, sobre entorno de preproducción siempre que exista, con ventana acordada, y midiendo el efecto sobre una sola petición para **extrapolar** el impacto en vez de provocarlo.
