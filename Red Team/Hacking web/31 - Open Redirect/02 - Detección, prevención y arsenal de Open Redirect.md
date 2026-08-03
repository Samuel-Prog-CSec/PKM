---
tags:
  - Web/Red-Team
  - Open-Redirect
  - Pentesting/Explotacion
  - Tipo/Arsenal
Descripción: "Pipeline típico de recon (encadena descubrimiento → filtrado → prueba masiva)"
Fecha de actualización: 2026-07-27
Nota previa: "[[01 - Bypasses de validación y chaining de Open Redirect]]"
Nota siguiente: ""
Area: "[[Open Redirect.base|Open Redirect]]"
---
---

# Arsenal

| Herramienta | Uso |
| - | - |
| [`gau`](https://github.com/lc/gau) + [`gf redirect`](https://github.com/1ndianl33t/Gf-Patterns) | Minar URLs históricas y filtrar parámetros de redirect (sucesor mantenido de `waybackurls`) |
| [OpenRedireX](https://github.com/devanshbatham/OpenRedireX) | Fuzzer dedicado: `cat urls.txt \| openredirex -p payloads.txt` |
| [Oralyzer](https://github.com/r0075h3ll/Oralyzer) | Detecta redirect por header/JS/meta + CRLF + minado Wayback |
| [`nuclei`](https://github.com/projectdiscovery/nuclei-templates) | `open-redirect-generic.yaml` + `headless-open-redirect.yaml` (variante *headless* para redirects por JS) |
| Burp [Param Miner](https://portswigger.net/bappstore/17d2949a985c4b7ca092728dba871943) + DOMInvader | Descubrir el parámetro de redirect oculto; DOMInvader traza sinks del DOM (`location.href`) en vivo |

Pipeline típico de recon (encadena descubrimiento → filtrado → prueba masiva):

```shell-session
$ cat domains.txt | gau | gf redirect | uro | qsreplace 'https://evil.com' | httpx -silent -fr -mc 200-399
```

`-fr` sigue las redirecciones y `-mc 200-399` acepta también respuestas `2xx` (no solo `3xx`), porque el redirect puede ir por `meta`/JS y responder `200`. Un hit se ve así: `https://target/redirect?url=https://evil.com [302] [https://evil.com]`.

> [!warning]+ Overridea la severidad del escáner
> Los templates de `nuclei` clasifican open redirect como *low* por defecto. Dado el chaining (OAuth, SSRF, client-side CSRF — [[01 - Bypasses de validación y chaining de Open Redirect|nota anterior]]), súbela en el triaje cuando encadene con impacto real.

# Prevención

En orden de robustez (OWASP Cheat Sheet + RFC 9700):

1. <mark style="background: #ADCCFFA6;">**Eliminar el parámetro de redirect**</mark> — rediseñar el flujo para que ninguna URL venga del atacante. Lo mejor.
2. **Indirección**: el cliente manda un ID/token opaco; el servidor lo mapea al destino real server-side. Nada que confundir en el parser.
3. **Si aceptas ruta relativa**: rechaza `://`, `//` inicial, `\` y `@`; parsea con librería real (`new URL()`, `urllib.parse`, `java.net.URI`) y valida el **host parseado**, nunca el string crudo. <mark style="background: #FF5582A6;">Ojo: un `//` inicial **no** es una ruta relativa segura</mark> (corrección a la vieja recomendación de "usa una ruta relativa").
4. **Si es una URL externa inevitable** (OAuth, webhooks): allowlist de **hosts/URLs exactos** sobre el host parseado, jamás `contains`/`startsWith`/regex sin anclar. Para OAuth, el RFC 9700 obliga a *exact match*.
5. **Página interstitial** mostrando el host real de destino (fallback de OWASP para enlaces salientes arbitrarios).
6. **No confíes en CSP** como backstop — es bypasseable a través del propio redirect.
7. **`Referrer-Policy: strict-origin-when-cross-origin`** explícito en páginas cuya URL lleve datos sensibles.
8. **Ningún cambio de estado por GET** — cierra la vía de client-side CSRF / SameSite bypass.

# Detección (lado defensor)

- Respuestas `3xx` cuyo `Location` apunta a un host **externo** con un parámetro de la request reflejado en él.
- Picos de `Referer` a dominios externos precedidos de una URL propia con parámetro de redirect.
- WAF: firmas de `//`, `@`, `\`, `%09` en parámetros tipo `url`/`next`/`redirect` — con la salvedad de que la ofuscación las evade; complementar con validación en el código, no confiar solo en el WAF.

> [!info]+ Fuentes
> [OWASP — Unvalidated Redirects and Forwards Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html); [PortSwigger — DOM-based open redirection](https://portswigger.net/web-security/dom-based/open-redirection); [Claroty Team82 — Exploiting URL Parsing Confusion](https://claroty.com/team82/research/exploiting-url-parsing-confusion); [RFC 9700](https://www.rfc-editor.org/info/rfc9700/); NDSS 2025 — "[Do (Not) Follow the White Rabbit](https://www.ndss-symposium.org/wp-content/uploads/2025-523-paper.pdf)".
