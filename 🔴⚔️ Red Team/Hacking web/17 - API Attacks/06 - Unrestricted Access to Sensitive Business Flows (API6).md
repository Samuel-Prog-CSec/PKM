---
tags:
  - Web/Red-Team
  - Pentesting/Explotacion
  - API
Descripción: "Todo negocio existe para generar ingresos"
Fecha de actualización: 2026-07-15
Nota previa: "[[05 - Broken Function Level Authorization (API5)]]"
Nota siguiente: "[[07 - Server-Side Request Forgery (API7)]]"
Area: "[[API Attacks.base|API Attacks]]"
---
---

Todo negocio existe para generar ingresos. Si una API <mark style="background: #ADCCFFA6;">expone un flujo de negocio sensible sin restringir adecuadamente su acceso o su automatización</mark>, es vulnerable a `Unrestricted Access to Sensitive Business Flows`. No es un bug técnico (no hay un `CWE` de inyección), sino un **abuso de lógica de negocio** — el atacante usa la API "correctamente" pero a una escala o de una forma que perjudica al negocio.

# Escenario: encadenar con el BFLA

En [[05 - Broken Function Level Authorization (API5)|BFLA]] accedimos a `/api/v1/products/discounts` sin permiso. Esa fuga no es solo información: <mark style="background: #FFB86CA6;">revela **cuándo** cada supplier rebajará sus productos y **cuánto**</mark>. Por ejemplo, el producto `a923b706-...` estará al 70% de descuento entre `2023-03-15` y `2023-09-15`.

Si además el endpoint de compra **no** tiene rate-limiting (sufre [[04 - Unrestricted Resource Consumption (API4)|Unrestricted Resource Consumption]]), la explotación es directa:

1. El día que empieza el descuento, <mark style="background: #FF5582A6;">compramos todo el stock al 70% de descuento</mark>.
2. Lo revendemos al precio original (o más) cuando el descuento termina.

<mark style="background: #8000E1A6;">Un flujo legítimo (comprar con descuento) se convierte en un ataque de acaparamiento/reventa</mark> gracias a la información filtrada y a la falta de límites.

# El patrón general (más allá del lab)

Los *sensitive business flows* son el terreno del **abuso de lógica de negocio**, muy rentable y casi invisible a los escáneres porque cada petición es "válida". Ejemplos reales de bug bounty:

- **Scalping / hoarding**: comprar todo el stock de un producto limitado para revender.
- **Abuso de cupones / referidos**: crear cuentas en masa para acumular créditos de bienvenida o bonos de referido.
- **Reservas fantasma**: bloquear inventario (asientos, citas) sin pagar.
- **Amplificación de coste**: disparar operaciones caras (envío de SMS/emails, generación de informes) que cuestan dinero al negocio.

> [!important]+ Cómo detectarlo
> Pregúntate por cada flujo: *"¿qué pasa si automatizo esto 10.000 veces, o lo ejecuto en un orden/momento no previsto?"*. La API asume un usuario humano comportándose "normal"; el atacante lo hace a escala de máquina. Estos hallazgos requieren **entender el modelo de negocio**, no solo el técnico — por eso son difíciles de escanear y valiosos de reportar.

# Prevención

- **Controles de acceso estrictos** en los endpoints que exponen operaciones/datos críticos (como `/api/v1/products/discounts`).
- **Defensas anti-automatización** proporcionales al riesgo: rate-limiting por usuario/IP, CAPTCHA en flujos sensibles, device fingerprinting, detección de patrones no-humanos.
- **Límites de negocio**: máximo de unidades por compra, cuotas por cuenta, ventanas temporales, validación de que el flujo se ejecuta en el orden esperado.

Siguiente: [[07 - Server-Side Request Forgery (API7)|SSRF]], donde encadenamos mass assignment con lectura de ficheros del servidor.

## Referencias

- OWASP — [API6:2023 Unrestricted Access to Sensitive Business Flows](https://owasp.org/API-Security/editions/2023/en/0xa6-unrestricted-access-to-sensitive-business-flows/)
- OWASP — [Automated Threats to Web Applications (OAT)](https://owasp.org/www-project-automated-threats-to-web-applications/)
- HTB Academy — *API Attacks* (base, 2024)
