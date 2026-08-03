---
tags:
  - Wi-Fi/WPS
  - Pentesting/Explotacion
Descripción: "Cómo derivan los fabricantes el PIN de fábrica del BSSID y del número de serie, con el caso Arcadyan/EasyBox y el estado real de las herramientas"
Fecha de actualización: 2026-08-01
Nota previa: "[[05 - PINs por defecto y bases de datos]]"
Nota siguiente: "[[07 - Pixie Dust y el fallo de entropía]]"
Area: "[[WPS.base|WPS]]"
---
---

Un PIN de fábrica tiene que estar impreso en la etiqueta y grabado en el firmware. <mark style="background: #ADCCFFA6;">Para no gestionar una base de datos por unidad, muchos fabricantes lo **derivan de algo que ya está en el dispositivo**: la MAC, el número de serie, o ambos</mark>. Si el algoritmo se conoce, el PIN de cualquier unidad de esa gama se calcula desde la calle, sin tocar el AP.

# Las familias de algoritmos

| Familia | Entrada | Ejemplo de fabricantes |
| ------- | ------- | ---------------------- |
| **Truncado del NIC** | Los últimos 24/28/32/36/44/48 bits del BSSID, módulo 10⁷ + checksum | Muy extendido |
| **Transformación de bits** | Invertir bits, nibbles o bytes del NIC antes de reducir | Realtek, Broadcom |
| **Aritmética OUI/NIC** | `OUI + NIC`, `OUI - NIC`, `OUI XOR NIC` | Varios |
| **Número de serie** | El serial, derivado a su vez de la MAC | Arcadyan, Vodafone EasyBox |
| **PIN estático** | Un valor fijo para toda la serie | Cisco (`12345670`), Broadcom, Airocon |

El más común es el truncado: se toman los últimos *n* bits del BSSID como entero, se reduce módulo 10⁷ y se añade el dígito de checksum.

```python
def pin_24bit(bssid_hex):
    """Los 24 bits bajos del BSSID → PIN de 7 dígitos + checksum."""
    nic = int(bssid_hex.replace(':', '')[-6:], 16)
    pin7 = nic % 10_000_000
    return f"{pin7:07d}{checksum(pin7)}"
```

<mark style="background: #FFB86CA6;">La consecuencia es que el PIN deja de ser un secreto: es una función pública de un identificador que el AP emite en cada beacon</mark>. No hay ataque de fuerza bruta; hay una cuenta.

# El caso Arcadyan / Vodafone EasyBox

El ejemplo mejor documentado, publicado en 2013 en [Full Disclosure](https://seclists.org/fulldisclosure/2013/Aug/51). Afecta a las pasarelas DSL de **Arcadyan Networks**, revendidas por Vodafone Alemania como *EasyBox* y por otros operadores bajo otras marcas.

La cadena es doble: el **número de serie se deriva del BSSID**, y el **PIN se deriva del número de serie**. Con sólo la MAC —que está en el aire— se obtienen ambos:

```shell-session
$ python2 /opt/Default-wps-pin/default-wps-pin.py 60:38:E0:D4:A2:5E

derived serial number: R----55185
SSID: Arcor|EasyBox|Vodafone-04D755
WPS pin: 27038895
```

<mark style="background: #8000E1A6;">La herramienta deduce además el SSID por defecto</mark>, lo que sirve para el camino inverso: identificar el modelo exacto a partir del nombre de la red antes siquiera de mirar el OUI.

> [!warning]+ Esta herramienta lleva doce años sin mantenimiento
> [`eye9poob/Default-wps-pin`](https://github.com/eye9poob/Default-wps-pin), que enlaza el módulo, tuvo su **último cambio en septiembre de 2014** y es **Python 2**, sin soporte desde enero de 2020. Ejecutarla exige instalar un intérprete retirado. <mark style="background: #FF5582A6;">El algoritmo sigue siendo válido; la implementación no</mark>. Hoy esa familia está cubierta por `wpspin` y por airgeddon, ambos en Python 3 y mantenidos.

# El resto de herramientas del módulo, y su estado real

Comprobado el 2026-08-01 contra sus repositorios:

| Herramienta | Último cambio | Lenguaje | Veredicto |
| ----------- | ------------- | -------- | --------- |
| [`Default-wps-pin`](https://github.com/eye9poob/Default-wps-pin) | 2014-09 | Python 2 | Abandonada. Sólo de referencia histórica |
| [`WPS-PIN` (WPSPIN.sh)](https://github.com/linkp2p/WPS-PIN) | 2023-12 | Shell | Funcional, con menú interactivo. Poco activa |
| [`nmk`](https://github.com/kcdtv/nmk) | 2021-10 | Shell + Python 2 | Muy específica: Arcadyan ARV7519/7520 y VRV9510 (Livebox 2.1 y Next) |
| [`airgeddon`](https://github.com/v1s1t0r1sh3r3/airgeddon) | **2026-07** | Shell | **La vía mantenida.** Integra generación y prueba |

`nmk` cubre un caso que ninguna otra resuelve, y merece la pena conocerlo porque **necesita el número de serie**, no sólo el BSSID:

```shell-session
$ python2 /opt/nmk/orangen.py A2BD 7281
99559236
```

Los cuatro últimos dígitos del BSSID de 2,4 GHz y los cuatro últimos del serial, que está en la pegatina del router. <mark style="background: #FFB8EBA6;">Requiere acceso físico o una foto del equipo</mark> — algo perfectamente plausible en un engagement con acceso a las oficinas, y un buen ejemplo de cómo el reconocimiento físico alimenta el ataque lógico.

# Qué hacer con esto en la práctica

El flujo eficiente no es ejecutar cinco herramientas, sino uno solo:

1. **Identificar el modelo**, no sólo el fabricante. El OUI da la marca; el WPS IE (`model_name`, `model_number`) da el modelo, y el SSID por defecto lo confirma.
2. **Generar la lista específica** de ese modelo con `wpspin` sin `-A`, en lugar de los 49 candidatos genéricos.
3. **Probarlos con `--max-attempts=1`** y pausas, como en [[05 - PINs por defecto y bases de datos]].

```shell-session
$ sudo wash -j -i mon0 | python3 -c "import sys,json; [print(json.loads(l)['essid'], json.loads(l).get('manufacturer','')) for l in sys.stdin if l.strip().startswith('{')]"
```

> [!important]+ Por qué esto importa más que la fuerza bruta
> Un PIN derivado del BSSID **no se protege con el bloqueo por intentos**. El AP puede bloquearse a los tres fallos y da igual: si el primer candidato es el correcto, nunca llega a fallar. <mark style="background: #FF5582A6;">Contra equipamiento de operador —routers de ISP desplegados por millones con firmware idéntico— es la vía con mejor relación éxito/ruido de todo el módulo</mark>.

# El lado defensivo

Para el informe, el matiz es importante: no basta con "cambiar el PIN". Muchos routers permiten regenerarlo, pero:

- El PIN nuevo sigue siendo de ocho dígitos con la misma validación en dos mitades: sigue habiendo 11.000 combinaciones.
- Algunos firmwares regeneran el PIN con el mismo algoritmo determinista, así que "cambiarlo" produce otro valor igualmente predecible.
- El PIN de la etiqueta sigue funcionando en muchos modelos aunque se haya configurado otro.

<mark style="background: #8000E1A6;">La única recomendación válida es desactivar WPS</mark>, y verificarlo después con `wash`.

Cuando el fabricante no tiene un algoritmo conocido, queda el fallo que afecta a los chipsets con generación de nonces defectuosa: [[07 - Pixie Dust y el fallo de entropía]].
