---
tags:
  - Web/Red-Team
  - Subdomain-Takeover
  - Pentesting/Explotacion
  - Tipo/Introduccion
Descripción: "Un *subdomain takeover* ocurre cuando un atacante reclama un subdominio de un sitio legítimo — y a partir de ahí sirve su propio contenido o intercepta tráfico desde un dominio…"
Fecha de actualización: 2026-07-27
Nota previa: ""
Nota siguiente: "[[01 - Identificación y explotación de Subdomain Takeover]]"
Area: "[[Subdomain Takeover.base|Subdomain Takeover]]"
---
---

<mark style="background: #ADCCFFA6;">Un *subdomain takeover* ocurre cuando un atacante reclama un subdominio de un sitio legítimo</mark> — y a partir de ahí sirve su propio contenido o intercepta tráfico desde un dominio de confianza. Nace de un **registro DNS colgante** (*dangling*): un `CNAME` o `A` que apunta a un recurso de terceros que ya no existe.

# DNS: los registros que importan

Un dominio es jerárquico y se lee de derecha a izquierda: TLD (`.com`), dominio (`example`), subdominio (`www`, `mail`…). Los subdominios se crean con registros DNS, y dos son los relevantes aquí:
- **`A`**: mapea un nombre a una o varias **IP**.
- **`CNAME`**: mapea un nombre a **otro nombre** (un alias).

Solo el administrador crea registros DNS (salvo que encuentres una vulnerabilidad que lo permita). El takeover no rompe el DNS — **aprovecha** un registro que apunta a un destino que el atacante **sí** puede reclamar.

# Cómo ocurre

<mark style="background: #8000E1A6;">El patrón es siempre el mismo: se desaprovisiona el recurso de terceros pero se olvida borrar el registro DNS que lo apuntaba</mark>. Ejemplo con Heroku:

1. Example Company crea una app en Heroku.
2. Heroku le asigna `unicorn457.herokuapp.com`.
3. La empresa crea un `CNAME`: `test.example.com → unicorn457.herokuapp.com`.
4. Meses después borra la app de Heroku… **pero no el `CNAME`**.
5. Un atacante ve el `CNAME` colgante apuntando a un `unicorn457.herokuapp.com` **sin dueño**.
6. Registra `unicorn457` en Heroku → ahora controla `test.example.com`.

Los servicios más asociados históricamente: <mark style="background: #FFB8EBA6;">Heroku, GitHub Pages, Amazon S3, Zendesk, SendGrid, Fastly</mark> y —cuando el `CNAME`/`A` apunta a un **dominio o IP expirados**— cualquiera que pueda re-registrarlos. El inventario vivo de servicios explotables lo mantiene el proyecto [`can-i-take-over-xyz`](https://github.com/EdOverflow/can-i-take-over-xyz) (ver [[02 - Detección, prevención y arsenal de Subdomain Takeover|arsenal]]).

# Por qué duele: impacto y chaining

El impacto depende de la configuración del subdominio y del dominio padre, pero <mark style="background: #FFB86CA6;">controlar un subdominio de confianza abre varias vías</mark>:

- **Robo de cookies del dominio padre.** Si una cookie se emite con `Domain=.example.com` (punto inicial), el navegador la envía a **todos** los subdominios. Un atacante en `test.example.com` roba las cookies de sesión de `example.com` (Arne Swinnen, *Web Hacking Pro Tips #8*).
- **Phishing sobre dominio legítimo**: un login falso en el subdominio secuestrado es indistinguible de la marca real.
- **Bypass de allowlists**: si `test.example.com` está en el `redirect_uri` de [[07 - Introducción a OAuth 2.0|OAuth]], en un `script-src` de CSP o en los orígenes CORS, tomarlo rompe esas defensas (encadena con [[04 - Mindset del cazador y encadenamiento de bugs|otras vulns]]).
- **Intercepción de correo**: si el registro colgante es de un servicio de email (SendGrid vía `MX`), se interceptan correos entrantes — el caso Uber que pagó **$10.000**.

Cómo **encontrarlos** (fingerprints por servicio) y **reclamarlos** (incluidos los trucos de wildcard y webhook), con los seis casos reales del libro, en la [[01 - Identificación y explotación de Subdomain Takeover|nota siguiente]].
