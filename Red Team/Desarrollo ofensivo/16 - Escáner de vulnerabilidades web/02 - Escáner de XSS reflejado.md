---
tags:
  - Go
  - Go/Web
  - XSS
Descripción: "XSS reflejado: tu input vuelve en la respuesta sin escapar, en un contexto donde el navegador lo ejecuta"
Fecha de actualización: 2026-07-26
Nota previa: "[[01 - Escáner de path traversal]]"
Nota siguiente: "[[03 - Escáner de Shellshock]]"
Area: "[[Escáner de vulnerabilidades web.base|Escáner de vulnerabilidades web]]"
---
---

XSS reflejado: tu input vuelve en la respuesta **sin escapar**, en un contexto donde el navegador lo ejecuta. La teoría (contextos, sinks, explotación, evasión) vive en Red Team [[02 - XSS Reflejado]] y [[04 - Descubrimiento de XSS]]; aquí el escáner sobre el [[00 - Motor de fuzzing web|motor de fuzzing]], con las tres superficies del libro (URL, parámetro, cabecera) unificadas.

> [!info]+ Fuente
> Recetas "Automated URL-based Cross-site scripting", "Automated parameter-based Cross-site scripting" y "Header-based Cross-site scripting" de *Python Web Penetration Testing Cookbook* (2015). El original grepea `<script>`; aquí usamos canario único, detección de escape y verificación de ejecución.

## Canario único, no `<script>`

<mark style="background: #FF5582A6;">Buscar `<script>` en la respuesta genera falsos positivos</mark>: casi toda página ya contiene `<script>`. La detección fiable inyecta un **canario aleatorio** rodeado de metacaracteres y comprueba si vuelve **sin escapar**:

```go
func xssCanary() string { return "xq" + randToken(6) + "zx" }   // token improbable y único

// El probe: rompe atributo/tag y mete el canario entre < >.
func xssMatcher(canary string) Matcher {
    reflected := []byte(`"><` + canary + `>`)   // si esto vuelve literal, los <>" no se escaparon
    return func(payload string, resp *http.Response, body []byte, _ time.Duration) (Finding, bool) {
        if bytes.Contains(body, reflected) {
            return Finding{
                Payload:  payload,
                Status:   resp.StatusCode,
                Evidence: "canario reflejado sin escapar (< > \" intactos)",
            }, true
        }
        return Finding{}, false
    }
}
```

Si la respuesta trae `"&gt;&lt;xq…zx&gt;` (escapado), la app filtra bien en ese contexto. Si trae `"><xq…zx>` literal, <mark style="background: #FFB86CA6;">los metacaracteres sobreviven</mark> → candidato a XSS.

## Las tres superficies, un solo motor

Cambias **dónde** pones el `§FUZZ§` y cubres las tres recetas del libro con la misma llamada:

```go
canary := xssCanary()
payload := `"><` + canary + `>`
m := xssMatcher(canary)

// URL / parámetro:
turl := Target{Method: http.MethodGet, URL: "https://target.tld/search?q=§FUZZ§"}
// Cabecera (User-Agent, Referer, X-Forwarded-For reflejados en errores/paneles/analytics):
thdr := Target{
    Method:  http.MethodGet,
    URL:     "https://target.tld/",
    Headers: map[string]string{"User-Agent": "§FUZZ§", "Referer": "§FUZZ§"},
}
Fuzz(ctx, turl, []string{payload}, m, client, 10, 20)
Fuzz(ctx, thdr, []string{payload}, m, client, 10, 20)
```

## Reflejo ≠ ejecución: verifica el contexto

Que el canario vuelva sin escapar es **necesario pero no suficiente**. Dónde aterriza decide el breakout: dentro de `<script>var x="AQUÍ"` necesitas `";…//`; en `<input value="AQUÍ">`, `"><svg…`; en texto HTML, `<svg onload=…>`. Y la confirmación real de que **ejecuta** la da un navegador: cargas la URL con [[05 - Screenshots con headless Chrome (chromedp)|chromedp]] y detectas si tu JS corrió (un handler de `dialog`, o el canario escrito en `document.title`). Es lo que hace `dalfox` internamente.

## Modernizaciones sobre el recetario

- **Canario aleatorio único** en vez de `<script>` — elimina los falsos positivos del original.
- **Detección por no-escape** de metacaracteres, no por presencia del string.
- **Las tres superficies unificadas** (URL/param/cabecera) sobre un motor, no tres scripts separados.
- <mark style="background: #8000E1A6;">Verificación con navegador headless</mark> para pasar de "reflejado" a "ejecuta", que el original ni plantea.
- **Conciencia de contexto** para elegir el payload de breakout, no un `<script>alert(1)</script>` que muere en cualquier atributo.

> [!info]+ Arsenal
> `dalfox` (Go) y `XSStrike` automatizan reflejo → contexto → ejecución con verificación headless y bypass de WAF. Tu escáner Go es la base didáctica y el punto de partida para lógica a medida. La evasión de filtros XSS está en Red Team [[05 - Evasión y ofuscación de XSS]]; la explotación avanzada, en [[00 - Introducción a la explotación XSS avanzada]].

El último escáner de la carpeta ataca un clásico de CGI legacy: ejecución de comandos vía Shellshock → [[03 - Escáner de Shellshock]].
