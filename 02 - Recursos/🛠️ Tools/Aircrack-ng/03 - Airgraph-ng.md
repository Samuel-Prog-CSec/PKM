---
tags:
  - Wi-Fi
  - Pentesting/Enumeracion
Descripción: "Convertir los CSV de airodump-ng en grafos de relación cliente-AP y de sondeo, y qué usar cuando el grafo se vuelve ilegible"
Fecha de actualización: 2026-08-01
Nota previa: "[[02 - Airodump-ng]]"
Nota siguiente: "[[04 - Aireplay-ng]]"
Area: "[[Aircrack-ng.base|Aircrack-ng]]"
---
---

<mark style="background: #ADCCFFA6;">`airgraph-ng` es un script de Python que convierte los `.csv` de `airodump-ng` en grafos con Graphviz</mark>. Produce dos vistas y ninguna más, pero ambas responden preguntas que la tabla de `airodump-ng` no contesta de un vistazo: quién habla con quién, y quién anda buscando redes que no están ahí.

# CAPR — clientes contra puntos de acceso

```shell-session
$ sudo airgraph-ng -i HTB-01.csv -g CAPR -o HTB_CAPR.png

**** WARNING Images can be large, up to 12 Feet by 12 Feet****
Creating your Graph using, HTB-01.csv and writing to, HTB_CAPR.png
```

![Grafo CAPR mostrando un punto de acceso con su cliente asociado y los metadatos de cifrado](https://academy.hackthebox.com/storage/modules/222/graph/HTB_CAPR.png)

El grafo colorea cada AP por su cifrado:

| Color | Cifrado |
| ----- | ------- |
| Verde | WPA |
| Amarillo | WEP |
| Rojo | Red abierta |
| Negro | Desconocido |

<mark style="background: #FFB8EBA6;">Sólo aparecen los AP que tienen algún cliente asociado</mark>: un AP sin clientes desaparece del grafo aunque esté en el `.csv`. Es una limitación deliberada —el grafo va de relaciones— pero conviene recordarla antes de concluir que una red no existe.

Lo que se lee bien aquí y mal en la tabla:

- **Densidad de clientes por AP.** El AP con veinte clientes es el que está en la zona de trabajo; el de uno, probablemente un repetidor o una impresora.
- **Clientes en varios AP.** Un mismo dispositivo colgando de dos BSSID indica roaming activo dentro de un ESS, y por tanto un despliegue empresarial con controlador.
- **La red que no encaja.** Un AP rojo (abierto) o amarillo (WEP) en medio de un despliegue verde salta a la vista de inmediato. <mark style="background: #FF5582A6;">Es el patrón visual del rogue AP y del equipo legado olvidado</mark>.

# CPG — grafo de sondeo

```shell-session
$ sudo airgraph-ng -i HTB-01.csv -g CPG -o HTB_CPG.png
```

![Grafo CPG mostrando las redes que un cliente está sondeando activamente](https://academy.hackthebox.com/storage/modules/222/graph/HTB_CPG.png)

Relaciona cada cliente con los SSID que está buscando en sus *probe requests* —su `PNL`—, incluso si no está asociado a nada. Es el material de un evil twin dirigido: si veinte portátiles buscan `Corp-WiFi`, levantar ese SSID captura veinte clientes. Y si un dispositivo busca `Aeropuerto_Free_WiFi`, es un candidato para KARMA.

Además tiene lectura defensiva y de OSINT: el conjunto de SSID que arrastra un dispositivo dibuja su historial de ubicaciones. En un informe, un CPG con los SSID de hoteles y aeropuertos de los portátiles de dirección es un hallazgo de fuga de información que se entiende sin explicar nada.

# Las limitaciones, y qué hacer con ellas

`airgraph-ng` está esencialmente congelado y se nota en dos cosas.

**El grafo se vuelve ilegible rápido.** El propio aviso de "hasta 12 pies por 12 pies" no es una broma: con más de treinta AP o un centenar de clientes, la imagen deja de servir. La solución es **filtrar en origen**, no en el grafo — capturar con `--essid` o `--bssid`, o recortar el `.csv`:

```shell-session
$ head -1 HTB-01.csv > filtrado.csv
$ grep -E "CyberCorp|00:14:6C" HTB-01.csv >> filtrado.csv
$ sudo airgraph-ng -i filtrado.csv -g CAPR -o objetivo.png
```

**No entiende los cifrados modernos.** La paleta de colores se detuvo en WPA: WPA2, WPA3 y OWE caen todos en "verde" o en "negro" según el caso, así que <mark style="background: #FFB86CA6;">el color no distingue una red WPA3 bien montada de una WPA con TKIP</mark>. Para esa distinción hay que volver a las columnas `ENC`/`CIPHER`/`AUTH` de [[02 - Airodump-ng]].

## Alternativas

| Herramienta | Cuándo compensa |
| ----------- | --------------- |
| **Kismet** | Reconocimiento continuo. Interfaz web con vistas de dispositivos, relaciones y series temporales, y base de datos consultable |
| **Wireshark · Statistics ▸ WLAN Traffic** | Sobre el `.cap`, sin pasar por CSV. Da conteos por BSSID y por trama |
| **Script propio sobre el CSV** | El `.csv` es trivial de parsear. Con `pandas` + `networkx` se obtiene el grafo que interese, con la paleta que interese |

Para un engagement de un día, `airgraph-ng` sigue siendo el camino más corto de captura a imagen para el informe. Para reconocimiento sostenido en un despliegue grande, Kismet lo supera con claridad — se detalla en la nota de arsenal, [[10 - Arsenal de herramientas Wi-Fi]].

> [!info]+ Dependencia de Graphviz
> `airgraph-ng` invoca `dot` por debajo. Si falta el paquete, falla con un error poco descriptivo:
> ```shell-session
> $ sudo apt install graphviz
> ```

La generación de tráfico —el otro lado del reconocimiento— es [[04 - Aireplay-ng]].
