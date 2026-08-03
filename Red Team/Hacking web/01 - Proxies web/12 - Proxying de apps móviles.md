---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Proxies
Descripción: "Las apps móviles hablan con el mismo tipo de back-end que una web, pero no usan el navegador, así que el setup del proxy no basta"
Fecha de actualización: 2026-06-23
Nota previa: "[[11 - OPSEC y evasión de detección]]"
Nota siguiente: "[[13 - Flujo profesional y alternativas modernas]]"
Area: "[[Proxies web.base|Proxies web]]"
---
---

Las apps móviles hablan con el mismo tipo de back-end que una web, pero **no usan el navegador**, así que el [[01 - Instalación y configuración del proxy|setup del proxy]] no basta. Hay que enrutar el dispositivo o emulador por Burp/ZAP/[[13 - Flujo profesional y alternativas modernas|Caido]], y superar dos obstáculos que la web no tiene: <mark style="background: #ADCCFFA6;">cómo confía la app en tu certificado, y el `certificate pinning`.</mark>

# 1 · Enrutar el dispositivo por el proxy

Configura el proxy manual del WiFi del dispositivo apuntando a `IP_del_host:8080` (o usa un emulador: Android Studio AVD, Genymotion, o el simulador de iOS). El proxy debe **escuchar en todas las interfaces**, no solo en `127.0.0.1` — en Burp, `Proxy settings > Proxy listeners`, bind a `All interfaces`, o el dispositivo no llegará.

# 2 · El certificado CA: más difícil que en web

Aquí empieza la fricción. Instalar el [[01 - Instalación y configuración del proxy|certificado CA]] como en Firefox **no es suficiente** en móvil moderno:

> [!warning]+ Android 7+ ignora los CA de usuario
> Hasta Android 6, un CA instalado por el usuario valía para todo. <mark style="background: #FF5582A6;">Desde Android 7 (API 24), las apps **solo confían en el almacén de CAs del sistema**</mark>, no en los de usuario, salvo que la app declare explícitamente un `networkSecurityConfig` que los acepte (raro en producción). Instalar tu CA "a mano" hará que el navegador del móvil funcione, pero las **apps seguirán rechazando** tu proxy.

La solución es meter tu CA en el **almacén del sistema**, lo que requiere root:

- **Magisk** con el módulo <mark style="background: #FFB86CA6;">`MagiskTrustUserCerts`</mark> (o "Move Certificates"): mueve automáticamente los CA de usuario al almacén de sistema en cada arranque. La vía estándar hoy.
- Manualmente: remontar `/system` en escritura y copiar el cert con el nombre `<hash>.0` que Android espera.
- **iOS**: instalar el perfil del CA y, crucial, activarlo en `Ajustes > General > Información > Ajustes de confianza de certificados`.

Con el CA en el sistema, ya ves el tráfico de las apps **que no hacen pinning**.

# 3 · Certificate pinning

El obstáculo final. <mark style="background: #FFB86CA6;">El `certificate pinning` empotra en la app el certificado (o su clave pública) que espera del servidor, y rechaza cualquier otro — incluido un CA de sistema.</mark> Tu proxy presenta un cert distinto, la app corta la conexión. Hay que romperlo **en tiempo de ejecución**, hookeando las funciones de validación para que siempre digan "válido":

| Herramienta | Cómo |
| - | - |
| <mark style="background: #FFB86CA6;">**objection**</mark> ([repo](https://github.com/sensepost/objection)) | `objection -g <paquete> explore` → `android sslpinning disable`. Hookea OkHttp `CertificatePinner`, `checkServerTrusted`, TrustManagers... Rompe los frameworks comunes en segundos |
| **Frida** ([repo](https://github.com/frida/frida)) | Inyecta en el proceso en RAM un script de bypass: el [universal pinning bypass](https://codeshare.frida.re/@pcipolloni/universal-android-ssl-pinning-bypass-with-frida/) o `frida-multiple-unpinning`. Para implementaciones **custom** que objection no cubre |

```shell-session
$ frida-ps -Uai                                   # listar apps del dispositivo
$ objection -g com.target.app explore
com.target.app on (android) > android sslpinning disable
$ frida -U -f com.target.app -l frida-multiple-unpinning.js   # alternativa con Frida
```

> [!warning]+ El gotcha de las dos capas de red
> Caso real (OWASP MASTG / NetSPI): tras `sslpinning disable` el tráfico **sigue sin aparecer**. Causa frecuente: la app tiene <mark style="background: #FF5582A6;">**dos pilas de red** — una con OkHttp (que objection rompe) y otra con una implementación propia</mark> (Flutter, un `.so` nativo, una librería custom) que necesita un script Frida dirigido a sus funciones concretas. Si el bypass "no funciona", asume una segunda capa antes de rendirte.

> [!important]+ Apps sin root
> Si no puedes rootear, re-empaqueta la app para inyectar el bypass: `objection patchapk -s app.apk` (mete el **Frida Gadget** en el APK), o `apktool` para editar el `networkSecurityConfig` y permitir CAs de usuario. Funciona si la app no detecta la manipulación (algunas comprueban su firma/integridad). Flutter, además, ignora el proxy del sistema: hay que forzarlo con `ProxyDroid`/iptables o un script Frida específico.

<mark style="background: #8000E1A6;">El flujo completo</mark>: enrutar dispositivo → CA en el almacén de sistema (Magisk) → romper el pinning (objection/Frida) → el tráfico de la app cae en tu proxy como cualquier web, listo para [[05 - Repeater - repetir y modificar peticiones|Repeater]] y el resto del arsenal. La metodología de referencia es la **OWASP MASTG**.

> [!info]+ Fuentes
> - [OWASP MASTG — Bypassing Certificate Pinning (MASTG-TECH-0012)](https://mas.owasp.org/MASTG/techniques/android/MASTG-TECH-0012/)
> - [HTTP Toolkit — Defeating pinning with Frida](https://httptoolkit.com/blog/frida-certificate-pinning/) · [NetSPI — 4 ways to bypass Android SSL pinning](https://www.netspi.com/blog/technical-blog/mobile-application-pentesting/four-ways-bypass-android-ssl-verification-certificate-pinning/)
> - [objection](https://github.com/sensepost/objection) · [Frida](https://frida.re/)
