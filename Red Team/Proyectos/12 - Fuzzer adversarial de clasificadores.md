---
tags:
  - Proyectos
  - Go
  - IA/Red-Team
  - IA/Adversarial
  - Tipo/Proyecto
Descripción: "Evalúa la robustez de un clasificador ML tratándolo como caja negra remota con coste por consulta, y reporta cuánto cuesta evadirlo en consultas y perturbación"
Fecha de actualización: 2026-08-04
Nota previa: "[[11 - Auditor de visibilidad de EDR]]"
Nota siguiente: "[[13 - Explotador de condiciones de carrera]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 5
Esfuerzo: 5-6 semanas
---
---

**Nombre propuesto**: `perturbo`

Un clasificador de ML en producción —el que decide si un correo es *phishing*, si una transacción es fraude, si un fichero es malicioso— es una defensa como cualquier otra, y como cualquier defensa se puede evaluar. La pregunta que un cliente que despliega uno debería poder responder es directa: <mark style="background: #FFB86CA6;">¿cuánto cuesta evadirlo?</mark>. La literatura responde a eso en un laboratorio con acceso total al modelo; en un engagement real, el clasificador es una API remota que devuelve un veredicto, cobra por consulta y registra quién pregunta.

# El problema que resuelve

Los ataques adversariales de caja negra están resueltos en la teoría —Square Attack, Sparse-RS, HopSkipJump— y empaquetados en librerías de investigación como ART, Foolbox o AutoAttack. Pero todas asumen el escenario de laboratorio: <mark style="background: #ADCCFFA6;">el modelo local, en tu GPU, consultable millones de veces gratis</mark>. El escenario de auditoría es el opuesto: una API que devuelve una etiqueta o un *score*, donde cada consulta cuesta dinero, hay *rate-limiting*, y mil peticiones por segundo disparan una alerta.

Ahí <mark style="background: #8000E1A6;">el presupuesto de consultas deja de ser una métrica secundaria y pasa a definir si el ataque es siquiera viable</mark>. Un método que evade en diez millones de consultas es un resultado de paper; contra una API con límite de tasa es irrelevante. Uno que evade en quinientas es un hallazgo de informe.

# Alcance del proyecto

Una herramienta que evalúa la robustez de un clasificador tratándolo como lo que es en un engagement: una **caja negra remota con coste por consulta**. Materializa como instrumento operativo los ataques que el vault ya cubre en teoría. Piezas:

- **Adaptadores de oráculo.** El objetivo se define por su interfaz —una API que devuelve etiqueta, *score* o *top-k*—, no por acceso al modelo. Cambiar de objetivo es cambiar de adaptador, no de ataque.
- **Motor de ataque *black-box*.** *Score-based* (Square Attack) y *decision-based* (HopSkipJump) para el caso denso; *sparse* (Sparse-RS) para el caso L0. Sin *substitute model* y sin gradientes: solo lo que el oráculo devuelve.
- **Gestor de presupuesto.** Cada evaluación lleva un techo de consultas y una cadencia. <mark style="background: #FF5582A6;">El objetivo que optimiza no es la tasa de éxito ideal, sino minimizar consultas</mark> — porque eso es lo que decide la viabilidad real.
- **Informe de robustez operativa.** El resultado se expresa en la métrica que un cliente entiende: "se evade en *N* consultas con una perturbación de tamaño ε bajo la norma L*p*", no en un número de *benchmark* académico.

# Funcionalidades principales

| Funcionalidad | Por qué importa |
| --- | --- |
| Oráculo por API, no por modelo | Refleja el acceso real de una auditoría; nunca asume el modelo en local |
| Ataque optimizado por consultas | La métrica que gobierna es el presupuesto, no el éxito en infinitas iteraciones |
| Modo denso y modo *sparse* | L∞/L2 para perturbación imperceptible; L0 para cambiar pocos elementos de la entrada |
| Cadencia configurable | El barrido adversarial es visible; la velocidad es un parámetro, no un valor fijo |
| Reanudable | Un presupuesto de miles de consultas se gasta en tandas; el estado persiste entre ellas |
| Respeto del espacio de entrada | El ejemplo generado sigue siendo válido en su dominio (un correo bien formado, una imagen en rango) |

# Qué existe ya y dónde se queda corto

**ART** (el *Adversarial Robustness Toolbox*), **Foolbox** y **AutoAttack** son librerías excelentes y son el estándar de facto para evaluar robustez —Square Attack, de hecho, forma parte de AutoAttack—. Pero están construidas para el *benchmarking* académico con el modelo local y consultas ilimitadas. <mark style="background: #FFB8EBA6;">El hueco es trasladar eso al engagement</mark>: un binario único, en Go, que trata al clasificador como una API remota con presupuesto y límite de tasa, reanudable, y que reporta en lenguaje de cliente. Es AutoAttack reescrito para el pentester en vez de para el *paper* —el mismo traslado del laboratorio al mundo real que hace el `farside` (10) con el catálogo de SSRF—.

# Cosas a tener en cuenta

> [!warning]+ Esto evalúa tu clasificador, o el del cliente autorizado
> Consultar masivamente un clasificador ajeno para evadirlo es abuso de un servicio. Hacerlo contra el del cliente, con un presupuesto de consultas acordado por escrito, es una auditoría de robustez. <mark style="background: #FF5582A6;">El enmarque y la autorización son lo que separa una cosa de la otra</mark>, y la herramienta debe pedir el objetivo y su alcance de forma explícita, no facilitar apuntarla a cualquier API.

- **Cada consulta deja rastro.** El clasificador del cliente registra las peticiones, y un barrido adversarial es perfectamente visible en sus logs. La cadencia tiene que ser un parámetro de primera clase y el informe debe reconocer la huella que ha generado —el mismo criterio de sigilo que el resto del catálogo—.
- **El dominio manda sobre el ataque.** Un clasificador de imágenes admite perturbaciones L∞ imperceptibles; uno de texto o de ficheros tiene restricciones de validez —el ejemplo tiene que seguir siendo un correo que parsea, un documento que abre— que un ataque pensado para imágenes ignora. El motor debe operar en el espacio de entrada real del dominio, no en un tensor abstracto.
- **La transferibilidad es una trampa.** Un ejemplo que evade un *substitute* entrenado por ti puede no evadir el objetivo real. Por eso el ataque es *query-based* contra el oráculo verdadero, no *transfer-based* contra una copia que quizá no se le parece.
- **Doble uso limpio y vendible.** El mismo informe le dice al equipo que entrena el clasificador dónde está su margen de robustez y cuánto sube con entrenamiento adversarial. Es el cierre natural con la cara defensiva de [[04 - Detección y defensa contra la evasión]].

# Fuera de alcance

No entrena *substitute models* ni asume acceso al modelo. No es una librería de investigación ni compite con ART en amplitud de algoritmos: implementa los pocos que importan en el escenario remoto. No extrae ni roba el modelo, ni envenena sus datos —esos son otros ataques y otras notas del área—.

# Criterio de terminado

Cuando, contra un clasificador propio expuesto por API con límite de tasa, evade una fracción configurable de las entradas dentro de un presupuesto de consultas dado, reporta la perturbación media necesaria por norma, y respeta la cadencia sin dispararse por encima del límite acordado.

# Conexiones en el vault

El marco conceptual es [[00 - Fundamentos de la evasión de modelos]], y el principio operativo —caja negra igual a exploración con presupuesto de consultas— es exactamente el de [[03 - GoodWords en caja negra con bandits]]. El ε que reporta se define en [[01 - Normas Lp y el presupuesto de perturbación]]; el gradiente que `perturbo` **no** tiene, en [[00 - Ataques de primer orden y el papel del gradiente]]; y el modo disperso, en [[00 - Fundamentos de los ataques dispersos y la norma L0]]. La cara defensiva cierra en [[04 - Detección y defensa contra la evasión]] y el resto de utillaje en [[05 - Arsenal para la evasión de modelos]].

> [!info]+ Fuentes
> - Andriushchenko et al., [*Square Attack — a query-efficient black-box adversarial attack via random search*](https://arxiv.org/abs/1912.00049), ECCV 2020 — ataque *score-based* sin gradientes, hoy parte de AutoAttack (consultado 2026-08-04).
> - Croce et al., [*Sparse-RS — a versatile framework for query-efficient sparse black-box adversarial attacks*](https://arxiv.org/pdf/2006.12834), AAAI 2022 — el caso L0 sin *substitute model*.
> - Chen, Jordan & Wainwright, [*HopSkipJumpAttack — a query-efficient decision-based attack*](https://arxiv.org/abs/1904.02144), IEEE S&P 2020 — el escenario en el que solo se obtiene la etiqueta, no el *score*.
> - [`Trusted-AI/adversarial-robustness-toolbox`](https://github.com/Trusted-AI/adversarial-robustness-toolbox) — la referencia de la que `perturbo` toma los algoritmos y de la que se separa por el escenario remoto.
