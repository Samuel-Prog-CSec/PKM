---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - Recon
Descripción: "La fuerza bruta adivina subdominios uno a uno"
Fecha de actualización: 2026-06-02
Nota previa: "[[03 - Enumeración DNS con dig]]"
Nota siguiente: "[[05 - Enumeración de subdominios]]"
Area: "[[Reconocimiento Web.base|Reconocimiento Web]]"
---
La fuerza bruta adivina subdominios uno a uno. La **transferencia de zona** es la vía perezosa y, cuando funciona, definitiva: <mark style="background: #FFB86CA6;">un servidor DNS mal configurado te entrega la zona entera de golpe</mark> —todos los subdominios, sus IPs y el resto de registros— sin adivinar nada.

# Qué es una transferencia de zona (AXFR)

<mark style="background: #ADCCFFA6;">Una transferencia de zona es una copia íntegra de todos los registros DNS de una zona desde un servidor de nombres a otro</mark>. Es un mecanismo legítimo: los servidores secundarios replican la zona del primario para dar redundancia y consistencia. El intercambio (`AXFR`, *Full Zone Transfer*) sigue este *handshake*:

1. **Petición `AXFR`**: el secundario pide la zona al primario (tipo `AXFR`).
2. **Envío del `SOA`**: el primario responde con su registro `SOA`, cuyo número de serie permite al secundario saber si su copia está al día.
3. **Transmisión de registros**: el primario envía **todos** los registros de la zona uno a uno (`A`, `AAAA`, `MX`, `CNAME`, `NS`…).
4. **Fin de la transferencia**: el primario reenvía el registro `SOA` de cierre (idéntico al inicial), que marca el final.
5. **Cierre**: la fiabilidad la garantiza `TCP` —el "ACK" del diagrama es el de transporte—; **no** existe un mensaje de confirmación a nivel `DNS` (`RFC 5936`).

![Diagrama de secuencia del handshake AXFR entre servidor secundario y primario](https://academy.hackthebox.com/storage/modules/144/ig_dns_zone_transfers_1.png)

> [!info]+ Detalle de transporte: TCP/53
> Las consultas DNS normales usan `UDP/53`, pero las transferencias de zona viajan por `TCP/53` porque el <mark style="background: #FFB86CA6;">volumen de datos supera el tamaño de un datagrama UDP</mark>. Por eso un firewall puede permitir DNS UDP y bloquear `AXFR` simplemente filtrando TCP/53.

# La vulnerabilidad

El problema está en **quién** puede iniciar la transferencia. En los inicios de internet era común permitir el `AXFR` a cualquier cliente —cómodo de administrar, pero un agujero enorme—: <mark style="background: #FF5582A6;">cualquiera podía pedir una copia completa del fichero de zona</mark>. Lo que revela es un mapa exhaustivo de la infraestructura:

- **Subdominios**: la lista completa, incluidos los que no se enlazan en ningún sitio —servidores de desarrollo, *staging*, paneles de administración—.
- **Direcciones IP**: la IP de cada subdominio, objetivos directos para la siguiente fase.
- **Registros `NS`**: los servidores autoritativos, que delatan el proveedor de hosting y posibles *misconfigs*.

# Explotación con `dig axfr`

Se pide con `dig`, indicando el servidor de nombres (`@`) y el dominio:

```shell-session
$ dig axfr @nsztm1.digi.ninja zonetransfer.me

zonetransfer.me.        7200  IN  SOA nsztm1.digi.ninja. robin.digi.ninja. 2019100801 ...
zonetransfer.me.        7200  IN  MX  0 ASPMX.L.GOOGLE.COM.
zonetransfer.me.        7200  IN  A   5.196.105.14
zonetransfer.me.        7200  IN  NS  nsztm1.digi.ninja.
_sip._tcp.zonetransfer.me. 14000 IN SRV 0 0 5060 www.zonetransfer.me.
canberra-office.zonetransfer.me. 7200 IN A 202.14.81.230
asfdbbox.zonetransfer.me. 7200  IN  A   127.0.0.1
[...]
;; XFR size: 50 records (messages 1, bytes 2085)
```

Si el servidor está mal configurado, recibes la zona entera. `zonetransfer.me` (de Robin Wood / digi.ninja) es un servicio creado **a propósito** para practicar: siempre devuelve la zona completa.

> [!success]+ Cómo leer un AXFR exitoso
> La línea `XFR size: 50 records` y la cascada de registros confirman el vuelco. A partir de ahí <mark style="background: #FF5582A6;">tienes el inventario completo de la zona sin haber tocado ni un solo servidor web del objetivo</mark>.

El flujo correcto es de dos pasos: <mark style="background: #FFB8EBA6;">primero obtienes los servidores de nombres y luego intentas el `AXFR` contra cada uno</mark>, porque basta con que **un** secundario esté mal configurado:

```shell-session
$ dig +short ns example.com
$ dig axfr @ns1.example.com example.com
$ dig axfr @ns2.example.com example.com
```

Herramientas como `dnsrecon -d dominio -t axfr`, `dnsenum` y `fierce` <mark style="background: #ADCCFFA6;">automatizan</mark> este "probar `AXFR` en todos los `NS`" por ti.

# Remediación

Hoy la mayoría de servidores restringen el `AXFR` a secundarios de confianza (cláusula `allow-transfer` en BIND) y lo autentican con `TSIG` (claves compartidas). Aun así, <mark style="background: #FFB8EBA6;">las *misconfigs* siguen apareciendo por error humano o sistemas legacy</mark> —sobre todo en DNS internos, entornos corporativos antiguos y máquinas de CTF—. Por eso intentar el `AXFR` (con autorización) sigue mereciendo la pena: <mark style="background: #ADCCFFA6;">aunque falle, la respuesta del servidor revela datos sobre su configuración y postura de seguridad</mark>.

> [!info]+ AXFR vs IXFR
> `IXFR` (*Incremental Zone Transfer*) transfiere solo los cambios desde un número de serie dado, en lugar de la zona completa. En recon te interesa `AXFR` (todo); `IXFR` es una optimización operativa de los administradores.

Cuando el `AXFR` está bien cerrado —el caso normal— vuelves a las técnicas de descubrimiento de subdominios pieza a pieza. La panorámica de esas técnicas está en [[05 - Enumeración de subdominios]].
