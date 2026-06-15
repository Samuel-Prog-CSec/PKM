---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - CSRF
Fecha de actualización: 2026-06-13
Nota previa: "[[07 - Herramientas para CSRF y CORS]]"
Nota siguiente:
Area: "[[CSRF.base|CSRF]]"
---
---

El `clickjacking` (o *UI redress*) es el ataque hermano del [[01 - Fundamentos y defensas de CSRF|CSRF]]: también consigue que la víctima ejecute una acción no intencionada en una aplicación donde está autenticada, pero por otra vía. <mark style="background: #ADCCFFA6;">Superpone la web víctima en un `iframe` invisible sobre un señuelo atractivo, de modo que la víctima cree pulsar el señuelo cuando en realidad clica en la aplicación real</mark>. Su relevancia hoy: <mark style="background: #FFB86CA6;">funciona justo donde el CSRF clásico ya no —cuando hay token anti-CSRF—</mark>, porque el clic ocurre sobre la página auténtica cargada en el iframe, con su token legítimo presente.

# Cómo funciona

El atacante aloja una página con dos capas: un señuelo visible ("Has ganado un premio, pulsa aquí") y, encima, un `iframe` de la aplicación víctima con `opacity: 0`, posicionado para que su botón sensible quede justo bajo el cursor del señuelo:

```html
<style>
  iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%;
           opacity: 0; z-index: 2; }
  #decoy { position: absolute; z-index: 1; }
</style>
<div id="decoy">¡Pulsa para reclamar tu premio!</div>
<iframe src="https://vulnerablesite.htb/account/delete"></iframe>
```

La víctima ve el señuelo, pulsa, y el clic aterriza en el botón real del iframe. <mark style="background: #8000E1A6;">Como la petición la dispara una interacción real dentro de la página auténtica, el token CSRF viaja correctamente</mark> y la aplicación la acepta. Por eso el clickjacking sortea la defensa que detiene al CSRF.

# Dos condiciones imprescindibles

1. **La página debe ser enmarcable**: si responde con `X-Frame-Options` o `CSP frame-ancestors` restrictivos, el navegador no la carga en el iframe y el ataque muere.
2. <mark style="background: #FF5582A6;">**La cookie debe enviarse dentro del iframe**</mark>: aquí entra el [[05 - Bypass de SameSite y defensas de cabecera|SameSite]]. Un `iframe` cross-site es un subrecurso, así que `SameSite=Lax` (el default moderno) o `Strict` **bloquean** la cookie y la víctima aparece deslogueada en el iframe —sin sesión, no hay acción sensible—. El clickjacking explotable exige hoy, en la práctica, `SameSite=None`. Es el mismo factor que limita el CSRF moderno.

# Variantes

- **Multi-paso / drag-and-drop**: encadenar varios clics o arrastres para flujos que requieren más de una acción, o para rellenar y enviar formularios (robo de datos arrastrando texto a un campo controlado).
- **Bait-and-switch**: mover el iframe en el último momento para que el clic caiga donde interesa.
- **Combinación con prefilled forms**: si la app acepta parámetros en `GET` que prerellenan un formulario, el iframe puede apuntar a una URL que deja la acción a un solo clic.

# Defensas

| Mecanismo | Estado | Nota |
| - | - | - |
| `CSP frame-ancestors 'none'`/`'self'` | **Recomendado** | La defensa moderna; reemplaza a XFO y es más granular |
| `X-Frame-Options: DENY`/`SAMEORIGIN` | Legacy/refuerzo | Aún amplio soporte; sin granularidad de `frame-ancestors` |
| Frame busting JS (`if (top!=self)...`) | Obsoleto | <mark style="background: #FFB8EBA6;">Bypasseable</mark> con `sandbox` del iframe (bloquea su JS) o `onbeforeunload` |
| `SameSite=Lax`/`Strict` | Colateral | Corta la sesión en el iframe; mitiga de hecho aunque no sea su fin |

`frame-ancestors` es una directiva de la misma [[04 - Content Security Policy (CSP)|CSP]] que ya usamos contra XSS — conviene revisarla en la cabecera al evaluar ambos.

# Detección

Lo primero: comprobar si la página se deja enmarcar. Revisa las cabeceras de respuesta (`X-Frame-Options`, `Content-Security-Policy: frame-ancestors`); si faltan o son laxas, monta un PoC con un `iframe` simple y mira si carga. <mark style="background: #FF5582A6;">El impacto depende de qué acción se logra con un clic</mark>: un *like* es *low*; borrar la cuenta o cambiar el email a uno tuyo, *high*. **Burp Clickbandit** genera el PoC de clickjacking automáticamente a partir de la página.

> [!warning]+ Por qué se reporta menos de lo que parece
> Muchos triajes rebajan el clickjacking: requiere interacción de la víctima y, con `SameSite=Lax` por defecto, a menudo la sesión ni viaja en el iframe. Para que sea un hallazgo sólido necesitas **las dos condiciones** (enmarcable + cookie cross-site) **y** una acción sensible de bajo número de clics. Demuéstralo con un PoC funcional y encadénalo a una acción de impacto real, o quedará como *informational*.

> [!info]+ Fuentes
> - [PortSwigger — Clickjacking](https://portswigger.net/web-security/clickjacking) · [Burp Clickbandit](https://portswigger.net/burp/documentation/desktop/tools/clickbandit)
> - [OWASP — Clickjacking Defense Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Clickjacking_Defense_Cheat_Sheet.html)

El CSRF y el clickjacking se potencian enormemente cuando hay un `XSS` de por medio: el XSS elimina la barrera same-site y abre el pivote a la red interna. Ese es el siguiente sub-tema: [[00 - Introducción a la explotación XSS avanzada]].
