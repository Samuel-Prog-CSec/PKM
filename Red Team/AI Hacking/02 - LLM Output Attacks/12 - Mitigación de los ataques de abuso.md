---
tags:
  - IA/Red-Team
  - IA
  - IA/Generativa
  - Pentesting/Reporting
  - Tipo/Defensa
Descripción: "Ninguna medida de esta nota cierra el problema, por la razón estructural de la nota anterior: un adversario con un modelo propio queda fuera del alcance de cualquier control del…"
Fecha de actualización: 2026-07-28
Nota previa: "[[11 - Evasión de detectores de contenido]]"
Nota siguiente: "[[13 - Safeguards en producción (Model Armor y ShieldGemma)]]"
Area: "[[LLM Output Attacks.base|LLM Output Attacks]]"
---
---

Ninguna medida de esta nota cierra el problema, por la razón estructural de [[10 - Ataques de abuso y desinformación#Por qué es difícil de mitigar|la nota anterior]]: un adversario con un modelo propio queda fuera del alcance de cualquier control del proveedor. Lo que sí se puede hacer es **encarecer el ataque** y **acotar la distribución**. Las medidas se reparten en tres capas, y conviene saber qué se puede esperar de cada una.

# Capa 1 — Safeguards del modelo

Lo que implementa quien crea el modelo, antes de que nadie lo despliegue.

**Antes del despliegue:**

- **Entrenamiento y evaluación adversarial** — exponer el modelo a peticiones de contenido dañino durante el entrenamiento para que aprenda a rechazarlas. Es lo que hace que un modelo actual se niegue a escribir sobre vacunas y autismo.
- **Detección de sesgos** en los datos de entrenamiento, para evitar que el modelo reproduzca prejuicios aprendidos.

**En el despliegue:**

- **Guardrails contextuales** — un modelo adicional que evalúa entrada y salida. [[13 - Safeguards en producción (Model Armor y ShieldGemma)]].
- **Filtrado y moderación de contenido** integrados en la plataforma.

<mark style="background: #FFB8EBA6;">Lo que esta capa consigue de verdad: elevar el listón para el usuario oportunista.</mark> Alguien que prueba a pedir desinformación directamente se topa con un rechazo. Alguien que aplica [[10 - Ataques de abuso y desinformación#Cómo se evade la resistencia|el truco del marcador de posición]] no se topa con nada, porque no hay salida problemática que filtrar.

# Capa 2 — Monitorización del contenido generado

Detectar el contenido dañino cuando circula, no cuando se genera.

## Detección de texto generado por IA

Descrito y matizado en [[11 - Evasión de detectores de contenido#Detectar texto generado por IA no funciona|la nota anterior]]: falsos positivos sesgados y evasión trivial por paráfrasis. **No es un control fiable** y hay que decirlo así al recomendar.

## Marcado de agua estadístico

Más sólido que la detección por inferencia. La idea: durante la generación, sesgar ligeramente las probabilidades de los tokens siguiendo una regla secreta, de forma que el texto resultante contenga una señal estadística verificable a posteriori. El impacto en la calidad es despreciable y es invisible para una persona.

> [!info]+ Fuente
> Trabajo de referencia: [*A Watermark for Large Language Models*, arXiv:2301.10226](https://arxiv.org/abs/2301.10226) (Kirchenbauer et al.).

Sus tres límites, que hay que enunciar juntos:

1. **Requiere que el generador coopere.** Un modelo open-weights ejecutado por el adversario no marca nada.
2. **La paráfrasis lo degrada.** Reescribir el texto con otro modelo destruye buena parte de la señal.
3. **Solo cubre texto largo.** En fragmentos cortos no hay suficientes tokens para que la señal sea estadísticamente significativa.

## Procedencia criptográfica — lo que HTB no cubre

<mark style="background: #8000E1A6;">El enfoque que ha ganado tracción desde 2024 invierte el planteamiento: en lugar de intentar detectar lo sintético, se **firma lo auténtico**.</mark>

El estándar es **C2PA** (`Coalition for Content Provenance and Authenticity`) y su implementación de usuario, las `Content Credentials`: metadatos firmados criptográficamente que acompañan al fichero y registran su origen y su cadena de ediciones, incluida la intervención de herramientas de IA. Está adoptado por fabricantes de cámaras, editores de imagen y varios proveedores de IA generativa.

Frente al marcado de agua tiene una ventaja decisiva y una debilidad conocida:

- **Ventaja**: la firma es verificable, no inferida. No hay falsos positivos ni umbrales que ajustar.
- **Debilidad**: los metadatos se pueden **eliminar**. Una captura de pantalla borra la procedencia. Por eso C2PA no prueba que algo sea sintético — prueba que algo es **auténtico**, y desplaza la carga: la ausencia de credencial se convierte en la señal.

Para un informe, esta distinción importa: recomendar C2PA como control de integridad de los activos propios de la organización es accionable; recomendarlo como detector de contenido ajeno no lo es.

## Fact-checking y detección de desinformación

Verificación contra fuentes, automatizada o humana. Es lo único que ataca el contenido por su **contenido** y no por su origen. Y es la capa que peor escala: la generación es instantánea y la verificación no.

# Capa 3 — Regulación y alfabetización

- **Políticas y regulación** — legislación contra el abuso y estándares sectoriales. [[14 - Marco regulatorio del contenido generado por IA]].
- **Alfabetización mediática** — enseñar a reconocer desinformación y fraude generado por IA.
- **Campañas de concienciación** sobre qué pueden y qué no pueden hacer los modelos.
- **Fomento del pensamiento crítico** y hábitos de verificación.

Suena a relleno de informe, pero hay un punto concreto y accionable para cualquier organización, ya señalado en [[10 - Ataques de abuso y desinformación#Amenazas cibernéticas y fraude|la nota de abuso]]: <mark style="background: #FF5582A6;">la formación en phishing basada en "busca faltas de ortografía y frases raras" está obsoleta y hay que reescribirla.</mark> El indicador ya no existe, y seguir enseñándolo es peor que no enseñar nada — genera una falsa sensación de capacidad de detección.

Lo que sustituye a ese indicador son controles que no dependen de juzgar un texto:

- **Verificación fuera de banda** obligatoria para cualquier operación económica o cambio de datos bancarios, por un canal distinto al que llegó la petición.
- **Autenticación del remitente** (SPF, DKIM, DMARC en `reject`) y marcado visible del correo externo.
- **Procedimientos que no admitan urgencia como excusa** para saltarse un paso.
- **MFA resistente a phishing** (FIDO2/passkeys) en lugar de OTP, que sí se puede pedir por teléfono con un pretexto perfecto.

# Cómo valorar el conjunto

| Medida | Contra un oportunista | Contra un adversario con recursos |
| - | - | - |
| Entrenamiento adversarial | Efectiva | Sin efecto (usa modelo propio) |
| Guardrails de contenido | Efectiva | Evadible ([[11 - Evasión de detectores de contenido]]) |
| Detección de texto IA | Poco fiable | Sin efecto |
| Marcado de agua | Efectiva si el generador coopera | Sin efecto |
| Procedencia C2PA | Efectiva para autenticar lo propio | No detecta lo sintético |
| Fact-checking humano | Efectiva pero lenta | Efectiva pero lenta |
| Controles de proceso (verificación fuera de banda) | Efectiva | **Efectiva** |

<mark style="background: #FFB86CA6;">La única fila que resiste en las dos columnas es la última</mark>, y no es una medida de IA: son controles de proceso que no dependen de detectar nada. Es la conclusión que conviene llevarse — y la que hay que poner en la recomendación cuando un cliente pregunta cómo protegerse de la desinformación generada por IA.
