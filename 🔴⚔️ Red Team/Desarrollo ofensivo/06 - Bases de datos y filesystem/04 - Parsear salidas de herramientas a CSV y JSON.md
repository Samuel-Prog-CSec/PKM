---
tags:
  - Go
  - Go/Datos
  - Pentesting/Reporting
Descripción: "Un engagement genera montañas de salida: el XML de Nmap, el de testssl/sslscan, los resultados de tus propios escáneres"
Fecha de actualización: 2026-07-26
Nota previa: "[[03 - Pillaging del sistema de ficheros]]"
Nota siguiente: 
Area: "[[Bases de datos y filesystem.base|Bases de datos y filesystem]]"
---
---

Un engagement genera montañas de salida: el XML de Nmap, el de `testssl`/`sslscan`, los resultados de tus propios [[00 - Motor de fuzzing web|escáneres]]. El paso de "datos crudos" a "informe" es transformación de datos estructurados, y Go lo hace con la stdlib: `encoding/xml` para consumir, `encoding/csv`/`encoding/json` para producir. La documentación y reporting como fase del pentest vive en Red Team [[00 - Introducción a la documentación y el reporting]]; aquí el plumbing en Go.

> [!info]+ Fuente
> Capítulo "Reporting" de *Python Web Penetration Testing Cookbook* (2015) — recetas "Converting Nmap XML to CSV" y "Parsing Sslscan into CSV". Descartamos las de `plot.ly` y Maltego (dependencias dated); el núcleo útil y perenne es el parseo XML → tabla.

## Nmap XML → structs

Mapeas el XML a structs con tags (nota [[12 - JSON, XML y datos estructurados]]). Solo declaras los campos que te interesan — `encoding/xml` ignora el resto:

```go
type NmapRun struct {
    XMLName xml.Name `xml:"nmaprun"`
    Hosts   []Host   `xml:"host"`
}
type Host struct {
    Addresses []Address `xml:"address"`
    Ports     []Port    `xml:"ports>port"`   // ruta anidada ports>port
}
type Address struct {
    Addr string `xml:"addr,attr"`
    Type string `xml:"addrtype,attr"`
}
type Port struct {
    Protocol string `xml:"protocol,attr"`
    PortID   int    `xml:"portid,attr"`
    State    struct {
        State string `xml:"state,attr"`   // <state state="open"/>
    } `xml:"state"`
    Service struct {
        Name string `xml:"name,attr"`     // <service name="http"/>
    } `xml:"service"`
}
```

<mark style="background: #ADCCFFA6;">La sintaxis `ports>port` "baja" por elementos anidados</mark>, y `,attr` lee un atributo del elemento **actual**. <mark style="background: #FF5582A6;">Ojo a un límite de `encoding/xml`</mark>: **no** puedes leer el atributo de un elemento hijo por ruta en un solo tag —`xml:"state>state,attr"` no funciona y dejaría el campo vacío **sin error**—. Por eso `state` y `service` van como **structs anidados**, cada uno con su `,attr`. Con eso, `xml.Unmarshal` puebla toda la estructura de una.

## Volcar a CSV

```go
func nmapToCSV(xmlPath, csvPath string) error {
    data, err := os.ReadFile(xmlPath)
    if err != nil {
        return fmt.Errorf("leyendo %s: %w", xmlPath, err)
    }
    var run NmapRun
    if err := xml.Unmarshal(data, &run); err != nil {
        return fmt.Errorf("parseando XML de nmap: %w", err)
    }

    f, err := os.Create(csvPath)
    if err != nil {
        return err
    }
    defer f.Close()

    w := csv.NewWriter(f)
    defer w.Flush()   // sin Flush, el buffer no se escribe
    w.Write([]string{"host", "proto", "puerto", "estado", "servicio"})
    for _, h := range run.Hosts {
        ip := firstIPv4(h.Addresses)
        for _, p := range h.Ports {
            w.Write([]string{ip, p.Protocol, strconv.Itoa(p.PortID), p.State.State, p.Service.Name})
        }
    }
    return w.Error()   // csv.Writer acumula errores; compruébalos al final
}
```

## Modernizaciones sobre el recetario

- **`encoding/xml` con structs tipados** en vez de parseo manual de strings — robusto ante cambios de formato.
- <mark style="background: #8000E1A6;">`encoding/json` como salida alternativa</mark>: un `json.MarshalIndent(run, "", "  ")` alimenta `jq`, dashboards o un ingestor de informes moderno mejor que el CSV plano.
- **Streaming para ficheros enormes**: un escaneo de /16 genera XML de cientos de MB. En vez de `ReadFile` + `Unmarshal` (todo en RAM), usa `xml.NewDecoder(f)` y `dec.Decode(&host)` por elemento `<host>` en un bucle — memoria constante (nota [[12 - JSON, XML y datos estructurados]]).
- **Descartamos `plot.ly` y Maltego** del original: hoy generas Markdown/JSON y lo ingiere tu plataforma de reporting.

> [!info]+ Arsenal de reporting
> El informe final no se hace a mano: **SysReptor**, **Ghostwriter** o **PlexTrac** ingieren hallazgos estructurados y generan el documento. Tu tool Go es el **adaptador** — convierte la salida cruda de cada herramienta al formato que tu plataforma consume. La metodología y herramientas de reporting están en Red Team (Pentesting) [[08 - Arsenal de herramientas de documentación y reporting]].

---

Con esto cierras el manejo de datos, del origen (SQL, Mongo, disco) al informe (parseo de salidas). El siguiente capítulo baja al nivel más crudo de la red — capturar y fabricar paquetes byte a byte con `gopacket` → [[Raw packets.base|Raw packets]].
