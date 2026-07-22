---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - Authentication
  - SAML
Fecha de actualización: 2026-06-23
Nota previa: "[[12 - Ataque de exclusión de firma SAML]]"
Nota siguiente: "[[14 - Vulnerabilidades adicionales y herramientas SAML]]"
Area: "[[Authentication Avanzado.base|Authentication Avanzado]]"
---
---

El ataque SAML más sofisticado, y el que funciona aunque el SP **sí** exija una firma válida. <mark style="background: #ADCCFFA6;">El `XML Signature Wrapping` (XSW) crea una discrepancia entre la lógica que **verifica** la firma y la lógica que **lee** los datos de autenticación.</mark> El verificador valida la assertion firmada y legítima; la aplicación lee una assertion distinta, inyectada y sin firmar, que tú controlas.

# La discrepancia: dos lógicas que miran sitios distintos

El XSW tiene éxito cuando se cumplen dos condiciones a la vez:

- <mark style="background: #FFB8EBA6;">El **verificador** busca el `ds:Signature`, mira a qué ID apunta su `ds:Reference`, verifica esa assertion firmada... y no comprueba nada más</mark> (ni cuántas assertions hay).
- La **aplicación** extrae los datos del usuario de la **primera** assertion que encuentra, sin comprobar que sea la que la firma protege.

Si inyectas una segunda assertion (maliciosa, sin firmar) en una posición donde la aplicación la lea primero, pero sin tocar la firmada original, <mark style="background: #FFB86CA6;">la firma sigue siendo válida (su assertion no cambió) y la app lee tus datos forjados.</mark>

# Dónde puede estar la firma

La complejidad del XSW viene de que la firma XML puede situarse de tres formas respecto al elemento que protege:

| Tipo | La firma es... |
| - | - |
| `enveloped` | Descendiente del elemento firmado (dentro de la Assertion) |
| `enveloping` | Predecesora (envuelve a la Assertion) |
| `detached` | Ni dentro ni fuera (hermana) |

Cada combinación de "qué se firma" (Response vs Assertion) y "dónde está la firma" genera una variante distinta de XSW. La estructura de partida típica: firma `enveloped` que protege solo la Assertion.

# Ejecución

Partimos de una Response cuya **Assertion** está firmada (`ds:Reference URI="#<ID_assertion>"`):

```xml
<samlp:Response ID="_941d...">
  <saml:Assertion ID="_3227..._a51a53c013">   <!-- firmada -->
    ... <ds:Signature> ... <ds:Reference URI="#_3227..._a51a53c013"/> ... </ds:Signature>
  </saml:Assertion>
</samlp:Response>
```

Los pasos:

1. Copia la `saml:Assertion` legítima y **quítale la firma**.
2. Manipula la copia: cambia el `ID` (p. ej. `_evilID`) y los atributos (`name` → `admin`, `id` → `1`).
3. **Inyecta** la assertion maliciosa **antes** de la original firmada, dejando esta intacta:

```xml
<samlp:Response ID="_941d...">
  <samlp:Status><samlp:StatusCode Value="...:Success"/></samlp:Status>
  <saml:Assertion ID="_evilID">      <!-- 1ª: inyectada, name=admin, SIN firma -->
    ...
  </saml:Assertion>
  <saml:Assertion ID="_3227..._a51a53c013">   <!-- 2ª: original, firmada, intacta -->
    ... <ds:Signature> ... </ds:Signature>
  </saml:Assertion>
</samlp:Response>
```

4. Re-codifica (Base64 → URL-encode) y envía el `SAMLResponse`.

<mark style="background: #8000E1A6;">El verificador encuentra la `ds:Signature`, valida la assertion `_3227...` (intacta → firma OK); la aplicación coge la **primera** assertion (`_evilID`) y te autentica como `admin`.</mark> La Response no está firmada en su conjunto, por eso puedes inyectar libremente dentro de ella.

> [!info]+ Caso real (2025): CVE-2025-23369 en GitHub Enterprise Server
> El XSW no es teoría de pizarra. GitHub Enterprise validaba las assertions con `libxml2`; <mark style="background: #FFB86CA6;">redefiniendo el `ID` del elemento `Response` mediante una entidad XML</mark>, se forzaba a verificar la firma contra el `Assertion` en lugar del `Response` → bypass de firma y login como cualquier usuario interno, incluido admin (CVSS 7.6, parcheado en GHES 3.12.14+). Es el puente entre el XSW de laboratorio y un ATO real reciente. [HackerOne #2579939](https://hackerone.com/reports/2579939).

> [!important]+ Probar muchas posiciones: el XSW es de fuerza bruta estructural
> No hay una única forma de XSW: el éxito depende de la idiosincrasia del parser y la lógica del SP. En la práctica se prueban **muchas** permutaciones (assertion inyectada antes/después/dentro, envolviendo la firma, anidada en el `Subject`...). Por eso se automatiza con **SAML Raider**, que aplica las variantes XSW conocidas con un clic. Detalle en [[14 - Vulnerabilidades adicionales y herramientas SAML]]. La teoría completa, en el [paper original de Somorovsky et al.](https://www.usenix.org/system/files/conference/usenixsecurity12/sec12-final91.pdf)

> [!info]+ Fuentes
> - [PortSwigger — XML signature wrapping](https://portswigger.net/web-security/saml)
> - ["On Breaking SAML: Be Whoever You Want to Be" (USENIX 2012)](https://www.usenix.org/system/files/conference/usenixsecurity12/sec12-final91.pdf)
