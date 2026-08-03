---
tags:
  - Go
  - Go/HTTP
  - Recon
Descripción: "El HTML que sirve el objetivo filtra inteligencia"
Fecha de actualización: 2026-07-26
Nota previa: "[[05 - Screenshots con headless Chrome (chromedp)]]"
Nota siguiente: "[[07 - Fingerprinting web y librerías JS obsoletas]]"
Area: "[[Clientes HTTP.base|Clientes HTTP]]"
---
---

El HTML que sirve el objetivo filtra inteligencia. Dos vetas clásicas: <mark style="background: #ADCCFFA6;">direcciones de correo</mark> (objetivos de phishing y semillas para password spraying) y <mark style="background: #ADCCFFA6;">comentarios en el código</mark> (`<!-- TODO -->`, notas de desarrollo, endpoints ocultos, a veces credenciales de debug). Encadenando esto con el [[04 - Crawler web concurrente|crawler]] mineas todo el sitio de una pasada. La metodología OSINT vive en Red Team [[00 - Reconocimiento web]]; aquí está el extractor en Go.

> [!info]+ Fuente
> Recetas "Finding e-mail addresses from web pages", "Finding comments in source code" y "Generating e-mail addresses from names" de *Python Web Penetration Testing Cookbook* (2015), unificadas y modernizadas.

## Extraer correos y comentarios

Regex sobre el cuerpo de la respuesta. La regla de oro: <mark style="background: #FFB8EBA6;">compila las regex una sola vez</mark>, a nivel de paquete — compilarlas dentro del bucle del crawler es caro y se repite por cada página (mismo principio que en [[01 - Fuzzer de SQL injection|el fuzzer]]):

```go
var (
    emailRe   = regexp.MustCompile(`[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}`)
    commentRe = regexp.MustCompile(`(?s)<!--(.*?)-->`)   // (?s): . casa saltos de línea
)

func harvest(body []byte) (emails, comments []string) {
    for _, m := range emailRe.FindAll(body, -1) {
        emails = append(emails, string(m))
    }
    for _, m := range commentRe.FindAllSubmatch(body, -1) {
        if c := strings.TrimSpace(string(m[1])); c != "" {
            comments = append(comments, c)
        }
    }
    return emails, comments
}
```

`FindAllSubmatch` con `m[1]` te da el **contenido** del comentario (grupo 1), no el `<!-- -->` envolvente. Para comentarios el regex `(?s)<!--(.*?)-->` es suficiente y robusto; la alternativa "correcta" es recorrer el árbol de nodos (`golang.org/x/net/html`, `html.CommentNode`), que `goquery` no expone por CSS.

> [!warning]+ Filtra los falsos positivos del correo
> Esa regex captura basura que **parece** un email: `sprite@2x.png`, `user@example.com` de plantillas, versiones `@1.2.3`. Deduplica (un `map[string]struct{}`) y descarta dominios de ejemplo y extensiones de imagen antes de reportar. Un set de emails con ruido quema credibilidad en el informe.

## Bonus: permutar nombres a correos

La receta de "generar emails desde nombres" es útil cuando conoces empleados (LinkedIn, `git log`, metadatos de [[03 - Scraping HTML - metadatos con goquery|documentos]]) pero no el formato corporativo. Generas los candidatos y los validas luego contra el login (nota [[02 - Enumeración de usuarios]]):

```go
func emailPermutations(first, last, domain string) []string {
    f, l := strings.ToLower(first), strings.ToLower(last)
    return []string{
        f + "." + l + "@" + domain,   // john.doe@
        f + l + "@" + domain,         // johndoe@
        f[:1] + l + "@" + domain,     // jdoe@   (nombres ASCII; para Unicode, indexa runas)
        f + "@" + domain,             // john@
        f + l[:1] + "@" + domain,     // johnd@
    }
}
```

## Modernizaciones sobre el recetario

- **`regexp` compilado a nivel de paquete**, no por-página. El original recompila en cada iteración.
- **Trabajo sobre `[]byte`** (`FindAll`, `FindAllSubmatch`) directamente desde el body, sin convertir a `string` primero — menos asignaciones (ver [[07 - Strings, runes y bytes]]).
- **Dedup y filtrado de FPs** explícitos, que el original ignora.
- <mark style="background: #FFB86CA6;">Veta moderna que el libro no cubre: los *source maps* de JavaScript</mark>. Las SPAs actuales meten poco en comentarios HTML, pero los bundles minificados suelen referenciar un `//# sourceMappingURL=app.js.map`. Ese `.map` reconstruye el **código fuente original** — rutas internas, nombres de variables, endpoints de API, a veces claves. Busca `sourceMappingURL` en cada `.js` servido y descárgalo.

> [!success]+ Qué hacer con el botín
> Correos → [[08 - Phishing|phishing]] y semillas de spraying. Comentarios → endpoints y parámetros ocultos que alimentan el [[00 - Motor de fuzzing web|fuzzer]]. Source maps → mapa del backend para caza de vulnerabilidades.

Para cerrar el recon, identificamos **qué tecnología** corre el objetivo y si arrastra librerías con CVEs conocidos → [[07 - Fingerprinting web y librerías JS obsoletas]].
