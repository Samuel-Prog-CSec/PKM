---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Verb-Tampering
Fecha de actualización: 2026-07-15
Nota previa: "[[02 - Bypass de autenticación básica]]"
Nota siguiente: "[[04 - Detección, evasión y prevención de Verb Tampering]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Segundo vector, más frecuente y más peligroso: **código inseguro** que aplica un filtro de seguridad a una fuente de parámetros pero ejecuta la acción con otra. El verb tampering nos deja <mark style="background: #FFB86CA6;">colar un payload de inyección por el hueco entre lo que se valida y lo que se ejecuta</mark>.

# El escenario

En el *File Manager*, al crear un fichero con caracteres especiales en el nombre (p. ej. `test;`) la app responde `Malicious Request Denied!`. Hay un filtro anti-inyección en el back-end. Por mucho que lo intentemos con el método normal, bloquea la petición.

El código responsable (que veremos entero en [[04 - Detección, evasión y prevención de Verb Tampering|prevención]]) es:

```php
if (isset($_REQUEST['filename'])) {
    if (!preg_match('/[^A-Za-z0-9. _-]/', $_POST['filename'])) {
        system("touch " . $_REQUEST['filename']);
    } else {
        echo "Malicious Request Denied!";
    }
}
```

<mark style="background: #ADCCFFA6;">El filtro `preg_match` inspecciona `$_POST['filename']`, pero `system()` ejecuta con `$_REQUEST['filename']`</mark> (que engloba `GET` **y** `POST`). Esa es la incoherencia explotable.

# Explotación

El formulario envía por `POST`, así que `$_POST['filename']` contiene `test;` y el filtro lo bloquea. La jugada: <mark style="background: #FF5582A6;">mover el payload de `POST` a `GET`</mark>. Interceptamos en [[01 - Instalación y configuración del proxy|Burp]] y cambiamos el método a `GET` (**Change Request Method**), poniendo el nombre malicioso en la query string:

```http
GET /index.php?filename=file1;%20touch%20file2; HTTP/1.1
Host: SERVER_IP
```

Ahora:

1. `$_POST['filename']` está **vacío** → `preg_match('/[^A-Za-z0-9. _-]/', '')` devuelve `0` (sin coincidencias) → `!0` = `true` → el filtro **se pasa**.
2. `system("touch " . $_REQUEST['filename'])` sí lee el valor de `GET` → se ejecuta `touch file1; touch file2;`.

Al comprobar el directorio, **ambos** ficheros `file1` y `file2` existen: hemos confirmado <mark style="background: #8000E1A6;">`Command Injection` saltándonos un filtro que, por sí solo, era correcto</mark>. Sin el verb tampering, la app habría estado protegida contra la [[00 - Introducción a Command Injection|inyección de comandos]].

> [!warning]+ Corrección al material de HTB
> El writeup original de HTB, en el paso de confirmación, dice "cambiar de nuevo a `POST`". Eso es **incorrecto** técnicamente: si el payload viaja por `POST`, `$_POST['filename']` vuelve a contener los caracteres especiales y el filtro lo bloquea. El bypass exige que el payload esté en `GET` (o en cualquier fuente que `$_REQUEST` recoja **salvo** `$_POST`), como confirma el propio código vulnerable. La regla mental correcta: **el payload va donde el filtro NO mira, pero `$_REQUEST` SÍ**.

# Generalización (más allá del lab)

Este patrón —filtro sobre una fuente, ejecución sobre otra— es un caso de <mark style="background: #FFB8EBA6;">**HTTP Parameter Pollution** cruzando el límite de método</mark>. Aparece en producción de formas más sutiles que dos líneas seguidas:

- Un middleware de validación que solo parsea el cuerpo `JSON`/`form` pero el handler lee también query params.
- Un WAF que inspecciona el `body` de los `POST` pero no la query string de otros métodos → mueve la inyección a `GET`/`PUT`.
- Frameworks con "merge" de parámetros: `$_REQUEST` en PHP, `request.values` en Flask, `params` en Rails (mezcla query + body + path). Si el filtro mira `request.form` pero el sink usa `request.values`, mismo bug.
- Precedencia de parámetros duplicados: enviar `filename` dos veces (uno limpio en la fuente filtrada, otro con payload en la otra) según qué fuente gane.

La caza sistemática de estas incoherencias y las cabeceras de *method override* que amplían el vector están en [[04 - Detección, evasión y prevención de Verb Tampering|Detección y evasión]]; la automatización, en [[05 - Herramientas para HTTP Verb Tampering|Herramientas]].

## Referencias

- OWASP — [Testing for HTTP Parameter Pollution (WSTG-INPV-04)](https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/07-Input_Validation_Testing/04-Testing_for_HTTP_Parameter_Pollution)
- OWASP WSTG — [Testing for HTTP Verb Tampering](https://owasp.org/www-project-web-security-testing-guide/v41/4-Web_Application_Security_Testing/07-Input_Validation_Testing/03-Testing_for_HTTP_Verb_Tampering)
- HTB Academy — *Web Attacks* (base, 2021)
