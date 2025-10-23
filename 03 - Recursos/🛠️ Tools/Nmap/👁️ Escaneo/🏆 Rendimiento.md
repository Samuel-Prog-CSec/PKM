El rendimiento del escaneo juega un papel importante cuando necesitamos escanear una red extensa o estamos lidiando con un ancho de banda de red bajo. 
Podemos usar varias opciones para indicarle a Nmap **qué tan rápido** (`-T <0-5>`), con **qué frecuencia** (`--min-parallelism <número>`), **qué tiempos de espera** (`--max-rtt-timeout <tiempo>`) deben tener los paquetes de prueba, **cuántos paquetes deben enviarse simultáneamente** (`--min-rate <número>`) y con **qué número de reintentos** (`--max-retries <número>`) deben escanearse los puertos de destino.


# Timeouts
Cuando Nmap envía un paquete, tarda un tiempo (==tiempo de ida y vuelta==, **RTT**) en recibir una respuesta del puerto escaneado. Generalmente, Nmap **comienza con un tiempo de espera alto** (`--min-RTT-timeout`) ==de 100 ms==. Veamos un ejemplo en que compararemos dos escaneos, escaneando toda la red con 256 hosts, incluidos los 100 puertos principales (`-F`).
==Con un RTT sin optimizar==:

```shell
sudo nmap 10.129.2.0/24 -F

<SNIP>
Nmap done: 256 IP addresses (10 hosts up) scanned in 39.44 seconds
```

==Con un RTT optimizado==:
```shell
sudo nmap 10.129.2.0/24 -F --initial-rtt-timeout 50ms --max-rtt-timeout 100ms

<SNIP>
Nmap done: 256 IP addresses (8 hosts up) scanned in 12.29 seconds
```
Vemos que en el ==escáner optimizado, se ha saltado 2 hosts==, podemos concluir que **configurar el tiempo de espera inicial de RTT en un período de tiempo demasiado corto puede hacer que pasemos por alto algunos hosts**.


# Max Retries
Otra forma de aumentar la velocidad de los escaneos es especificar la tasa de reintentos de los paquetes enviados (`--max-retries`). El **valor predeterminado para la tasa de reintentos es 10**, por lo que si Nmap no recibe una respuesta para un puerto, ==no enviará más paquetes a ese puerto y se omitirá==. Usaremos el mismo ejemplo anterior pero modificando el número máximo de reintentos.
==Con un número sin optimizar==:

```shell
sudo nmap 10.129.2.0/24 -F | grep "/tcp" | wc -l

23
```

==Con un número optimizado==:
```shell
sudo nmap 10.129.2.0/24 -F --max-retries 0 | grep "/tcp" | wc -l

21
```
Nuevamente, reconocemos que **la aceleración también puede tener un efecto negativo en nuestros resultados**, lo que significa que podemos pasar por alto información importante.


# Rates
Si conocemos el ancho de banda de la red, podemos trabajar con la tasa de envío de paquetes, lo que acelera significativamente nuestros análisis con Nmap. Al configurar la **tasa mínima para enviar paquetes** (`--min-rate <número>`), le indicamos a Nmap que ==envíe simultáneamente la cantidad especificada de paquetes por segundo e intentará mantener la tasa en consecuencia==.


# Timing
Nmap ofrece seis plantillas de tiempos diferentes (`-T <0-5>`) para que las usemos. Estos valores (0-5) **determinan la agresividad de nuestros análisis**. Esto también ==puede tener efectos negativos si el análisis es demasiado agresivo y los sistemas de seguridad pueden bloquearnos== debido al tráfico de red producido. La plantilla de tiempos predeterminada que se utiliza cuando no hemos definido nada más es la normal (`-T 3`). Las opciones de tiempos son:
- `-T 0` / `-T paranoid`
- `-T 1` / `-T sneaky`
- `-T 2` / `-T polite`
- `-T 3` / `-T normal`
- `-T 4` / `-T aggressive`
- `-T 5` / `-T insane`

Estas plantillas contienen opciones que también podemos configurar manualmente, y ya hemos visto algunas de ellas. Las opciones utilizadas exactas con sus valores se pueden encontrar aquí: https://nmap.org/book/performance-timing-templates.html


---
**Podemos encontrar más información del rendimiento de Nmap en**: [https://nmap.org/book/man-performance.html](https://nmap.org/book/man-performance.html)




