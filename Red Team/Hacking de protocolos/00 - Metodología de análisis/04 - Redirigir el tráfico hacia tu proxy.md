---
tags:
  - Protocolos
  - Redes
  - Proxies
  - Pentesting/Explotacion
Descripción: "Seis vías para que una aplicación que no quiere hablar con tu proxy acabe haciéndolo: config, hosts, DNS, DNAT transparente, LD_PRELOAD y parcheo del binario"
Fecha de actualización: 2026-08-03
Nota previa: "[[03 - Proxies de intercepción para protocolos no-HTTP]]"
Nota siguiente: "[[05 - Del hex dump a la estructura del protocolo]]"
Area: "[[Análisis de protocolos.base|Análisis de protocolos]]"
---
---

Tener el proxy montado es la mitad del trabajo. La otra mitad —y casi siempre la más frustrante— es <mark style="background: #FFB8EBA6;">conseguir que la aplicación objetivo pase por él</mark>. Van ordenadas de menos a más invasiva: prueba siempre en ese orden, porque cada escalón introduce más artefactos en el análisis.

## 1. La configuración de la aplicación

Lo obvio, y sorprendentemente a menudo suficiente. Busca en el fichero de configuración, el registro de Windows, las variables de entorno o los argumentos de línea de comandos. Muchos clientes admiten cambiar el host de destino aunque no expongan opción de proxy: apuntar a `127.0.0.1` y montar ahí un *port-forward* resuelve el caso.

En Java, sin tocar la aplicación:

```shell-session
$ java -DsocksProxyHost=127.0.0.1 -DsocksProxyPort=1080 -jar cliente.jar
$ java -Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=8080 -Dhttps.proxyHost=127.0.0.1 ...
```

Y en .NET, `App.config` con `<system.net><defaultProxy>`.

> [!warning]+ El puerto puede no ser el que crees
> Si solo puedes cambiar la **IP** pero no el puerto, y la aplicación abre varias conexiones (patrón *broker* → servicio, típico de CORBA, DCOM o clústeres), tendrás que levantar un *port-forward* por cada puerto. Descúbrelos primero con captura pasiva o con [[02 - Aislar el tráfico de una aplicación con trazado de syscalls|trazado de syscalls]] — adivinarlos es perder la tarde.

## 2. El fichero `hosts`

Resolución estática, antes de cualquier DNS. `/etc/hosts` en Unix, `C:\Windows\System32\drivers\etc\hosts` en Windows:

```text
127.0.0.1       api.objetivo.com
::1             api.objetivo.com
```

Necesario poner **también la línea IPv6**: si el resolver prefiere AAAA y solo has redirigido A, la aplicación se te escapa por IPv6 y te vuelves loco buscando por qué no ves tráfico.

> [!warning]+ El EDR vigila el fichero `hosts`
> Modificar `hosts` es una técnica de *malware* catalogada (**MITRE ATT&CK [T1565.001](https://attack.mitre.org/techniques/T1565/001/)**, y como mecanismo de evasión de defensas). Muchos AV/EDR lo bloquean o lo alertan. En un *engagement* real esto **puede disparar la detección** — si el objetivo del ejercicio incluye pasar desapercibido, considera una vía que no toque el disco del objetivo (DNAT en el gateway, punto 4).

## 3. DNS bajo tu control

Cuando no puedes tocar el sistema de ficheros —dispositivo embebido, appliance, móvil sin *root*— pero sí la configuración de red. Un DNS que responda tu IP a todo:

```shell-session
# dnsmasq: responde 192.168.1.50 a cualquier consulta A
$ dnsmasq -d --address=/#/192.168.1.50 --no-resolv

# Alternativa Python: dnschef, útil para spoofing selectivo por dominio
$ dnschef --fakeip 192.168.1.50 --fakedomains api.objetivo.com
```

El `dnsspoof` de dsniff que cita el libro sigue funcionando pero es de otra época; `dnsmasq` y `dnschef` son el estándar práctico. Detalle de la técnica ofensiva completa en [[04 - DNS spoofing y redirección de nombres]].

## 4. Redirección transparente en el gateway: DNAT

La más potente y la que no toca el objetivo en absoluto. Requiere que tu máquina esté en el camino ([[00 - Ponerse en el camino - routing, NAT y forwarding]]).

> [!important]+ `iptables` sigue en los dedos, `nftables` en el kernel
> El libro usa `iptables`, y los comandos funcionan — pero desde Debian 10, RHEL 8 y Ubuntu 20.10 el binario que ejecutas es **`iptables-nft`**, una capa de compatibilidad que traduce a `nftables`. Netfilter tiene `iptables` en mantenimiento legado (solo correcciones de seguridad). Aprende la sintaxis nativa, sobre todo para no mezclar reglas de ambos mundos en la misma máquina — mezclarlas produce un orden de evaluación que no es el que esperas.

```shell-session
# nftables (nativo)
$ sudo nft add table ip nat
$ sudo nft 'add chain ip nat prerouting { type nat hook prerouting priority dstnat; }'
$ sudo nft add rule ip nat prerouting ip daddr 10.10.10.5 tcp dport 12345 \
    dnat to 192.168.1.50:4444

# iptables-nft (equivalente, sintaxis heredada)
$ sudo iptables -t nat -A PREROUTING -p tcp -d 10.10.10.5 --dport 12345 \
    -j DNAT --to-destination 192.168.1.50:4444
```

Para redirigir tráfico que **sale de la propia máquina** (analizas un cliente local) la cadena es `OUTPUT`, no `PREROUTING`:

```shell-session
$ sudo iptables -t nat -A OUTPUT -p tcp --dport 12345 -j REDIRECT --to-port 4444
```

Con `mitmproxy` esto se combina con el modo transparente, que recupera el destino original del socket vía `SO_ORIGINAL_DST`:

```shell-session
$ mitmdump --mode transparent --set connection_strategy=lazy
```

<mark style="background: #8000E1A6;">Sin `--mode transparent` el proxy no sabe a dónde iba la conexión</mark> y no puede reenviarla: es el fallo número uno al montar esto.

## 5. Inyectar en el proceso: `LD_PRELOAD` y wrappers

Sin tocar red ni configuración, sustituyendo las funciones de socket:

```shell-session
$ proxychains4 -f proxychains.conf ./cliente     # Linux, LD_PRELOAD
$ tsocks ./cliente                               # alternativa clásica
```

Funciona solo con binarios **enlazados dinámicamente**; un binario Go estático o con `-static` ignora `LD_PRELOAD` por completo. Ahí el escalón siguiente es Frida enganchando `connect` directamente ([[03 - Reversing dinámico - debuggers y hooking]]).

## 6. Parchear el binario

Último recurso: localizar la IP o el nombre de host embebido y reescribirlo. Si la cadena destino tiene la misma longitud o menos, un editor hexadecimal basta. Para lógica más compleja (comprobación de certificado *pinneado*, verificación de integridad), toca el flujo de [[00 - Cuándo hay que abrir el binario]].

## Cuando el objetivo es un móvil

Caso frecuente y con reglas propias — proxy de sistema, certificado de CA en el almacén de usuario vs. sistema, `Network Security Config` en Android 7+, *pinning*, y el rodeo por Frida. Está desarrollado en [[12 - Proxying de apps móviles]].

> [!info]+ Fuentes
> - [nftables wiki — Performing Network Address Translation](https://wiki.nftables.org/wiki-nftables/index.php/Performing_Network_Address_Translation_(NAT)).
> - [mitmproxy — Transparent Proxying](https://docs.mitmproxy.org/stable/howto-transparent/).
> - MITRE ATT&CK [T1565.001](https://attack.mitre.org/techniques/T1565/001/) para el riesgo de detección del fichero `hosts`.
