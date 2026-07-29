---
tags:
  - Go
  - Go/Cripto
  - TLS
Descripción: "En el TLS normal solo el cliente verifica al servidor"
Fecha de actualización: 2026-07-25
Nota previa: "[[03 - Cifrado asimétrico - RSA con OAEP y PSS]]"
Nota siguiente: "[[05 - Brute-forcing RC2 concurrente]]"
Area: "[[Criptografía.base|Criptografía]]"
---
---

En el TLS normal solo el cliente verifica al servidor. En la **autenticación mutua** (mTLS) <mark style="background: #ADCCFFA6;">ambos extremos se autentican con certificados</mark>: cada uno tiene su par de claves, intercambian los certificados (públicos) y validan al otro. Es la aplicación directa del [[03 - Cifrado asimétrico - RSA con OAEP y PSS|asimétrico]], y en ofensiva es la base de un canal C2 que resiste interceptación. Los fundamentos de TLS y PKI están en [[00 - Introducción a HTTPS y TLS]] y [[01 - Infraestructura de Clave Pública (PKI)]]; aquí, el mTLS en Go.

Primero generas los certificados autofirmados con `openssl` (uno para el servidor, uno por cada cliente):

```shell-session
$ openssl req -nodes -x509 -newkey rsa:4096 -keyout serverKey.pem -out serverCrt.pem -days 365
$ openssl req -nodes -x509 -newkey rsa:4096 -keyout clientKey.pem -out clientCrt.pem -days 365
```

## El servidor que exige certificado de cliente

El servidor carga el certificado del cliente en un *pool* y configura el TLS para **requerir y verificar** el cert del cliente:

```go
func main() {
    clientCert, err := os.ReadFile("clientCrt.pem")   // os.ReadFile, no ioutil
    if err != nil {
        log.Fatal(err)
    }
    pool := x509.NewCertPool()
    pool.AppendCertsFromPEM(clientCert)               // repetir por cada cliente autorizado

    server := &http.Server{
        Addr: ":9443",
        TLSConfig: &tls.Config{
            ClientCAs:  pool,
            ClientAuth: tls.RequireAndVerifyClientCert,  // <- la clave del mTLS
            MinVersion: tls.VersionTLS12,                // no negociar TLS viejo
        },
    }
    http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
        // El cert del cliente ya está validado; se puede leer su identidad:
        fmt.Fprintf(w, "hola %s", r.TLS.PeerCertificates[0].Subject.CommonName)
    })
    log.Fatal(server.ListenAndServeTLS("serverCrt.pem", "serverKey.pem"))
}
```

<mark style="background: #FFB86CA6;">`tls.RequireAndVerifyClientCert` es lo que convierte TLS normal en mTLS</mark>: sin un certificado de cliente en el pool, el *handshake* falla. El servidor nunca ve la clave **privada** del cliente — le basta la pública para autenticarlo. La identidad validada aparece en `r.TLS.PeerCertificates`.

## El cliente que presenta su certificado

```go
func main() {
    cert, err := tls.LoadX509KeyPair("clientCrt.pem", "clientKey.pem")  // su par
    if err != nil {
        log.Fatal(err)
    }
    serverCert, _ := os.ReadFile("serverCrt.pem")
    pool := x509.NewCertPool()
    pool.AppendCertsFromPEM(serverCert)

    client := &http.Client{
        Transport: &http.Transport{
            TLSClientConfig: &tls.Config{
                Certificates: []tls.Certificate{cert},   // presenta su cert
                RootCAs:      pool,                       // valida al servidor
                MinVersion:   tls.VersionTLS12,
            },
        },
    }
    resp, err := client.Get("https://server.local:9443/hello")
    if err != nil {
        log.Fatal(err)
    }
    defer resp.Body.Close()
    body, _ := io.ReadAll(resp.Body)                     // io.ReadAll, no ioutil
    fmt.Printf("%s\n", body)
}
```

## Modernizaciones sobre el libro

> [!warning]+ Borra `tlsConf.BuildNameToCertificate()`
> El libro llama a `BuildNameToCertificate()` en cliente y servidor. <mark style="background: #FF5582A6;">Está deprecado desde Go 1.14 y es un *no-op*</mark>: el runtime selecciona el certificado por SNI automáticamente. Llamarlo hoy no hace nada — bórralo. Y sustituye `ioutil.ReadFile`/`ioutil.ReadAll` por `os.ReadFile`/`io.ReadAll` (`ioutil` deprecado desde Go 1.16). Añade `MinVersion: tls.VersionTLS12` explícito para no negociar versiones viejas; el TLS de Go ya usa 1.3 por defecto.

> [!important]+ mTLS como OPSEC de C2
> Esto no es solo teoría defensiva. Un implante que habla con su servidor C2 por **mTLS** obliga a que ambos extremos presenten certificado: <mark style="background: #8000E1A6;">un proxy corporativo que intente inspeccionar el tráfico (TLS *break-and-inspect*) no tiene el certificado de cliente y el *handshake* falla</mark>, y un analista no puede conectar al C2 sin la clave privada del cliente (frustra el *sinkholing* y el análisis). Es una técnica real de *hardening* de C2 — el mismo `tls.Config` que ves aquí. La contrapartida: distribuir y proteger los certs del implante.

Del canal autenticado pasamos a atacar cifrado débil por fuerza bruta, con concurrencia real → [[05 - Brute-forcing RC2 concurrente]].
