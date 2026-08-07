---
tags:
  - Wi-Fi/Enterprise
  - Seguridad/Contraseñas
  - Pentesting/Explotacion
Descripción: "Qué credenciales deja escapar cada método EAP, por qué la identidad externa anónima invalida media técnica, y cómo se craquea un reto MSCHAPv2 offline"
Fecha de actualización: 2026-08-04
Nota previa: "[[07 - Precomputación de PMK y su vigencia real]]"
Nota siguiente: "[[09 - Contraseñas de dispositivos de red Cisco]]"
Area: "[[Cracking Wi-Fi.base|Cracking Wi-Fi]]"
---
---

En WPA-Enterprise no hay PSK que recuperar: la autenticación la hace un servidor RADIUS contra un directorio, casi siempre Active Directory. <mark style="background: #ADCCFFA6;">El objetivo deja de ser una contraseña de red y pasa a ser **una credencial de usuario del dominio**</mark>, lo que cambia por completo el impacto: no se entra en la Wi-Fi, se entra en la organización.

# Qué expone cada método EAP

| Método | Qué viaja recuperable | Ataque |
| ------ | --------------------- | ------ |
| **EAP-MD5** | Reto y respuesta MD5 | Offline, trivial. Sin cifrado de túnel |
| **LEAP** | Reto/respuesta MSCHAPv1 | Offline con `asleap`. Obsoleto de Cisco |
| **PEAP-MSCHAPv2** | Reto/respuesta MSCHAPv2 **si se rompe el túnel TLS** | Offline vía AP falso |
| **EAP-TTLS-PAP** | **Contraseña en claro** dentro del túnel | Offline vía AP falso, resultado inmediato |
| **EAP-GTC** | **Contraseña en claro** o token OTP | Igual, y a menudo el objetivo del *downgrade* |
| **EAP-TLS** | Nada. Certificado por ambos lados | Ninguno por credencial |

El patrón está claro: <mark style="background: #FFB86CA6;">todo lo que no sea EAP-TLS entrega algo aprovechable **si el cliente acepta un servidor falso**</mark>. La seguridad de PEAP y TTLS no está en el método, está en que el suplicante valide el certificado del RADIUS. Ese es el fallo real, y se explota en [[08 - WPA2-Enterprise, evil twin y robo de credenciales]].

# La identidad: lo que se ve sin romper nada

Antes de montar el túnel TLS, el cliente responde a `EAP-Request/Identity` con una identidad **en claro**. Capturar tráfico de asociación y filtrar por `eap` en Wireshark suele mostrar `DOMINIO\usuario` o `usuario@dominio`.

```shell-session
$ hcxpcapngtool -o hash.hc22000 -I identidades.txt -U usuarios.txt captura.pcapng
```

`hcxpcapngtool` extrae esa información directamente: `-I` la lista de identidades EAP y `-U` la de usuarios. Es reconocimiento puramente pasivo, sin tocar a nadie.

> [!warning]+ La identidad externa anónima invalida la mitad de esta técnica
> HTB presenta la fuga de identidad como si fuera universal. <mark style="background: #FF5582A6;">No lo es</mark>: PEAP y TTLS permiten enviar una **identidad externa** distinta de la real —`anonymous`, `anonymous@empresa.com`— y reservar la verdadera para dentro del túnel cifrado. Es lo que hace `wpa_supplicant` cuando se configura `anonymous_identity`, y lo que hacen por defecto los perfiles de Windows y de los MDM bien montados.
>
> Con identidad externa configurada, la captura pasiva no da usuarios: sólo `anonymous`. Y al revés, **encontrar nombres reales en claro es en sí mismo el hallazgo**: indica que los suplicantes no usan identidad externa y habilita enumeración de usuarios del dominio desde el aparcamiento.

Con un usuario confirmado se infiere el esquema del resto (`nombre.apellido`, `ninicial+apellido`) y se generan candidatas con `username-anarchy`, cuyo modo `--recognise` deduce el formato:

```shell-session
$ ./username-anarchy --recognise cindy.walker
$ ./username-anarchy --input-file nombres.txt --select-format first.last > usuarios.txt
```

La herramienta va por la **v0.6 (sep-2024)** y sigue siendo la referencia. El resto de la generación de usuarios —fuentes OSINT, metadatos de documentos— está en [[04 - Generación de wordlists]] y no se repite aquí.

# Fuerza bruta online: por qué casi nunca

HTB propone `air-hammer` para probar usuarios y contraseñas contra el AP real. Es una idea de 2017 que hoy tiene tres problemas serios:

1. **Bloqueo de cuentas.** Cada intento fallido va contra Active Directory. Una pasada de `rockyou` sobre veinte usuarios bloquea a veinte personas y convierte el pentest en un incidente de disponibilidad — justo lo que el alcance suele prohibir.
2. **Registro total.** El RADIUS deja un `Access-Reject` por intento, con usuario, MAC y hora. Es el evento más fácil de alertar que existe en una red inalámbrica.
3. **La herramienta está muerta.** `air-hammer` no tiene ninguna versión publicada, su último cambio es de junio de 2024 y <mark style="background: #FF5582A6;">HTB la ejecuta con `python2`</mark>, un intérprete sin soporte desde enero de 2020.

Sigue habiendo un caso legítimo: **password spraying muy acotado**, una o dos contraseñas plausibles (`Empresa2026!`, la estacional) contra una lista de usuarios, respetando el umbral de bloqueo y la ventana de reintentos del dominio. Eso es un ataque quirúrgico y defendible; recorrer un diccionario no lo es. La disciplina completa está en [[04 - Password spraying, stuffing y defaults]].

# La vía correcta: capturar el reto y crackearlo offline

Un AP falso con un RADIUS propio negocia el método más débil que el cliente acepte y captura el intercambio. Si el resultado es un reto/respuesta MSCHAPv2, se craquea sin volver a tocar la red y sin generar un solo `Access-Reject`.

```text
jdorian::::a93621d5c06394680afaad8dd8962600555155eaa051dec2:aaf244ed0b4ed3b3
        └── respuesta (24 B) ────────────────────────────┘ └── reto (8 B) ──┘
```

```shell-session
$ hashcat -m 5500 reto.txt wordlist.txt -r best64.rule
$ asleap -C aa:f2:44:ed:0b:4e:d3:b3 -R a9:36:21:... -W wordlist.txt
```

<mark style="background: #ADCCFFA6;">El modo `5500` de hashcat es `NetNTLMv1 / NetNTLMv1+ESS`</mark>, y sirve porque MSCHAPv2 y NetNTLMv1 comparten construcción: el hash NT se parte en tres claves DES que cifran el reto. `asleap`, de Joshua Wright, hace lo mismo desde la óptica inalámbrica y también cubre LEAP.

> [!important]+ MSCHAPv2 no depende de la fuerza de la contraseña
> La tercera clave DES sólo conserva **2 bytes** del hash NT, así que se recupera al instante; las otras dos son DES completo. <mark style="background: #8000E1A6;">El keyspace efectivo es 2⁵⁶, no el de la contraseña</mark>: una passphrase larguísima cae igual.
>
> El servicio [crack.sh](https://crack.sh/) agota ese espacio por hardware dedicado con garantía de éxito —su propia documentación habla de **unas 26 horas** para el barrido completo— y acepta explícitamente MSCHAPv2 y WPA-Enterprise. Operativamente eso significa que **cualquier credencial PEAP-MSCHAPv2 capturada debe considerarse comprometida**, no "pendiente de crackear".
>
> Cuidado con el matiz contractual: enviar el reto de un cliente a un servicio de terceros es exfiltrar material de autenticación suyo. Requiere autorización expresa, como cualquier crackeo fuera de su entorno.

# Qué se reporta

El hallazgo casi nunca es "la contraseña de fulano es débil". Es la **configuración del suplicante**, porque afecta a toda la flota:

| Observación | Hallazgo |
| ----------- | -------- |
| Identidades reales en claro | Falta `anonymous_identity`: enumeración de usuarios desde fuera |
| El cliente aceptó un RADIUS falso | Falta `ca_cert`: robo de credenciales de dominio |
| Aceptó negociar GTC o TTLS-PAP | Falta restricción de métodos: contraseña en claro |
| Falta `domain_suffix_match` | Un certificado válido de **cualquier CA** engaña al cliente |

La corrección se aplica por GPO o MDM en un sitio y protege a todos los dispositivos; cambiar la contraseña de un usuario no arregla nada. Ese es el argumento que hay que llevar al informe.
