---
tags:
  - Wi-Fi/Enterprise
  - Pentesting/Reporting
Descripción: "Qué se hace después del Domain Admin para demostrar impacto real, el análisis de contraseñas del dominio y el cierre ordenado del engagement inalámbrico"
Fecha de actualización: 2026-08-04
Nota previa: "[[10 - Del Wi-Fi al dominio - la cadena]]"
Nota siguiente: "[[12 - Detección y evasión en entorno corporativo]]"
Area: "[[Wi-Fi corporativo.base|Wi-Fi corporativo]]"
---
---

Llegar a *Domain Admin* impresiona a un público técnico y no le dice nada al comité de dirección que paga la auditoría. <mark style="background: #ADCCFFA6;">La post-explotación es la fase que traduce el privilegio en impacto de negocio</mark>, y en un hospital eso significa historias clínicas, no hashes.

# Antes de tocar nada

Toda acción de esta fase necesita autorización específica, porque toca datos reales:

| Acción | Requisito |
| ------ | --------- |
| Acceder a recursos con datos sensibles | Autorización previa; capturas **redactadas** |
| Crackear el NTDS fuera del entorno | Autorización en el RoE, ver [[05 - Cracking en la nube y rigs]] |
| Probar exfiltración | Acordado, con datos ficticios |
| Crear cuentas | Sólo si se ha pactado como prueba de detección |

<mark style="background: #FF5582A6;">Nunca se sacan ficheros reales del entorno del cliente ni se toman capturas sin redactar</mark>. La evidencia de que se pudo acceder a un recurso es la ruta y los permisos, no su contenido.

# Demostrar impacto

| Comprobación | Qué demuestra |
| ------------ | ------------- |
| Recursos con datos sensibles accesibles a cualquier admin | Falta de RBAC: cualquier administrador ve nóminas o historiales |
| Acceso a bases de datos de clientes | Los DBA no deberían ser todos los DA |
| Exfiltración de datos ficticios sin alerta | No hay DLP ni control de salida |
| Reutilización de contraseñas en hipervisores y equipos de red | Un compromiso se propaga fuera del dominio |
| Creación de una cuenta privilegiada sin alerta | El SOC no monitoriza lo mínimo |
| Volcado del NTDS sin alerta | Falta detección de la acción más ruidosa que existe |

Las dos últimas son las más valiosas y las que más se olvidan: <mark style="background: #FFB86CA6;">no miden la seguridad preventiva, miden la capacidad de detección</mark>. Un cliente que aprende que su SOC no vio un DCSync obtiene más valor que uno que recibe otra recomendación de parcheo.

Para eso hay que registrar **fecha y hora exactas de cada acción relevante**, de modo que el cliente pueda cruzarlas con sus registros y comprobar qué llegó a su SIEM y qué no. Ese cruce suele ser la parte más apreciada del informe.

# Análisis de contraseñas del dominio

Con el NTDS volcado, el análisis estadístico sustenta el hallazgo de "contraseñas débiles" con datos en vez de opiniones:

```shell-session
$ hashcat -m 1000 starlight_ntds /usr/share/wordlists/rockyou.txt -r best64.rule
$ hashcat -m 1000 starlight_ntds --show --username
```

Lo que se lleva al informe, como anexo:

| Métrica | Por qué importa |
| ------- | --------------- |
| Hashes obtenidos / crackeados / porcentaje | La magnitud del problema |
| Tiempo y hardware empleados | Contextualiza: 30 % en 15 s no es lo mismo que en 3 días |
| Top 10 de contraseñas más repetidas | Suele revelar un patrón corporativo |
| Distribución por longitud | Sostiene la recomendación de longitud mínima |
| Cuentas privilegiadas crackeadas | El dato que mueve decisiones |
| Cuentas que **comparten** hash | Reutilización: vale aunque no se craqueen |

> [!important]+ Contar bien lo crackeado
> hashcat puede reportar tres contraseñas recuperadas de las cuales dos sean el hash vacío `31d6cfe0d16ae931b73c59d7e0c089c0` de cuentas deshabilitadas (`Guest`, `DefaultAccount`). <mark style="background: #FF5582A6;">Incluirlas infla la cifra y desacredita el informe</mark> en cuanto el cliente lo revise. Se filtran las cuentas deshabilitadas y las de servicio antes de calcular porcentajes.

La lista de cuentas que **comparten hash** merece su propio apartado: dos cuentas con el mismo NT hash son la misma contraseña, y un par `jsmith` / `jsmith_adm` idéntico es un hallazgo de primer orden aunque ninguna se craquee — porque el hash sirve igual para [[13 - Pass the Hash (PtH)|Pass the Hash]].

El bucle que multiplica resultados: crackear, analizar los patrones obtenidos, generar máscaras y reglas a partir de ellos, y repetir. Las herramientas están en [[03 - Máscaras y charsets personalizados]].

# Cierre del engagement

El trabajo no termina con el último ataque. El cierre ordenado es lo que distingue una auditoría profesional:

| Tarea | Detalle |
| ----- | ------- |
| Aviso al cliente | Correo de fin de pruebas con resumen de hallazgos críticos |
| Retirada de artefactos | Webshells, binarios subidos, ficheros temporales |
| Retirada de las cajas de ataque | Son equipos propios en sedes del cliente |
| Registro de cambios | Todo lo subido y modificado, **aunque se haya revertido** |
| Cronología con marcas de tiempo | Para el cruce con los registros del cliente |
| Destrucción de material | Handshakes, hashes, credenciales — documentada |

<mark style="background: #8000E1A6;">La destrucción del material inalámbrico no es opcional</mark>: los handshakes capturados son verificadores de la contraseña del cliente y a menudo contienen identidades de personas. Su borrado forma parte del cumplimiento del RGPD y se declara en el informe. El procedimiento general está en [[15 - Cierre del engagement]].

Un principio que evita la mayoría de conversaciones incómodas: **nada de alto impacto sin discutirlo antes**. Si una vía prometedora exige un cambio potencialmente disruptivo, la opción profesional es documentar el ataque y su viabilidad, no ejecutarlo y explicarlo después.

# Los hallazgos del engagement

Ordenados como acabarían en el informe, de mayor a menor impacto:

| # | Hallazgo | Origen |
| - | -------- | ------ |
| 1 | Suplantación de red Enterprise → credenciales de dominio | [[08 - WPA2-Enterprise, evil twin y robo de credenciales]] |
| 2 | Red inalámbrica sin segmentar del LAN corporativo | [[10 - Del Wi-Fi al dominio - la cadena]] |
| 3 | Permisos de escritura para todos en el `web root` | Ídem |
| 4 | Contraseñas en claro en scripts y configuraciones | Ídem |
| 5 | Reutilización de contraseñas entre red y dominio | [[09 - Contraseñas de dispositivos de red Cisco]] |
| 6 | WPS con PIN por defecto | [[03 - WPA2-PSK en un engagement]] |
| 7 | WPA3 en modo transición sin `transition_disable` | [[05 - WPA3 en modo transición y downgrade]] |
| 8 | Gateway con CVE conocido y credenciales débiles | [[09 - Explotación del gateway inalámbrico]] |
| 9 | `PMF` no aplicado en varios AP | [[01 - Reconocimiento de un parque de APs]] |
| 10 | Fuga de identidad EAP en claro | [[08 - Cracking de identidades WPA-Enterprise]] |
| 11 | Cifrado TKIP en uso | [[03 - WPA2-PSK en un engagement]] |
| 12 | Sin aislamiento de clientes en la red de invitados | [[02 - Redes guest y portales cautivos]] |

<mark style="background: #FFB8EBA6;">El orden no es el de gravedad técnica sino el de la cadena</mark>: los dos primeros son los que permiten todo lo demás, y arreglarlos rompe el ataque aunque los otros diez sigan ahí. Esa jerarquía es lo que convierte una lista de hallazgos en una recomendación accionable — el formato concreto está en [[06 - Cómo redactar un hallazgo]].
