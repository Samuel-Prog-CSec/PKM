---
tags:
  - IA/Red-Team
  - IA/LLM
  - Pentesting/Reporting
Descripción: "Cómo encaja PyRIT en un trabajo real, desde el alcance hasta la entrega"
Fecha de actualización: 2026-07-28
Nota previa: "[[02 - Ataques multi-turno con PyRIT]]"
Nota siguiente: 
Area: "[[PyRIT.base|PyRIT]]"
---
---

Cómo encaja PyRIT en un trabajo real, desde el alcance hasta la entrega.

# Los tres ejecutables

La versión 1.x permite trabajar sin escribir Python, y eso cambia cuándo merece la pena sacarlo:

```shell-session
# Sondeo interactivo a mano contra un objetivo configurado
$ pyrit_shell

# Ejecutar un escenario completo
$ pyrit_scan --help
```

Los `scenarios` disponibles son `adaptive`, `airt`, `benchmark`, `foundry` y `garak`. <mark style="background: #ADCCFFA6;">`pyrit_shell` es la vía rápida</mark>: permite probar payloads contra el target ya configurado sin montar un script, y es lo que se usa para **verificar a mano** un hallazgo antes de escribirlo.

# El flujo

1. **[[02 - Reconocimiento de aplicaciones LLM|Reconocimiento]] manual** con proxy. Se necesita la petición HTTP real para configurar el `http_target`, y saber dónde vive el guardrail para elegir estrategia.
2. **Barrido con [[00 - Qué es garak y cuándo usarlo|garak]]** para saber qué familias hacen ceder al objetivo. PyRIT sin esa información es caro y a ciegas.
3. **Configurar el target** contra la aplicación real, y un **modelo adversario local** (sin alineamiento fuerte) para generar los ataques.
4. **Validar el scorer** sobre una muestra revisada a mano antes de fiarse de ninguna cifra.
5. **Ataque dirigido** por coste creciente: CCA → Crescendo → PAIR → TAP.
6. **Medir el ASR** con `batch_scorer` sobre repeticiones suficientes.
7. **Exportar de `Memory`** las conversaciones que produjeron los hallazgos, como evidencia.

<mark style="background: #FF5582A6;">El paso 4 es el que más se salta y el que más informes estropea.</mark> Un scorer mal calibrado produce cifras de ASR que no significan nada, y eso se descubre en la reunión de cierre.

# El modelo adversario

Detalle práctico que condiciona todo el montaje: **el LLM que genera los ataques tiene que estar dispuesto a generarlos**. Un modelo comercial alineado se niega a producir prompts de jailbreak, y el ataque no arranca.

Las opciones, por orden de conveniencia:

| Opción | Nota |
| - | - |
| **Modelo open-weights local** (`Ollama`, `vLLM`) sin fine-tuning de seguridad | <mark style="background: #8000E1A6;">La correcta.</mark> Sin coste por token, sin términos de servicio que incumplir, y sin enviar los payloads a un tercero |
| Modelo comercial con acceso de investigación | Requiere acuerdo con el proveedor |
| Modelo comercial jailbreakeado | Frágil y probablemente contra los términos de servicio. Evitar |

Que el adversario sea local tiene además el efecto de OPSEC de [[14 - Detección y evasión en prompt injection|desarrollar fuera del objetivo]]: las decenas de intentos fallidos se quedan en local y contra el cliente solo van los que ya funcionan.

# Alcance y OPSEC

PyRIT es **ruidoso y caro por diseño**. Antes de ejecutar, por escrito:

- **Volumen máximo** de peticiones y ventana horaria. Un TAP puede ser cientos de llamadas.
- **Quién paga los tokens** del objetivo, si es una API de pago del cliente.
- **Categorías de contenido** que se van a probar — PyRIT genera contenido dañino de forma deliberada ([[08 - Fundamentos del jailbreaking#Consideraciones legales y de alcance|criterio de alcance]]).
- **Aviso al SOC** con la IP de origen. Una ráfaga de rechazos de guardrail es exactamente lo que dispara un incidente.

Y sobre la base de datos de `Memory`: contiene todos los payloads y todo el contenido dañino generado. Se trata como evidencia — cifrada, con retención acotada y destruida al cierre.

# Qué se entrega

Lo que hace valioso el uso de PyRIT en un informe no es "hemos usado PyRIT", sino tres cosas concretas:

| Entregable | Por qué importa |
| - | - |
| **ASR por técnica**, con número de repeticiones | Convierte "el modelo es vulnerable" en un riesgo cuantificado y priorizable |
| **La conversación literal** que produjo el hallazgo | Evidencia reproducible, exportada de `Memory` |
| **Qué técnicas NO funcionaron** | Información de defensa: dice contra qué está cubierto el cliente |

<mark style="background: #FFB86CA6;">La tercera es la que más se olvida y la que más agradece un cliente maduro.</mark> Un informe que dice "Crescendo funciona con ASR 0,7, PAIR con 0,9, y los payloads de un solo turno se bloquean todos" describe la postura de seguridad real; uno que solo lista lo que funcionó, no.

# Frente a las alternativas

| Herramienta | Cuándo | Nota |
| - | - | - |
| [[00 - Qué es garak y cuándo usarlo\|`garak`]] | Barrido inicial, cobertura amplia | Primero, siempre |
| **`PyRIT`** | Ataque dirigido, multi-turno, medición de ASR | Cuando garak indica por dónde |
| `promptfoo` | Regresión en CI para el cliente | Entregable final |
| Manual + [[02 - Interceptación de peticiones\|Burp]] | CCA, lógica de negocio, salida insegura | Nada lo automatiza bien |

El arsenal completo del tema está en [[15 - Arsenal de herramientas para prompt injection]].
