---
tags:
  - Pentesting/Explotacion
  - Web/Red-Team
  - Datos
Fecha de actualización: 2025-10-20
Nota previa: "[[Bypass de autenticación]]"
Nota siguiente: "[[Exfiltración avanzada de datos]]"
Area: "[[Inyección XPath]]"
---
---

Discutiremos **cómo manipular consultas [[Inyección XPath#Fundamentos XPath|XPath]] de modo que accedamos a datos arbitrarios** de documentos *XML*, utilizando técnicas similares a [[💉🧲 Inyección de Unión]].

Para demostrar la exfiltración de datos mediante [[Inyección XPath]] en un escenario base simple, consideremos una aplicación web que nos permite consultar datos sobre las calles de San Francisco. Podemos ingresar una consulta de búsqueda y elegir entre un nombre de calle largo y corto. La aplicación web muestra todas las calles de San Francisco que coinciden con nuestra consulta:
![Formulario de búsqueda del índice de calles de San Francisco con entrada "BAR". Opciones para nombre de calle largo o corto. Botón enviar. La lista de resultados incluye calles como BARCELONA AVE y LOMBARD ST.](https://academy.hackthebox.com/storage/modules/204/dataexfil_1.png)

Al observar la solicitud, podemos ver que la consulta de búsqueda se envía en el parámetro *GET* `q`, mientras que nuestra elección de un nombre de calle largo/corto se transmite en el parámetro *GET* `f`:
![Solicitud y respuesta HTTP. Solicitud: GET a /index.php con los parámetros q=BAR y f=fullstreetname en xpath-exfil.htb. Respuesta: Formulario HTML con botón de envío. La lista de resultados incluye calles como BARCELONA AVE y LOMBARD ST.](https://academy.hackthebox.com/storage/modules/204/dataexfil_2.png)

La aplicación web devuelve todas las calles que contienen nuestra consulta de búsqueda como una subcadena. El parámetro `f` parece controlar qué propiedad de las calles coincidentes se muestra, que es el nombre completo de la calle o una versión abreviada. Esto revela dos nombres de nodos: `fullstreetname` y `streetname`. Para explotar con éxito las vulnerabilidades de inyección XPath, es fundamental intentar comprender/representar la estructura de la consulta XPath y el documento XML adjunto que consulta la aplicación web, de manera similar a lo que se hace cuando se explotan las vulnerabilidades de [[SQL Inyection]].

Del comportamiento de la aplicación web podemos deducir información sobre la consulta XPath que se realiza. Dado que no conocemos los nombres de los nodos de elementos en el documento *XML*, indicaremos la ruta mediante nombres de marcador de posición de un solo carácter `a`, `b`, `c`, y `d`. Lo más probable es que la consulta se vea así:
```xpath
/a/b/c/[contains(d/text(), 'BAR')]/fullstreetname
```

**Nota:** No sabemos si la profundidad del esquema XML es tres como se muestra arriba (`/a/b/c`). Discutiremos cómo determinar la profundidad del esquema en la siguiente sección.

En este caso, la cadena de búsqueda que proporcionamos en el parámetro GET `q` se inserta en el predicado que filtra el nombre de la calle utilizando el `contains` función. Después de eso, el parámetro GET `f` determina la propiedad que muestra la aplicación web de todas las calles coincidentes, por lo que se agrega al final de la consulta.

A partir de la consulta anterior, sabemos que el documento XML debe verse similar a esto (nuevamente, no conocemos los nombres de los nodos, por lo que usamos los mismos nombres de marcador de posición que arriba):
```xml
<a>
	<b>
		<c>
			<d>???</d>
			<streetname>BARCELONA</streetname>
			<fullstreetname>BARCELONA AVE</fullstreetname>
		</c>
	</b>
</a>
```

## Confirmación de la inyección XPath
Podemos confirmar la inyección XPath enviando la carga útil `SOMETHINGINVALID') or ('1'='1` en el `q` parámetro. Esto daría como resultado la siguiente consulta XPath:
```xpath
/a/b/c/[contains(d/text(), 'SOMETHINGINVALID') or ('1'='1')]
```

Si bien nuestra subcadena proporcionada no es válida, la inyectada `or` La cláusula evalúa a `true` de modo que el predicado se vuelve universalmente verdadero. Por lo tanto, coincide con todos los nodos a esa profundidad. Si enviamos esta carga útil, la aplicación web responde con todos los nombres de las calles, confirmando así la vulnerabilidad de inyección XPath:
![Solicitud y respuesta HTTP. Solicitud: LLEGAR a /index.php con el parámetro q=SOMETHINGINVALID')+or+('1'='1 en xpath-exfil.htb. Respuesta: La lista de resultados HTML incluye calles como 01ST ST, 02ND AVE y 03RD ST.](https://academy.hackthebox.com/storage/modules/204/xpath_fixed.png)

## Exfiltración de datos
¿Cómo podemos aprovechar esta inyección XPath para exfiltrar datos aparte de los datos de la calle? La forma más sencilla es construir una consulta que devuelva el documento XML completo para que podamos buscarlo en busca de información interesante. Hay múltiples formas diferentes de lograrlo. Sin embargo, lo más sencillo probablemente sea agregar una nueva consulta que devuelva todos los nodos de texto. Podemos hacer esto con una solicitud como esta:
```http
GET /index.php?q=SOMETHINGINVALID&f=fullstreetname+|+//text() HTTP/1.1
Host: xpath-exfil.htb


```

Luego, la aplicación web ejecutará la siguiente consulta:
```xpath
/a/b/c/[contains(d/text(), 'SOMETHINGINVALID')]/fullstreetname | //text()
```

Estamos agregando una segunda consulta con el `|` operador, similar a un [[💉🧲 Inyección de Unión]] basada en. La segunda consulta, `//text()`, devuelve todos los nodos de texto en el documento XML. Por tanto, la respuesta contiene todos los datos almacenados en el documento *XML*. Dependiendo del tamaño del documento *XML*, la respuesta puede ser bastante grande. Por lo tanto, puede llevar algún tiempo analizar los datos con atención. En nuestro ejemplo, podemos encontrar un conjunto de datos de usuario al final del documento después del conjunto de datos que contiene información sobre las calles de San Francisco:
![Solicitud y respuesta HTTP. Solicitud: LLEGAR a/index.php con los parámetros q=SOMETHINGINVALID y f=fullstreetname+//text() en xpath-exfil.htb. Respuesta: El contenido HTML incluye datos como "kgrenville", "Cuenta de prueba interna", "administrador" y "HTB{TESTFLAG}".](https://academy.hackthebox.com/storage/modules/204/dataexfil_4.png)

De esta forma, aprovechamos con éxito la inyección XPath para exfiltrar todo el documento XML.

También podríamos lograr el mismo resultado utilizando esta carga útil en el `q` parámetro: `SOMETHINGINVALID') or ('1'='1` y configurando el `f` parámetro a `../../..//text()`. Esto daría como resultado la siguiente consulta XPath:
```xpath
/a/b/c/[contains(d/text(), 'SOMETHINGINVALID') or ('1'='1')]/../../..//text()
```

El predicado es universal `true` debido a nuestra inyección `or` cláusula. Además, nuestra carga útil se inyectó en el `f` El parámetro vuelve a la raíz del documento y selecciona todos los nodos de texto, al igual que nuestra carga útil anterior. Por tanto, esta consulta también devuelve el documento XML completo.