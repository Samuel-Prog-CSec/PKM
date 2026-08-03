---
tags:
  - Reversing
  - Protocolos
  - Pentesting/Explotacion
Descripción: "Ejecutar en vez de leer: dónde poner breakpoints para cazar el protocolo y por qué Frida resuelve en veinte líneas lo que el análisis estático tarda días"
Fecha de actualización: 2026-08-03
Nota previa: "[[02 - Localizar el código de red en un binario]]"
Nota siguiente: "[[04 - Aplicaciones gestionadas - .NET, Java y ofuscación]]"
Area: "[[Reversing de protocolos.base|Reversing de protocolos]]"
---
---

El análisis estático te dice qué **puede** hacer el programa; el dinámico, qué **hace**. Para criptografía propietaria, compresión rara o *framing* calculado, ejecutar y observar es órdenes de magnitud más rápido que leer desensamblado: en vez de reconstruir el algoritmo, <mark style="background: #8000E1A6;">te colocas justo antes de que cifre y justo después de que descifre</mark>.

## Dónde poner los breakpoints

Por orden de rentabilidad:

1. **`send` / `recv` / `SSL_write` / `SSL_read`.** El punto exacto donde los datos cruzan la frontera. En `send` ves el paquete **ya construido**; retrocediendo por la pila de llamadas llegas a quien lo construyó.
2. **La función de cifrado**, si la identificaste por constantes ([[02 - Localizar el código de red en un binario]]). Antes de cifrar tienes el texto plano; después, el que sale al cable.
3. **La función que calcula el checksum o el MAC.** Enganchándola puedes generar valores válidos para paquetes que fabriques tú, sin reimplementar el algoritmo.
4. **Asignación de memoria** (`malloc`, `HeapAlloc`) con el tamaño que sale del protocolo — donde aparecen los desbordamientos.

La pila de llamadas en el momento del *breakpoint* es lo más valioso: te da el camino completo desde el bucle de red hasta el parser, y con eso el análisis estático deja de ser exploratorio y pasa a ser dirigido.

## Depuradores por plataforma

| Plataforma | Herramienta | Nota |
| - | - | - |
| Windows | **x64dbg** | Libre, moderno, con plugins anti-anti-debug (`ScyllaHide`) |
| Windows | **WinDbg / CDB** | Oficial de Microsoft; imprescindible para modo kernel |
| Linux | **GDB + `pwndbg` o `GEF`** | Los plugins son lo que lo hace usable para seguridad |
| macOS | **LLDB** | El nativo; SIP limita qué se puede trazar |
| Todos | **Ghidra + debugger** | Sincroniza vista estática y dinámica |
| Todos | **Frida** | No es depurador: instrumenta. Ver abajo |

> [!warning]+ El `IDA Pro Free` del libro ya no es lo que era
> El libro construye el capítulo sobre **IDA Pro Free Edition 5.0**, que era x86-32, sin decompilador y sin uso comercial. Hoy:
> - **Ghidra 12.1.2** (NSA, libre y de código abierto, junio 2026) trae **decompilador para todas las arquitecturas**, es gratis y **sí permite uso comercial**. Para pentest profesional es la opción por defecto.
> - **IDA Free** actual soporta x86/x86-64 y trae decompilador **solo en la nube y solo para x86**, sin SDK ni IDAPython, y **prohíbe el uso comercial**.
> - **Binary Ninja** y **radare2/rizin + Cutter** completan el panorama.
>
> Es decir: la recomendación del libro se ha invertido. Salvo que ya tengas licencia de IDA Pro, **empieza por Ghidra**.

## Frida: la pieza que el libro no tiene

`Frida` (17.16.4, julio 2026) inyecta un motor de JavaScript en el proceso y deja enganchar cualquier función. Es lo más productivo que existe hoy para este problema, y no aparece en el libro porque en 2018 aún no era el estándar.

**Volcar todo lo que entra y sale del socket:**

```javascript
['send', 'recv'].forEach(nombre => {
  Interceptor.attach(Module.getExportByName(null, nombre), {
    onEnter(args) { this.buf = args[1]; this.len = args[2].toInt32(); },
    onLeave(ret) {
      const n = ret.toInt32();
      if (n > 0) console.log(`[${nombre}] ${n}B\n` + hexdump(this.buf, { length: n }));
    }
  });
});
```

**Texto plano de TLS, sin proxy ni CA:**

```javascript
Interceptor.attach(Module.getExportByName('libssl.so.3', 'SSL_write'), {
  onEnter(args) {
    console.log('[TLS →]\n' + hexdump(args[1], { length: args[2].toInt32() }));
  }
});
```

**Sacar la clave de una función de cifrado propietaria:**

```javascript
// 0x1a2b0 = offset de la función localizado en Ghidra
const cifrar = Module.getBaseAddress('cliente').add(0x1a2b0);
Interceptor.attach(cifrar, {
  onEnter(args) {
    console.log('clave:', hexdump(args[0], { length: 32 }));
    console.log('plano:', hexdump(args[1], { length: args[2].toInt32() }));
  }
});
```

> [!important]+ Por qué cambia el cálculo
> Con esos tres *scripts* resuelves casos que por análisis estático llevarían días: no necesitas entender el algoritmo, solo interceptar sus argumentos. Y funciona **igual de bien contra código ofuscado**, porque la ofuscación protege el código, no los datos que pasan por él en tiempo de ejecución.
>
> Frida además **sustituye** valores: `args[2].writeU32(0x1000)` cambia una longitud antes de que la función la use — un fuzzer en el punto exacto, sin tocar la red.

Y con `frida-trace`, sin escribir nada:

```shell-session
$ frida-trace -f ./cliente -i 'send' -i 'recv' -i 'SSL_*'
$ frida-trace -U -f com.app.objetivo -i 'SSL_*'        # sobre Android por USB
```

## Cuando el binario se defiende

Un objetivo con anti-*debugging* detectará `ptrace` y `IsDebuggerPresent`. Opciones:

- **Frida en vez de depurador**: instrumenta sin `ptrace`, así que `TracerPid` sigue a 0 (aunque Frida tiene sus propias huellas detectables).
- **eBPF `uprobes`**: trazan funciones de usuario desde el kernel, invisibles para el proceso.
- **Plugins anti-anti-debug**: `ScyllaHide`, `HyperHide` para x64dbg.
- **Parchear** las comprobaciones — definitivo pero rompe firmas.

El detalle de este juego está en [[Evasión de defensas.base|Evasión de defensas]] y en [[08 - Detección y evasión del análisis activo]].

## El bucle que funciona

Estático y dinámico no compiten, se turnan:

1. **Estático** → localizar candidatos por imports y cadenas.
2. **Dinámico** → *breakpoint* o *hook* para confirmar cuál es el bueno.
3. **Estático** → entender la lógica alrededor, con la función ya identificada.
4. **Dinámico** → validar la hipótesis modificando argumentos y viendo qué sale al cable.

Ghidra e IDA sincronizan ambas vistas: renombras una función en el depurador y el cambio aparece en el desensamblado.

> [!info]+ Fuentes
> - [Frida — JavaScript API](https://frida.re/docs/javascript-api/) (`Interceptor`, `Module`, `hexdump`). Versión verificada 17.16.4 (2026-07-21).
> - [Ghidra](https://github.com/NationalSecurityAgency/ghidra/releases) — versión verificada 12.1.2 (2026-06-05).
> - [IDA Free — limitaciones](https://hex-rays.com/ida-free): decompilador solo en la nube y solo x86, sin uso comercial.
> - [pwndbg](https://github.com/pwndbg/pwndbg) y [GEF](https://github.com/hugsy/gef) para GDB.
