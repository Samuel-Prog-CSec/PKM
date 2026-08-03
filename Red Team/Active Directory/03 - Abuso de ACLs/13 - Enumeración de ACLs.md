---
tags:
  - Active-Directory
  - Windows
  - Pentesting/Enumeracion
Descripción: "Enumerar ACLs es buscar, entre miles de ACE, los pocos que te dan ventaja"
Fecha de actualización: 2026-07-21
Nota previa: "[[12 - Primer de abuso de ACLs]]"
Nota siguiente: "[[14 - Tácticas de abuso de ACLs]]"
Area: "[[AD Abuso de ACLs.base|Abuso de ACLs]]"
---
---

Enumerar ACLs es buscar, entre miles de ACE, los pocos que te dan ventaja. Dos caminos: PowerView (preciso, manual) y BloodHound (visual, encadenado). <mark style="background: #ADCCFFA6;">En la práctica, BloodHound primero para ver la ruta, PowerView después para confirmar y ejecutar.</mark>

# Con PowerView

```powershell
Find-InterestingDomainAcl -ResolveGUIDs
Get-DomainObjectACL -Identity adunn -ResolveGUIDs | ? {$_.ActiveDirectoryRights -match "GenericAll|WriteDacl|ForceChangePassword"}
```

<mark style="background: #FFB8EBA6;">El flag `-ResolveGUIDs` es imprescindible</mark>: sin él, los derechos extendidos (como `ForceChangePassword`) aparecen como un GUID ilegible en vez de su nombre.

El patrón útil parte del *principal* que controlas para ver sobre qué tiene derechos: <mark style="background: #FF5582A6;">así descubres la cadena hacia arriba</mark>.

```powershell
$sid = Convert-NameToSid "damundsen"
Get-DomainObjectACL -ResolveGUIDs | ? {$_.SecurityIdentifier -eq $sid}
```

# Con BloodHound

Marca tu usuario como *Owned* y usa las *queries* pre-hechas —**"Shortest Path from Owned Principals"**— o, sobre cualquier nodo, *Node Info → Outbound Object Control*. <mark style="background: #FFB86CA6;">El grafo te dice, literalmente, "desde aquí llegas a Domain Admin en 3 saltos" y qué ACE abusar en cada uno.</mark>

> [!info]+ Enumerar contra el DC, con cabeza
> La recolección de SharpHound/bloodhound-python ya trae las ACL (`-c DCOnly` basta para el grafo de ACLs, sin tocar hosts). Recuerda el ruido de la recolección ([[04 - Enumeración con credenciales]]) y que MDI observa el LDAP masivo. Con la ruta clara, saltas a [[14 - Tácticas de abuso de ACLs]].
