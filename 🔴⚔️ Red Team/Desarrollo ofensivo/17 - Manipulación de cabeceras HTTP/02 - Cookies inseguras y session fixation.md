---
tags:
  - Go
  - Go/Web
  - Cookies
Descripción: "Una cookie de sesión mal marcada es un token robable: sin HttpOnly la roba un XSS, sin Secure viaja en claro, sin SameSite habilita CSRF. Y si la app no rota el ID de sesión al…"
Fecha de actualización: 2026-07-26
Nota previa: "[[01 - Auditoría de cabeceras de seguridad y clickjacking]]"
Nota siguiente: "[[03 - Spoofing de User-Agent y sitios alternativos]]"
Area: "[[Manipulación de cabeceras HTTP.base|Manipulación de cabeceras HTTP]]"
---
---

Una cookie de sesión mal marcada es un token robable: sin `HttpOnly` la roba un XSS, sin `Secure` viaja en claro, sin `SameSite` habilita CSRF. Y si la app **no rota** el ID de sesión al hacer login, un atacante puede **fijar** la sesión de la víctima. La teoría vive en Red Team [[10 - Ataques a tokens de sesión]]; aquí el auditor y el test de fixation en Go.

> [!info]+ Fuente
> Recetas "Testing for insecure cookie flags" y "Session fixation through a cookie injection" de *Python Web Penetration Testing Cookbook* (2015).

## Auditar los flags

Go parsea las cookies por ti: `resp.Cookies()` devuelve `[]*http.Cookie` con los flags ya interpretados. No haces regex sobre `Set-Cookie` como el original:

```go
func auditCookies(resp *http.Response) []string {
    var issues []string
    for _, c := range resp.Cookies() {
        if !c.Secure {
            issues = append(issues, c.Name+": sin Secure (viaja en claro sobre HTTP)")
        }
        if !c.HttpOnly {
            issues = append(issues, c.Name+": sin HttpOnly (accesible desde JS → robo por XSS)")
        }
        if c.SameSite == http.SameSiteNoneMode || c.SameSite == http.SameSiteDefaultMode {
            issues = append(issues, c.Name+": SameSite ausente/None (riesgo CSRF)")
        }
    }
    return issues
}
```

<mark style="background: #FFB8EBA6;">Matiz de `SameSite`</mark>: `http.SameSiteDefaultMode` significa que el atributo **no venía** en la cabecera. Los navegadores modernos tratan la ausencia como `Lax`, pero no declararlo explícitamente es una debilidad y un objetivo de auditoría.

## Test de session fixation con un cookie jar

La fixation se detecta comparando el ID de sesión **antes y después** del login. Si no cambia, la app reutiliza la sesión anónima como autenticada → un atacante que fije un ID conocido hereda la sesión. Con un `cookiejar` mantienes el estado entre peticiones:

```go
func testSessionFixation(ctx context.Context, loginURL string, form url.Values, cookieName string) (bool, error) {
    jar, _ := cookiejar.New(nil)
    client := &http.Client{Jar: jar, Timeout: 10 * time.Second}
    u, _ := url.Parse(loginURL)

    // 1) sesión anónima (visita previa que asigna la cookie)
    if _, err := client.Get(loginURL); err != nil {
        return false, err
    }
    pre := cookieValue(jar, u, cookieName)

    // 2) login con el mismo jar
    req, _ := http.NewRequestWithContext(ctx, http.MethodPost, loginURL, strings.NewReader(form.Encode()))
    req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
    resp, err := client.Do(req)
    if err != nil {
        return false, err
    }
    resp.Body.Close()
    post := cookieValue(jar, u, cookieName)

    return pre != "" && pre == post, nil   // mismo ID tras autenticar → vulnerable
}
```

<mark style="background: #FF5582A6;">`pre == post` tras un login exitoso = session fixation</mark>. Una app sana **regenera** el identificador al autenticar.

## Modernizaciones sobre el recetario

- **`resp.Cookies()` y `http.Cookie`** en vez de parsear `Set-Cookie` a mano — los flags ya vienen tipados (`c.Secure`, `c.HttpOnly`, `c.SameSite`).
- **`net/http/cookiejar`** para el test de fixation: mantiene el estado de sesión entre peticiones idiomáticamente.
- <mark style="background: #8000E1A6;">Cookie prefixes</mark>, que el original no conocía: `__Host-` y `__Secure-` fuerzan `Secure` (+ path/host) a nivel de navegador. Una cookie de sesión sin prefijo es una debilidad extra que auditar en 2026.
- **Chequeo de `SameSite` explícito**, distinguiendo ausente (`Default`) de `None`.

> [!warning]+ Rotación ≠ solo el ID
> Que el ID de sesión cambie al login es necesario pero no suficiente: la app debe **invalidar** el anterior en servidor. Un ID nuevo que deja vivo el viejo sigue siendo explotable. Eso ya no se ve desde el cliente — requiere probar si la sesión pre-login sigue autenticada. Metodología en Red Team [[10 - Ataques a tokens de sesión]] y [[13 - Session IDs débiles]].

El último frente de cabeceras: cambiar tu identidad (User-Agent, IP declarada) para ver contenido distinto → [[03 - Spoofing de User-Agent y sitios alternativos]].
