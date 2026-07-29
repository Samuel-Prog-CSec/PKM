---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - IDOR
Descripción: "Antes de explotar hay que localizar las referencias directas"
Fecha de actualización: 2026-07-15
Nota previa: "[[06 - Introducción a IDOR]]"
Nota siguiente: "[[08 - Enumeración masiva de IDOR]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Antes de explotar hay que **localizar las referencias directas**. Un IDOR se caza estudiando cómo la app identifica los objetos. Cuatro frentes: parámetros/APIs, código front-end, referencias codificadas/hasheadas, y comparación entre roles.

# Parámetros URL y APIs

El primer paso: cada vez que recibas un fichero o recurso, estudia la petición HTTP buscando <mark style="background: #ADCCFFA6;">parámetros o endpoints con una referencia a objeto</mark> — `?uid=1`, `?filename=file_1.pdf`, `/api/users/1/documents`. No solo en la query string: también en **cookies** y otras cabeceras.

En los casos básicos, incrementa el valor (`?uid=2`, `?filename=file_2.pdf`) o fuzzéalo con miles de variantes. Cualquier acierto que devuelva datos que no son tuyos es un IDOR.

> [!tip]+ No solo IDs numéricos
> Busca también: nombres de fichero predecibles, timestamps, `base64`, hashes, JWT con claims de identidad, y parámetros "filtro" (`uid_filter=1`) que se pueden manipular **o eliminar** para volcar todos los registros.

# Análisis del front-end (AJAX)

Los frameworks JavaScript a menudo colocan **todas** las llamadas en el front-end y solo usan las apropiadas según el rol. Si no eres admin, las funciones admin están "desactivadas" en la UI — pero <mark style="background: #FFB86CA6;">siguen presentes en el código JS y puedes invocarlas directamente</mark>.

```javascript
function changeUserPassword() {
    $.ajax({
        url: "change_password.php",
        type: "post",
        dataType: "json",
        data: { uid: user.uid, password: user.password, is_admin: is_admin },
        success: function(result) { /* ... */ }
    });
}
```

Esta función quizá nunca se llame como usuario normal, pero localizarla en el código revela el endpoint, sus parámetros (`uid`, `is_admin`) y cómo replicarla. Lo mismo aplica al **back-end** si tienes el código (apps open-source, o tras un [[14 - Introducción a XXE|XXE]]/LFI que filtre fuentes).

<mark style="background: #FFB8EBA6;">Herramientas modernas para esto</mark>: extraer y analizar los `.js` con `LinkFinder`, `xnLinkFinder`, `getJS` o el mapeo de JS de Burp; buscar endpoints y parámetros ocultos que nunca aparecen navegando.

# Referencias codificadas o hasheadas

## Encoding

Si la referencia está **codificada**, decodifícala, modifícala y vuelve a codificar. Un valor como `?filename=ZmlsZV8xMjMucGRm` grita `base64` por su charset → decodifica a `file_123.pdf`. Prueba `file_124.pdf` → `?filename=ZmlsZV8xMjQucGRm`:

```shell-session
$ echo -n "ZmlsZV8xMjMucGRm" | base64 -d
file_123.pdf
$ echo -n "file_124.pdf" | base64
ZmlsZV8xMjQucGRm
```

## Hashing

Una referencia como `download.php?filename=c81e728d9d4c2f636f067f89cc14862c` parece segura. Pero mira el código: a menudo se hashea un valor **predecible**:

> [!info]+ Los dos ejemplos son independientes
> El hash de la URL (`c81e728d…` es `md5("2")`) y el código de abajo (que hashea `'file_1.pdf'`) son **ilustraciones separadas** — una muestra cómo se ve una referencia hasheada, la otra cómo el front-end la calcula. En un objetivo real, ambos coincidirían (el hash de la URL sería el que produce este código).

```javascript
$.ajax({
    url: "download.php",
    type: "post",
    dataType: "json",
    data: { filename: CryptoJS.MD5('file_1.pdf').toString() }
});
```

Si sabes que hashea el nombre con `MD5`, calculas el hash de otros ficheros y los pides. Si no ves el código, identifica el algoritmo (`hash-identifier`, `hashid`, o por longitud/charset) y prueba a hashear valores candidatos hasta que coincida. <mark style="background: #FF5582A6;">Hashear/codificar la referencia NO es control de acceso</mark> — solo seguridad por oscuridad.

# Comparar roles

Para IDOR avanzados, **registra varios usuarios** y compara sus peticiones y referencias. Así entiendes cómo se calculan los identificadores y los reproduces para otros.

Ejemplo: el usuario 1 ve su salario con esta llamada:

```json
{
  "attributes": { "type": "salary", "url": "/services/data/salaries/users/1" },
  "Id": "1",
  "Name": "User1"
}
```

El usuario 2 no tiene esos parámetros para replicarla — pero con los detalles a mano, repites la misma llamada logueado como User2. <mark style="background: #8000E1A6;">Si la app solo exige una sesión válida y no compara la sesión con el dato pedido, devuelve el salario ajeno</mark> → IDOR confirmado. Aunque no puedas calcular los parámetros de otros, ya habrás identificado el fallo de control de acceso de fondo.

> [!info]+ Automatizar la comparación de roles
> La forma profesional de esto es capturar los flujos con dos sesiones y contrastarlos automáticamente: **Autorize** o **Auth Analyzer** (extensiones de Burp) repiten cada petición con la cookie de otro usuario y marcan en verde/rojo si el control de acceso falla. Es el estándar en pentest de autorización — ver [[13 - Herramientas para IDOR|Herramientas para IDOR]].

Localizada la referencia, pasamos a explotarla en masa: [[08 - Enumeración masiva de IDOR|enumeración masiva]].

## Referencias

- PortSwigger — [Finding and exploiting IDORs](https://portswigger.net/web-security/access-control/idor)
- OWASP WSTG — [Testing for IDOR (WSTG-ATHZ-04)](https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/05-Authorization_Testing/04-Testing_for_Insecure_Direct_Object_References)
- HackTricks — [IDOR](https://book.hacktricks.xyz/pentesting-web/idor)
- HTB Academy — *Web Attacks* (base, 2021)
