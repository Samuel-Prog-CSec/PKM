---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
Fecha de actualización: 2026-06-02
Nota previa: "[[06 - Fuerza bruta de subdominios]]"
Nota siguiente: "[[08 - Virtual Hosts]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
---

Cada vez que un sitio sirve `HTTPS`, presenta un certificado `SSL/TLS` que verifica su identidad. Para evitar que una `CA` (Certificate Authority) emita certificados fraudulentos sin que nadie se entere, existe `Certificate Transparency`: <mark style="background: #ADCCFFA6;">los `CT logs` son registros públicos, *append-only*, que anotan la emisión de cada certificado `SSL/TLS`</mark>. Cuando una CA emite un certificado, debe enviarlo a varios `CT logs` independientes, abiertos a inspección por cualquiera.

> [!info]+ Cómo se garantiza el *append-only*
> Cada `CT log` es un **árbol de Merkle** criptográfico: añadir un certificado produce una prueba que no permite borrar ni alterar entradas anteriores sin romper el hash raíz. Al emitir un certificado, la CA recibe un `SCT` (*Signed Certificate Timestamp*) que prueba su inclusión en el log; los navegadores pueden **exigir** ese `SCT` para aceptar el certificado. No cambia tu uso ofensivo (sigues consultando `crt.sh`), pero es lo que distingue un CT log de "una base de datos de certificados".

# Para qué existen

El propósito de diseño es defensivo, pero entenderlo explica por qué son una mina para el recon:

- **Detección temprana de certificados *rogue***: monitorizando los logs, un equipo de seguridad detecta certificados sospechosos o mal emitidos para su dominio y los revoca antes de que se usen para suplantación o `MITM`.
- **Responsabilidad de las CA**: si una CA emite un certificado que viola las normas, queda públicamente visible en los logs.
- **Refuerzo del Web PKI**: añaden supervisión pública al sistema de confianza que sostiene la comunicación segura.

# Por qué son oro para el recon

A diferencia de la fuerza bruta o las `wordlists`, que **adivinan**, <mark style="background: #FFB86CA6;">los CT logs son un registro **definitivo** de los certificados emitidos para un dominio y sus subdominios</mark>. No dependes de tu diccionario ni de tu algoritmo: obtienes la lista real de nombres para los que el objetivo pidió certificado.

Dos ventajas adicionales:

- **Visión histórica**: aparecen subdominios de certificados antiguos o caducados. <mark style="background: #FF5582A6;">Esos hosts suelen alojar software o configuraciones desactualizadas — candidatos perfectos a explotación</mark>.
- **Fugas previas al despliegue**: muchas organizaciones emiten el certificado de `staging.` o `internal-app.` **antes** de exponer el servicio. El nombre aparece en CT aunque el host aún no sea público — un soplo de infraestructura futura.

Los subdominios viven en el campo `SAN` (`Subject Alternative Name`) del certificado, que lista todos los nombres que ampara. Un único certificado puede declarar decenas de subdominios de golpe.

# Dónde buscar

| Herramienta | Características | Pros | Contras |
| - | - | - | - |
| `crt.sh` | Interfaz web sencilla, búsqueda por dominio, muestra detalles y `SAN` | Gratis, sin registro, API JSON | Filtrado y análisis limitados |
| `Censys` | Motor de búsqueda de dispositivos e infra, filtrado avanzado por dominio/IP/atributos del certificado | Datos extensos, API, *pivoting* | Requiere registro (capa gratuita) |

# `crt.sh` desde la terminal

`crt.sh` expone una API JSON, ideal para automatizar. Para sacar todos los subdominios `dev` de `facebook.com`:

```shell-session
$ curl -s "https://crt.sh/?q=facebook.com&output=json" \
  | jq -r '.[] | select(.name_value | contains("dev")) | .name_value' \
  | sort -u

*.dev.facebook.com
*.newdev.facebook.com
dev.facebook.com
devvm1958.ftw3.facebook.com
facebook-amex-dev.facebook.com
newdev.facebook.com
```

- `curl ...output=json`: obtiene los certificados que coinciden con `facebook.com` en JSON.
- `jq ... contains("dev")`: filtra las entradas cuyo `name_value` contiene `dev`.
- `sort -u`: ordena y elimina duplicados.

> [!warning]+ Wildcards y nombres muertos
> Verás muchas entradas *wildcard* (`*.dev.facebook.com`): el certificado ampara cualquier host bajo ese sufijo, pero **no** te dice qué hosts existen realmente. Además, parte de los nombres de CT corresponden a certificados viejos cuyos hosts ya no resuelven. <mark style="background: #8000E1A6;">CT te da candidatos, no hosts vivos</mark>: pasa siempre la lista por un resolvedor (`dnsx`, `puredns`) y un sondeo HTTP (`httpx`) para quedarte con lo que responde.

> [!info]+ Herramientas que consumen CT
> No necesitas parsear `crt.sh` a mano: `subfinder` y `amass` ya integran los CT logs entre sus fuentes pasivas. `certspotter` monitoriza emisiones nuevas en tiempo real (útil para recon continuo), y `cero` extrae los `SAN` directamente del handshake TLS de hosts vivos. En `Censys` o `Shodan` puedes **pivotar por certificado**: dado el hash o el `SAN` de un certificado, encuentras todos los hosts que lo presentan — una vía para correlacionar infraestructura aparentemente inconexa.

CT y DNS cubren los hosts que el objetivo publica. Pero algunos servidores esconden sitios que solo responden a la cabecera `Host` correcta y nunca aparecen en ningún registro: los [[08 - Virtual Hosts]].
