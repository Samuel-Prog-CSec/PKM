---
tags:
  - Go
  - Go/Cripto
Descripción: "El cifrado asimétrico resuelve el talón de Aquiles del simétrico —distribuir la clave— usando dos claves matemáticamente relacionadas: una pública y una privada"
Fecha de actualización: 2026-07-25
Nota previa: "[[02 - Cifrado simétrico - descifrar AES]]"
Nota siguiente: "[[04 - Autenticación mutua con TLS]]"
Area: "[[Criptografía.base|Criptografía]]"
---
---

El cifrado asimétrico resuelve el talón de Aquiles del simétrico —distribuir la clave— usando **dos** claves matemáticamente relacionadas: una **pública** y una **privada**. <mark style="background: #ADCCFFA6;">Lo cifrado con la pública solo lo descifra la privada, y lo firmado con la privada lo verifica la pública</mark>. La pública se reparte sin riesgo; solo la privada se guarda. Go implementa RSA en `crypto/rsa`.

## Cifrar, descifrar, firmar y verificar

Generas el par y usas los modos **seguros** de RSA — OAEP para cifrar, PSS para firmar:

```go
priv, err := rsa.GenerateKey(rand.Reader, 2048)   // rand.Reader = crypto/rand
if err != nil {
    log.Fatal(err)
}
pub := &priv.PublicKey

// Cifrado: con la pública -> solo la privada descifra
msg := []byte("una session key, por ejemplo")
ct, _ := rsa.EncryptOAEP(sha256.New(), rand.Reader, pub, msg, nil)
pt, _ := rsa.DecryptOAEP(sha256.New(), rand.Reader, priv, ct, nil)

// Firma: con la privada -> la pública verifica autenticidad + integridad
h := sha256.Sum256(msg)
sig, _ := rsa.SignPSS(rand.Reader, priv, crypto.SHA256, h[:], nil)
err = rsa.VerifyPSS(pub, crypto.SHA256, h[:], sig, nil)   // nil = firma válida
```

Dos operaciones distintas: **cifras con la pública** (confidencialidad — solo el dueño de la privada lee) y **firmas con la privada** (autenticidad — cualquiera con la pública confirma quién firmó y que el mensaje no cambió). <mark style="background: #FFB86CA6;">El intercambio de claves públicas no necesita canal seguro</mark>: aunque un MITM intercepte la pública, sin la privada no descifra nada.

## El modelo híbrido

RSA es **mucho más lento** que AES, así que casi nunca se cifra el grueso de los datos con él. El patrón real (TLS, SSH, PGP): asimétrico para **negociar**, simétrico para el **tráfico**.

> [!important]+ Asimétrico para la clave, simétrico para los datos
> Cliente y servidor usan RSA (u otro asimétrico) para intercambiar de forma segura una **session key** simétrica pequeña; a partir de ahí cifran todo con AES, que es rápido. <mark style="background: #8000E1A6;">Lo mejor de ambos mundos</mark>: la robustez de distribución del asimétrico y la velocidad del simétrico. Por eso el ejemplo cifra "una session key" — es el caso de uso canónico.

## Modernización: OAEP/PSS ya, y mira al post-cuántico

> [!success]+ El libro usa los modos correctos
> A diferencia de otros ejemplos, aquí el libro está **adelantado**: usa **OAEP** (no el viejo `EncryptPKCS1v15`) y **PSS** (no `SignPKCS1v15`). Es lo correcto — <mark style="background: #FF5582A6;">el padding PKCS#1 v1.5 es vulnerable</mark> (ataques Bleichenbacher) y Go 1.26 ya deprecó `EncryptPKCS1v15` para cifrado nuevo. Mantén OAEP y PSS. Y sube el tamaño de clave: 2048 es el mínimo hoy, 3072/4096 para datos de vida larga.

> [!info]+ RSA y la amenaza cuántica
> RSA (y toda la cripto asimétrica clásica) caerá ante un ordenador cuántico suficientemente grande vía el algoritmo de Shor — de ahí la cosecha *"harvest now, decrypt later"*. Go ya se prepara: desde **Go 1.24** la stdlib trae `crypto/mlkem` (ML-KEM, el KEM post-cuántico estandarizado por NIST en FIPS 203), y el TLS de Go negocia por defecto el híbrido `X25519MLKEM768`. Para tooling nuevo con requisitos a largo plazo, es lo que viene.

RSA `rand.Reader` es `crypto/rand` — **nunca** `math/rand` para generar claves (predecible). La aplicación estrella del asimétrico en tooling es autenticar ambos extremos de una conexión: la autenticación mutua con TLS → [[04 - Autenticación mutua con TLS]]. Los fundamentos de PKI y certificados están en [[01 - Infraestructura de Clave Pública (PKI)]].
