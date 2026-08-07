---
tags:
  - Seguridad/Contraseñas
  - Pentesting/Post-Explotacion
  - Tipo/Arsenal
Descripción: "Qué GPU alquilar en 2026 y por qué la receta clásica de Tesla K80 ya no existe, más el problema contractual de sacar hashes del cliente"
Fecha de actualización: 2026-08-04
Nota previa: "[[04 - Backends, dispositivos y tuning]]"
Nota siguiente: 
Area: "[[Hashcat.base|Hashcat]]"
---
---

Alquilar GPU por horas resuelve el problema de no tener rig, pero la mayoría de guías que circulan describen hardware que **ya no se puede alquilar** y omiten el único punto que puede acabar con el engagement en un despacho de abogados.

# La receta clásica ya no funciona

> [!warning]+ El Tesla K80 está apagado desde 2024
> Cursos y tutoriales —el módulo 312 de HTB entre ellos— proponen crear una VM con **8 × NVIDIA Tesla K80** en Google Cloud. <mark style="background: #FF5582A6;">Google marcó el K80 como obsoleto el **1 de mayo de 2023** y lo apagó el **1 de mayo de 2024**</mark>: desde esa fecha no se pueden crear ni arrancar instancias con esa GPU.
>
> Aunque se pudiera, no serviría: el K80 es arquitectura **Kepler (2014)**, y las versiones de CUDA que hashcat necesita hoy dejaron de darle soporte. Google recomendó el **T4** como reemplazo directo. Fuente: [documentación de fin de soporte del K80](https://docs.cloud.google.com/compute/docs/eol/k80-eol).

# Qué se alquila hoy

| GPU | Perfil | Dónde |
| --- | ------ | ----- |
| **T4** | Barata, 16 GB, buena relación coste/hora | GCP, AWS `g4dn`, Azure NCas |
| **L4** | Sucesora del T4, Ada Lovelace | GCP `g2` |
| **A100** | Alto rendimiento, 40/80 GB | Todos los grandes |
| **H100** | Máximo, caro | Todos los grandes |
| **RTX 4090 / 5090** | La mejor relación precio/rendimiento en cracking | Vast.ai, RunPod y similares |

<mark style="background: #FFB86CA6;">Para cracking, las tarjetas de consumo baten a las de datacenter en coste por hash</mark>: una RTX 4090 hace **2.533,3 kH/s** en `-m 22000` y cuesta una fracción por hora de lo que cuesta una A100, que está optimizada para precisión doble y memoria — cosas que a hashcat no le sirven. Los mercados tipo Vast.ai o RunPod alquilan justo eso.

La referencia de rendimiento por modo está en los [benchmarks de Chick3nman](https://gist.github.com/Chick3nman/32e662a5bb63bc4f51b847bb422222fd), que es la fuente que la comunidad usa para comparar.

# `apt install hashcat` no basta

El paso que las guías se saltan: instalar el paquete de la distribución deja un hashcat que **sólo ve la CPU**. Hacen falta tres piezas, en orden:

1. **Driver propietario de NVIDIA** para el kernel de la VM.
2. **CUDA Toolkit**, o al menos el runtime OpenCL correspondiente.
3. **hashcat de hashcat.net**, no el del repositorio, si la distribución va retrasada — Debian 12 empaqueta la 6.2.6 y la rama actual es la **7.1.2**.

```shell-session
$ hashcat -I          # si no aparece la GPU, el problema es el driver
$ hashcat -b -m 22000 # confirmar el rendimiento esperado antes de cargar el trabajo
```

<mark style="background: #FFB8EBA6;">Si `-I` no lista la GPU, ninguna opción de hashcat lo va a arreglar</mark>, y añadir `--force` sólo consigue que corra en CPU sin decirlo claramente. Las imágenes preinstaladas con CUDA (las *Deep Learning VM* de GCP y equivalentes) ahorran esa hora de configuración.

# El punto que decide si se puede hacer

Subir hashes a una máquina de terceros es **sacar material de autenticación del cliente de su entorno**. No es un detalle administrativo:

| Riesgo | Concreción |
| ------ | ---------- |
| Contractual | El acuerdo suele prohibir procesar datos fuera de infraestructura acordada |
| Legal | Un handshake WPA o un NTDS contienen datos personales — RGPD |
| Jurisdicción | La región de la VM determina qué ley aplica al dato |
| Persistencia | Discos, snapshots y logs del proveedor sobreviven al engagement |

Lo que hay que tener resuelto **antes** de capturar nada:

1. **Autorización expresa en el RoE**, indicando que habrá crackeo offline fuera del entorno y en qué proveedor y región.
2. **Mínimo material posible**: hashes filtrados al alcance (`hcxhashtool --essid`), nunca capturas completas.
3. **Destrucción documentada**: borrar instancia y discos al terminar, y dejarlo por escrito en el informe.

Si el cliente no autoriza el traslado, sigue habiendo opción: crackear con CPU en el entorno del cliente para cazar lo evidente. Se pierde el análisis de contraseñas en profundidad, y eso mismo se refleja como limitación del alcance en el informe.

> [!important]+ Servicios de crackeo gestionados
> [crack.sh](https://crack.sh/) agota el espacio DES completo —MSCHAPv2, NetNTLMv1, WPA-Enterprise— con garantía de éxito y del orden de **26 horas** para el barrido. Es la vía práctica para [[08 - Cracking de identidades WPA-Enterprise|credenciales EAP]], y aplica **exactamente la misma cautela**: enviar un reto es entregar material del cliente a un tercero.

# Cuándo la nube no compensa

| Situación | Mejor opción |
| --------- | ------------ |
| Diccionario + reglas sobre `-m 22000` | Portátil con GPU decente; son minutos |
| Un puñado de handshakes | Local. El tiempo de aprovisionar supera al de crackear |
| Análisis de NTDS de miles de hashes | Nube o rig propio |
| Máscaras de días sobre un objetivo concreto | Nube, o mejor: **mejores máscaras** |

<mark style="background: #8000E1A6;">Antes de alquilar potencia conviene agotar la información</mark>: una máscara derivada del contexto del cliente reduce el espacio en varios órdenes de magnitud, y sale gratis. La nube compra fuerza bruta, que es el recurso menos rentable de los disponibles — el razonamiento completo, con la aritmética, está en [[04 - Anatomía de una contraseña Wi-Fi]].
