---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
  - IA/Adversarial
  - Tipo/Defensa
Descripción: "El epsilon overfitting y cómo evitarlo muestreando el presupuesto, cómo se lee una tabla de robustez por epsilon y por qué evaluar con FGSM e I-FGSM no basta"
Fecha de actualización: 2026-07-29
Nota previa: "[[06 - Entrenamiento adversarial y el problema min-max]]"
Nota siguiente: "[[08 - Adversarial tuning con LoRA para seguridad]]"
Area: "[[Defensa de IA.base|Defensa de IA]]"
---
---

Entrenar siempre con el mismo $\epsilon$ tiene un fallo específico: <mark style="background: #ADCCFFA6;">el modelo se vuelve robusto **en ese valor concreto** y se desmorona en otros. Es el `epsilon overfitting`.</mark> La corrección es muestrear el presupuesto durante el entrenamiento.

```pseudocode
para cada lote (imagenes, etiquetas):
    1. batch_epsilon = random_choice([0.1, 0.2, ..., 1.0])   # <-- epsilon distinto por lote
    2. adv = FGSM(modelo, imagenes, etiquetas, batch_epsilon)
    3. ... entrenamiento combinado como antes ...
```

Los lotes de $\epsilon$ bajo enseñan precisión ante perturbaciones sutiles; los de $\epsilon$ alto, resistencia a ataques severos. El modelo aprende que la entrada puede venir perturbada **en cualquier magnitud** y debe clasificarla igual.

| $\epsilon$ | Entrenado en $\epsilon$ único | Entrenado con *spread* |
| - | - | - |
| 0,3 | 98 % | 98 % |
| 0,5 | 91 % | **95 %** |
| 0,7 | 75 % | **87 %** |
| 1,0 | 33 % | **66 %** |

Ambos empatan en el $\epsilon$ de entrenamiento (0,3) y divergen fuera. <mark style="background: #8000E1A6;">El valor del *spread* no es mejorar el punto medido, sino **impedir que la métrica mienta** sobre lo que pasa alrededor.</mark>

# Cómo se lee una tabla de robustez

El evaluador del laboratorio produce, para cada modelo, precisión y tasa de éxito del ataque a lo largo del espectro de $\epsilon$. Comparando línea base, entrenamiento a $\epsilon$ único y *spread*, con **FGSM** e **I-FGSM**:

| $\epsilon$ | Base FGSM | Base I-FGSM | Único FGSM | Único I-FGSM | Spread FGSM | Spread I-FGSM |
| - | - | - | - | - | - | - |
| 0,1 | 95,2 % | 94,2 % | 99,0 % | 98,8 % | 98,4 % | 98,4 % |
| **0,3** | **73,8 %** | **52,0 %** | 97,0 % | 97,2 % | 97,6 % | 97,6 % |
| 0,5 | 40,4 % | 9,0 % | 93,2 % | 92,2 % | 95,8 % | 95,6 % |
| 0,7 | 16,4 % | 0,6 % | 76,2 % | 71,8 % | 93,6 % | 93,0 % |
| 1,0 | 7,0 % | **0,0 %** | 36,8 % | 24,8 % | 76,6 % | 77,0 % |

Tres lecturas:

**1. Los ataques iterativos son mucho peores que los de un paso.** Contra el modelo sin defensa, FGSM sube gradualmente mientras I-FGSM se dispara: 48 % de éxito en $\epsilon=0{,}3$, 91 % en 0,5 y **100 % en 1,0**. Si se evalúa solo con FGSM, el modelo parece cuatro veces más robusto de lo que es. <mark style="background: #FF5582A6;">Evaluar con el ataque más débil disponible es la forma más común de publicar robustez falsa.</mark>

**2. El modelo de $\epsilon$ único se derrumba fuera de su punto.** 97 % en 0,3 y 36,8 % en 1,0 (24,8 % con I-FGSM): es exactamente el `epsilon overfitting`, y sería invisible en un informe que reportase solo el valor de entrenamiento.

**3. La lectura del atacante y la del defensor son la misma tabla.** El evaluador imprime las dos porque `éxito del ataque = 100 % − precisión`. Es útil en un informe: el cliente lee precisión, el equipo de seguridad lee tasa de éxito.

## Patrones de diagnóstico

- **Caída abrupta en un $\epsilon$ concreto** (95 % en 0,3 y 60 % en 0,4) → `epsilon overfitting`. Solución: *spread*.
- **I-FGSM 3-5 puntos por debajo de FGSM** → normal, los iterativos encuentran mejores ejemplos.
- **Diferencia mayor de 10 puntos entre FGSM e I-FGSM** → sospechar que la defensa se apoya en artefactos del ataque de un paso, es decir, [[06 - Entrenamiento adversarial y el problema min-max#El error de usar solo FGSM en el bucle interno|enmascaramiento de gradiente]].
- **Precisión limpia muy por debajo de la línea base** (<95 %) → entrenamiento insuficiente sobre ejemplos limpios; bajar el $\epsilon$ de entrenamiento, subir la proporción limpia o añadir épocas.
- **Precisión robusta <90 %** → $\epsilon$ de entrenamiento demasiado bajo, pocas épocas, o el bucle está reutilizando ejemplos adversariales rancios en vez de generarlos frescos cada lote.

El análisis de fallos concretos completa el cuadro: los pares confundidos bajo ataque son los que comparten rasgos (3/8, 4/9, 7/1), y las clasificaciones erróneas **con alta confianza** (un 9 predicho como 4 con 0,91) indican que el ejemplo adversarial no rozó la frontera sino que entró a fondo en la región equivocada.

# Dos advertencias sobre esta evaluación

> [!warning]+ $\epsilon = 1{,}0$ en $[0,1]$ no mide robustez
> Con píxeles en `[0,1]` y $\epsilon = 1{,}0$, FGSM lleva **cada píxel** a 0 o a 1 según el signo del gradiente. La imagen original queda destruida: lo que se clasifica es el patrón binario del signo del gradiente, no un dígito perturbado. <mark style="background: #FFB86CA6;">Que un modelo acierte el 76,6 % ahí no es robustez, es que el patrón de signos sigue correlacionando con la clase</mark> — el propio ataque filtra información de la entrada. El rango con significado en MNIST llega hasta $\epsilon \approx 0{,}3$-$0{,}4$; por encima, la comparación entre modelos deja de ser interpretable. Un informe que presuma de robustez a $\epsilon=1{,}0$ está midiendo un artefacto.

> [!warning]+ FGSM e I-FGSM no son un protocolo de evaluación suficiente
> Son los dos ataques que se acaban de enseñar, y evaluar una defensa con los ataques contra los que se entrenó es circular. El estándar de la comunidad es **`AutoAttack`** —ensemble de APGD-CE, APGD-DLR, FAB y Square, sin hiperparámetros que ajustar— precisamente porque muchas defensas publicadas se rompieron al reevaluarse con ataques adaptativos. La regla, desarrollada en [[04 - Detección y defensa contra la evasión|detección y defensa]] y en [[05 - Arsenal para la evasión de modelos|el arsenal de evasión]]: <mark style="background: #FFB8EBA6;">una defensa vale lo que vale el protocolo que la evalúa.</mark>
>
> Y hay que añadir una pasada de **norma distinta**: `AutoAttack` cubre $L_\infty$ y $L_2$, no $L_0$. Un modelo entrenado y evaluado solo en $L_\infty$ puede caer con [[08 - JSMA por pares, saliencia conjunta y poda|40 píxeles saturados]].

# El protocolo que sí se sostiene

1. **Entrenar con PGD** (o FGSM con inicialización aleatoria), no con FGSM puro.
2. **Muestrear $\epsilon$** durante el entrenamiento, dentro del rango con significado para el dominio.
3. **Evaluar con `AutoAttack`** en la norma de entrenamiento, y con una pasada específica en las normas que el modelo de amenaza real contemple ($L_0$ si el dominio es discreto).
4. **Reportar la curva completa** precisión-vs-$\epsilon$, no un único punto.
5. **Reportar también la precisión limpia**: una defensa que cuesta 20 puntos limpios puede ser inaceptable para el producto aunque su robustez sea excelente.
6. **Comparar contra [RobustBench](https://robustbench.github.io/)** para saber si el resultado está en el estado del arte o dos años por detrás.

> [!important]+ Erratas del módulo
> Las cifras del ataque contra el modelo sin defensa aparecen con tres valores distintos: la introducción dice que la precisión cae "a aproximadamente el 74 %" con FGSM y "alrededor del 52 %" con I-FGSM (coherente con el evaluador: 73,8 % y 52,0 %), pero la sección de compromiso afirma que el mismo clasificador "colapsa a alrededor del 5 % bajo ataque FGSM". Mismo patrón de inconsistencias numéricas que en [[04 - Ejecución y evaluación del MIA#Erratas del módulo|el módulo de privacidad]] y en el de ataques dispersos: **reproducir antes de citar**.
