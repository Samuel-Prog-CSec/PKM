---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - HTTP/Host-Header
Fecha de actualización: 2026-07-14
Nota previa: "[[10 - Bypass de validación del Host Header]]"
Nota siguiente: "[[12 - Introducción a Session Puzzling]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

Cierre operativo del bloque de Host Header: cómo **detectarlos con método**, con qué **herramientas**, y cómo **prevenirlos** a nivel de código.

# Metodología de detección

1. **¿La app usa el `Host`?** Manda una petición con `Host` (y override headers) modificado a un valor de control y busca dónde aparece: cuerpo, enlaces absolutos (`<script src>`, `<link>`, `action`), cabecera `Location` de un redirect, o —el más valioso— un **email** (reset de contraseña).
2. **Prueba TODAS las override headers**: `X-Forwarded-Host`, `X-Host`, `X-Forwarded-Server`, `Forwarded`, `X-HTTP-Host-Override`, `X-Original-Host`.
3. **Si hay validación, atácala** con los [[10 - Bypass de validación del Host Header|bypasses]] (puerto, sufijo/prefijo, representaciones de localhost).
4. **Clasifica el impacto**: reflejo en enlace → [[08 - Password Reset Poisoning|reset poisoning]] o [[09 - Web Cache Poisoning por Host Header|cache poisoning]]; decisión de acceso → [[07 - Bypass de autenticación por Host Header|auth bypass]].

# Arsenal

| Herramienta | Uso |
| - | - |
| **Burp Repeater** | Manipular `Host`/override headers y observar el reflejo. El flujo base |
| **Param Miner** | *Guess headers* prueba automáticamente la lista de override headers y detecta cuáles se reflejan / son unkeyed |
| **ffuf** | Fuzzing del `Host` para [[07 - Bypass de autenticación por Host Header|auth bypass por IP]] y descubrimiento de vhosts |
| **Interactsh / Burp Collaborator** | Capturar el callback OOB del token de reset o de credenciales |
| **nuclei** | Templates `host-header-injection`, `web cache poisoning` para triage |
| **SecLists** | Wordlists de override headers y de valores localhost/internos |

```shell-session
# Descubrir vhosts / IPs internas que la app confía
$ ffuf -u http://target/ -w vhosts.txt -H 'Host: FUZZ' -fs <tamaño-baseline>
# Triage automatizado
$ nuclei -tags host-header,cache -u https://target.htb
```

# Prevención (a nivel de código)

**No confíes ciegamente en el `Host`.** Este patrón es vulnerable — <mark style="background: #FF5582A6;">la autorización jamás debe depender del `Host`</mark>:

```php
if (is_local_request($_SERVER['HTTP_HOST'])) {   // ← controlable por el cliente
    echo "Welcome Admin!";
}
```

La fuente de una petición se decide con `$_SERVER['REMOTE_ADDR']` (y reglas de firewall para lo interno), nunca con el `Host`. Y las apps internas **no** deben correr en el mismo servidor que las externas (se alcanzan por vhost brute-forcing).

**Validación por sufijo = vulnerable.** El clásico `str_ends_with` permite el bypass por postfix:

```php
// VULNERABLE: acepta evilvulndomain.htb
function check_host($h) { return str_ends_with($h, get_config_value('domain')); }
```

La corrección: <mark style="background: #FF5582A6;">construir las URLs absolutas **siempre** desde el dominio de **configuración**</mark>, sin tocar el `Host`:

```php
// SEGURO
function create_reset_link($user) {
    $token = generate_reset_token($user);
    return "http://" . get_config_value('domain') . "/pw_reset.php?token=" . $token;
}
```

> [!important] Cuatro reglas que cierran el vector
> - <mark style="background: #ADCCFFA6;">**URLs relativas** siempre que se pueda (inmunes a todo esto)</mark>; absolutas solo cuando es obligatorio (emails), y desde config.
> - **Desactivar override headers** en el servidor/borde.
> - <mark style="background: #FF5582A6;">**Parchear** los bugs de `Host` aunque parezcan inexplotables</mark>: un XSS reflejado vía `Host` "no explotable" se weaponiza con [[09 - Web Cache Poisoning por Host Header|cache poisoning]].
> - **Nunca** confiar en que otro sistema (CDN, proxy) te proteja: la app debe defenderse sola.

```php
// Ejemplo del XSS-por-Host "inexplotable"… hasta que hay caché de por medio
<script src="http://<?php echo $_SERVER['HTTP_HOST'] ?>/test.js"></script>
// Host: 127.0.0.1"></script><script>alert(1)</script><script src="
```

Con esto cierra el bloque de Host Header. El último bloque del módulo, [[12 - Introducción a Session Puzzling|Session Puzzling]], cambia de terreno: de las cabeceras al **estado de sesión** del servidor.

## Referencias

- [PortSwigger — How to prevent Host header attacks](https://portswigger.net/web-security/host-header#how-to-prevent-http-host-header-attacks)
- [SecLists — HTTP header wordlists](https://github.com/danielmiessler/SecLists)
