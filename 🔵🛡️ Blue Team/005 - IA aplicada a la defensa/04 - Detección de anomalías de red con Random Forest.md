---
tags:
  - Blue-Team
  - IA
  - IA/Defensa
  - Tipo/Deteccion
Descripción: "Segundo caso: clasificar tráfico de red como normal o malicioso usando un Random Forest sobre features tabulares"
Fecha de actualización: 2026-07-28
Nota previa: "[[03 - Entrenamiento y evaluación del clasificador de spam]]"
Nota siguiente: "[[05 - Entrenamiento y evaluación del detector de anomalías]]"
Area: "[[IA defensiva.base|IA defensiva]]"
---
---

Segundo caso: clasificar tráfico de red como normal o malicioso usando un `Random Forest` sobre features tabulares. Cambia el tipo de dato, el algoritmo y —como se verá— la honestidad conceptual del planteamiento.

# Random Forest, en corto

<mark style="background: #ADCCFFA6;">Un `Random Forest` entrena muchos árboles de decisión sobre muestras y subconjuntos de features distintos, y agrega sus votos.</mark> Tres mecanismos lo definen:

1. **`Bootstrapping`** — cada árbol se entrena sobre una muestra con reemplazo del conjunto original.
2. **Subconjunto aleatorio de features** — en cada partición, el árbol solo considera algunas de las features disponibles.
3. **Votación** — en clasificación gana la clase más votada; en regresión se promedia.

Esa doble aleatoriedad decorrelaciona los árboles, lo que reduce la varianza sin aumentar apenas el sesgo. Es el motivo de que un bosque generalice mucho mejor que un árbol suelto — ver [[05 - Árboles de decisión y ensembles]].

Para datos tabulares como estos es una elección acertada: no requiere escalado, tolera features en escalas heterogéneas, maneja bien las categóricas codificadas y da importancia de features de serie.

> [!warning]+ Esto no es detección de anomalías, es clasificación supervisada
> El módulo afirma que "para detección de anomalías, el `Random Forest` se entrena exclusivamente con datos normales" y que los puntos que no encajan se marcan como anómalos. <mark style="background: #FF5582A6;">El código que viene después hace algo distinto: entrena un clasificador **multiclase supervisado** con ataques etiquetados.</mark>
>
> La diferencia es sustancial y conviene tenerla clara:
> - **Detección de anomalías** (no supervisada) — se modela solo lo normal y se marca lo que se desvía. Puede señalar ataques nunca vistos; genera muchos falsos positivos. Es lo que hacen `Isolation Forest` o `One-Class SVM`, ver [[11 - Detección de anomalías]].
> - **Clasificación supervisada** — se aprende a distinguir clases a partir de ejemplos etiquetados de cada una. Es mucho más precisa **y solo reconoce lo que ha visto antes**. No detecta ataques nuevos.
>
> Lo que se construye aquí es lo segundo. Es un enfoque perfectamente válido, pero llamarlo detección de anomalías crea una expectativa falsa sobre su capacidad frente a técnicas desconocidas — que es justo lo que un atacante va a usar.

# El dataset NSL-KDD

`NSL-KDD` es una revisión de `KDD Cup 1999` que elimina registros duplicados y corrige el desbalance de clases, publicada por Tavallaee et al. en 2009. Incluye 41 features por conexión más la etiqueta de ataque.

```python
import requests, zipfile, io
import pandas as pd

url = "https://academy.hackthebox.com/storage/modules/292/KDD_dataset.zip"
z = zipfile.ZipFile(io.BytesIO(requests.get(url).content))
z.extractall('.')

columns = [
    'duration', 'protocol_type', 'service', 'flag', 'src_bytes', 'dst_bytes',
    'land', 'wrong_fragment', 'urgent', 'hot', 'num_failed_logins', 'logged_in',
    'num_compromised', 'root_shell', 'su_attempted', 'num_root', 'num_file_creations',
    'num_shells', 'num_access_files', 'num_outbound_cmds', 'is_host_login', 'is_guest_login',
    'count', 'srv_count', 'serror_rate', 'srv_serror_rate', 'rerror_rate', 'srv_rerror_rate',
    'same_srv_rate', 'diff_srv_rate', 'srv_diff_host_rate', 'dst_host_count', 'dst_host_srv_count',
    'dst_host_same_srv_rate', 'dst_host_diff_srv_rate', 'dst_host_same_src_port_rate',
    'dst_host_srv_diff_host_rate', 'dst_host_serror_rate', 'dst_host_srv_serror_rate',
    'dst_host_rerror_rate', 'dst_host_srv_rerror_rate', 'attack', 'level'
]

df = pd.read_csv('KDD+.txt', names=columns)
```

Las features cubren tres grupos: **básicas** de la conexión (`duration`, `src_bytes`, `dst_bytes`, `protocol_type`), **de contenido** derivadas del payload (`num_failed_logins`, `root_shell`, `hot`) y **estadísticas de tráfico** calculadas sobre ventanas de conexiones (`serror_rate`, `same_srv_rate`, `dst_host_count`).

> [!warning]+ NSL-KDD sigue siendo el estándar de facto y sigue estando obsoleto
> <mark style="background: #FFB86CA6;">Los datos originales provienen de una simulación DARPA de 1998.</mark> Las categorías de ataque —`neptune`, `smurf`, `teardrop`, `pod`— son de finales de los noventa y no representan absolutamente nada del panorama de 2026: no hay TLS, ni HTTP/2 o /3, ni tráfico en la nube, ni C2 sobre canales legítimos, ni movimiento lateral con credenciales válidas. Ya en 1999 McHugh publicó una crítica metodológica del conjunto DARPA original, y `NSL-KDD` corrigió los duplicados sin poder corregir la obsolescencia del tráfico.
>
> Sirve para aprender el pipeline. **No sirve** como evidencia de que un detector funciona. Un producto o un paper de 2026 que reporte resultados sobre `NSL-KDD` está reportando sobre un problema resuelto hace veinticinco años — ver [[02 - Datasets para seguridad]].

# Construir los objetivos

## Binario

```python
df['attack_flag'] = df['attack'].apply(lambda a: 0 if a == 'normal' else 1)
```

## Multiclase

Los ataques se agrupan en cuatro familias más el tráfico normal:

```python
dos_attacks       = ['apache2','back','land','neptune','mailbomb','pod',
                     'processtable','smurf','teardrop','udpstorm','worm']
probe_attacks     = ['ipsweep','mscan','nmap','portsweep','saint','satan']
privilege_attacks = ['buffer_overflow','loadmodule','perl','ps',
                     'rootkit','sqlattack','xterm']
access_attacks    = ['ftp_write','guess_passwd','http_tunnel','imap',
                     'multihop','named','phf','sendmail','snmpgetattack',
                     'snmpguess','spy','warezclient','warezmaster',
                     'xclock','xsnoop']

def map_attack(attack):
    if attack in dos_attacks:       return 1
    elif attack in probe_attacks:   return 2
    elif attack in privilege_attacks: return 3
    elif attack in access_attacks:  return 4
    else:                           return 0

df['attack_map'] = df['attack'].apply(map_attack)
```

> [!important]+ Errata corregida: `loadmdoule`
> El listado original del módulo escribe `'loadmdoule'` en `privilege_attacks`. En `NSL-KDD` el ataque se llama **`loadmodule`**, así que ninguna fila casa con la cadena mal escrita y todas caen en el `else` final. <mark style="background: #FF5582A6;">Resultado: todas las conexiones del ataque `loadmodule` —una escalada de privilegios— quedan etiquetadas como tráfico **normal**.</mark>
>
> El código de arriba ya está corregido. Merece la pena quedarse con el patrón general más que con la errata concreta: <mark style="background: #8000E1A6;">un mapeo de etiquetas basado en comparación exacta de cadenas falla en silencio</mark>. Cualquier valor que no case cae en la categoría por defecto, y si esa categoría es "benigno", se está entrenando al modelo para ignorar ataques. La defensa es trivial y casi nunca se aplica: comprobar que la unión de las listas cubre todos los valores distintos presentes en la columna.
> ```python
> conocidos = set(dos_attacks + probe_attacks + privilege_attacks + access_attacks) | {'normal'}
> print("Sin mapear:", set(df['attack'].unique()) - conocidos)
> ```

# Features y partición

```python
features_to_encode = ['protocol_type', 'service']
encoded = pd.get_dummies(df[features_to_encode])

numeric_features = [
    'duration','src_bytes','dst_bytes','wrong_fragment','urgent','hot',
    'num_failed_logins','num_compromised','root_shell','su_attempted',
    'num_root','num_file_creations','num_shells','num_access_files',
    'num_outbound_cmds','count','srv_count','serror_rate',
    'srv_serror_rate','rerror_rate','srv_rerror_rate','same_srv_rate',
    'diff_srv_rate','srv_diff_host_rate','dst_host_count','dst_host_srv_count',
    'dst_host_same_srv_rate','dst_host_diff_srv_rate',
    'dst_host_same_src_port_rate','dst_host_srv_diff_host_rate',
    'dst_host_serror_rate','dst_host_srv_serror_rate','dst_host_rerror_rate',
    'dst_host_srv_rerror_rate'
]

train_set = encoded.join(df[numeric_features])
multi_y = df['attack_map']
```

<mark style="background: #FFB8EBA6;">Nótese que `flag` no entra en el conjunto de features</mark> pese a codificar el estado de la conexión TCP (`SF`, `S0`, `REJ`…), que es una de las señales más discriminantes para escaneos y SYN floods. Es una decisión que el módulo no justifica y que conviene revisar si se reproduce el ejercicio.

Partición en train / validación / test:

```python
from sklearn.model_selection import train_test_split

train_X, test_X, train_y, test_y = train_test_split(
    train_set, multi_y, test_size=0.2, random_state=1337)

multi_train_X, multi_val_X, multi_train_y, multi_val_y = train_test_split(
    train_X, train_y, test_size=0.3, random_state=1337)
```

Aquí faltan dos cosas ya señaladas en [[04 - Transformación de datos]]: **`stratify`**, imprescindible con clases tan desiguales como `privilege_attacks` (unas pocas decenas de muestras frente a decenas de miles de DoS), y una partición **temporal** si los datos tuvieran marca de tiempo utilizable. Con una partición puramente aleatoria, las clases minoritarias pueden quedar prácticamente ausentes del test y su métrica se vuelve ruido.

## Fuentes

- Contenido base del módulo *Applications of AI in InfoSec* de HTB Academy, con dos correcciones al original —la confusión entre detección de anomalías y clasificación supervisada, y la errata `loadmdoule`— y ampliado con la crítica de vigencia de `NSL-KDD` y las carencias de la partición.
- Tavallaee, Bagheri, Lu & Ghorbani, *A Detailed Analysis of the KDD CUP 99 Data Set*, IEEE CISDA 2009 — origen de `NSL-KDD`.
