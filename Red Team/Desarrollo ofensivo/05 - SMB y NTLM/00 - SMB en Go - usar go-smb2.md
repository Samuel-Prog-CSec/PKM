---
tags:
  - Go
  - Go/SMB
  - SMB
  - Tipo/Introduccion
Descripción: "SMB es el protocolo más útil en post-explotación Windows: comparte archivos e impresoras, pero sobre todo permite comunicación entre procesos por named pipes, que es como PsExec…"
Fecha de actualización: 2026-07-24
Nota previa: 
Nota siguiente: "[[01 - Codificación binaria a medida - reflection y struct tags]]"
Area: "[[SMB y NTLM.base|SMB y NTLM]]"
---
---

SMB es el protocolo más útil en post-explotación Windows: comparte archivos e impresoras, pero sobre todo permite **comunicación entre procesos por named pipes**, que es como PsExec ejecuta comandos en remoto. También es el protocolo más **complejo** del libro. Y aquí está **la modernización más grande de todo el curso**: el libro construye SMB **desde cero** (13 páginas de reflection y encoding a medida) porque, en 2020, "no existía ni un paquete estándar ni de terceros que implementara SMB en Go". <mark style="background: #FF5582A6;">En 2026 eso ya es falso</mark> — hay librería madura. Esta nota reencuadra el capítulo entero.

## SMB en 2026: dialectos y el fin de SMBv1

SMB tiene varios **dialectos** (1.0, 2.0, 2.1, 3.0, 3.0.2, 3.1.1); cliente y servidor negocian el más alto que ambos soporten. La tabla del libro (que llega a 3.02 y apunta a Windows 8.1) está **desfasada**:

- <mark style="background: #FFB86CA6;">**SMBv1 está muerto**: Microsoft lo desactivó por defecto desde Windows 10 1709 (2017) y Windows Server 2019 — **Server 2016 aún lo trae activado**</mark> por su historial de vulns (EternalBlue). Encontrártelo activo hoy es, en sí mismo, un hallazgo.
- **SMB 3.1.1** es el dialecto actual (Windows 10/11, Server 2016+): trae integridad *pre-auth* y cifrado AES. El libro usa 2.1 "porque casi todo lo soporta"; hoy apuntas a 3.x.

## El flujo de autenticación NTLMSSP

Establecer una sesión SMB autenticada es una danza de mensajes (el libro la detalla en 7 pasos; aquí lo esencial):

1. **Negotiate**: el cliente ofrece sus dialectos; el servidor elige uno y anuncia sus mecanismos de auth.
2. **Session Setup (NTLMSSP Negotiate)**: el cliente propone NTLMSSP.
3. El servidor responde con un **challenge** (un reto aleatorio).
4. **Session Setup (NTLMSSP Authenticate)**: el cliente calcula el **hash NTLM** (solo a partir de la **contraseña**: `MD4(UTF-16LE(pass))`) y, combinándolo con usuario, dominio, el challenge del servidor y un challenge propio, genera la **respuesta al reto** (`NTOWFv2`). La envía.
5. El servidor valida la respuesta contra el DC. Si cuadra, devuelve un **session ID**.

<mark style="background: #ADCCFFA6;">La clave: el cliente demuestra que conoce el hash NTLM **sin enviar la contraseña**</mark> — un challenge-response. Esto es exactamente lo que hace posible el *pass-the-hash* (nota [[02 - Password spraying y pass-the-hash sobre SMB]]): si tienes el hash, puedes autenticarte aunque no sepas la contraseña.

## La gran modernización: `go-smb2`

En vez de implementar todo eso, usas una librería. La referencia histórica es **`github.com/hirochachacha/go-smb2`**, pero **está congelada desde 2023**; para código nuevo usa el fork mantenido **`github.com/cloudsoda/go-smb2`** (API casi idéntica —mismo `NTLMInitiator`— y su `Dial` toma `context` directamente). El ejemplo usa la API original; conectar y autenticarse son unas líneas:

```go
import "github.com/hirochachacha/go-smb2"

conn, err := net.Dial("tcp", "10.0.1.5:445")   // SMB va sobre TCP/445
if err != nil {
    return err
}
defer conn.Close()

d := &smb2.Dialer{
    Initiator: &smb2.NTLMInitiator{
        User:     "administrator",
        Password: "P@ssw0rd!",
        Domain:   "CORP",
    },
}
s, err := d.DialContext(ctx, conn)   // *smb2.Session autenticado (context-aware); err != nil = login falló
if err != nil {
    return err
}
defer s.Logoff()

shares, _ := s.ListSharenames()   // enumerar shares, montar, leer/escribir archivos...
```

<mark style="background: #8000E1A6;">La librería negocia dialecto y NTLMSSP por ti</mark>, y el `NTLMInitiator` es también la puerta al pass-the-hash (tiene campo `Hash`). Todas las utilidades del capítulo —spraying, PtH— se montan sobre esto, no sobre una librería hecha a mano.

## Lo del libro que SÍ conserva valor

Entonces, ¿tiro a la basura las 13 páginas de reflection y encoding del libro? **No.** La *técnica* que usa para serializar SMB —codificación binaria posicional, *little-endian*, de longitud fija y variable, con `struct tags` y reflexión— es una lección de Go genuinamente útil para **cualquier protocolo binario a medida** (parseo de paquetes crudos, formatos de fichero, otros protocolos sin librería). Lo que cambia es el encuadre: <mark style="background: #FFB8EBA6;">es una técnica general de encoding, no "cómo hacer SMB"</mark>. La desgranamos en la nota siguiente → [[01 - Codificación binaria a medida - reflection y struct tags]].
