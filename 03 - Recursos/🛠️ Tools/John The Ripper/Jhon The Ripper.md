---
tags:
  - Seguridad/Contraseñas
  - Introduccion
  - Pentesting/Explotacion
Fecha de actualización: 2025-11-03
Nota previa:
Nota siguiente:
Area: "[[Descifrado de contraseñas]]"
---
---

[Jhon The Ripper](https://github.com/openwall/john) (aka. `JtR` aka. `john`) es una conocida herramienta de pruebas de penetración que se utiliza para descifrar contraseñas mediante diversos ataques, incluidos la fuerza bruta y el diccionario. Es un software de código abierto desarrollado inicialmente para sistemas basados en UNIX y se lanzó por primera vez en 1996. Se ha convertido en un elemento básico de la industria de la seguridad debido a sus diversas capacidades. El `"jumbo"`Se recomienda esta variante para nuestros usos, ya que tiene optimizaciones de rendimiento, características adicionales como listas de palabras multilingües y soporte para arquitecturas de 64 bits. Esta versión es capaz de descifrar contraseñas con mayor precisión y velocidad. Con JtR se incluyen varias herramientas para convertir diferentes tipos de archivos y hashes en formatos que JtR puede utilizar. Además, el software se actualiza periódicamente para mantenerse al día con las tendencias y tecnologías de seguridad actuales.

# Modos de craqueo
## Modo de grieta única
`Single crack mode` es una técnica de descifrado basada en reglas que resulta más útil cuando se apunta a credenciales de Linux. Genera candidatos de contraseña basados en el nombre de usuario de la víctima, el nombre del directorio de inicio y [GECOS](https://en.wikipedia.org/wiki/Gecos_field) valores (nombre completo, número de habitación, número de teléfono, etc.). Estas cadenas se ejecutan contra un gran conjunto de reglas que aplican modificaciones de cadenas comunes que se ven en las contraseñas (por ejemplo, un usuario cuyo nombre real es `Bob Smith` podría usar `Smith1` como su contraseña).

**Nota:** El proceso de autenticación de Linux, así como el descifrado de reglas, se tratarán en profundidad en secciones posteriores. El siguiente ejemplo se simplifica con fines demostrativos.

Imaginemos que nosotros, como atacantes, nos topamos con el archivo `passwd` con los siguientes contenidos:
```
r0lf:$6$ues25dIanlctrWxg$nZHVz2z4kCy1760Ee28M1xtHdGoy0C2cYzZ8l2sVa1kIa8K9gAcdBP.GI6ng/qA4oaMrgElZ1Cb9OeXO4Fvy3/:0:0:Rolf Sebastian:/home/r0lf:/bin/bash
```

Con base en el contenido del expediente, se puede inferir que la víctima tiene el nombre de usuario `r0lf`, el verdadero nombre `Rolf Sebastian`, y el directorio de inicio `/home/r0lf`. El modo de crack único utilizará esta información para generar contraseñas candidatas y probarlas con el hash. Podemos ejecutar el ataque con el siguiente comando:
```shell-session
$ john --single passwd

Using default input encoding: UTF-8
Loaded 1 password hash (sha512crypt, crypt(3) $6$ [SHA512 256/256 AVX2 4x])
Cost 1 (iteration count) is 5000 for all loaded hashes
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
[...SNIP...]        (r0lf)     
1g 0:00:00:00 DONE 1/3 (2025-04-10 07:47) 12.50g/s 5400p/s 5400c/s 5400C/s NAITSABESFL0R..rSebastiannaitsabeSr
Use the "--show" option to display all of the cracked passwords reliably
Session completed.
```

## Modo lista de palabras
`Wordlist mode` se utiliza para descifrar contraseñas con un ataque de diccionario, lo que significa que intenta todas las contraseñas en una lista de palabras proporcionada contra el hash de la contraseña. La sintaxis básica del comando es la siguiente:
```shell-session
$ john --wordlist=<wordlist_file> <hash_file>
```

El archivo (o archivos) de lista de palabras utilizado para descifrar los hashes de contraseñas debe estar en formato de texto simple, con una palabra por línea. Se pueden especificar varias listas de palabras separándolas con una coma. Las reglas, ya sean personalizadas o integradas, se pueden especificar utilizando el `--rules` argumento. Estos se pueden aplicar para generar contraseñas candidatas mediante transformaciones como agregar números, poner letras en mayúscula y agregar caracteres especiales.

## Modo incremental
`Incremental mode` es un potente modo de descifrado de contraseñas de estilo fuerza bruta que genera contraseñas candidatas basadas en un modelo estadístico ([Cadenas de Markov](https://en.wikipedia.org/wiki/Markov_chain)). Está diseñado para probar todas las combinaciones de caracteres definidas por un conjunto de caracteres específico, priorizando las contraseñas más probables según los datos de entrenamiento.

Este modo es el más exhaustivo, pero también el que requiere más tiempo. Genera conjeturas de contraseñas dinámicamente y no depende de una lista de palabras predefinida, a diferencia del modo de lista de palabras. A diferencia de los ataques de fuerza bruta puramente aleatorios, el modo incremental utiliza un modelo estadístico para hacer conjeturas fundamentadas, lo que da como resultado un enfoque significativamente más eficiente que los ataques de fuerza bruta ingenuos.

La sintaxis básica es:
```shell-session
$ john --incremental <hash_file>
```

De forma predeterminada, JtR utiliza modos incrementales predefinidos especificados en su archivo de configuración (`john.conf`), que definen conjuntos de caracteres y longitudes de contraseñas. Puede personalizarlos o definir los suyos propios para contraseñas de destino que utilicen caracteres especiales o patrones específicos.
```shell-session
$ grep '# Incremental modes' -A 100 /etc/john/john.conf

# Incremental modes

# This is for one-off uses (make your own custom.chr).
# A charset can now also be named directly from command-line, so no config
# entry needed: --incremental=whatever.chr
[Incremental:Custom]
File = $JOHN/custom.chr
MinLen = 0

# The theoretical CharCount is 211, we've got 196.
[Incremental:UTF8]
File = $JOHN/utf8.chr
MinLen = 0
CharCount = 196

# This is CP1252, a super-set of ISO-8859-1.
# The theoretical CharCount is 219, we've got 203.
[Incremental:Latin1]
File = $JOHN/latin1.chr
MinLen = 0
CharCount = 203

[Incremental:ASCII]
File = $JOHN/ascii.chr
MinLen = 0
MaxLen = 13
CharCount = 95

...SNIP...
```

**Nota:** Este modo puede consumir muchos recursos y ser lento, especialmente para contraseñas largas o complejas. Personalizar el conjunto y la longitud de los personajes puede mejorar el rendimiento y enfocar el ataque.

---

# Identificación de formatos hash
A veces, los hashes de contraseñas pueden aparecer en un formato desconocido, e incluso John el Destripador (JtR) puede no ser capaz de identificarlos con total certeza. Por ejemplo, considere el siguiente hash:
```
193069ceb0461e1d40d216e32c79c704
```

Una forma de tener una idea es consultar [Documentación hash de muestra de JtR](https://openwall.info/wiki/john/sample-hashes), o [esta lista de PentestMonkey](https://pentestmonkey.net/cheat-sheet/john-the-ripper-hash-formats). Ambas fuentes enumeran varios hashes de ejemplo, así como el formato JtR correspondiente. Otra opción es utilizar una herramienta como [hashID](https://github.com/psypanda/hashID), que compara los hashes suministrados con una lista incorporada para sugerir formatos potenciales. Añadiendo el `-j` flag, hashID, además del formato hash, enumerará el formato JtR correspondiente:
```shell-session
$ hashid -j 193069ceb0461e1d40d216e32c79c704

Analyzing '193069ceb0461e1d40d216e32c79c704'
[+] MD2 [JtR Format: md2]
[+] MD5 [JtR Format: raw-md5]
[+] MD4 [JtR Format: raw-md4]
[+] Double MD5 
[+] LM [JtR Format: lm]
[+] RIPEMD-128 [JtR Format: ripemd-128]
[+] Haval-128 [JtR Format: haval-128-4]
[+] Tiger-128 
[+] Skein-256(128) 
[+] Skein-512(128) 
[+] Lotus Notes/Domino 5 [JtR Format: lotus5]
[+] Skype 
[+] Snefru-128 [JtR Format: snefru-128]
[+] NTLM [JtR Format: nt]
[+] Domain Cached Credentials [JtR Format: mscach]
[+] Domain Cached Credentials 2 [JtR Format: mscach2]
[+] DNSSEC(NSEC3) 
[+] RAdmin v2.x [JtR Format: radmin]
```

Desafortunadamente, en nuestro ejemplo todavía no está muy claro en qué formato se encuentra el hash. Este será a veces el caso y es simplemente uno de los "problemas" que encontrarás como pentester. Muchas veces, el contexto de dónde proviene el hash será suficiente para presentar argumentos fundamentados sobre el formato. En este ejemplo específico, el formato hash es RIPEMD-128.

JtR admite cientos de formatos hash, algunos de los cuales se enumeran en la siguiente tabla. El `--format` Se puede proporcionar un argumento para indicarle a JtR qué formato tienen los hashes de destino.

| **Formato hash**           | **Comando de ejemplo**                            | **Descripción**                                                              |
| -------------------------- | ------------------------------------------------- | ---------------------------------------------------------------------------- |
| *afs*                      | `john --format=afs [...] <hash_file>`             | Hashes de contraseñas de AFS (Andrew File System)                            |
| *bfegg*                    | `john --format=bfegg [...] <hash_file>`           | hashes de bfegg utilizados en bots IRC de Eggdrop                            |
| *bf*                       | `john --format=bf [...] <hash_file>`              | Hashes de cripta (3) basados en Blowfish                                     |
| *bsdi*                     | `john --format=bsdi [...] <hash_file>`            | Hashes BSDi crypt(3)                                                         |
| *cripta(3)*                | `john --format=crypt [...] <hash_file>`           | Hashes tradicionales de cripta (3) de Unix                                   |
| *des*                      | `john --format=des [...] <hash_file>`             | Hashes tradicionales de cripta (3) basados en DES                            |
| *dmd5*                     | `john --format=dmd5 [...] <hash_file>`            | Hashes de contraseñas DMD5 (Dragonfly BSD MD5)                               |
| *dominosec*                | `john --format=dominosec [...] <hash_file>`       | Hashes de contraseñas de IBM Lotus Domino 6/7                                |
| *Hashes SID de EPiServer*  | `john --format=episerver [...] <hash_file>`       | Hashes de contraseñas del SID (identificador de seguridad) de EPiServer      |
| *hdaa*                     | `john --format=hdaa [...] <hash_file>`            | Hashes de contraseñas HDAA utilizados en Openwall GNU/Linux                  |
| *hmac-md5*                 | `john --format=hmac-md5 [...] <hash_file>`        | hashes de contraseñas hmac-md5                                               |
| *hmailserver*              | `john --format=hmailserver [...] <hash_file>`     | hashes de contraseñas de hmailserver                                         |
| *ipb2*                     | `john --format=ipb2 [...] <hash_file>`            | Hashes de contraseñas de Invision Power Board 2                              |
| *krb4*                     | `john --format=krb4 [...] <hash_file>`            | Hashes de contraseñas de Kerberos 4                                          |
| *krb5*                     | `john --format=krb5 [...] <hash_file>`            | Hashes de contraseñas de Kerberos 5                                          |
| *LM*                       | `john --format=LM [...] <hash_file>`              | Hashes de contraseñas de LM (Lan Manager)                                    |
| *loto5*                    | `john --format=lotus5 [...] <hash_file>`          | Hashes de contraseñas de Lotus Notes/Domino 5                                |
| *mscash*                   | `john --format=mscash [...] <hash_file>`          | Hashes de contraseñas de MS Cache                                            |
| *mscash2*                  | `john --format=mscash2 [...] <hash_file>`         | Hashes de contraseñas de MS Cache v2                                         |
| *mschapv2*                 | `john --format=mschapv2 [...] <hash_file>`        | Hashes de contraseñas de MS CHAP v2                                          |
| *mskrb5*                   | `john --format=mskrb5 [...] <hash_file>`          | Hashes de contraseñas de MS Kerberos 5                                       |
| *mssql05*                  | `john --format=mssql05 [...] <hash_file>`         | Hashes de contraseñas de MS SQL 2005                                         |
| *mssql*                    | `john --format=mssql [...] <hash_file>`           | Hashes de contraseñas de MS SQL                                              |
| *mysql-fast*               | `john --format=mysql-fast [...] <hash_file>`      | Hashes de contraseñas rápidas MySQL                                          |
| *mysql*                    | `john --format=mysql [...] <hash_file>`           | Hashes de contraseñas MySQL                                                  |
| *mysql-sha1*               | `john --format=mysql-sha1 [...] <hash_file>`      | Hashes de contraseñas MySQL SHA1                                             |
| *NETLM*                    | `john --format=netlm [...] <hash_file>`           | Hashes de contraseñas de NETLM (NT LAN Manager)                              |
| *NETLMv2*                  | `john --format=netlmv2 [...] <hash_file>`         | Hashes de contraseñas de NETLMv2 (NT LAN Manager versión 2)                  |
| *NETNTLM*                  | `john --format=netntlm [...] <hash_file>`         | Hashes de contraseñas de NETNTLM (NT LAN Manager)                            |
| *NETNTLMv2*                | `john --format=netntlmv2 [...] <hash_file>`       | Hashes de contraseñas de NETNTLMv2 (NT LAN Manager versión 2)                |
| *NEThalfLM*                | `john --format=nethalflm [...] <hash_file>`       | Hashes de contraseñas de NEThalfLM (NT LAN Manager)                          |
| *md5ns*                    | `john --format=md5ns [...] <hash_file>`           | hashes de contraseñas md5ns (espacio de nombres MD5)                         |
| *nsldap*                   | `john --format=nsldap [...] <hash_file>`          | hashes de contraseñas nsldap (OpenLDAP SHA)                                  |
| *ssha*                     | `john --format=ssha [...] <hash_file>`            | hashes de contraseñas ssha (SHA salado)                                      |
| *NT*                       | `john --format=nt [...] <hash_file>`              | Hashes de contraseñas de NT (Windows NT)                                     |
| *openssha*                 | `john --format=openssha [...] <hash_file>`        | Hashes de contraseñas de clave privada OPENSSH                               |
| *oráculo11*                | `john --format=oracle11 [...] <hash_file>`        | Hashes de contraseñas de Oracle 11                                           |
| *oráculo*                  | `john --format=oracle [...] <hash_file>`          | Hashes de contraseñas de Oracle                                              |
| *pdf*                      | `john --format=pdf [...] <hash_file>`             | Hashes de contraseñas en formato PDF (documento portátil)                    |
| *phpass-md5*               | `john --format=phpass-md5 [...] <hash_file>`      | PHPass-MD5 (marco de hash de contraseñas PHP portátil) hashes de contraseñas |
| *phps*                     | `john --format=phps [...] <hash_file>`            | Hashes de contraseñas PHPS                                                   |
| *pix-md5*                  | `john --format=pix-md5 [...] <hash_file>`         | Hashes de contraseñas Cisco PIX MD5                                          |
| *po*                       | `john --format=po [...] <hash_file>`              | Hashes de contraseñas Po (Sybase SQL Anywhere)                               |
| *rar*                      | `john --format=rar [...] <hash_file>`             | Hashes de contraseñas RAR (WinRAR)                                           |
| *md4 crudo*                | `john --format=raw-md4 [...] <hash_file>`         | Hashes de contraseñas MD4 sin formato                                        |
| *md5 crudo*                | `john --format=raw-md5 [...] <hash_file>`         | Hashes de contraseñas MD5 sin formato                                        |
| *unicode md5 sin procesar* | `john --format=raw-md5-unicode [...] <hash_file>` | Hashes de contraseñas Unicode MD5 sin formato                                |
| *sha1 crudo*               | `john --format=raw-sha1 [...] <hash_file>`        | Hashes de contraseñas SHA1 sin procesar                                      |
| *sha224 cruda*             | `john --format=raw-sha224 [...] <hash_file>`      | Hashes de contraseñas SHA224 sin procesar                                    |
| *sha256 crudo*             | `john --format=raw-sha256 [...] <hash_file>`      | Hashes de contraseñas SHA256 sin procesar                                    |
| *sha384 crudo*             | `john --format=raw-sha384 [...] <hash_file>`      | Hashes de contraseñas SHA384 sin procesar                                    |
| *sha512 cruda*             | `john --format=raw-sha512 [...] <hash_file>`      | Hashes de contraseñas SHA512 sin procesar                                    |
| *salted-sha*               | `john --format=salted-sha [...] <hash_file>`      | Hashes de contraseñas SHA saladas                                            |
| *sapb*                     | `john --format=sapb [...] <hash_file>`            | Hashes de contraseñas de SAP CODVN B (BCODE)                                 |
| *sapg*                     | `john --format=sapg [...] <hash_file>`            | Hashes de contraseñas de SAP CODVN G (PASSCODE)                              |
| *sha1-gen*                 | `john --format=sha1-gen [...] <hash_file>`        | Hashes de contraseñas SHA1 genéricos                                         |
| *skey*                     | `john --format=skey [...] <hash_file>`            | Hashes S/Key (contraseña de un solo uso)                                     |
| *ssh*                      | `john --format=ssh [...] <hash_file>`             | Hashes de contraseñas SSH (Secure Shell)                                     |
| *sibaseasa*                | `john --format=sybasease [...] <hash_file>`       | Hashes de contraseñas ASE de Sybase                                          |
| *xsha*                     | `john --format=xsha [...] <hash_file>`            | hashes de contraseñas xsha (SHA extendido)                                   |
| *cremallera*               | `john --format=zip [...] <hash_file>`             | Hashes de contraseñas ZIP (WinZip)                                           |

---

# Descifrando archivos
También es posible descifrar archivos cifrados o protegidos con contraseña con JtR. Múltiple `"2john"` Las herramientas vienen con JtR que se pueden usar para procesar archivos y producir hashes compatibles con JtR. La sintaxis generalizada para estas herramientas es:
```shell-session
$ <tool> <file_to_crack> > file.hash
```

Algunas de las herramientas incluidas con JtR son:

| **Herramienta**         | **Descripción**                                           |
| ----------------------- | --------------------------------------------------------- |
| `pdf2john`              | Convierte documentos PDF para John                        |
| `ssh2john`              | Convierte claves privadas SSH para John                   |
| `mscash2john`           | Convierte hashes de MS Cash para John                     |
| `keychain2john`         | Convierte archivos de llavero de OS X para John           |
| `rar2john`              | Convierte archivos RAR para John                          |
| `pfx2john`              | Convierte archivos PKCS#12 para John                      |
| `truecrypt_volume2john` | Convierte volúmenes de TrueCrypt para John                |
| `keepass2john`          | Convierte bases de datos KeePass para John                |
| `vncpcap2john`          | Convierte archivos VNC PCAP para John                     |
| `putty2john`            | Convierte claves privadas de PuTTY para John              |
| `zip2john`              | Convierte archivos ZIP para John                          |
| `hccap2john`            | Convierte capturas de apretón de manos WPA/WPA2 para John |
| `office2john`           | Convierte documentos de MS Office para John               |
| `wpa2john`              | Convierte los apretones de manos WPA/WPA2 para John       |
| ...RECORTE...           | ...RECORTE...                                             |

Se puede encontrar una colección aún más grande en el `Pwnbox`:
```shell-session
$ locate *2john*

/usr/bin/bitlocker2john
/usr/bin/dmg2john
/usr/bin/gpg2john
/usr/bin/hccap2john
/usr/bin/keepass2john
/usr/bin/putty2john
/usr/bin/racf2john
/usr/bin/rar2john
/usr/bin/uaf2john
/usr/bin/vncpcap2john
/usr/bin/wlanhcx2john
/usr/bin/wpapcap2john
/usr/bin/zip2john
/usr/share/john/1password2john.py
/usr/share/john/7z2john.pl
/usr/share/john/DPAPImk2john.py
/usr/share/john/adxcsouf2john.py
/usr/share/john/aem2john.py
/usr/share/john/aix2john.pl
/usr/share/john/aix2john.py
/usr/share/john/andotp2john.py
/usr/share/john/androidbackup2john.py
...SNIP...
```