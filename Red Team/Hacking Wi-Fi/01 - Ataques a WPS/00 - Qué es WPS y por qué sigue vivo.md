---
tags:
  - Wi-Fi/WPS
  - Pentesting/Enumeracion
  - Tipo/Introduccion
Descripción: "Los cuatro métodos de conexión WPS, por qué el método PIN quedó roto en 2011 y por qué en 2026 sigue activado en la mayoría de routers"
Fecha de actualización: 2026-08-01
Nota previa: 
Nota siguiente: "[[01 - El protocolo de registro y la anatomía del PIN]]"
Area: "[[WPS.base|WPS]]"
---
---

<mark style="background: #ADCCFFA6;">`WPS` (*Wi-Fi Protected Setup*) es un mecanismo de aprovisionamiento pensado para que un usuario sin conocimientos técnicos conecte un dispositivo a su red sin teclear la contraseña</mark>. Lo desarrolló Cisco y la Wi-Fi Alliance lo certificó en 2007. Resuelve un problema real —las claves WPA robustas son incómodas de introducir en una impresora o una cámara— y lo resuelve introduciendo un fallo de diseño que sigue siendo, veinte años después, la vía más rápida de entrar en una red WPA2 doméstica.

# Los cuatro métodos

| Método | Cómo funciona | Riesgo |
| ------ | ------------- | ------ |
| **PBC** (*Push Button Configuration*) | Se pulsa un botón físico o virtual en AP y cliente; durante ~2 minutos se aceptan asociaciones | Ventana temporal abierta a cualquiera en alcance |
| **PIN Entry** | Un PIN de 8 dígitos, impreso en la etiqueta o generado en el panel del AP | **Roto por diseño** |
| **NFC** | Acercar el dispositivo al AP | Requiere proximidad física. Poco desplegado |
| **USB** | Transferir la configuración con una memoria | Prácticamente en desuso |

El **método PIN es el problema**, y su presencia es obligatoria: la certificación WPS exige que un AP soporte PIN, mientras que PBC es opcional en el cliente. <mark style="background: #FFB86CA6;">Un dispositivo certificado WPS acepta el método PIN aunque el usuario sólo use el botón</mark>.

# El fallo

El PIN de ocho dígitos debería dar 10⁸ combinaciones. En la práctica son **11.000**, por dos motivos acumulados:

1. El último dígito es un **checksum** calculable a partir de los otros siete → 10⁷.
2. El AP valida el PIN **en dos mitades independientes** y responde con `NACK` en cuanto la primera es incorrecta → 10⁴ + 10³ = **11.000**.

<mark style="background: #FF5582A6;">Ese segundo punto es el error de diseño</mark>: al filtrar en qué mitad ha fallado, el AP convierte un problema exponencial en dos problemas pequeños e independientes. La mecánica exacta está en [[01 - El protocolo de registro y la anatomía del PIN]].

> [!info]+ Cronología del ataque
> - **Diciembre de 2011** — Stefan Viehböck publica la debilidad del PIN y US-CERT emite el aviso [VU#723755](https://www.kb.cert.org/vuls/id/723755) (`CVE-2011-5053`). Nacen `reaver` y `bully`: el PIN cae en unas horas de fuerza bruta *online*.
> - **Verano de 2014** — Dominique Bongard presenta el **ataque Pixie Dust** en [hack.lu](http://archive.hack.lu/2014/Hacklu2014_offline_bruteforce_attack_on_wps.pdf): muchos chipsets generan los nonces `E-S1`/`E-S2` con PRNG predecibles —Broadcom usa `rand()` de C, y en Ralink valen directamente cero—, lo que permite recuperar el PIN **offline en segundos**.
> - **2026** — WPS sigue activado por defecto en buena parte del equipamiento doméstico y de PYME.

# Por qué sigue existiendo

Es la pregunta que hay que responder en el informe, porque el administrador dirá que "eso se arregló hace años".

**WPA3 no admite WPS.** Su sustituto es **Wi-Fi Easy Connect**, la marca de la Wi-Fi Alliance para el *Device Provisioning Protocol* (`DPP`), que sustituye el PIN por criptografía de clave pública con un código QR. <mark style="background: #FFB8EBA6;">Pero la Wi-Fi Alliance **no exige** Easy Connect para certificar WPA3</mark>: es un programa aparte, y su adopción es marginal — en febrero de 2025 había apenas 23 dispositivos certificados DPP de 6 fabricantes.

El resultado son tres situaciones que se encuentran a diario:

- **Redes WPA2 con WPS activo.** Lo más común. El ataque funciona íntegro.
- **Redes en modo transición WPA3/WPA2** donde el AP mantiene WPS para la parte WPA2. El "tenemos WPA3" no protege.
- **Equipamiento que no permite desactivarlo**, o cuyo interruptor de la interfaz web no desactiva realmente el método PIN — un fallo documentado en varios fabricantes.

Cisco publicó en su blog corporativo [*It is time to deprecate and replace Wi-Fi (un)Protected Setup*](https://blogs.cisco.com/networking/it-is-time-to-deprecate-and-replace-wi-fi-unprotected-setup), lo que da una idea de dónde está el consenso — y de que la retirada aún no ha ocurrido.

# Por qué es un hallazgo grave

Comprometer WPS no da acceso a una sesión: <mark style="background: #8000E1A6;">devuelve la **`WPA-PSK` en claro**</mark>. Con ella se entra en la red como un cliente legítimo, se descifra el tráfico capturado de todos los clientes cuyo handshake se tenga, y se conserva el acceso indefinidamente — hasta que alguien cambie la contraseña, cosa que no ocurre.

Y a diferencia del cracking de WPA2, **no depende de la fortaleza de la contraseña**. Una PSK de 63 caracteres aleatorios cae igual que `12345678` si WPS está activo. Es la razón por la que la comprobación de WPS va antes que cualquier intento de captura de handshake.

> [!important]+ El orden en un engagement
> `wash` o `airodump-ng --wps` tardan segundos y no transmiten nada. Hacerlo **antes** de plantear la captura de handshake evita horas de cracking innecesario. Ver [[02 - Reconocimiento de WPS]].

# Lo que hay que recomendar

1. **Desactivar WPS por completo**, y verificar que el interruptor funciona — comprobándolo con `wash` después.
2. Si el equipamiento no lo permite, **sustituirlo**. No hay mitigación parcial: el bloqueo tras intentos fallidos ralentiza la fuerza bruta online pero no impide Pixie Dust, que necesita **un solo intercambio**.
3. Migrar el aprovisionamiento a **Wi-Fi Easy Connect** donde exista soporte, o simplemente a introducir la contraseña.

El detalle del protocolo que hace posible todo esto es [[01 - El protocolo de registro y la anatomía del PIN]].
