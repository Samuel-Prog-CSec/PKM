---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Proxies
Descripción: "Antes de interceptar nada hay que poner el proxy entre el navegador y el objetivo"
Fecha de actualización: 2026-06-23
Nota previa: "[[00 - Introducción a los proxies web]]"
Nota siguiente: "[[02 - Interceptación de peticiones]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

Antes de interceptar nada hay que poner el proxy entre el navegador y el objetivo. Burp y ZAP vienen **preinstalados** en Kali, Parrot y PwnBox; si no, se descargan de su web o como `JAR` multiplataforma (`java -jar burpsuite.jar`). Lo que importa no es instalarlos, sino los dos pasos que todo el mundo olvida: **enrutar el navegador** por el proxy y **confiar en su certificado CA** (la [[01 - Infraestructura de Clave Pública (PKI)|cadena de confianza X.509]] que esto aprovecha es la misma que estudia la nota de PKI).

# Arranque de Burp

Al abrir Burp se pide crear proyecto. En la versión **Community** solo hay proyectos **temporales** (no se guardan en disco — esa es una limitación de pago); elige `Temporary project` → `Use Burp Defaults` → `Start Burp`. La Pro permite guardar el proyecto, útil al escanear apps grandes. ZAP pregunta lo mismo: para una sesión normal, proyecto temporal (`No`).

# Navegador preconfigurado (la vía rápida)

<mark style="background: #FF5582A6;">La forma más rápida y la que usa hoy casi todo el mundo</mark>: el navegador Chromium que Burp trae integrado, ya configurado con el proxy y el certificado. En `Proxy > Intercept`, botón `Open Browser`:

![Pestaña Proxy de Burp con Intercept desactivado y el botón "Open Browser" que lanza el navegador integrado, ya enrutado por Burp.](https://academy.hackthebox.com/storage/modules/110/burp_preconfigured_browser.png)

En ZAP, el icono de Firefox al final de la barra superior abre su navegador preconfigurado. <mark style="background: #FFB8EBA6;">Para este módulo, el navegador preconfigurado es suficiente</mark> y evita todo el paso de FoxyProxy y certificados.

# Navegador real + FoxyProxy

Cuando quieras usar tu Firefox real (extensiones, perfiles, sesiones), hay que enrutarlo manualmente. Burp y ZAP escuchan en `127.0.0.1:8080` por defecto (configurable en `Proxy > Proxy settings > Proxy listeners`). En vez de cambiar el proxy a mano en las preferencias de Firefox, la extensión **FoxyProxy** lo conmuta de un clic — añade un perfil con IP `127.0.0.1`, puerto `8080`:

![Configuración de un proxy en FoxyProxy: IP 127.0.0.1, puerto 8080, nombre Burp/ZAP.](https://academy.hackthebox.com/storage/modules/110/foxyproxy_add.png)

Luego seleccionas `Burp`/`ZAP` desde el icono de FoxyProxy para activar el enrutado.

# Certificado CA: el paso crítico para HTTPS

> [!warning]+ Sin el certificado CA, el HTTPS se rompe
> El proxy hace MITM de TLS: presenta su **propio** certificado al navegador. Si no instalas su CA como confiable, Firefox dará errores de certificado en cada sitio HTTPS y parte del tráfico no se enrutará. <mark style="background: #FFB86CA6;">Es el error de setup número uno.</mark> El navegador preconfigurado ya lo trae instalado; con navegador propio hay que hacerlo a mano.

Con Burp seleccionado en FoxyProxy, navega a `http://burp` y descarga el certificado (`CA Certificate`):

![Cabecera de Burp Suite con el botón "CA Certificate" para descargar el certificado de la autoridad.](https://academy.hackthebox.com/storage/modules/110/burp_cert.jpg)

En ZAP el certificado se exporta desde `Tools > Options > Network > Server Certificates > Save`. Después, en Firefox (`about:preferences#privacy > View Certificates > Authorities > Import`), importa el certificado descargado y marca **confiar para identificar sitios web**:

![Administrador de certificados de Firefox, pestaña Authorities, con la opción Import para añadir el CA del proxy.](https://academy.hackthebox.com/storage/modules/110/firefox_import_cert.png)

Hecho esto, todo el tráfico HTTPS de Firefox pasa limpio por el proxy. <mark style="background: #8000E1A6;">Atajo profesional: usa el navegador integrado de Burp y te ahorras FoxyProxy + certificado por completo.</mark>

> [!info]+ Fuentes
> - [Burp — descargas](https://portswigger.net/burp/releases/) · [ZAP — descargas](https://www.zaproxy.org/download/) · [FoxyProxy](https://addons.mozilla.org/firefox/addon/foxyproxy-standard/)
