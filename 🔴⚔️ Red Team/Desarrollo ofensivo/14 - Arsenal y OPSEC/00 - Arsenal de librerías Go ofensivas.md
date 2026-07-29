---
tags:
  - Go
  - Go/Arsenal
  - Tipo/Arsenal
Descripción: "Referencia transversal: las librerías con las que se construye tooling ofensivo en Go, mapeadas a la tarea que resuelven y con su estado en 2026"
Fecha de actualización: 2026-07-25
Nota previa: ""
Nota siguiente: "[[01 - Herramientas del ecosistema Go ofensivo]]"
Area: "[[Arsenal y OPSEC.base|Arsenal y OPSEC]]"
---
---

Referencia transversal: las **librerías** con las que se construye tooling ofensivo en Go, mapeadas a la tarea que resuelven y con su estado en 2026. La regla de Go —*"a little copying is better than a little dependency"*— sigue vigente: la stdlib cubre sorprendentemente mucho (HTTP, TLS, cripto, syscalls), y solo sales a terceros cuando de verdad hace falta.

## El mapa: tarea → librería

| Tarea | Librería | Estado 2026 | Nota |
| - | - | - | - |
| TCP/UDP, sockets | `net` (stdlib) | — | [[00 - El paquete net y el modelo de conexión]] |
| Captura de paquetes | `github.com/gopacket/gopacket` | **fork** vivo (el `google/*` está muerto) | [[00 - gopacket - capturar y filtrar tráfico]] |
| Cliente/servidor HTTP | `net/http` (stdlib) | Robusto, HTTP/2 nativo | [[00 - El cliente HTTP de Go]] |
| Scraping HTML | `github.com/PuerkitoBio/goquery` | Mantenido (API jQuery) | [[03 - Scraping HTML - metadatos con goquery]] |
| WebSockets | `github.com/coder/websocket` | Sustituye a `gorilla` y `nhooyr` | [[03 - Keylogging con WebSockets]] |
| DNS a bajo nivel | `github.com/miekg/dns` | Estándar de facto | [[00 - Clientes DNS con miekg-dns]] |
| SMB | `github.com/cloudsoda/go-smb2` | fork mantenido de `hirochachacha` | [[00 - SMB en Go - usar go-smb2]] |
| SQL | `database/sql` (stdlib) + driver | — | [[00 - Bases de datos SQL - database-sql]] |
| MongoDB | `go.mongodb.org/mongo-driver/v2` | v2 (2025) | [[01 - MongoDB con el driver oficial]] |
| Serialización binaria | `encoding/binary` (stdlib) | — | [[01 - Codificación binaria a medida - reflection y struct tags]] |
| Cripto simétrica/asimétrica | `crypto/*` (stdlib) | AES-GCM, RSA-OAEP, ML-KEM (1.24+) | [[00 - Hashing - cracking y almacenamiento seguro]] |
| Hashing de passwords | `golang.org/x/crypto/argon2` | Argon2id > bcrypt | [[00 - Hashing - cracking y almacenamiento seguro]] |
| Syscalls Linux/Windows | `golang.org/x/sys/{unix,windows}` | Sustituye a `syscall` (congelado) | [[00 - Llamar a la Windows API desde Go]] |
| Parseo PE/ELF | `debug/pe`, `debug/elf` (stdlib) | — | [[02 - Parsear ficheros PE con debug-pe]] |
| RPC / C2 | `google.golang.org/grpc` + protobuf | `grpc.NewClient` (no `Dial`) | [[00 - Diseñar la API C2 con gRPC y Protobuf]] |
| MessagePack (Metasploit RPC) | `github.com/vmihailenco/msgpack/v5` | v5 | [[02 - RPC con Metasploit (MessagePack)]] |

## Criterios de elección en 2026

<mark style="background: #ADCCFFA6;">Tres reglas para no arrastrar dependencias muertas o inseguras</mark>:

1. **Prefiere la stdlib.** `net`, `net/http`, `crypto/*`, `encoding/*`, `debug/*` cubren la mayoría del tooling sin una sola dependencia externa. Menos superficie de ataque, cross-compilation limpia, cero *supply-chain risk*.
2. **Verifica que el repo está vivo.** El caso `gopacket` es el aviso: <mark style="background: #FF5582A6;">Google archivó librerías muy usadas</mark>. Antes de importar, comprueba el último commit, los *issues* abiertos y si hay un fork mantenido (el patrón `google/gopacket` → `gopacket/gopacket` se repite). `govulncheck` sobre tu `go.mod` te dice si arrastras CVEs conocidos.
3. **`syscall` está congelado.** Para cualquier interacción a bajo nivel con el SO, `golang.org/x/sys/unix` y `golang.org/x/sys/windows` — nunca el `syscall` de la stdlib, que no recibe nada nuevo desde Go 1.4.

> [!info]+ Verificar una dependencia sin instalarla
> `go get <pkg>@<versión>` la añade, pero antes conviene auditarla: **pkg.go.dev** te da versiones, importadores y CVEs conocidos de cualquier módulo sin tocarlo. Y `govulncheck ./...` sobre tu proyecto reporta solo las vulnerabilidades **alcanzables** desde tu código (no todas las del árbol), que es lo que de verdad importa.

Estas son las piezas para **construir** tools. La otra mitad del arsenal son las herramientas ya hechas —muchas escritas en Go— que usas directamente → [[01 - Herramientas del ecosistema Go ofensivo]].
