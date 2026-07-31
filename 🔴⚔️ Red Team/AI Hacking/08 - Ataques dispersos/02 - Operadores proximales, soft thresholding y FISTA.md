---
tags:
  - IA/Red-Team
  - IA
  - IA/Adversarial
  - Pentesting/Explotacion
Descripción: "La maquinaria que hace que L1 produzca ceros exactos sin gradiente: el operador proximal, su forma cerrada para L1 (soft thresholding) y la aceleración de Nesterov que da FISTA"
Fecha de actualización: 2026-07-29
Nota previa: "[[01 - ElasticNet (EAD) y la mezcla L1 + L2]]"
Nota siguiente: "[[03 - El objetivo de EAD, margen C&W y binary search]]"
Area: "[[Ataques dispersos.base|Ataques dispersos]]"
---
---

[[02 - FGSM, el ataque de un solo paso|FGSM]] tiene solución cerrada: un gradiente, un `sign`, listo. [[04 - DeepFool y la perturbación mínima|DeepFool]] resuelve proyecciones lineales con fórmula. <mark style="background: #ADCCFFA6;">El objetivo mixto de EAD no admite ninguna de las dos cosas, porque el término $L_1$ no es diferenciable justo donde nace la dispersión.</mark> `FISTA` (*Fast Iterative Shrinkage-Thresholding Algorithm*) es la herramienta que resuelve ese tipo de problema: descompone el objetivo en una parte suave y otra no suave, trata cada una con lo que le corresponde, y acelera con momento de Nesterov.

> [!info]+ Fuente primaria
> [*A Fast Iterative Shrinkage-Thresholding Algorithm for Linear Inverse Problems*](https://epubs.siam.org/doi/10.1137/080716542) — Beck y Teboulle, *SIAM Journal on Imaging Sciences* 2(1), 2009. FISTA no nació para ML adversarial sino para reconstrucción de imagen; EAD lo importa tal cual.

# El operador proximal: proyectar, pero con penalización

La proyección ya aparecía en los ataques anteriores: FGSM proyecta sobre la bola $L_\infty$, [[03 - I-FGSM, PGD y el refinamiento iterativo|PGD]] reproyecta tras cada paso. La proyección responde a *"¿cuál es el punto más cercano dentro del conjunto $C$?"*. El operador proximal generaliza esa pregunta a *"¿qué punto minimiza la distancia a donde estoy **más** una penalización?"*:

$$\text{prox}_{\lambda h}(z) = \arg\min_x \left\{ \tfrac{1}{2}\lVert x - z \rVert_2^2 + \lambda h(x) \right\}$$

Dos fuerzas en tensión: el primer término tira hacia $z$ (quédate cerca de donde estás), el segundo tira hacia donde $h$ sea pequeña. El minimizador equilibra ambas. <mark style="background: #8000E1A6;">Según qué sea $h$, se recupera un objeto conocido u otro:</mark>

| $h$ | $\text{prox}_{\lambda h}$ resultante |
| - | - |
| Función indicadora de un conjunto ($0$ dentro, $\infty$ fuera) | La **proyección** ordinaria |
| Diferenciable, p. ej. $\lVert x \rVert_2^2$ | Forma cerrada equivalente a un paso de gradiente |
| **No suave**, p. ej. $\lVert x \rVert_1$ | Una operación bien definida que **sustituye** al gradiente inexistente |

La última fila es la que importa: el operador proximal es lo que permite optimizar $L_1$ sin necesitar su derivada.

# Soft thresholding: la forma cerrada de $L_1$

Para $h(x) = \lVert x \rVert_1$ el operador proximal tiene una forma elegante y **elemento a elemento**:

$$\mathcal{S}_\lambda(z)_i = \begin{cases} z_i - \lambda & \text{si } z_i > \lambda \\ 0 & \text{si } |z_i| \le \lambda \\ z_i + \lambda & \text{si } z_i < -\lambda \end{cases}$$

Tres regiones, tres acciones. Con $\lambda = 0{,}1$ y $z = [0{,}12,\; 0{,}08,\; -0{,}25]$ sale $\mathcal{S}_{0,1}(z) = [0{,}02,\; 0{,}0,\; -0{,}15]$: el primero sobrevive encogido, el segundo **muere**, el tercero sobrevive encogido por el otro lado.

El nombre distingue esta operación del *hard thresholding*, que anularía los valores pequeños dejando los grandes intactos. Aquí no: los supervivientes también pagan peaje de $\lambda$. La imagen mental es tijeras (duro) frente a apretar gradualmente (blando).

## Por qué funciona

Basta mirar una coordenada. Se busca el $x_i$ que minimiza $\tfrac{1}{2}(x_i - z_i)^2 + \lambda |x_i|$: una parábola que tira hacia $z_i$ contra un valor absoluto que tira hacia cero. Separando por casos:

- **$z_i > \lambda$**: suponiendo $x_i > 0$, $|x_i| = x_i$; derivando e igualando a cero, $x_i - z_i + \lambda = 0 \Rightarrow x_i = z_i - \lambda$.
- **$z_i < -\lambda$**: simétrico, $x_i = z_i + \lambda$.
- **$|z_i| \le \lambda$**: la penalización $L_1$ domina al tirón cuadrático y el mínimo cae **exactamente** en cero.

<mark style="background: #FFB86CA6;">Ese "exactamente" es todo el asunto.</mark> Un descenso de gradiente con regularización $L_1$ deja valores de $10^{-4}$ que cuentan como no nulos en $L_0$; el soft thresholding produce ceros de verdad.

## Separabilidad: por qué se puede hacer coordenada a coordenada

Tanto $\lVert x \rVert_1 = \sum_i |x_i|$ como $\lVert x \rVert_2^2 = \sum_i x_i^2$ se descomponen en sumas de términos independientes. El problema proximal multidimensional se parte por tanto en $n$ problemas unidimensionales que no se hablan entre sí — de ahí que la operación sea trivialmente vectorizable y barata.

<mark style="background: #FFB8EBA6;">Contrasta con el operador proximal de $L_2$ (sin cuadrado):</mark> $\text{prox}_{\lambda h}(z) = \max(0,\, 1 - \lambda/\lVert z \rVert_2) \cdot z$, que escala el vector **entero** como una unidad. Encoge, pero no crea dispersión: o todas las coordenadas sobreviven o ninguna. Es la razón matemática de que $L_2$ nunca produzca ceros y $L_1$ sí.

# De proximal a FISTA

El **método de gradiente proximal** resuelve $\min_x \{f(x) + h(x)\}$ con $f$ suave y $h$ no, alternando las dos herramientas:

$$x^{(k+1)} = \text{prox}_{\eta h}\!\left( x^{(k)} - \eta \nabla f(x^{(k)}) \right)$$

Un paso de gradiente sobre lo suave, un paso proximal sobre lo que no lo es. Converge, pero a ritmo $O(1/k)$ — lento para precisión alta.

FISTA lo acelera con **momento de Nesterov**: en vez de evaluar el gradiente en el punto actual $x^{(k)}$, lo evalúa en un punto **extrapolado** $y^{(k)}$ que anticipa hacia dónde va la optimización.

$$x^{(k+1)} = \text{prox}_{\eta h}\!\left( y^{(k)} - \eta \nabla f(y^{(k)}) \right)$$
$$t_{k+1} = \frac{1 + \sqrt{1 + 4t_k^2}}{2}, \qquad y^{(k+1)} = x^{(k+1)} + \frac{t_k - 1}{t_{k+1}}\left(x^{(k+1)} - x^{(k)}\right)$$

La secuencia $t_k$ (desde $t_0 = 1$) crece con las iteraciones y está elegida para garantizar convergencia $O(1/k^2)$: una mejora cuadrática. La intuición del *look-ahead*: si los últimos pasos apuntan todos en la misma dirección, medir el gradiente un poco más adelante ahorra iteraciones.

## La aproximación $k/(k+3)$

Como $t_k \approx k/2$ para $k$ grande, el coeficiente real $(t_k - 1)/t_{k+1}$ tiende a $(k-2)/(k+1)$. Las implementaciones —la de EAD incluida— suelen usar la aproximación más conservadora $k/(k+3)$:

```python
def compute_fista_momentum(iteration):
    return iteration / (iteration + 3.0)
```

| Iteración | 1 | 5 | 10 | 50 | 100 | 1000 |
| - | - | - | - | - | - | - |
| Momento | 0,250 | 0,625 | 0,769 | 0,943 | 0,971 | 0,997 |

Arranca prudente y se vuelve agresivo. Tiene sentido: al principio la optimización no sabe nada del paisaje y comprometerse con una dirección es tirar cómputo; tras 100 iteraciones con evidencia acumulada, acelerar sale rentable. El `+3` del denominador mantiene el coeficiente por debajo de 1, impidiendo que el momento se coma la señal del gradiente. <mark style="background: #8000E1A6;">Es una ventaja sobre el momento fijo (típicamente 0,9) de los optimizadores habituales: elimina un hiperparámetro, porque el calendario se ajusta solo.</mark>

# Aplicado a EAD

La descomposición del objetivo cae sola:

- **Parte suave** $f(x') = c \cdot \max\big(Z_y(x') - \max_{j \ne y} Z_j(x') + \kappa,\, 0\big) + \lVert x' - x \rVert_2^2$ — pérdida adversarial más energía. Se deriva con `backward()`: la primera parte atraviesa la red entera, la segunda tiene gradiente $2(x' - x)$.
- **Parte no suave** $h(x') = \beta \lVert x' - x \rVert_1$ — se maneja con soft thresholding, **nunca** entra en el cálculo del gradiente.

Como la dispersión se impone sobre la perturbación y no sobre la imagen, el operador se aplica desplazado:

$$\text{prox}_{\eta \beta \lVert \cdot \rVert_1}(z) = x + \mathcal{S}_{\eta\beta}(z - x)$$

Cada iteración de FISTA hace cuatro cosas en orden: gradiente de la parte suave en $y^{(k)}$ → paso con tasa $\eta$ → soft thresholding con umbral $\eta\beta$ → actualización del punto de momento. Se repite entre 100 y 1000 veces.

> [!example]+ Una iteración a mano
> Tras el paso de gradiente, la perturbación candidata es $\delta = [0{,}12,\; -0{,}07]$ con $\beta = 0{,}1$. El soft thresholding devuelve $[0{,}02,\; 0{,}0]$: la primera coordenada sobrevive encogida, la segunda se anula. Con $k = 10$, el momento $10/13 \approx 0{,}769$ extrapola el siguiente punto de evaluación en la dirección del avance reciente.

El efecto acumulado es brutal. Sobre una matriz de prueba de 25 valores con 22 no nulos, aplicar $\beta = 0{,}1$ deja 9 supervivientes: **64 % de dispersión en un solo paso**, y los eliminados son ceros exactos, no residuos de $0{,}001$. El filtrado no es arbitrario: los píxeles con gradiente débil generan perturbaciones pequeñas que consumen presupuesto $L_0$ sin mover la frontera de decisión, y el umbral los descarta automáticamente.

> [!warning]+ La garantía teórica no aplica aquí, y conviene decirlo
> $O(1/k^2)$ exige $\nabla f$ Lipschitz, $h$ convexa y $\eta \le 1/L$. <mark style="background: #FF5582A6;">La pérdida de una red neuronal no es convexa, así que la garantía formalmente no se cumple</mark> — FISTA se usa aquí de forma **heurística**, y funciona bien empíricamente, pero encuentra mínimos locales, no globales. Consecuencia práctica: distintas inicializaciones pueden dar ataques de calidad distinta. EAD lo mitiga arrancando siempre de perturbación cero y dejando que la búsqueda binaria de $c$ actúe como reinicio múltiple con presiones distintas.

Con la maquinaria de optimización clara, falta definir **qué** se optimiza exactamente: la pérdida de margen que fuerza el error de clasificación y el mecanismo que calibra su peso. Eso es [[03 - El objetivo de EAD, margen C&W y binary search|la siguiente nota]].
