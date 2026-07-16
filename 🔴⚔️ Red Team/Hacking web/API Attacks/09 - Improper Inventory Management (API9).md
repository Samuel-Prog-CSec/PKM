---
tags:
  - Web/Red-Team
  - Pentesting/Enumeracion
  - API
Fecha de actualización: 2026-07-15
Nota previa: "[[08 - Security Misconfiguration (API8)]]"
Nota siguiente: "[[10 - Unsafe Consumption of APIs (API10)]]"
Area: "[[API Attacks.base|API Attacks]]"
---
---

A medida que una API evoluciona, un **versionado** descuidado deja versiones viejas, incompatibles o de prueba **accesibles**, ampliando la superficie de ataque. `Improper Inventory Management` es exactamente eso: <mark style="background: #ADCCFFA6;">no saber (ni controlar) qué endpoints y versiones están realmente expuestos</mark>.

# Escenario: la versión `v0` olvidada

Hemos trabajado con `v1`. Pero en el desplegable *"Select a definition"* de Swagger aparece otra versión: `v0`. Su descripción la delata: contiene **datos legacy y borrados**, es un backup sin mantenimiento que **debería haberse eliminado**.

Al inspeccionar sus endpoints, <mark style="background: #FFB86CA6;">ninguno tiene el candado</mark> — no requieren autenticación. Invocamos:

```http
GET /api/v0/customers/deleted
```

Y la API expone los datos de customers **borrados**, incluyendo sus <mark style="background: #FF5582A6;">hashes de contraseña</mark>. La cadena de impacto:

1. Versión vieja sin auth (control de acceso ausente).
2. + [[03 - Broken Object Property Level Authorization (API3)|Excessive Data Exposure]] (devuelve hashes).
3. → crackeamos los hashes offline.
4. → por **reutilización de contraseñas**, comprometemos cuentas activas de quien se reregistró con la misma clave.

<mark style="background: #8000E1A6;">Un endpoint que "ya no existe" (v0) tumba la seguridad del que sí existe (v1)</mark>.

# Metodología: cazar el inventario oculto

Este es un hallazgo de **enumeración**, y en bug bounty real es de los más productivos. Qué buscar:

- <mark style="background: #FFB8EBA6;">**Versiones**</mark>: `/api/v0/`, `/v1/`, `/v2/`, `/v1.1/`, `/beta/`, `/internal/`. Una versión puede carecer del control de acceso, del rate-limit o del parcheo que otra sí tiene.
- **Entornos**: subdominios `dev.`, `staging.`, `test.`, `uat.`, `api-internal.` — enumeración de subdominios ([[05 - Enumeración de subdominios|recon]]) y de hosts virtuales.
- **Shadow APIs**: endpoints no documentados en el Swagger actual pero vivos (los revelan JS del front, colecciones de Postman filtradas, `gau`/`waybackurls` sobre histórico).
- **Definiciones alternativas**: el propio Swagger a veces lista varias "definitions"; `/swagger/v0/swagger.json`, `/openapi.json`, `/api-docs`.

> [!tip]+ El diff entre versiones es oro
> Cuando encuentres `v1` y `v2` del mismo endpoint, **compáralas**: a menudo `v2` arregló un BOLA/BFLA que `v1` aún tiene, o `v1` acepta parámetros que `v2` ya no valida. La versión "deprecada pero viva" es el eslabón débil.

# Prevención

- **Versionado y ciclo de vida** claros: deprecar y **retirar** (sunset) las versiones viejas, no dejarlas colgando.
- Eliminar `v0` por completo o, como mínimo, restringirlo a desarrollo/local e inaccesible desde fuera; si no, protegerlo con autenticación estricta (solo admins).
- **Inventario** actualizado de todos los endpoints, versiones y entornos expuestos (API gateway, catálogo).

Siguiente, el último riesgo: [[10 - Unsafe Consumption of APIs (API10)|Unsafe Consumption of APIs]].

## Referencias

- OWASP — [API9:2023 Improper Inventory Management](https://owasp.org/API-Security/editions/2023/en/0xa9-improper-inventory-management/)
- [gau](https://github.com/lc/gau) · [waybackurls](https://github.com/tomnomnom/waybackurls) (histórico de endpoints)
- HTB Academy — *API Attacks* (base, 2024)
