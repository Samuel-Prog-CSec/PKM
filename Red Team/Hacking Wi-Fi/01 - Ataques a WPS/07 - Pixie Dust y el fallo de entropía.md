---
tags:
  - Wi-Fi/WPS
  - Pentesting/Explotacion
Descripción: "Por qué los nonces E-S1 y E-S2 predecibles convierten el PIN en un problema offline de 11.000 candidatos resolubles en milisegundos"
Fecha de actualización: 2026-08-01
Nota previa: "[[06 - Algoritmos de generación de PIN]]"
Nota siguiente: "[[08 - Ejecución del ataque Pixie Dust]]"
Area: "[[WPS.base|WPS]]"
---
---

<mark style="background: #ADCCFFA6;">Pixie Dust convierte la fuerza bruta *online* de 11.000 intentos contra el AP en un cálculo *offline* de milisegundos</mark>. Lo descubrió **Dominique Bongard** en el verano de 2014 y lo presentó en [hack.lu](http://archive.hack.lu/2014/Hacklu2014_offline_bruteforce_attack_on_wps.pdf). No explota el protocolo WPS, sino la **implementación** del generador de números aleatorios de determinados chipsets.

# El planteamiento

En M3 el AP entrega dos hashes:

```text
E-Hash1 = HMAC-SHA-256(AuthKey, E-S1 ‖ PSK1 ‖ PKe ‖ PKr)
E-Hash2 = HMAC-SHA-256(AuthKey, E-S2 ‖ PSK2 ‖ PKe ‖ PKr)
```

De los cuatro términos de cada expresión, tres son accesibles al atacante:

| Término | ¿Se conoce? |
| ------- | ----------- |
| `PKe` | **Sí** — llega en M1 |
| `PKr` | **Sí** — lo genera el propio atacante |
| `AuthKey` | **Sí** — se deriva del secreto DH y los nonces públicos |
| `PSK1` / `PSK2` | No, pero son sólo **10⁴ y 10³ candidatos** |
| `E-S1` / `E-S2` | **No.** 128 bits cada uno |

<mark style="background: #FFB86CA6;">Todo el problema se reduce a esos dos nonces</mark>. Si fueran realmente aleatorios, adivinarlos costaría 2¹²⁸ y el ataque no existiría. Pero si son predecibles, se sustituyen en la fórmula y quedan como únicas incógnitas `PSK1` y `PSK2`, que se recorren enteros en local:

```text
para cada PSK1 en 0000..9999:
    si HMAC-SHA-256(AuthKey, E-S1 ‖ PSK1 ‖ PKe ‖ PKr) == E-Hash1:
        primera mitad encontrada
```

Once mil comprobaciones de HMAC-SHA-256 en una CPU son un instante.

# Los tres patrones de fallo

## 1 · Nonce nulo — Ralink, MediaTek, Celeno

El caso más simple y más extendido: **los nonces nunca se generan** y quedan a cero.

```text
E-Hash1 = HMAC-SHA-256(AuthKey, 0x00…00 ‖ PSK1 ‖ PKe ‖ PKr)
```

No hay nada que adivinar. Se reconoce en la salida de la herramienta:

```text
[*] Seed ES1: 0x00000000
[*] Seed ES2: 0x00000000
[*] ES1: 00000000000000000000000000000000
[*] ES2: 00000000000000000000000000000000
```

## 2 · PRNG compartido — Broadcom

El chipset usa **el mismo generador** para el nonce `N1`, para `PKe` y para `E-S1`/`E-S2`. Como `N1` y `PKe` viajan en claro en M1, se puede **recuperar el estado interno del PRNG** buscando la semilla que los produce, y con ella generar los nonces siguientes.

Bongard documentó que varias implementaciones de Broadcom usan directamente `rand()` de la biblioteca estándar de C — un LCG cuyo estado se reconstruye a partir de una sola salida.

## 3 · Semilla temporal — Realtek

El PRNG se siembra con el **timestamp Unix** del intercambio EAP. Como los mensajes se suceden en milisegundos, `E-S1`, `E-S2` y `PKe` se generan con la misma semilla o con semillas que difieren en muy poco:

```text
E-S1 = E-S2 = PKe        (mismo segundo)
E-S1 = E-S2 = PKe + N    (N pequeño)
```

Basta con recorrer un rango corto de timestamps alrededor del momento de la captura.

# Qué implica en la práctica

<mark style="background: #FF5582A6;">Pixie Dust necesita **un solo intercambio EAP**: llega hasta M3, guarda los valores y desconecta</mark>. Eso tiene tres consecuencias que lo convierten en el primer vector a probar:

- **No dispara el bloqueo.** Un AP que se bloquea a los tres PIN fallidos no llega a contar ninguno, porque no se prueba ningún PIN contra él.
- **Es casi instantáneo.** De milisegundos a unos minutos, frente a horas.
- **Deja poquísimo rastro.** Una asociación y un intercambio EAP incompleto, indistinguible de un cliente que abandona un registro WPS.

| | Fuerza bruta online | Pixie Dust |
| - | ------------------- | ---------- |
| Intercambios con el AP | Hasta 11.000 | **1** |
| Tiempo | 3–10 h | ms – min |
| Bloqueo del AP | Muy probable | No aplica |
| Ruido en WIDS | Alto | Mínimo |
| Requisito | Que no bloquee | **Que el chipset sea vulnerable** |

# Qué lo hace fallar

Un AP **no** es vulnerable si su PRNG genera nonces con entropía real. Los chipsets modernos y el firmware actualizado suelen estar corregidos, así que Pixie Dust falla en buena parte del equipamiento nuevo. La herramienta lo dice sin ambigüedad:

```text
[-] WPS pin not found!
```

Cuando eso ocurre, se pasa a los PIN por defecto ([[06 - Algoritmos de generación de PIN]]) y, sólo como último recurso, a la fuerza bruta.

> [!important]+ Recuperar la PSK de una captura pasiva
> Una capacidad que HTB no menciona y que cambia el planteamiento: **desde la versión 1.4, `pixiewps` puede recuperar la `WPA-PSK` directamente de una captura pasiva completa** de un registro WPS legítimo (mensajes M1 a M7), en los dispositivos que funcionan con `--mode 3` ([README de pixiewps](https://github.com/wiire-a/pixiewps)).
>
> <mark style="background: #8000E1A6;">Eso significa que, si un usuario legítimo pulsa el botón WPS mientras se está capturando, la contraseña cae sin transmitir absolutamente nada</mark>. En un engagement con presencia física prolongada, dejar una captura corriendo sobre el canal del AP es gratis y puede resolver el objetivo solo.

# El lado defensivo

La mitigación no está en el protocolo sino en el firmware, y por eso es tan difícil de comprobar desde fuera:

1. **Actualizar el firmware.** Los parches que corrigen el PRNG existen para buena parte del equipamiento afectado, aunque rara vez se aplican en el parque doméstico.
2. **Desactivar WPS**, que es lo único que elimina la superficie completa.
3. **No confiar en el bloqueo por intentos** como mitigación: no afecta en absoluto a este vector.

La ejecución concreta con reaver y OneShot es [[08 - Ejecución del ataque Pixie Dust]].
