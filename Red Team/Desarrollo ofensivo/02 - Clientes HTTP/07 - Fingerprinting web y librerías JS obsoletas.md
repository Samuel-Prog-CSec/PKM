---
tags:
  - Go
  - Go/HTTP
  - Recon
Descripción: "Antes de atacar, identificas qué corre el objetivo: servidor, framework y —clave para bug bounty— las librerías JavaScript que arrastra"
Fecha de actualización: 2026-07-26
Nota previa: "[[06 - Harvesting de correos y comentarios del código fuente]]"
Nota siguiente: 
Area: "[[Clientes HTTP.base|Clientes HTTP]]"
---
---

Antes de atacar, identificas **qué corre** el objetivo: servidor, framework y —clave para bug bounty— las **librerías JavaScript** que arrastra. Una versión vieja de jQuery, Angular o Bootstrap es a menudo un CVE servido en bandeja (OWASP A06:2021, *Vulnerable and Outdated Components*). La metodología de fingerprinting vive en Red Team [[09 - Fingerprinting web]]; aquí el detector en Go.

> [!info]+ Fuente y modernización
> Receta "jQuery checking" de *Python Web Penetration Testing Cookbook* (2015). El original solo **imprime la versión** de jQuery. La modernización real es mapear esa versión a **CVEs conocidos** con el dataset de [retire.js](https://github.com/RetireJS/retire.js) — el estándar mantenido para detectar librerías JS vulnerables.

## Fingerprint del servidor por cabeceras

Lo barato primero: las cabeceras de respuesta delatan el stack. Un `HEAD` basta:

```go
func serverFingerprint(h http.Header) map[string]string {
    fp := map[string]string{}
    for _, k := range []string{"Server", "X-Powered-By", "X-AspNet-Version", "X-Generator", "Via"} {
        if v := h.Get(k); v != "" {
            fp[k] = v
        }
    }
    return fp
}
```

`Server: Apache/2.4.29`, `X-Powered-By: PHP/5.6.40`, `X-Generator: Drupal 7` — cada uno acota exploits. La manipulación **activa** de estas cabeceras (métodos, spoofing) la vemos en [[00 - Testing de métodos HTTP y fingerprinting|el bloque de cabeceras]].

## Detectar librerías JS y su versión

Recorres los `<script src>` con `goquery` y sacas la versión del nombre del fichero (o, si está inline, del banner `/*! jQuery v3.4.1 */`):

```go
type Finding struct {
    Library string
    Version string
    Source  string
}

// Compiladas una vez. La versión va en el grupo 1.
var libRes = map[string]*regexp.Regexp{
    "jquery":    regexp.MustCompile(`(?i)jquery[.\-/]?v?(\d+\.\d+\.\d+)`),
    "bootstrap": regexp.MustCompile(`(?i)bootstrap[.\-/]?v?(\d+\.\d+\.\d+)`),
    "angular":   regexp.MustCompile(`(?i)angular(?:js)?[.\-/]?v?(\d+\.\d+\.\d+)`),
}

func detectLibs(doc *goquery.Document) []Finding {
    var out []Finding
    doc.Find("script[src]").Each(func(_ int, s *goquery.Selection) {
        src, _ := s.Attr("src")
        for lib, re := range libRes {
            if m := re.FindStringSubmatch(src); m != nil {
                out = append(out, Finding{Library: lib, Version: m[1], Source: src})
            }
        }
    })
    return out
}
```

## De versión a vulnerabilidad — no lo hardcodees

El paso que hace útil el fingerprint es cruzar `(lib, versión)` contra vulnerabilidades conocidas. <mark style="background: #FF5582A6;">jQuery < 3.5.0 arrastra XSS</mark> (`CVE-2020-11022` / `CVE-2020-11023`) vía `.html()` con HTML no confiable. Compara con semver de verdad, no con prefijos de string:

```go
import "golang.org/x/mod/semver"   // comparación semver correcta

func jqueryVulnerable(version string) bool {
    return semver.Compare("v"+version, "v3.5.0") < 0
}
```

Pero <mark style="background: #8000E1A6;">no mantengas tú la base de reglas</mark>: envejece a las semanas. Carga el `jsrepository.json` de **retire.js** (regex + rangos de versión + CVEs, actualizado por la comunidad) y evalúa contra él. Tu herramienta pone el motor; retire.js pone el conocimiento.

## Modernizaciones sobre el recetario

- **De "imprimir versión" a mapear CVE**: el valor está en la correlación con vulnerabilidades, no en el número suelto.
- **Comparación con `golang.org/x/mod/semver`**, no comparando strings: léxicográficamente `"3.10.0"` sale **menor** que `"3.9.0"` (porque el tercer carácter `'1' < '9'`), justo al revés que en semver, donde 3.10.0 es **mayor** que 3.9.0. Comparar versiones como strings te haría marcar una versión parcheada como vulnerable, o viceversa.
- **Dataset externo (retire.js)** en vez de reglas hardcodeadas que caducan.
- **Detección también inline y en cabeceras**, no solo por nombre de fichero — muchos sitios sirven `app.min.js` sin versión en el nombre, pero con banner dentro.

> [!info]+ Arsenal
> `retire.js` (CLI y extensión), `Wappalyzer` (fingerprint de stack) y `nuclei` con sus plantillas de *tech-detect* automatizan esto en producción. Tu detector Go encaja cuando lo integras en un pipeline propio o el objetivo tiene una carga rara. En Red Team, el escaneo con plantillas está en [[26 - Escaneo dirigido con nuclei]].

---

Con esto cierras el bloque de recon web sobre el cliente HTTP: crawling, screenshots, harvesting y fingerprinting. El siguiente capítulo le da la vuelta — en vez de **consumir** servicios, **montar los tuyos** para phishing, keylogging y C2 → [[Servidores HTTP.base|Servidores HTTP]].
