---
tags:
  - Go
  - Go/Web
  - HTTP
  - Tipo/Introduccion
Descripción: "La capa de transporte HTTP tiene su propia superficie de ataque: qué métodos acepta el servidor, cómo reacciona a verbos raros, qué delata en sus cabeceras"
Fecha de actualización: 2026-07-26
Nota previa: 
Nota siguiente: "[[01 - Auditoría de cabeceras de seguridad y clickjacking]]"
Area: "[[Manipulación de cabeceras HTTP.base|Manipulación de cabeceras HTTP]]"
---
---

La capa de transporte HTTP tiene su propia superficie de ataque: qué **métodos** acepta el servidor, cómo reacciona a verbos raros, qué delata en sus **cabeceras**. Un `PUT` habilitado puede subir un webshell; un verbo arbitrario que el servidor trata como `GET` puede saltarse la autorización (verb tampering). La teoría vive en Red Team [[01 - Introducción a HTTP Verb Tampering]]; aquí el tester en Go.

> [!info]+ Fuente
> Recetas "Testing HTTP methods" y "Fingerprinting servers through HTTP headers" de *Python Web Penetration Testing Cookbook* (2015).

## Qué métodos acepta

`OPTIONS` suele responder con la cabecera `Allow`, pero **no te fíes**: muchos servidores mienten o la omiten. Confirmas probando cada método y viendo el status real:

```go
var probeMethods = []string{
    http.MethodGet, http.MethodPost, http.MethodPut, http.MethodDelete,
    http.MethodOptions, http.MethodPatch, "TRACE", "ZATER",   // incluye un verbo inventado
}

func methodMatrix(ctx context.Context, client *http.Client, target string) map[string]int {
    out := make(map[string]int, len(probeMethods))
    for _, m := range probeMethods {
        req, err := http.NewRequestWithContext(ctx, m, target, nil)
        if err != nil {
            continue
        }
        resp, err := client.Do(req)
        if err != nil {
            continue
        }
        io.Copy(io.Discard, resp.Body)
        resp.Body.Close()
        out[m] = resp.StatusCode   // 405 = no permitido; 200/otros = habilitado
    }
    return out
}
```

## Cómo leer la matriz

- <mark style="background: #FFB86CA6;">`PUT` / `DELETE` con `200`/`201`/`204`</mark>: escritura o borrado de recursos. `PUT` habilitado es a menudo subida directa de ficheros → webshell.
- **`TRACE` habilitado**: Cross-Site Tracing (XST), refleja cabeceras — puede filtrar cookies `HttpOnly` en navegadores viejos.
- <mark style="background: #FF5582A6;">El verbo inventado (`ZATER`) devuelve `200` en vez de `405`</mark>: el servidor trata los verbos desconocidos como `GET`. Si un endpoint protegido solo filtra `GET`/`POST`, un verbo raro **salta la autorización** — la esencia del verb tampering.

Comparas la matriz de un endpoint público con la de uno protegido: si `GET /admin` da `401` pero `ZATER /admin` o `HEAD /admin` dan `200`, tienes bypass. La detección/evasión completa está en Red Team [[04 - Detección, evasión y prevención de Verb Tampering]].

> [!warning]+ Estos métodos MODIFICAN el objetivo
> `PUT`, `DELETE`, `PATCH` no son de solo lectura: pueden **crear, sobrescribir o borrar** recursos reales en el servidor. Probarlos a ciegas en un engagement puede destruir datos o dejar ficheros. Lánzalos solo con autorización explícita, contra rutas de prueba, y nunca en un barrido automático indiscriminado. En duda, usa `OPTIONS` y para.

## Fingerprint por cabeceras

Cada método puede devolver cabeceras distintas que delatan el stack (ya visto en el [[07 - Fingerprinting web y librerías JS obsoletas|fingerprinting de recon]], aquí desde el ángulo de manipulación):

```go
func headerFingerprint(h http.Header) map[string]string {
    fp := map[string]string{}
    for _, k := range []string{"Server", "X-Powered-By", "X-AspNet-Version", "X-Backend-Server"} {
        if v := h.Get(k); v != "" {
            fp[k] = v
        }
    }
    return fp
}
```

## Modernizaciones sobre el recetario

- **Verbo arbitrario** en la batería para pillar el "trata lo desconocido como GET" — el vector real de verb tampering, que el original no prueba.
- **Confirmación por status real**, no confiar en el `Allow` de `OPTIONS`.
- **`context` y cliente reutilizado** con timeout.
- <mark style="background: #8000E1A6;">Aviso de seguridad explícito</mark> sobre métodos destructivos — el original los lanza sin advertir, y en real eso rompe cosas.

> [!info]+ Arsenal
> `nmap --script http-methods`, `nuclei` con plantillas de verb tampering, y Burp (Repeater/Intruder) para probar verbos a mano. Herramientas en Red Team [[05 - Herramientas para HTTP Verb Tampering]].

Del método pasamos al contenido de las cabeceras de respuesta: auditar las de **seguridad** y detectar clickjacking → [[01 - Auditoría de cabeceras de seguridad y clickjacking]].
