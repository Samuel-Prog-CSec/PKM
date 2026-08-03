---
tags:
  - Protocolos
  - Evasion
  - Redes
  - Tipo/Deteccion
Descripción: "Qué rastro deja interponerse en un protocolo (RTT, TTL, certificados, huella TLS) y cómo lo detectan pinning, JA4 y anti-debug — con las contramedidas realistas"
Fecha de actualización: 2026-08-03
Nota previa: "[[07 - Modificar el protocolo en vuelo]]"
Nota siguiente: "[[09 - Arsenal de análisis de protocolos]]"
Area: "[[Análisis de protocolos.base|Análisis de protocolos]]"
---
---

El laboratorio del libro no se defiende. Un producto real de 2026 sí: comprueba certificados, mide latencias, se niega a arrancar bajo *debugger* y manda telemetría cuando algo huele mal. Esta nota va de qué rastro dejas al interponerte y qué se puede hacer al respecto.

## Lo que delata un proxy

| Señal | Por qué aparece | Quién la mira |
| - | - | - |
| **RTT anómalo** | Dos conexiones TCP en serie en vez de una | Cliente con `timeout` estricto o telemetría de latencia |
| **TTL / hop count** | El paquete nace en tu máquina, no en el servidor | IDS con perfilado de red |
| **Certificado distinto** | Tu CA no es la del servidor | *Pinning*, `Expect-CT` histórico, Certificate Transparency |
| **Huella TLS (JA3/JA4)** | Tu librería negocia distinto que el cliente real | WAF, anti-bot, CDN |
| **`hosts` modificado** | Escritura en un fichero vigilado | EDR — MITRE ATT&CK [T1565.001](https://attack.mitre.org/techniques/T1565/001/) |
| **ARP anómalo** | Dos IPs con la misma MAC, *gratuitous ARP* en ráfaga | DAI del switch, `arpwatch`, NDR |
| **`ptrace` activo** | `TracerPid` distinto de 0 | Anti-debug de la propia app |

### Certificate pinning

Es la defensa que más veces bloquea un análisis. La aplicación no confía en el almacén del sistema: lleva incrustado el certificado o el hash de la clave pública del servidor. <mark style="background: #FF5582A6;">Añadir tu CA al almacén de confianza no sirve de nada</mark>.

Vías, de menos a más invasiva:

1. **Sustituir el material *pinneado*** si está en un fichero de configuración o un `.pem` suelto junto al binario. Sorprendentemente frecuente.
2. **Frida** enganchando la función de verificación — la vía universal. En Android, `objection`/`frida-multiple-unpinning` cubren OkHttp, TrustManager, Conscrypt y Flutter; en escritorio, hay que localizar la función a mano ([[03 - Reversing dinámico - debuggers y hooking]]).
3. **Parchear el binario** para saltarse la comprobación. Definitivo, pero rompe firmas y comprobaciones de integridad.

En Android 7+ hay además la `Network Security Config`: por defecto **las apps no confían en las CA instaladas por el usuario**, así que el certificado hay que meterlo en el almacén del sistema (requiere *root*) o modificar el manifiesto de la app. Detalle en [[12 - Proxying de apps móviles]].

### Huella TLS: JA3, JA4 y el problema del `ClientHello`

El `ClientHello` es una firma: orden de *cipher suites*, extensiones, curvas, versiones. `JA3` (hash MD5 de esos campos) y su sucesor **`JA4`** —hoy el estándar de facto, con partes legibles y resistente a la aleatorización GREASE— identifican **la librería que negocia**, no el usuario.

Si el cliente real es un Java 17 y tu proxy renegocia con OpenSSL 3.5, la huella cambia y un WAF o un anti-bot puede cortarte. La contramedida es **preservar la huella**: reenviar el `ClientHello` original en vez de generar uno propio, o usar utilidades que imitan huellas concretas (`curl-impersonate`, `utls` en Go). Es la misma mecánica que en [[11 - OPSEC y evasión de detección]].

> [!warning]+ El cambio de huella no siempre es opcional
> Interponerse **implica** renegociar TLS. Si el objetivo perfila huellas y no puedes replicar la del cliente, la vía activa está cerrada y hay que volver al *hooking* en el proceso: enganchar `SSL_write` deja el TLS del cliente intacto porque no hay proxy en el camino.

### Anti-debugging

Un binario que detecta que lo trazas puede negarse a arrancar, comportarse distinto o alertar. Comprobaciones típicas: `IsDebuggerPresent`/`NtQueryInformationProcess` en Windows, `TracerPid` en `/proc/self/status` o un `ptrace(PTRACE_TRACEME)` que falla en Linux, `P_TRACED` con `sysctl` en macOS; y medición de tiempos (una instrucción que tarda de más porque hay un *breakpoint*).

Contramedidas: `eBPF` en vez de `ptrace` (no aparece en `TracerPid`), plugins anti-anti-debug (`ScyllaHide`, `HyperHide` para x64dbg) o parchear las comprobaciones. Este terreno se solapa con [[Evasión de defensas.base|Evasión de defensas]].

## Del lado defensivo: qué habría que vigilar

Puesto que la mitad del valor de esta nota es saber qué se detecta, el resumen para *blue team*:

- **En el switch**: Dynamic ARP Inspection y DHCP snooping cortan de raíz el MITM de capa 2 ([[05 - Detección y evasión del MITM de capa 2]]). RA Guard para IPv6.
- **En el endpoint**: integridad del almacén de CA de confianza y del fichero `hosts`; alerta ante instalación de CA nuevas.
- **En la aplicación**: *pinning*, y detección de latencia anómala en el *handshake*.
- **En la red**: perfilado JA4 de clientes conocidos; un cliente propietario que de pronto negocia como OpenSSL es una anomalía de alta fidelidad.

## Lo que no es evasión, es alcance

Buena parte de lo anterior solo tiene sentido en un ejercicio de *red team* con objetivo de sigilo. En un pentest de aplicación al uso, <mark style="background: #ADCCFFA6;">el camino correcto es pedir el material que quita el bloqueo</mark>: una build sin *pinning*, el certificado del entorno de pruebas, o acceso al host. Gastar dos días evadiendo una defensa que el cliente te habría desactivado por correo es tiempo que no dedicas a buscar fallos.

> [!info]+ Fuentes
> - [FoxIO — JA4+ Network Fingerprinting](https://github.com/FoxIOLLC/JA4) — especificación y por qué sustituye a JA3.
> - [Android — Network Security Configuration](https://developer.android.com/privacy-and-security/security-config) para el cambio de confianza en CA de usuario desde Android 7.
> - MITRE ATT&CK [T1565.001](https://attack.mitre.org/techniques/T1565/001/) (modificación de datos almacenados) y [T1622](https://attack.mitre.org/techniques/T1622/) (evasión por *debugger*).
