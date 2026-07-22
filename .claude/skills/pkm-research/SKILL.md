---
name: pkm-research
description: Use when investigating a technique, vulnerability, tool, protocol or claim against primary/official sources for the PKM — gathering docs/RFC/source-code facts, verifying an HTB claim, modernizing content, or when the user asks to research a topic or delegate reading legwork. Materializes eje 1 / eje 4 of the vault (bug bounty & pentest research).
---

# Investigación con fuentes de confianza (eje 1 · eje 4)

Materializa el **eje 1** (investigar/profundizar SIEMPRE) y el **eje 4** (fuentes citadas con atribución por-fuente) del vault. Aplica al enriquecer una nota, verificar una afirmación de HTB, o investigar un tema a demanda (pentest / bug bounty). Adaptación PKM de `/research` de aihero.dev.

## Principio

> Cada afirmación no trivial se sigue hasta la **fuente que la posee** y se cita. Se prefiere la fuente **primaria** sobre la secundaria.

## Jerarquía de confianza (de más a menos)

1. **Primaria / oficial**: RFCs, specs (WHATWG, W3C, OWASP ASVS y *Cheat Sheets* oficiales), documentación del *vendor* (nmap.org, docs de la herramienta), **código fuente** del proyecto, advisories/CVE (NVD, vendor), papers.
2. **Referencia de la comunidad, mantenida y actual**: PortSwigger Web Security Academy, HackTricks, SANS, blogs de investigación reconocidos y recientes.
3. **Secundaria**: posts sueltos, foros (StackOverflow, Reddit) — solo como pista; verificar contra 1 o 2.

Descartar fuentes desactualizadas o sin autoría fiable. Ante conflicto, **gana la primaria** y se señala la discrepancia.

## Cómo investigar

- **Paralelizar en background**: para investigación pesada, despachar un `Agent` (o la skill `deep-research`) que reúna y verifique fuentes **mientras** se redactan otras notas del módulo. No bloquear la escritura.
- **Trazar claim → fuente**: cada dato que entra en la nota tiene una fuente localizable.
- **Verificar, no copiar**: contrastar con la fuente primaria. Si HTB dice algo que la spec contradice, **gana la spec** (y se documenta el matiz).

## Salida

- **Al enriquecer una nota**: integrar el hallazgo en el cuerpo con **atribución por-fuente** (enlace inline, o callout `> [!info]+ Fuente: <url>`; indicar qué parte viene de cuál) — ver `pkm-note-format` § Fuentes.
- **Investigación a demanda (no ligada a una nota)**: dejar una nota citada en el vault (bajo el sub-tema relevante o `02 - Recursos/Biblioteca/`), con las fuentes y su **fecha de consulta**.

## Anti-patrones

- ❌ Citar HackTricks/un blog cuando existe la spec/RFC/doc oficial que lo dice.
- ❌ Afirmar sin fuente localizable ("se sabe que…").
- ❌ Bloquear la redacción esperando a una investigación que puede correr en background.
- ❌ Copiar la conclusión de una fuente secundaria sin contrastarla con la primaria.
- ❌ Presentar fuentes sin fecha / desactualizadas como estado del arte.
