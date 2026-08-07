---
tags:
  - Proyectos
  - Go
  - Pivoting
  - Pentesting/Movimiento-Lateral
  - Tipo/Proyecto
Descripción: "Descubre desde un punto de apoyo qué segmentos son alcanzables y traza el grafo de conectividad interna, convirtiendo el pivoting a ciegas en un mapa de rutas y cuellos de botella"
Fecha de actualización: 2026-08-04
Nota previa: "[[05 - Detector de señuelos defensivos en Active Directory]]"
Nota siguiente: "[[07 - Reconstructor de protocolos binarios]]"
Area: "[[Proyectos ofensivos.base|Proyectos ofensivos]]"
Estado: Idea
Dificultad: 4
Esfuerzo: 4-5 semanas
---
---

**Nombre propuesto**: `reachmap`

Tienes un punto de apoyo en la DMZ y quince rutas posibles hacia dentro. ¿Cuáles llevan a algún sitio? Hoy eso se averigua a mano: montar un pivote con Ligolo-ng, lanzar un `nmap` a través del túnel, ver qué responde, montar el siguiente pivote, repetir. Es lento, es ruidoso, y —lo importante— <mark style="background: #FFB86CA6;">el mapa mental de la red interna vive solo en tu cabeza y en capturas de pantalla sueltas</mark>. Cuando el engagement termina, ese conocimiento se pierde.

BloodHound te da el grafo de *identidad* (quién puede sobre quién). Nadie te da el grafo de *red* (qué host alcanza a qué host, por qué puerto, a través de qué pivote). Este proyecto construye ese segundo grafo.

# El problema que resuelve

El pivoting moderno resolvió el transporte: Ligolo-ng monta un `TUN` y te deja usar herramientas nativas sin `proxychains`, y es excelente en eso. Lo que ninguna herramienta de pivoting hace es la **cartografía**: descubrir automáticamente, desde uno o varios puntos de apoyo, qué segmentos existen, cuáles son alcanzables desde dónde, y consolidarlo en un modelo consultable.

El resultado es que el pentester improvisa el movimiento lateral en lugar de planificarlo, repite escaneos que ya hizo porque no recuerda el resultado, y no sabe identificar el **cuello de botella**: ese host único a través del cual pasan todas las rutas hacia el segmento crítico, que es tanto la joya para el atacante como el punto de corte para el defensor.

# Alcance del proyecto

Un orquestador que se apoya en agentes ligeros desplegados en los hosts comprometidos y construye incrementalmente un grafo de alcanzabilidad. El transporte no se reinventa —se apoya en lo que ya existe— y el valor está en la capa de descubrimiento y modelado por encima.

**Descubrimiento de segmentos.** Desde cada agente, inventariar de forma pasiva antes que activa: interfaces y máscaras, tabla de rutas, caché ARP y vecinos, tabla de conexiones establecidas (`netstat`), servidores DNS y sufijos, entradas del fichero de hosts. <mark style="background: #ADCCFFA6;">La tabla de rutas y la caché ARP de un host ya te dicen qué redes conoce sin enviar un solo paquete de sondeo</mark>, y eso es oro en un entorno vigilado.

**Prueba de alcanzabilidad calibrada.** Cuando hay que sondear activamente, hacerlo con presupuesto: número de sondas, espaciado y orden configurables, priorizando los puertos que de verdad importan para el movimiento lateral (445, 3389, 5985, 22, 1433) antes que un barrido general.

**Consolidación en grafo.** Nodos que son hosts y segmentos; aristas que son "alcanza a, por el puerto X, a través del agente Y". Sobre ese grafo, las consultas que un pentester quiere y hoy no puede hacer:

```shell-session
$ reachmap query --reachable-from dmz-web01 --port 445
sql-cluster01   vía dmz-web01 → app-tier02 (2 saltos)
fileserver03    vía dmz-web01 → app-tier02 (2 saltos)

$ reachmap chokepoints
app-tier02   87% de las rutas al segmento 10.20.50.0/24 pasan por aquí
```

# Funcionalidades principales

| Funcionalidad | Detalle |
| --- | --- |
| Inventario pasivo primero | Rutas, ARP, conexiones y DNS de cada agente antes de sondear nada |
| Sondeo con presupuesto | Cadencia y volumen controlados; nunca un barrido a discreción |
| Grafo incremental persistente | El mapa se construye y sobrevive entre sesiones; reanudable |
| Detección de cuellos de botella | Centralidad sobre el grafo para hallar el host de corte |
| Deduplicación de escaneos | No repetir lo ya sabido; el modelo recuerda qué se probó y cuándo |
| Exportación a Graphviz y JSON | El mapa entra directo en el informe como figura de topología |

# Qué existe ya y dónde se queda corto

- **Ligolo-ng** resuelve el túnel y el enrutado con `TUN`, soporta doble pivote y sesiones concurrentes. Es la base de transporte ideal, pero su modelo de la red es la tabla de rutas que tú le configuras a mano: no descubre segmentos ni construye grafo.
- **BloodHound** es el precedente conceptual —grafo, cuellos de botella, consultas— pero sobre el plano de identidad. Su propia investigación empresarial demostró el valor de encontrar el nodo por el que pasan miles de caminos; este proyecto traslada esa idea al plano de red, donde no existe.
- Los **escáneres de red** (`nmap`, `masscan`) descubren hosts, pero no modelan alcanzabilidad multi-pivote ni consolidan resultados entre puntos de apoyo. Cada escaneo es una foto suelta.

El hueco —cartografía de alcanzabilidad multi-pivote, incremental y consultable— está genuinamente vacío.

# Cosas a tener en cuenta

> [!warning]+ El descubrimiento activo es el momento más ruidoso de un engagement
> Un barrido de puertos a través de un pivote enciende IDS, NetFlow y correlación de conexiones anómalas. <mark style="background: #FF5582A6;">La herramienta tiene que hacer del sigilo un parámetro de primera clase, no una opción escondida</mark>: por defecto, pasivo; el sondeo activo, explícito, calibrado y registrado. Un cartógrafo que barre a discreción es un generador de alertas con grafo bonito.

- **El grafo es tan sensible como el registro de operación.** Es el plano de la red interna del cliente; cifrado en reposo y destrucción tras la retención, igual que en el proyecto 01.
- **Gestión de agentes = disciplina de limpieza.** Cada agente desplegado es un artefacto en un host del cliente que hay que retirar. La herramienta debe llevar la cuenta de qué desplegó y dónde, y tener un teardown fiable — un agente olvidado es un hallazgo del equipo azul con tu nombre.
- **Cuidado con inferir alcanzabilidad de más.** Que A vea a B y B vea a C no implica que A alcance a C: puede haber un firewall con estado o segmentación L3 en medio. El grafo debe distinguir "alcanzabilidad **verificada** salto a salto" de "alcanzabilidad **inferida**", y no vender la segunda como la primera.
- **La caché ARP miente por diseño.** Es información volátil y a veces envenenada. Úsala como pista de descubrimiento, no como verdad de topología.

# Fuera de alcance

No reimplementa el túnel: se apoya en Ligolo-ng o equivalente para el transporte. No explota nada: mapea. Y no es un C2 — la gestión de agentes es la mínima para la cartografía, no un framework de post-explotación.

# Criterio de terminado

Cuando en un laboratorio de tres segmentos con doble pivote, la herramienta descubre la topología partiendo solo del punto de apoyo en la DMZ, identifica correctamente el host de corte hacia el segmento interno, y produce un diagrama de topología listo para el informe.

# Conexiones en el vault

Los fundamentos de red que hacen posible el descubrimiento pasivo están en [[01 - Fundamentos de red del pivoting]]; el transporte sobre el que se construye, en [[13 - Pivoting moderno con Ligolo-ng]]. La cara de detección —qué enciende el sondeo activo— vive en [[15 - Detección y evasión de túneles]], y el resto del arsenal de la fase, en [[16 - Arsenal de herramientas de pivoting]]. La disciplina de fabricar la ventana de menor vigilancia para el sondeo ruidoso está en [[04 - Explotar y crear circunstancias]].

> [!info]+ Fuentes
> - Nicolas Chatelain, [Ligolo-ng](https://github.com/nicocha30/ligolo-ng) — modelo de transporte `TUN` y pivoting multi-hop sobre el que se apoya el proyecto (consultado 2026-08-04).
> - SpecterOps, [documentación de pathfinding de BloodHound](https://bloodhound.specterops.io/analyze-data/explore/search) — el precedente de grafo y cuellos de botella en el plano de identidad.
