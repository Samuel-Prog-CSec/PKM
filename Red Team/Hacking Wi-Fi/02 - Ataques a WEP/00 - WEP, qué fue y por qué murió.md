---
tags:
  - Wi-Fi/WEP
  - Pentesting/Enumeracion
  - Tipo/Introduccion
Descripción: "Los tres fallos de diseño de WEP —IV de 24 bits, ICV lineal y clave estática— y por qué sigue apareciendo en entornos industriales en 2026"
Fecha de actualización: 2026-08-01
Nota previa: 
Nota siguiente: "[[01 - RC4 y la generación del keystream]]"
Area: "[[WEP.base|WEP]]"
---
---

<mark style="background: #ADCCFFA6;">`WEP` (*Wired Equivalent Privacy*) fue el primer mecanismo de cifrado de 802.11, publicado con el estándar en 1997</mark>. Su nombre declara su ambición: dar a una red inalámbrica una privacidad *equivalente* a la de un cable. No lo consiguió, y su autopsia sigue siendo el mejor ejemplo de cómo un diseño criptográfico se rompe por las decisiones de alrededor, no por el cifrado en sí.

# Las piezas

| Componente | Función |
| ---------- | ------- |
| **Clave WEP** | 40 o 104 bits, **estática** y compartida por toda la red |
| **IV** | Vector de inicialización de **24 bits**, distinto por paquete, transmitido **en claro** |
| **RC4** | Cifrado de flujo. Genera el `keystream` a partir de IV ‖ clave |
| **ICV** | `CRC-32` del texto en claro, cifrado junto con él |

De ahí el marketing: "WEP de 64 bits" son 40 bits de clave + 24 de IV; "WEP de 128 bits", 104 + 24. <mark style="background: #FFB8EBA6;">La clave real es de 40 o 104 bits</mark>; el resto es un valor público. Existen variantes propietarias de 232 bits, fuera del estándar.

> [!info]+ Por qué 40 bits
> No fue una decisión técnica. En 1997 la criptografía estaba clasificada como munición por la normativa de exportación de EE. UU., que limitaba las claves exportables. Cuando esas restricciones se levantaron, WEP se amplió a 104 bits **pero mantuvo el IV de 24** — y ahí sigue el fallo, porque el problema nunca fue la longitud de la clave.

# Los tres fallos

## 1 · El IV es demasiado corto

Veinticuatro bits son 16.777.216 valores posibles. Un enlace saturado los agota en horas, pero no hace falta esperar tanto: por la **paradoja del cumpleaños**, la probabilidad de que dos paquetes compartan IV supera el 50 % en torno a los **5.000 paquetes**.

<mark style="background: #FFB86CA6;">Dos paquetes con el mismo IV y la misma clave producen el **mismo keystream**</mark>. Y en un cifrado de flujo eso es fatal:

```text
C1 = P1 ⊕ KS
C2 = P2 ⊕ KS
C1 ⊕ C2 = P1 ⊕ P2      ← el keystream desaparece
```

El atacante obtiene el XOR de dos textos en claro sin conocer la clave. Con tráfico predecible —cabeceras IP, ARP, DHCP— eso se resuelve.

Peor aún: el estándar **no especifica cómo generar el IV**. Muchas implementaciones lo usan secuencialmente desde cero en cada reinicio, lo que garantiza colisiones inmediatas entre dispositivos.

## 2 · El ICV es lineal

`CRC-32` detecta errores de transmisión; no es una función de integridad criptográfica. Su propiedad fatal es la **linealidad respecto al XOR**, que permite modificar un paquete cifrado y corregir su checksum **sin conocer la clave**. Es la base de la inyección de tráfico y de [[07 - KoreK ChopChop]]. Se desarrolla en [[02 - El ICV CRC-32 y su linealidad]].

## 3 · La clave es estática y compartida

No hay derivación por sesión ni por cliente: la misma clave cifra todo el tráfico de todos los dispositivos hasta que un humano la cambia. <mark style="background: #FF5582A6;">Recuperarla una vez da acceso permanente y permite descifrar retroactivamente todo lo capturado</mark>.

Y en el cifrado de flujo, la clave estática es lo que hace que las colisiones de IV importen: si la clave rotara, un IV repetido no daría el mismo keystream.

# La cronología del colapso

| Año | Hito |
| --- | ---- |
| 1997 | WEP se publica con 802.11 |
| 2001 | **FMS** — Fluhrer, Mantin y Shamir explotan IVs débiles del KSA de RC4 |
| 2004 | **KoreK** generaliza FMS con 17 correlaciones estadísticas |
| 2004 | La Wi-Fi Alliance **retira WEP**; llegan WPA y luego 802.11i/WPA2 |
| 2005 | **ChopChop** (KoreK) descifra paquetes sin conocer la clave |
| 2007 | **PTW** — Pyshkin, Tews y Weinmann bajan el listón a ~40.000 paquetes |
| 2007 | **Café Latte** — Vivek Ramachandran ataca al cliente, no al AP |

<mark style="background: #8000E1A6;">De "roto en teoría" a "roto en minutos con herramientas de línea de comandos" pasaron seis años</mark>. Hoy una clave WEP de 104 bits se recupera en minutos con los ataques de inyección de este módulo.

# Autenticación WEP: Open y Shared

WEP admite dos modos de autenticación 802.11, y el que parece más seguro lo es menos.

**Open System** — el cliente se asocia sin probar nada. Sin la clave correcta no podrá cifrar ni descifrar, así que el control efectivo llega después.

**Shared Key** — el AP envía 128 bytes de texto de desafío en claro, el cliente los devuelve cifrados y el AP verifica.

![Intercambio de autenticación WEP con clave compartida: petición, desafío, respuesta cifrada y confirmación](https://academy.hackthebox.com/storage/modules/222/Auth_Methods/Wep_process.png)

> [!warning]+ Shared Key es peor que Open
> Un observador del intercambio obtiene el desafío **en claro** y **cifrado**. Ambos juntos revelan directamente 128 bytes de `keystream` válido para ese IV:
> ```text
> KS = desafío_claro ⊕ desafío_cifrado
> ```
> <mark style="background: #FF5582A6;">Con ese keystream se puede forjar tráfico sin conocer la clave</mark> — es exactamente lo que hace el *fake authentication* de `aireplay-ng -1`, que abre la puerta a todos los ataques de inyección. El modo pensado para "probar identidad" acaba regalando material criptográfico. Ver [[09 - Atacar un AP WEP sin clientes]].

# Por qué sigue importando en 2026

WEP lleva veinte años retirado y, aun así, aparece. Dónde buscarlo:

- **Sistemas de control industrial y SCADA.** Equipamiento con ciclos de vida de 20–30 años, certificado con un firmware concreto que nadie va a recertificar.
- **Dispositivos médicos y de laboratorio** anteriores a WPA2.
- **Escáneres de código de barras y terminales de almacén** heredados.
- **Redes de invitados olvidadas** en hoteles, gimnasios y comunidades.
- **Modos de migración WPA/WEP**, donde un AP acepta ambos por compatibilidad — lo que convierte una red "WPA" en una red WEP a efectos prácticos ([[04 - Aireplay-ng]], ataque `-8`).

Se detecta en un escaneo pasivo, sin transmitir nada:

```shell-session
$ sudo airodump-ng --band abg -t WEP wlan0mon
```

> [!important]+ Cómo redactar el hallazgo
> Encontrar WEP no es "cifrado débil": es **ausencia efectiva de cifrado**. La clave se recupera en minutos con independencia de su longitud, y una vez obtenida descifra retroactivamente todo el tráfico capturado. La recomendación no es cambiar la clave ni alargarla, sino **migrar el equipamiento**; y si un dispositivo industrial no puede migrarse, aislarlo en su propia VLAN sin acceso al resto de la red y tratar ese segmento como no confiable.

Cómo funciona el cifrado por dentro —y dónde exactamente se rompe— empieza en [[01 - RC4 y la generación del keystream]].
