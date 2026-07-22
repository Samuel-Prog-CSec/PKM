---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - HTTP/Host-Header
Fecha de actualización: 2026-07-14
Nota previa: "[[05 - Detección, herramientas y prevención de Cache Poisoning]]"
Nota siguiente: "[[07 - Bypass de autenticación por Host Header]]"
Area: "[[HTTP Misconfigurations.base|HTTP Misconfigurations]]"
---
---

La cabecera **`Host`** es obligatoria desde HTTP/1.1 e indica a qué host va la petición. Su razón de ser son los **Virtual Hosts** (`vhosts`): un mismo servidor, en una misma IP y puerto, aloja varias aplicaciones y decide cuál servir según el `Host`. Es independiente del DNS. Los **CDN** (Cloudflare, Akamai) también enrutan por `Host` a través de sus proxies y balanceadores.

```apache
<VirtualHost *:80>
  DocumentRoot "/var/www/testapp"
  ServerName testapp.htb          # ← se sirve si Host: testapp.htb
</VirtualHost>
<VirtualHost *:80>
  DocumentRoot "/var/www/anotherdomain"
  ServerName anotherdomain.org     # ← se sirve si Host: anotherdomain.org
</VirtualHost>
```

Como el `Host` **decide qué aplicación responde**, enumerar vhosts por fuerza bruta (fuzzing del `Host` con `ffuf`) descubre aplicaciones ocultas no publicadas en DNS — un paso de recon habitual.

# Por qué el `Host` es peligroso

<mark style="background: #ADCCFFA6;">Las vulnerabilidades de Host header nacen de **confiar** en el valor del `Host` sin validarlo</mark>. Y el `Host` es <mark style="background: #FF5582A6;">input **controlable por el cliente**</mark>. De ahí las dos familias principales:

- **Decisiones de seguridad basadas en el `Host`**: si la app usa el `Host` para comprobar autorización (p. ej. "si `Host` es `localhost`/`intranet`, salta el login"), manipularlo da un [[07 - Bypass de autenticación por Host Header|bypass de autenticación]].
- **Construcción de enlaces absolutos**: la app necesita saber su dominio para generar URLs absolutas (enlaces de reset de contraseña, imports de scripts). Si toma ese dominio del `Host` sin validar, aparece el [[08 - Password Reset Poisoning|password reset poisoning]].

# Override Headers: el `Host` tiene primos

Existen cabeceras que **anulan o complementan** el significado del `Host`, y que muchos servidores/frameworks respetan. Son las **override headers**:

| Cabecera | Nota |
| - | - |
| `X-Forwarded-Host` | La más común; proxies la usan para el host original |
| `X-Host`, `X-Forwarded-Server` | Variantes de proxy |
| `X-HTTP-Host-Override` | Override explícito |
| `Forwarded` | La estándar (RFC 7239): `Forwarded: host=evil.htb` |
| `X-Original-Host` | Otra variante frecuente |

<mark style="background: #FFB86CA6;">El fallo típico: la validación se aplica **solo al `Host`** y no a las override headers</mark>. Si la app las soporta, colar `X-Forwarded-Host: evil.htb` sortea la validación y reintroduce el ataque. **Siempre** se prueban todas.

# Cuando no puedes tocar el `Host` directamente (evasión)

En un objetivo real tras un CDN, poner un `Host` inventado suele fallar: el intermediario no sabe enrutarlo y descarta la petición. Técnicas de PortSwigger para inyectar igualmente:

- **Override headers** (arriba) — el atajo más limpio.
- **`Host` duplicado**: enviar dos cabeceras `Host`; front-end y back-end pueden priorizar distinta.
  ```http
  Host: legit.htb
  Host: evil.htb
  ```
- **URL absoluta en la request line** + `Host`: `GET https://legit.htb/ HTTP/1.1` con `Host: evil.htb` — algunos servidores prefieren uno u otro.
- **Line wrapping / indentación**: una línea `Host` indentada con espacio/tab que el front-end ignora pero el back-end procesa.
- **Puerto o subdominio arbitrario**: `Host: legit.htb:evil` o inyectar en el puerto si solo se valida el dominio base.

> [!warning] Detección tras un CDN
> Si el `Host` inválido se descarta antes de llegar al backend, el ataque puede seguir siendo viable **combinado con [[01 - Introducción a Web Cache Poisoning|web cache poisoning]]**: envenenas la caché con un `Host`/`X-Forwarded-Host` malicioso para un recurso legítimo, y la respuesta envenenada se sirve a las víctimas. <mark style="background: #8000E1A6;">Host header y cache poisoning se potencian mutuamente</mark>.

# Metodología de detección

1. Envía la petición con el `Host` (o `X-Forwarded-Host`) modificado a un valor de control (`evil.htb`).
2. Busca **dónde se refleja**: en el cuerpo, en un enlace absoluto, en una cabecera `Location` (redirect), o —el más jugoso— en un **correo** (reset de contraseña).
3. Prueba **todas** las override headers y las técnicas de inyección si el `Host` directo se bloquea.

Los ataques concretos —[[07 - Bypass de autenticación por Host Header|auth bypass]], [[08 - Password Reset Poisoning|reset poisoning]], [[09 - Web Cache Poisoning por Host Header|cache poisoning por Host]] y [[10 - Bypass de validación del Host Header|bypass de validación]]— se ven en las notas siguientes.

## Referencias

- [PortSwigger — HTTP Host header attacks](https://portswigger.net/web-security/host-header)
- [PortSwigger — How to test for Host header injection](https://portswigger.net/web-security/host-header/exploiting)
- [RFC 7239 — Forwarded HTTP Extension](https://www.rfc-editor.org/rfc/rfc7239)
