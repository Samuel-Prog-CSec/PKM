---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Command-Injection
Fecha de actualización: 2026-06-13
Nota previa: "[[02 - Operadores de inyección de comandos]]"
Nota siguiente: "[[04 - Bypass de filtros de espacios]]"
Area: "[[Command Injection.base|Command Injection]]"
---
---

Cuando la aplicación **sí** valida en el back-end, el payload `127.0.0.1; whoami` deja de funcionar y devuelve un `invalid input`. Antes de lanzar técnicas de evasión a ciegas, hay un paso de enumeración que ahorra horas: <mark style="background: #ADCCFFA6;">identificar exactamente qué se está filtrando y quién lo filtra</mark>. Evadir un filtro que no conoces es disparar al aire; cada payload de bypass gastado a lo loco acerca un `rate limit` o un baneo de IP. Esta nota es el reconocimiento previo a las cuatro notas de bypass que siguen.

# Las tres capas de defensa

Las mitigaciones contra command injection se apilan en tres niveles, de menos a más sofisticado:

| Defensa | Dónde vive | Cómo bloquea |
| - | - | - |
| **Blacklist de caracteres** | Código de la app | Deniega si la entrada contiene `;`, `&`, `\|`, espacios… |
| **Blacklist de comandos** | Código de la app | Deniega si detecta `whoami`, `cat`, `nc`… |
| **WAF** | Capa delante de la app | Reglas genéricas contra patrones de inyección (también SQLi, XSS) |

Una blacklist de caracteres en `PHP` suele ser tan simple como esto:

```php
$blacklist = ['&', '|', ';', ...SNIP...];
foreach ($blacklist as $character) {
    if (strpos($_POST['ip'], $character) !== false) {
        echo "Invalid input";
    }
}
```

Si **cualquier** carácter de la entrada coincide con la lista, la petición se rechaza. El [[04 - Bypass de filtros de espacios|bypass]] consistirá en lograr el mismo comando sin usar ninguno de los caracteres prohibidos.

# ¿Quién bloquea? Aplicación vs. WAF

La **forma** del rechazo delata el origen, y eso cambia tu estrategia:

- <mark style="background: #FF5582A6;">Si el error aparece en el mismo flujo de salida</mark> (en el campo donde antes salía el `ping`, devuelto por la propia app), lo más probable es que sea una blacklist **de la aplicación**: limitada, específica de ese parámetro, fácil de mapear.
- <mark style="background: #FFB86CA6;">Si el rechazo te lleva a una página distinta</mark> —un bloque genérico con tu IP, un *request ID*, un "access denied" corporativo—, hay un **WAF** delante. Su alcance es más amplio y sus reglas, más difíciles de enumerar carácter a carácter.

## Fingerprinting del WAF

Identificar *qué* WAF tienes enfrente orienta el repertorio de bypass, porque cada producto tiene debilidades documentadas. Esto HTB no lo cubre, y en un objetivo real es lo primero:

```shell-session
$ wafw00f https://target.htb -a
```

`wafw00f` (de EnableSecurity) huele la firma de 150+ WAFs. Señales que también revisar a mano:

- **Cabeceras**: `Server: cloudflare`, `cf-ray`, `x-amzn-*` (AWS WAF), `x-sucuri-id`, `Server: AkamaiGHost`.
- **Cookies**: `__cfduid`/`__cf_bm` (Cloudflare), `incap_ses`/`visid_incap` (Imperva Incapsula), `ak_bmsc` (Akamai).
- **Página de bloqueo**: el HTML del "Attention Required" de Cloudflare, el "Request blocked" de AWS, el "This website is using a security service" genérico.
- **Código de estado**: muchos WAFs responden `403`, `406` o `429` ante un payload, no el `200` con "invalid input" de una blacklist de app.

> [!info]+ Los sospechosos habituales en 2026
> El mercado lo dominan **Cloudflare**, **AWS WAF**, **Akamai**, **Imperva** y, en self-hosted, **ModSecurity** con el `OWASP Core Rule Set (CRS)`. El CRS es open source: puedes leer sus reglas de detección de command injection (`REQUEST-932-APPLICATION-ATTACK-RCE.conf`) y diseñar el bypass contra la regex exacta. Es la ventaja del defensor convertida en ventaja del atacante.

# Aislar qué carácter (o comando) dispara el bloqueo

Confirmado que hay filtro, hay que localizar la causa exacta. La técnica es **reducir el payload** y añadir un elemento cada vez, observando cuándo salta el rechazo. Partiendo de `127.0.0.1` (que sabemos válido), añadimos solo el punto y coma:

```text
127.0.0.1;
```

Si esto ya devuelve `invalid input`, el `;` está en la lista. Se repite con cada operador (`&`, `|`, `&&`, `||`, `\n`), con el espacio, y con el nombre del comando (`whoami`) por separado. <mark style="background: #8000E1A6;">El objetivo es construir un mapa: estos caracteres pasan, estos no; este comando pasa, este no</mark>. Ese mapa dicta qué nota de bypass aplicar:

- ¿Bloquea el espacio? → [[04 - Bypass de filtros de espacios]].
- ¿Bloquea `/`, `;` u otros caracteres? → [[05 - Bypass de caracteres en blacklist]].
- ¿Bloquea el nombre del comando? → [[06 - Bypass de comandos en blacklist]].

> [!important]+ Hazlo en Repeater, una variable cada vez
> Igual que en la [[01 - Detección de SQL Injection|detección de SQLi]], el aislamiento se hace en [[05 - Repeater - repetir y modificar peticiones|Repeater]] cambiando **un** elemento por petición. Cambiar varios a la vez te deja sin saber cuál disparó el bloqueo. Anota qué pasa y qué no — ese inventario es el que conviertes en payload de evasión.

# Por qué las blacklists están condenadas

Conviene entender la debilidad estructural que vas a explotar: <mark style="background: #FFB86CA6;">una blacklist es un enfoque negativo —enumerar lo malo— y es imposible enumerarlo todo</mark>. El shell ofrece tantas formas de escribir el mismo comando (variables de entorno, comodines, codificación, concatenación) que ninguna lista las cubre. Por eso el bloque de evasión que sigue funciona tan bien, y por eso la [[09 - Prevención de Command Injection|prevención]] correcta nunca es una blacklist, sino no invocar la shell en primer lugar.

> [!info]+ Fuentes
> - [wafw00f](https://github.com/EnableSecurity/wafw00f) — fingerprinting de WAF
> - [OWASP ModSecurity Core Rule Set](https://coreruleset.org/) — reglas RCE (`932*`)
> - [PortSwigger — OS command injection](https://portswigger.net/web-security/os-command-injection)

Con el mapa de lo filtrado en la mano, empezamos por el caso más común: el filtrado del carácter de espacio. [[04 - Bypass de filtros de espacios]].
