---
tags:
  - Pentesting/Enumeracion
  - Escaneo/Redes
  - Linux
  - Tipo/Introduccion
Descripción: "Por qué masscan barre un /8 en minutos y Nmap no: la pila TCP/IP propia, las SYN cookies y la permutación sin memoria"
Fecha de actualización: 2026-08-04
Nota previa:
Nota siguiente: "[[01 - Sintaxis, rangos y exclusiones]]"
Area: "[[Masscan.base|Masscan]]"
---
---

<mark style="background: #ADCCFFA6;">`masscan` es un escáner de puertos TCP asíncrono con **pila TCP/IP propia en espacio de usuario**</mark>, escrito por Robert Graham. Su autor lo resume como *«lo que nginx es a Apache»* aplicado al escaneo: la misma tarea, otro modelo de concurrencia. Anuncia hasta **25 millones de paquetes por segundo** y barrer el IPv4 público en un puerto en unos 3 minutos.

Aquí importa el **porqué**, no la cifra. Entender por qué puede ir tan rápido explica también sus tres debilidades —no hace *fingerprinting*, degrada con pérdida de paquetes y es imposible de disimular— y por eso [[09 - Arsenal de herramientas de escaneo|el pipeline profesional]] lo combina con [[00 - Introducción a Nmap|Nmap]] en vez de sustituirlo.

# El cuello de botella que masscan elimina

Nmap es **stateful**: por cada sonda que envía guarda una entrada en una tabla en memoria (destino, puerto, momento del envío, reintentos pendientes) y hace *timing* adaptativo sobre ella — sube o baja el ritmo según los RTT y las pérdidas que observa (ver [[05 - Rendimiento y timing]]). Esa contabilidad es exactamente lo que da su precisión, y también lo que lo ancla: mantener y recorrer millones de entradas vivas cuesta memoria y CPU, y el *timing* adaptativo frena en cuanto huele pérdidas.

masscan renuncia a la tabla entera. <mark style="background: #8000E1A6;">No recuerda ninguna sonda: reconstruye el estado a partir de la respuesta que le llega</mark>. Sin estado no hay memoria que crezca, no hay estructura que recorrer y no hay razón para frenar. El escáner queda reducido a dos hilos casi independientes —uno que transmite a ritmo constante y otro que recibe— comunicados por *ring buffers* que evitan los mutex del kernel.

## Las SYN cookies: estado dentro del paquete

El truco es el mismo que usan los kernels contra los *SYN floods*, invertido. En cada `SYN` saliente, masscan pone como **número de secuencia inicial** un valor derivado de la propia conexión:

```c
uint64_t syn_cookie(ipaddress ip_them, unsigned port_them,
                    ipaddress ip_me, unsigned port_me,
                    uint64_t entropy);
```

Esa función es un **SipHash-2-4** sobre la tupla `(IP destino, puerto destino, IP origen, puerto origen)` más una entropía de 64 bits generada al arrancar. Cuando vuelve un `SYN/ACK`, masscan recalcula la cookie con los datos de la cabecera recibida y la compara con el número de acuse: si cuadran, el paquete es respuesta a una sonda suya; si no, es ruido y lo descarta.

> [!important]+ Qué implica esto en la práctica
> El escáner **no necesita saber qué envió** para validar lo que recibe. Puedes matar el proceso, cambiar de rango o recibir la respuesta veinte segundos tarde: mientras la entropía sea la misma, la validación funciona. Es también la razón de que masscan sea inmune a que un tercero le inyecte resultados falsos sin conocer el secreto — algo que un escáner que solo mira "¿es un SYN/ACK del puerto 80?" no puede garantizar.

## Aleatorización sin memoria: BlackRock

Un escaneo secuencial de `10.0.0.0/8` machaca cada `/24` durante segundos seguidos: satura enlaces pequeños y es un patrón trivial de detectar. Lo correcto es aleatorizar el orden, pero barajar una lista de 4.000 millones de objetivos requiere guardarla.

masscan lo resuelve con **BlackRock2**, una <mark style="background: #ADCCFFA6;">cifra que preserva el formato (*format-preserving encryption*) construida como una red de Feistel</mark> con S-boxes de DES como función de ronda. Cifra el índice `i` del recorrido y devuelve otro índice dentro del mismo rango; si el resultado se sale, vuelve a cifrar hasta caer dentro (*cycle walking*). Como toda cifra es una biyección, la salida es una **permutación 1:1 del espacio de objetivos**: cada IP:puerto aparece exactamente una vez, en orden pseudoaleatorio, y el recorrido sigue siendo un simple `i++`.

De ahí salen dos propiedades operativas: el orden es **reproducible** fijando `--seed`, y el escaneo se puede **partir entre máquinas** (`--shards`) sin coordinación ni solapamiento, porque cada nodo se queda con una clase de índices distinta. Se ven en [[02 - Rendimiento - rate, adaptador y transmisión]].

# Lo que masscan hereda de Nmap y lo que no

masscan imita la interfaz de Nmap por comodidad, pero varios comportamientos están **fijados y no se pueden cambiar**. Según su propia documentación, equivale a tener siempre puestos:

| Flag de Nmap | Significado en masscan |
| --- | --- |
| `-sS` | Solo *SYN scan*. No hay Connect, FIN, NULL, Xmas ni idle scan. |
| `-Pn` | Nunca hace descubrimiento previo de host. |
| `-n` | Nunca resuelve DNS — los objetivos son IPs o rangos, **no nombres**. |
| `--randomize-hosts` | El orden siempre es aleatorio (BlackRock). |
| `--send-eth` | Siempre construye la trama Ethernet completa vía libpcap. |

<mark style="background: #FFB8EBA6;">Tampoco acepta la notación de objetivos rara de Nmap</mark> (`10.0.0.*`, `192.168.[1-3].0/24`): solo IP suelta, rango `a-b` y CIDR. Y no trae puertos por defecto — sin `-p` no escanea nada.

# Cuándo usarlo y cuándo no

|  | masscan | Nmap |
| --- | --- | --- |
| **Rango enorme** (`/16`, `/8`, ASN entero) | Sí, es su caso de uso | Inviable en tiempo real |
| **Identificar servicio y versión** | No (banners crudos, ver [[04 - Banner grabbing y modo stateful]]) | Sí, `-sCV` es el patrón oro |
| **Red con pérdida de paquetes** | Falsos negativos (sin reintentos adaptativos) | Aguanta bien |
| **Sigilo** | <mark style="background: #FF5582A6;">Ninguno: es un cañón</mark> | Modulable (`-T0`, `--scan-delay`) |
| **UDP** | Limitado, por *payloads* precargados | `-sU` con scripts NSE |

> [!warning]+ El error caro: creerse los resultados de una sola pasada
> Sin estado no hay reintento adaptativo. En un enlace saturado o contra un objetivo con *rate-limiting* de ICMP/RST, masscan **pierde respuestas y las cuenta como puerto cerrado**. En un engagement real eso significa no ver un servicio que sí estaba. La regla es escanear dos veces con `--seed` distinto y confirmar siempre con Nmap lo que salga abierto.

> [!info]+ Estado del proyecto (verificado 2026-08-04 contra la API de GitHub)
> El **último *release* etiquetado es 1.3.2, de enero de 2021** — cinco años sin versión —, pero `master` sigue recibiendo commits (último *push*: abril de 2026) y acumula cientos por delante de esa etiqueta. <mark style="background: #FF5582A6;">El paquete `masscan` de las distros es 1.3.2 y le faltan correcciones de IPv6 y de la pila de banners</mark>: para trabajo serio, compilar de `master`. Ojo también con los binarios de terceros que aparecen al buscar "masscan Windows" — un repo huérfano es blanco de suplantación, el mismo riesgo señalado en el ecosistema Wi-Fi.

> [!info]+ Fuentes
> - Robert Graham — [README y `doc/masscan.8` del repositorio oficial](https://github.com/robertdavidgraham/masscan) (arquitectura, flags fijados, límites de rendimiento, aviso «*Scanning the entire Internet is bad*»).
> - Código fuente: `src/syn-cookie.c` (SipHash-2-4 sobre la tupla + entropía) y `src/crypto-blackrock2.c` (red de Feistel con S-boxes de DES y *cycle walking*).
