---
tags:
  - Web/Red-Team
  - Introduccion
  - Pentesting/Vulnerabilidad
Fecha de actualización: 2025-10-27
Nota previa:
Nota siguiente: "[[Explotación de vulnerabilidades de generación de PDF]]"
Area: "[[Web Pentesting.base|Web Pentesting]]"
---
---

# Generación de PDF
El [Formato de documento portátil (PDF)](https://www.pdfa.org/resource/iso-32000-pdf/) es un <mark style="background: #FFB8EBA6;">formato de archivo implementado para proporcionar una presentación de documentos independiente de la plataforma</mark>. Para permitir la generación de *PDF*, las <mark style="background: #FFB86CA6;">aplicaciones web dependen de bibliotecas o complementos de generación de *PDF*</mark>.

Sin embargo, las <mark style="background: #ADCCFFA6;">configuraciones incorrectas, la falta de configuración adecuada y las versiones obsoletas de estas bibliotecas externas abren la puerta a vulnerabilidades</mark>, causadas principalmente por usuarios que introducen información maliciosa que no se desinfecta adecuadamente.

A modo de ejemplo, aquí hay algunas <mark style="background: #FFB8EBA6;">bibliotecas de generación de *PDF* que se utilizan comúnmente</mark> en aplicaciones web:
- [TCPDF](https://tcpdf.org/).
- [html2pdf](https://github.com/spipu/html2pdf).
- [mPDF](https://mpdf.github.io/).
- [DomPDF](https://github.com/dompdf/dompdf).
- [Kit de PDF](https://pdfkit.org/).
- [wkhtmltopdf](https://wkhtmltopdf.org/).
- [PD4ML](https://pd4ml.com/).

Dado que las aplicaciones web deben poder diseñar los archivos *PDF*, estas bibliotecas <mark style="background: #ADCCFFA6;">aceptan código *HTML* como entrada y lo utilizan para generar el archivo *PDF* final</mark>. Esto permite que la aplicación web controle el diseño del archivo *PDF* mediante *CSS* en el código *HTML*. Las bibliotecas <mark style="background: #FFB86CA6;">funcionan analizando el código *HTML*, renderizándolo y creando un *PDF*</mark>.

## Ejemplo: wkhtmltopdf
Como ejemplo de cómo funcionan los generadores de *PDF*, veremos `wkhtmltopdf`, para lo cual se puede descargar un binario precompilado [aquí](https://wkhtmltopdf.org/downloads.html). Hay un aviso de seguridad en negrita en la parte superior de la página que <mark style="background: #FFB8EBA6;">sugiere las vulnerabilidades que estamos a punto de analizar</mark>:
> " *Do not use wkhtmltopdf with any untrusted HTML – be sure to sanitize any user-supplied HTML/JS, otherwise it can lead to complete takeover of the server it is running on!* "

Después de descargar `wkhtmltopdf`, podemos instalarlo usando el siguiente comando en distribuciones de *Linux* basadas en *Debian*:
```shell-session
$ sudo dpkg -i wkhtmltox_0.12.6.1-2.bullseye_amd64.deb
```

Corriendo `wkhtmltopdf` con la opción `-h`, mostrará la información de ayuda de la herramienta:
```shell-session
$ wkhtmltopdf -h

Name:
  wkhtmltopdf 0.12.6.1 (with patched qt)

Synopsis:
  wkhtmltopdf [GLOBAL OPTION]... [OBJECT]... <output file>

<SNIP>
```

Al proporcionar una *URL* a `wkhtmltopdf`, **recuperará automáticamente el sitio web y lo convertirá a *PDF***:
```shell-session
$ wkhtmltopdf https://academy.hackthebox.com/ htb.pdf

Loading pages (1/6)
Counting pages (2/6)                                               
Resolving links (4/6)                                                       
Loading headers and footers (5/6)                                           
Printing pages (6/6)
Done
```
> [!check]+
> Al observar el *PDF* resultante, podemos reconocer el sitio web de *HackTheBox* *Academy*, aunque se ha redimensionado para que quepa en páginas *PDF*.

Además, podemos proporcionar a la herramienta un archivo *HTML* local para simular más de cerca lo que hace una biblioteca de generación de *PDF* en una aplicación web. Como ejemplo, el siguiente archivo *HTML*:
```html
<!DOCTYPE html>
<html>
    <head>
    </head>
    <body>
        <h1>Hello World!</h1>
        <p>This is some text.</p>
    </body>
</html>
```

Ahora podemos correr `wkhtmltopdf` en el archivo *HTML* para producir un equivalente en *PDF*:
```shell-session
$ wkhtmltopdf ./index.html test.pdf

Loading pages (1/6)
Counting pages (2/6)                                               
Resolving links (4/6)                                                       
Loading headers and footers (5/6)                                           
Printing pages (6/6)
Done
```

Para simular un ejemplo del mundo real de cómo una aplicación web podría utilizar la generación de *PDF*, consideremos una <mark style="background: #FFB8EBA6;">tienda en línea que proporciona facturas en *PDF* a los clientes después de completar un pedido</mark>. Esto se puede lograr fácilmente utilizando una biblioteca de generación de *PDF*. Por ejemplo, descarguemos una plantilla *HTML* de factura de código abierto desde [aquí](https://github.com/sparksuite/simple-html-invoice-template). Entonces podemos correr `wkhtmltopdf` para generar una factura *PDF* a partir del código *HTML* con su *CSS* personalizado. El *PDF* generado se ve así:
![Factura con número, fechas de creación y vencimiento, datos del remitente y del destinatario, método de pago como cheque, lista detallada con precios, total $385,00.](https://academy.hackthebox.com/storage/modules/204/pdf_3.png)

---

# Análisis de archivos PDF
<mark style="background: #ADCCFFA6;">Necesitamos determinar qué biblioteca de generación de *PDF* utiliza una aplicación web para abordar vulnerabilidades y configuraciones incorrectas</mark> específicas. Afortunadamente, **la mayoría de estas bibliotecas agregan información en los metadatos del *PDF* generado que nos ayuda a identificar la biblioteca**. Por lo tanto, simplemente necesitamos conseguir un *PDF* generado por la aplicación web para su análisis. <mark style="background: #FFB86CA6;">Para mostrar los metadatos de un archivo *PDF*, podemos utilizar la herramienta `exiftool`</mark>, que se puede instalar así:
```shell-session
$ apt install libimage-exiftool-perl
```

Corriendo `exiftool` con la opción `-h` mostrará la información de ayuda de la herramienta:
```shell-session
$ exiftool -h

Syntax:  exiftool [OPTIONS] FILE

Consult the exiftool documentation for a full list of options
```

Cuando corremos `exiftool` en un archivo *PDF* generado, <mark style="background: #FF5582A6;">los campos `creator` y `producer` de metadatos nos brindan más información sobre la biblioteca de generación de PDF y su versión específica</mark>, en este caso `wkhtmltopdf 0.12.6.1` y `Qt 4.8.7`, respectivamente:
```shell-session
$ exiftool invoice.pdf

ExifTool Version Number         : 12.16
File Name                       : invoice.pdf
Directory                       : .
File Size                       : 18 KiB
File Modification Date/Time     : 2023:03:13 20:42:24+01:00
File Access Date/Time           : 2023:03:13 20:42:24+01:00
File Inode Change Date/Time     : 2023:03:13 20:42:24+01:00
File Permissions                : rw-r--r--
File Type                       : PDF
File Type Extension             : pdf
MIME Type                       : application/pdf
PDF Version                     : 1.4
Linearized                      : No
Title                           : A simple, clean, and responsive HTML invoice template
Creator                         : wkhtmltopdf 0.12.6.1
Producer                        : Qt 4.8.7
Create Date                     : 2023:03:13 20:42:24+01:00
Page Count                      : 1
```

**Esto nos permite buscar vulnerabilidades para una versión específica** de la biblioteca de generación de *PDF*. Alternativamente, también podemos utilizar la herramienta [pdfinfo](https://linux.die.net/man/1/pdfinfo) para lograr la misma tarea:
```shell-session
$ pdfinfo invoice.pdf

Title:          A simple, clean, and responsive HTML invoice template
Creator:        wkhtmltopdf 0.12.6.1
Producer:       Qt 4.8.7
CreationDate:   Mon Mar 13 20:42:24 2023 CET
Tagged:         no
UserProperties: no
Suspects:       no
Form:           none
JavaScript:     no
Pages:          1
Encrypted:      no
Page size:      595 x 842 pts (A4)
Page rot:       0
File size:      18488 bytes
Optimized:      no
PDF version:    1.4
```

Aquí hay otro ejemplo de salida de `exiftool` en un *PDF* generado por una biblioteca diferente (`dompdf`):
```shell-session
$ exiftool file.pdf

ExifTool Version Number         : 12.16
File Name                       : file.pdf
Directory                       : .
File Size                       : 1071 bytes
File Modification Date/Time     : 2023:03:13 20:45:10+01:00
File Access Date/Time           : 2023:03:13 20:45:10+01:00
File Inode Change Date/Time     : 2023:03:13 20:45:14+01:00
File Permissions                : rw-r--r--
File Type                       : PDF
File Type Extension             : pdf
MIME Type                       : application/pdf
PDF Version                     : 1.7
Linearized                      : No
Page Count                      : 1
Producer                        : dompdf 2.0.3 + CPDF
Create Date                     : 2023:03:13 12:45:05-07:00
Modify Date                     : 2023:03:13 12:45:05-07:00
```