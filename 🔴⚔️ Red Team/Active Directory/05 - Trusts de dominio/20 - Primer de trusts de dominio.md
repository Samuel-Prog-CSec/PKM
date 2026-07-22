---
tags:
  - Active-Directory
  - Windows
  - Pentesting/Enumeracion
Fecha de actualización: 2026-07-21
Nota previa: "[[19 - Configuraciones erróneas varias]]"
Nota siguiente: "[[21 - Ataque a trust hijo a padre]]"
Area: "[[AD Trusts de dominio.base|Trusts de dominio]]"
---
---

<mark style="background: #ADCCFFA6;">Un *trust* (relación de confianza) enlaza dos dominios para que los usuarios de uno accedan a recursos del otro</mark>. Es lo que convierte "controlo un dominio" en "controlo el bosque" — o, con suerte, el bosque de otra empresa. Entender el tipo y la dirección de cada trust es el paso previo a abusarlo.

# Tipos y propiedades

Un trust se define por dos ejes:

- **Dirección**: unidireccional (A confía en B, no al revés) o bidireccional.
- **Transitividad**: transitivo (la confianza se extiende a los dominios en los que el otro confía) o no transitivo.

| Tipo | Contexto | Transitivo | Dirección |
| --- | --- | --- | --- |
| Parent-child | Dentro de un bosque | Sí | Bidireccional |
| Tree-root | Entre árboles de un bosque | Sí | Bidireccional |
| External | Entre dominios de bosques distintos | No | Uni/bi |
| Forest | Entre dos bosques | Sí | Uni/bi |

# Por qué importan

<mark style="background: #FFB86CA6;">El límite de seguridad real en AD es el bosque, no el dominio</mark>. Dentro de un bosque, todos los dominios confían transitivamente entre sí, así que <mark style="background: #8000E1A6;">comprometer un dominio hijo lleva al dominio raíz</mark> (y por tanto a `Enterprise Admins`) — es [[21 - Ataque a trust hijo a padre]]. Entre bosques, un trust mal filtrado puede dejar escalar de una empresa a otra ([[22 - Abuso de trust cross-forest]]).

# Enumeración

```powershell
Get-DomainTrust                 # PowerView
Get-DomainTrustMapping          # mapea toda la red de trusts
Get-ADTrust -Filter *           # módulo AD
```

Desde CMD, `nltest /domain_trusts` y `netdom query trust`. <mark style="background: #FFB8EBA6;">BloodHound los dibuja como aristas entre dominios</mark>, la forma más rápida de ver rutas entre dominios y bosques.

> [!info]+ El bosque manda
> Que el bosque sea el límite de seguridad tiene una consecuencia ofensiva directa: si comprometes cualquier dominio hijo, el dominio raíz está a un ataque de distancia. Por eso, tras dominar un dominio, lo siguiente es siempre mapear los trusts.
