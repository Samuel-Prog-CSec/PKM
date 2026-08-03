---
tags:
  - Reversing
  - Protocolos
  - Pentesting/Enumeracion
Descripción: "Cuando el cliente es .NET o Java, decompilar devuelve código casi original — y cómo lidiar con la ofuscación que intenta impedirlo"
Fecha de actualización: 2026-08-03
Nota previa: "[[03 - Reversing dinámico - debuggers y hooking]]"
Nota siguiente: 
Area: "[[Reversing de protocolos.base|Reversing de protocolos]]"
---
---

Antes de sufrir con desensamblado, comprueba con qué estás tratando. Si el cliente es **.NET o Java**, no hace falta reversing: hace falta un decompilador, y en diez minutos tienes código fuente legible. Es la diferencia entre días y una tarde.

```shell-session
$ file cliente.exe
# PE32 executable ... Mono/.Net assembly  ← .NET, no código nativo

$ file cliente.jar
# Java archive data (JAR)                 ← un ZIP con .class dentro
```

Si al cargar un `.exe` en un desensamblador de x86 lo que sale es basura y un mensaje sobre metadatos .NET, ya lo sabes.

## Por qué decompilan tan bien

Ambos compilan a un **bytecode intermedio** —`CIL` en .NET, *Java bytecode* en la JVM— que conserva metadatos abundantes: nombres de clases, de métodos, de campos, tipos de parámetros y firmas completas. Ese bytecode es de alto nivel y bastante predecible, así que la reconstrucción a C# o Java es <mark style="background: #ADCCFFA6;">prácticamente equivalente al original</mark>, salvo comentarios y nombres de variables locales.

## .NET

| Herramienta | Estado | Nota |
| - | - | - |
| **ILSpy** | Activo | Libre y multiplataforma. El que cita el libro y sigue siendo válido |
| **dnSpyEx** | Activo | Fork mantenido de dnSpy: decompila **y depura**, incluso editando el código en caliente |
| **dotPeek** | Gratuito (JetBrains) | Muy buena calidad de decompilación |
| **ILSpy CLI** (`ilspycmd`) | Activo | Para automatizar |
| ~~.NET Reflector~~ | Comercial | El del libro; ILSpy nació como su alternativa libre |

Flujo: abre el ejecutable principal —el decompilador resuelve solas las dependencias— y busca por los espacios de nombres que delatan red y cripto:

```text
System.Net.Sockets          → TcpClient, Socket, NetworkStream
System.Net.Http             → HttpClient
System.Security.Cryptography → Aes, RSA, HMACSHA256
System.IO                   → BinaryReader / BinaryWriter  ← el parser del protocolo
```

**`BinaryReader` y `BinaryWriter` son el hallazgo directo**: sus llamadas (`ReadInt32`, `ReadString`, `Write(byte[])`) son literalmente la gramática del protocolo, campo a campo y en orden. Encontrar la clase que los usa te da la especificación completa sin analizar un solo byte del cable.

`dnSpyEx` permite además poner *breakpoints* y **editar el código en ejecución**: quitar una comprobación de certificado o cambiar un endpoint es cuestión de minutos.

## Java

Un `.jar` es un ZIP con `.class` dentro (más `META-INF/MANIFEST.MF`). Se descomprime con cualquier cosa.

| Herramienta | Estado | Nota |
| - | - | - |
| **CFR** | Activo | Muy buena con construcciones modernas (lambdas, `switch` sobre cadenas, *records*) |
| **Procyon** | Activo | Alternativa sólida |
| **Vineflower** | Activo | Sucesor de Fernflower, el motor de IntelliJ |
| **Recaf** | Activo | GUI: decompila, **edita y reempaqueta** |
| **jadx** | Activo | Para **Android** (APK/DEX). El estándar de facto |
| ~~JD-GUI~~ | Estancado | El del libro; muy por detrás con Java moderno |

```shell-session
$ java -jar cfr.jar cliente.jar --outputdir fuentes/
$ jadx -d salida/ app.apk                      # Android
$ grep -rn "DataInputStream\|readInt\|writeUTF" fuentes/
```

Lo equivalente a `BinaryReader`: **`DataInputStream`/`DataOutputStream`** (`readInt`, `readUTF`, `writeShort`) o `ByteBuffer` con `order(ByteOrder.BIG_ENDIAN)`. Y `javax.crypto` para el cifrado.

> [!important]+ Java lo pone todo aún más fácil
> `writeUTF()` escribe una cadena con **prefijo de longitud de 2 octetos big endian**. Si en el volcado ves cadenas precedidas de un `uint16`, ya sabes que el otro extremo es Java y que el parser es `DataInputStream` — [[01 - Datos de longitud variable|patrón de longitud prefijada]] identificado sin desensamblar nada.
>
> Y si el volcado empieza por **`AC ED 00 05`**, el protocolo transporta objetos serializados de Java, con todo lo que eso implica ([[03 - Formatos binarios estructurados]]).

## Ofuscación

Cuando el fabricante no quiere que leas su «salsa secreta», pasa el binario por `ProGuard`/`R8` (Java, Android), `Dotfuscator`/`ConfuserEx`/`Eazfuscator` (.NET) o similares. Lo que hacen:

- **Renombrar** clases, métodos y campos a `a`, `b`, `aa`… Es lo más común y lo menos dañino.
- **Cifrar cadenas**, descifrándolas en tiempo de ejecución.
- **Aplanar el flujo de control** (*control flow flattening*): convertir la estructura en una máquina de estados ilegible.
- **Inyectar código muerto** y comprobaciones anti-manipulación.

Cómo se lidia con ello:

> [!important]+ Lo que la ofuscación NO puede tocar
> **Las llamadas a librerías externas.** `Socket.Send`, `SSL_write`, `javax.crypto.Cipher.doFinal` **tienen que aparecer con su nombre real**, porque el runtime las resuelve por nombre. Un método puede llamarse `a.b.c()`, pero si dentro invoca `Cipher.doFinal`, ahí está tu punto de partida. **Busca siempre por las APIs del sistema, nunca por los nombres del programa.**

El resto de tácticas:

- **Ejecutar el desofuscador del propio programa.** Como .NET y Java cargan código dinámicamente, puedes escribir un arnés que llame a la rutina de descifrado de cadenas y volcarlas todas. Herramientas como `de4dot` (.NET) automatizan esto para los ofuscadores conocidos.
- **Reversing dinámico.** Enganchar `Cipher.doFinal` con Frida te da el texto plano sin descifrar nada ([[03 - Reversing dinámico - debuggers y hooking]]). La ofuscación protege el código, **no los datos que lo atraviesan**.
- **Renombrar según avanzas.** El decompilador propaga el cambio a todas las referencias; renombrando 20 símbolos clave, el código pasa de ilegible a seguible.

## Y no olvides el otro extremo

Muchas veces el cliente está ofuscado y el **servidor no**. O al revés. Si el producto trae ambos —típico en software empresarial— empieza por el que sea gestionado y sin ofuscar: el protocolo es el mismo.

> [!info]+ Fuentes
> - [ILSpy](https://github.com/icsharpcode/ILSpy) y [dnSpyEx](https://github.com/dnSpyEx/dnSpy).
> - [CFR](https://www.benf.org/other/cfr/), [Vineflower](https://github.com/Vineflower/vineflower), [jadx](https://github.com/skylot/jadx).
> - [de4dot](https://github.com/de4dot/de4dot) — desofuscador de .NET para ofuscadores conocidos.
> - Forshaw, *Attacking Network Protocols*, cap. 6, «Reverse Engineering Managed Languages» (JD-GUI y .NET Reflector, hoy superados).
