---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
  - Introduccion
  - Tipo/Introduccion
Descripción: "Los ataques dispersos cambian pocas features en vez de todas un poco: el presupuesto es L0 (cuántas), no la magnitud, y eso cambia matemática, amenaza y defensas"
Fecha de actualización: 2026-07-29
Nota previa: 
Nota siguiente: "[[01 - ElasticNet (EAD) y la mezcla L1 + L2]]"
Area: "[[Ataques dispersos.base|Ataques dispersos]]"
---
---

<mark style="background: #ADCCFFA6;">Un ataque disperso busca la clasificación errónea cambiando **el menor número posible de dimensiones** de la entrada, sin importar cuánto cambia cada una.</mark> El presupuesto se mide con la pseudo-norma $L_0$, que cuenta coordenadas distintas entre la entrada adversarial y la original:

$$\lVert x_{adv} - x \rVert_0 = \left|\{\, i \mid (x_{adv})_i \ne x_i \,\}\right|$$

Es el giro respecto a los [[00 - Ataques de primer orden y el papel del gradiente|ataques de primer orden]]: allí la restricción era el **tamaño** de cada cambio ($L_\infty$, $L_2$); aquí es el **número** de cambios. La [[01 - Normas Lp y el presupuesto de perturbación|nota de normas]] ya sitúa $L_0$ dentro de la familia $L_p$; lo que sigue es por qué esa elección concreta reordena todo lo demás.

# $L_0$ no es una norma, y ahí empieza el problema

Técnicamente $L_0$ es una **pseudo-norma**: incumple la homogeneidad ($\lVert 2\delta \rVert_0 = \lVert \delta \rVert_0$, duplicar la perturbación no duplica la medida). Esa propiedad, que suena a tecnicismo, tiene tres consecuencias operativas duras:

- **Es discontinua.** Pasar de $\delta_i = 0$ a $\delta_i = 10^{-9}$ salta de 0 a 1 en la cuenta. No hay gradiente que seguir.
- **Es no convexa.** No hay garantía de que el óptimo local sea global.
- **Su optimización exacta es combinatoria.** Elegir qué 20 píxeles de una imagen MNIST tocar son $\binom{784}{20} \approx 10^{39}$ combinaciones. <mark style="background: #FF5582A6;">La búsqueda exhaustiva no es lenta: es imposible.</mark>

De ahí que no exista "el" ataque $L_0$ sino familias de aproximaciones, cada una atacando el problema por un lado distinto.

# Por qué el presupuesto realista suele ser $L_0$

En el lab, el modelo de amenaza $L_\infty$ es cómodo: se asume que el atacante puede tocar cada valor de entrada un poquito. <mark style="background: #FFB86CA6;">En sistemas reales el atacante casi nunca controla todas las dimensiones, y las que controla suelen ser discretas.</mark> Casos donde $L_0$ es la restricción natural, no una elección estética:

| Dominio | Por qué el presupuesto es $L_0$ |
| - | - |
| Detección de malware por features | Solo se pueden añadir/quitar imports, secciones o cadenas concretas; no existe "el 3% de una API importada" |
| NLP / clasificadores de texto | La unidad mínima es el token: sustituir 2 palabras es $L_0 = 2$; no hay medias palabras |
| Tráfico de red / logs | Se controlan campos concretos del paquete o del evento, no un desplazamiento continuo del vector |
| Ataques físicos | Una pegatina, un parche impreso o unos píxeles muertos afectan a una región acotada, con magnitud libre dentro de ella |
| Firmware / *bit flips* | El ataque literalmente voltea $k$ bits (Rowhammer y familia); la magnitud por bit no es negociable |

Esto conecta con el [[08 - Límites y evasión de los detectores ML|problem-space vs feature-space]]: un ataque que perturba 784 valores continuos en un vector de features de malware puede ser matemáticamente válido y a la vez **irrealizable** sobre el binario. Un ataque disperso que cambia 6 features es, con mucha más frecuencia, materializable.

# Modelo de amenaza y presupuestos secundarios

Se asume un atacante en **tiempo de inferencia** —el modelo ya está entrenado y desplegado; esto no es [[01 - Taxonomía de los ataques a los datos|envenenamiento]]—, con dos variantes:

- **Caja blanca**: se calculan derivadas a través del modelo y se usan para decidir qué features tocar. Es lo que hacen EAD y JSMA.
- **Caja negra**: se estiman puntuaciones de importancia por consulta, o se transfieren patrones dispersos desde un modelo sustituto. La lógica es la misma que en [[03 - GoodWords en caja negra con bandits|GoodWords con bandits]]: sin gradiente, se compra información con consultas.

El presupuesto principal es $L_0$, pero rara vez va solo. Se añaden **límites auxiliares** en $L_2$ o $L_\infty$ para que los cambios sigan siendo válidos y no descaradamente visibles, más las restricciones de caja del dominio (píxeles en `[0,1]`). 

> [!important]+ Las restricciones de caja no son un detalle de implementación
> Un píxel que alcanza 0.0 o 1.0 queda **saturado**: no admite más cambio en esa dirección y desperdiciar iteraciones sobre él es el bug más común de estos ataques. Tanto EAD (vía *clipping* en el operador proximal) como JSMA (vía máscara del espacio de búsqueda) dedican código explícito a retirarlos. Si además el modelo normaliza la entrada con $\hat{x} = (x - \mu)/\sigma$, el gradiente atraviesa esa capa por la regla de la cadena, así que **razonar en espacio de píxel sigue siendo correcto** mientras se respeten los límites del dominio original.

# Dos caminos hacia la dispersión

Como $L_0$ es inoptimizable de frente, los dos ataques del tema atacan flancos opuestos:

**1. Relajación convexa — [[01 - ElasticNet (EAD) y la mezcla L1 + L2|ElasticNet (EAD)]].** En lugar de contar coordenadas, se penaliza la suma de sus magnitudes con $L_1$. No es una sustitución arbitraria: <mark style="background: #FFB8EBA6;">$\lVert x \rVert_1$ es la **envolvente convexa** de $\lVert x \rVert_0$ sobre la bola unidad $L_\infty$</mark> —la función convexa más grande que queda por debajo de $L_0$ en $\{x : \lVert x \rVert_\infty \le 1\}$—, es decir, la mejor aproximación convexa posible dentro de las restricciones de caja que el dominio ya impone.

Geométricamente, la bola $L_1$ es un politopo con vértices **sobre los ejes** (en 2D, el rombo de la [[01 - Normas Lp y el presupuesto de perturbación|metáfora de la distancia Manhattan]]): al optimizar contra esa geometría, la solución tiende a caer en esos vértices, donde la mayoría de coordenadas valen **exactamente cero**. Es el mismo mecanismo por el que LASSO selecciona variables en regresión y por el que Ridge ($L_2$, bola esférica y sin esquinas) no lo hace. La ventaja es que el problema queda continuo y se puede optimizar con herramientas de análisis convexo; el precio es que $L_0$ solo se controla de forma **indirecta**, mediante un parámetro $\beta$ que no dice cuántas coordenadas van a sobrevivir.

**2. Selección combinatoria voraz — [[06 - JSMA, el Jacobiano y los mapas de saliencia|JSMA]].** Aceptar que el problema es combinatorio y resolverlo *greedy*: en cada iteración, puntuar todas las features con un mapa de saliencia derivado del Jacobiano, modificar la mejor (o el mejor par), y repetir hasta lograr la clasificación errónea o agotar el presupuesto. Aquí el control de $L_0$ es **explícito y duro** —se cuenta cada feature tocada—, a cambio de no tener ninguna garantía de optimalidad.

<mark style="background: #8000E1A6;">La diferencia práctica es dónde vive el presupuesto: en EAD es un parámetro que empuja hacia la dispersión; en JSMA es un contador que la impone.</mark>

# Lo que la dispersión compra y lo que cuesta

El intercambio no es "mejor" ni "peor" que $L_\infty$: es **otro perfil de detectabilidad**.

- **Lo que compra**: perturbaciones que atraviesan defensas calibradas sobre estadísticos **globales** de ruido (varianza de la imagen, entropía, distancia media al vecino) porque el 95% de la entrada sigue siendo bit a bit idéntico. Y, en el lado defensivo, interpretabilidad: las features que el ataque elige son literalmente las que el modelo considera decisivas.
- **Lo que cuesta**: <mark style="background: #FFB8EBA6;">disperso no significa imperceptible.</mark> JSMA con paso $\theta = 1{,}0$ satura píxeles de negro a blanco: para un humano son puntos o trazos evidentes. Se cambia sigilo frente al **ojo** por sigilo frente al **detector estadístico** — decisión que depende por completo de quién sea el verificador en el sistema atacado.

# El punto que importa para el reporting

Hay una afirmación que aparece constantemente en informes de robustez y que estos ataques desmontan: <mark style="background: #FF5582A6;">un modelo endurecido con entrenamiento adversarial $L_\infty$ (el estándar de facto, PGD-AT) **no** hereda robustez frente a ataques $L_0$.</mark> Las defensas son específicas de la norma para la que se entrenaron, y la mayoría de *leaderboards* públicos —[RobustBench](https://robustbench.github.io/) incluido— reportan $L_\infty$ y $L_2$. Un cliente que dice "nuestro modelo es robusto" casi siempre quiere decir "contra $L_\infty$ con $\epsilon$ concreto".

Certificar frente a $L_0$ requiere maquinaria distinta: la línea dominante es la **ablación aleatoria** de Levine y Feizi ([arXiv:1911.09272](https://arxiv.org/abs/1911.09272), AAAI 2020), que en vez de añadir ruido **borra** features al azar y clasifica por mayoría, obteniendo certificados del tipo "ninguna alteración de $\le 8$ píxeles cambia esta predicción". El detalle completo, junto con las defensas empíricas, está en [[04 - Detección y defensa contra la evasión|detección y defensa contra la evasión]], que cubre las tres carpetas de evasión del vault.

> [!info]+ Recorrido del tema
> Las notas siguientes desarrollan EAD (relajación $L_1$ + optimización proximal con FISTA) y JSMA (saliencia sobre el Jacobiano, variantes de un píxel y por pares), y cierran comparando ambos con el estado del arte actual en [[09 - EAD frente a JSMA y el estado del arte en ataques L0|ataques $L_0$ modernos]]. Las herramientas viven en [[05 - Arsenal para la evasión de modelos|el arsenal común de evasión]].
