# PKM — Segundo cerebro digital

[![Licencia: CC BY-NC-SA 4.0](https://img.shields.io/badge/Licencia-CC%20BY--NC--SA%204.0-blue.svg?logo=creativecommons&logoColor=white)](LICENSE)

Vault de [Obsidian](https://obsidian.md) donde guardo y organizo mi conocimiento técnico de
seguridad ofensiva: hacking web, pentesting, Active Directory, redes, desarrollo ofensivo y
seguridad de sistemas de IA. Son notas de referencia profesional escritas en español, con los
términos técnicos consolidados en inglés.

Está estructurado como un [Zettelkasten](https://es.wikipedia.org/wiki/Zettelkasten): cada nota
es atómica, trata un único concepto y se enlaza con sus vecinas. Los índices son archivos
`.base` (Obsidian Bases), no notas MOC manuales.

## Cómo usarlo

```shell-session
$ git clone https://github.com/Samuel-Prog-CSec/PKM.git
```

Y abre la carpeta como vault desde Obsidian (`Open folder as vault`). La configuración del
vault viaja en `.obsidian/`, así que los plugins y temas que uso se aplican solos.

## Licencia y alcance

Mis notas (todo el contenido original de este repositorio) están bajo
[**CC BY-NC-SA 4.0**](LICENSE): puedes copiarlas, adaptarlas y compartirlas citándome, sin uso
comercial y manteniendo la misma licencia en lo que derives.

Eso **no** cubre el material de terceros que convive en el repositorio, sobre el que no tengo
derechos y que por tanto no puedo licenciar:

- **`02 - Recursos/Biblioteca/PDF/`** — libros con copyright de sus editoriales (No Starch
  Press, Packt, Wiley…). Están aquí para mi uso personal; consulta y compra cada libro en su
  editorial.
- **Contenido derivado de [HTB Academy](https://academy.hackthebox.com)** — buena parte de las
  notas parte de sus módulos, reelaborada, traducida, ampliada y actualizada. El material
  original es de Hack The Box; las imágenes se referencian a sus URLs públicas para preservar
  la atribución.
- **Plugins de Obsidian** bajo `.obsidian/plugins/`, cada uno con la licencia de su autor.

## Contribuciones

No acepto pull requests: es un vault personal y `main` está protegida. Si detectas una errata,
un enlace roto o algo técnicamente incorrecto, abre un
[issue](https://github.com/Samuel-Prog-CSec/PKM/issues) y lo reviso.
