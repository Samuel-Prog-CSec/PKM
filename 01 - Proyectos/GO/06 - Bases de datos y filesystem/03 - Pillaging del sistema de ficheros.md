---
tags:
  - Go
  - Go/Datos
  - Post-Explotacion
Fecha de actualización: 2026-07-24
Nota previa: "[[02 - Data mining - buscar datos jugosos]]"
Nota siguiente: 
Area: "[[Bases de datos y filesystem.base|Bases de datos y filesystem]]"
---
---

El último tool del capítulo saquea el disco: recorre un árbol de directorios buscando ficheros jugosos — claves SSH, `.env`, bases de KeePass, credenciales de cloud, ficheros de despliegue con contraseñas. Es looting puro de post-explotación, y Go lo hace casi trivial con `path/filepath`. Modernizamos el recorrido del libro y lo llevamos más allá del match por nombre.

## Recorrer el árbol: `WalkDir` sobre `Walk`

El libro usa `filepath.Walk`. La versión moderna es **`filepath.WalkDir`** (Go 1.16): recibe un `fs.DirEntry` en vez de un `os.FileInfo`, lo que <mark style="background: #FFB8EBA6;">evita un `stat` por cada fichero</mark> — bastante más rápido sobre árboles grandes o shares de red lentos.

```go
var patterns = []*regexp.Regexp{   // compiladas una vez, a nivel de paquete
    regexp.MustCompile(`(?i)id_rsa|\.pem$|\.ppk$`),        // claves privadas
    regexp.MustCompile(`(?i)\.env$|credentials|\.kdbx$`),  // secretos y KeePass
    regexp.MustCompile(`(?i)password|passwd|unattend`),
}

func main() {
    root := os.Args[1]
    filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
        if err != nil {
            return nil          // ignora errores de permisos y sigue (no abortes todo el walk)
        }
        if d.IsDir() {
            return nil          // matchea solo nombres de FICHERO, no de directorio
        }
        for _, re := range patterns {
            if re.MatchString(d.Name()) {
                fmt.Printf("[+] HIT: %s\n", path)
            }
        }
        return nil
    })
}
```

Dos mejoras ya sobre el libro: <mark style="background: #FFB86CA6;">devolver `nil` ante un error de permisos</mark> (si no, un directorio prohibido aborta el recorrido entero) y matchear solo el nombre del fichero (`d.Name()`), no el path completo con sus directorios. Para saltar un subárbol entero, devuelves `filepath.SkipDir`.

## Del nombre al contenido

El libro solo mira **nombres**. Un `id_rsa` se llama así, pero muchos secretos no lo anuncian en el nombre — una clave privada puede estar en `deploy.txt`. El salto de calidad es mirar **dentro** (un grep de secretos):

```go
var secretRe = regexp.MustCompile(`(?i)-----BEGIN [A-Z ]*PRIVATE KEY-----|aws_secret_access_key|api[_-]?key`)

// dentro del walkFn, para ficheros de texto de tamaño razonable:
if info, err := d.Info(); err == nil && info.Size() < 5<<20 {   // < 5 MB, evita binarios enormes (y comprueba err: el fichero pudo borrarse)
    if data, err := os.ReadFile(path); err == nil && secretRe.Match(data) {
        fmt.Printf("[+] SECRETO en %s\n", path)
    }
}
```

<mark style="background: #FF5582A6;">Leer el contenido de cada fichero es caro y ruidoso</mark> (mucho I/O, y toca ficheros que dejan rastro de acceso), así que acótalo: por tamaño, por extensión, o solo tras un primer filtro por nombre.

## Qué buscar en un engagement

La lista de patrones es donde vive el conocimiento ofensivo. Objetivos típicos del looting:

| Objetivo | Pistas |
| - | - |
| Claves SSH | `id_rsa`, `id_ed25519`, `.pem`, `.ppk` |
| Credenciales cloud | `.aws/credentials`, `.azure/`, `gcloud` |
| Configs de app | `.env`, `web.config`, `application.properties`, `settings.py` |
| Gestores de contraseñas | `.kdbx` (KeePass) |
| Despliegue Windows | `unattend.xml`, `sysprep.xml`, `Groups.xml` (GPP) |

La metodología de looting (qué priorizar, cómo exfiltrar sin disparar DLP) es Red Team; aquí tienes el recolector en Go.

## Detalles: permisos, modtime y `os.Root`

- **Prioriza por tiempo**: un `d.Info().ModTime()` reciente suele señalar ficheros en uso activo — más valiosos que uno de hace años.
- **`os.Root` (Go 1.24)**: si la raíz del recorrido viene de entrada no confiable (un share montado, input del usuario), `os.Root` **acota** el acceso a ese subárbol e impide escapes vía symlinks o `..` (path traversal). Matiz importante: `os.Root` acota las **aperturas** de fichero; para confinar el **recorrido** en sí hay que combinarlo con `root.FS()` + `fs.WalkDir` (un `filepath.WalkDir` sobre una ruta pelada no queda confinado). Para tu propio walk controlado es opcional; para tooling que otros usan, buena higiene.

---

Con esto cierras el Cap. 7: sabes conectarte a SQL y MongoDB con drivers modernos, minar esquemas con una interfaz elegante y saquear el disco. El siguiente capítulo baja al nivel más crudo de la red — capturar y fabricar paquetes byte a byte con `gopacket` → [[Raw packets.base|Raw packets]] (Cap. 8).
