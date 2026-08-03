---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - File-Upload
Descripción: "Muchas aplicaciones validan el formato del fichero solo con JavaScript en el navegador, antes de enviarlo"
Fecha de actualización: 2026-06-21
Nota previa: "[[01 - Explotación básica - web shells y reverse shells]]"
Nota siguiente: "[[03 - Bypass de blacklist de extensiones]]"
Area: "[[File Upload.base|File Upload]]"
---
---

Muchas aplicaciones validan el formato del fichero **solo** con JavaScript en el navegador, antes de enviarlo. <mark style="background: #ADCCFFA6;">La validación en cliente es un control de UX, no de seguridad</mark>: <mark style="background: #8000E1A6;">todo el código que corre en el navegador está bajo nuestro control absoluto</mark>. El servidor envía el front-end, pero quien lo ejecuta y renderiza somos nosotros, así que podemos saltarnos cualquier comprobación que viva ahí. Si el back-end no revalida, esto basta para subir cualquier tipo de fichero.

La señal de que la validación es puramente client-side: al seleccionar un fichero no permitido aparece el error y se deshabilita el botón **sin que la página recargue ni se envíe ninguna petición HTTP**. Toda la lógica está en el navegador.

Hay dos formas de evadirla. Conviene conocer las dos porque, según el caso, una es más cómoda que la otra.

# Método 1 — Modificar la petición en el proxy

El más fiable y el que se usa por defecto en un engagement. <mark style="background: #FF5582A6;">Se ignora por completo el front-end: se sube una imagen legítima y se reescribe la petición en vuelo.</mark>

1. Interceptar con [[02 - Interceptación de peticiones|Burp/Caido]] una subida normal de imagen. La petición va a `/upload.php` como `multipart/form-data`.
2. En la petición, los dos campos a tocar son `filename="HTB.png"` y el contenido del fichero al final.
3. Cambiar `filename` a `shell.php` y el contenido por el del [[01 - Explotación básica - web shells y reverse shells|web shell]].
4. Reenviar. Si el back-end no valida, responde `File successfully uploaded`.

```http
POST /upload.php HTTP/1.1
Host: target
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="uploadFile"; filename="shell.php"
Content-Type: image/png

<?php system($_REQUEST['cmd']); ?>
------WebKitFormBoundary--
```

El `Content-Type` del fichero (aquí `image/png`) se puede dejar tal cual en esta fase; solo importa cuando hay [[05 - Validación de tipo - Content-Type y magic bytes|validación de tipo]].

# Método 2 — Desactivar la validación en el front-end

A veces es más cómodo manipular el propio JavaScript y luego usar el formulario con normalidad, sin proxy.

Con el inspector (`CTRL+SHIFT+C`) localizamos el `<input>` de fichero:

```html
<input type="file" name="uploadFile" id="uploadFile" onchange="checkFile(this)" accept=".jpg,.jpeg,.png">
```

Dos piezas interesantes:

- **`accept=".jpg,.jpeg,.png"`**: limita el diálogo de selección. Se elude eligiendo "Todos los archivos", o borrando el atributo.
- **`onchange="checkFile(this)"`**: ejecuta la función validadora al elegir fichero. Inspeccionándola en la consola (`CTRL+SHIFT+K`, escribir `checkFile`) vemos que comprueba la extensión y, si no es imagen, muestra el error y deshabilita el botón.

La vía rápida no es reescribir JavaScript, sino **eliminar la llamada**: doble clic sobre `checkFile(this)` en el HTML y borrarla. Sin validador, el `<input>` acepta cualquier fichero.

> [!note]+ El cambio es temporal —y no importa
> Editar el DOM no persiste tras recargar, porque solo cambia tu copia local. Da igual: el único objetivo es colar **una** subida saltándose la comprobación. En Firefox se hace en el inspector directamente; en Chrome el equivalente para cambios persistentes son los **Local Overrides**.

# Por qué esta capa nunca es suficiente (para el defensor)

<mark style="background: #FFB86CA6;">Confiar la seguridad al cliente equivale a no tener seguridad</mark>: cualquier control en el navegador se desactiva en segundos. La validación client-side solo sirve para mejorar la experiencia (evitar que un usuario honesto suba el fichero equivocado) y para reducir ruido. <mark style="background: #FFB8EBA6;">En SPAs modernas (React, Vue, Angular) la validación vive en componentes JS, pero es exactamente igual de saltable</mark> —interceptar la petición XHR/fetch funciona idéntico.

> [!warning]+ Puede haber validación en ambos lados
> Que exista validación en cliente **no excluye** que también la haya en el servidor. Si tras saltarte el JavaScript el upload sigue fallando (`Extension not allowed`, `Only images are allowed`), es que hay una segunda capa en el back-end. Ahí empieza el trabajo real: [[03 - Bypass de blacklist de extensiones|blacklist]], [[04 - Bypass de whitelist y doble extensión|whitelist]] y [[05 - Validación de tipo - Content-Type y magic bytes|validación de contenido]].

> [!info]+ Fuentes
> - [PortSwigger — Flawed file type validation](https://portswigger.net/web-security/file-upload#flawed-file-type-validation)
> - [OWASP WSTG — Test Upload of Malicious Files](https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/10-Business_Logic_Testing/09-Test_Upload_of_Unexpected_File_Types)

Cuando la validación se mueve al servidor, la primera y más débil forma es comparar la extensión contra una lista negra: [[03 - Bypass de blacklist de extensiones]].
