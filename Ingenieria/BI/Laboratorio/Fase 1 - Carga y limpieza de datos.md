# Explicación técnica rápida (por qué)

- Power Query intenta **detectar automáticamente** tipos (fecha, número, texto). Eso a veces falla: interpreta valores numéricos como texto si hay espacios invisibles o caracteres extra, o interpreta fechas en un formato distinto al del CSV.
- La **codificación** (UTF-8 vs Windows-1252 vs ISO) afecta a cómo se muestran las tildes y la ñ. Si la codificación no se elige correctamente, verás caracteres extraños (� o secuencias como Ã­).
- Es preferible **controlar manualmente** los tipos y la limpieza: más trabajo al principio, pero evita errores difíciles de depurar después y asegura que los conteos y agregados sean correctos.

---

# Paso a paso guiado (Power BI Desktop)
## 0) Preparación / herramientas opcionales
- Si tienes **Notepad++** u otro editor: puedes abrir el CSV y revisar su codificación (menú _Encoding_). Si ves que está en UTF-8 sin BOM o en ANSI (Windows-1252), apúntalo. Eso te ayuda al reimportar.
- También puedes abrir el CSV en Excel con el asistente “Desde texto/CSV” y probar distinta codificación para ver cuál muestra bien las tildes — es un ensayo rápido.

## 1) Importar el CSV probando la codificación adecuada
1. En Power BI Desktop: **Obtener datos > Texto/CSV** y selecciona `store_data.csv`.
2. En la ventana de previsualización hay 3 controles importantes:
    - **File Origin** (Origen del archivo / codificación). Suele venir por defecto en alguna opción; cámbiala para probar:
        - `65001: Unicode (UTF-8)`
        - `1252: Western European (Windows)`
        - `28591: Western European (ISO-8859-1)`  
            Prueba cada una hasta que los **acentos y la ñ se muestren correctamente** en la vista previa.
    - **Delimiter**: `Comma` (coma) — asegúrate de que sea coma.
    - Botón **Transformar datos**: pulsa para abrir Power Query (no uses “Cargar” todavía).
3. **Si con ninguna opción los acentos se ven bien**: prueba abrir el CSV en Notepad++ y convertir a UTF-8 (Encoding → Convert to UTF-8) y guarda una copia, vuelve a importarla.
    - **Por qué:** elegir el File Origin correcto evita los rombos y caracteres extraños y es la forma más limpia de arreglarlo en origen.

---

## 2) Primeros pasos en Power Query (importante: evitar “cosas raras” automáticas)
1. En Power Query, en el panel **Applied Steps** verás algo como `Source` y después `Changed Type` (o `Tipo cambiado`).
    - **Haz clic derecho** sobre `Changed Type` → **Eliminar** (Remove).
    - **Por qué:** la etapa automática suele introducir conversiones erróneas basadas en las primeras filas. Borrarla te deja con los datos crudos y te permite limpiar y convertir con control.
2. Revisa las cabeceras y filas: comprueba que columnas aparecen cortadas por comas dentro de comillas (si hay comillas en los textos). Si detectas columnas desalineadas, vuelve al paso de importación y comprueba el delimitador y el carácter de texto.

---

## 3) Limpieza general de textos y espacios (todo lo que hay que hacer aquí)
### A) Trim + Clean en columnas de texto
- Selecciona las columnas que son **texto** (Customer Name, City, State, Country, Product Name, Market, Region, etc.).
- En la cinta: **Transformar > Formato > Eliminar espacios (Trim)** y luego **Formatear > Limpiar (Clean)**.
    - **Trim** quita espacios al inicio y final.
    - **Clean** elimina caracteres no imprimibles (salto de línea, etc.).
- **Por qué:** muchas columnas tienen espacios extra y caracteres invisibles que hacen fallar los matches y los joins.

### B) Reemplazar non-breaking space (espacio no separable, U+00A0)
Algunos valores (ej.: `" 933.57 "` en tu CSV) contienen espacios raros que **no** elimina Trim. Procedimiento:
**Opción UI (intentar):**
- Selecciona la columna (ej. `Shipping Cost`), **Transformar > Reemplazar valores**.
- En _Valor a buscar_ pega un espacio normal y prueba a reemplazar por nada. Si no funciona, es NBSP y tu copia pega el carácter allí.

**Opción avanzada (más fiable)** — pegar este paso en Advanced Editor o crear un paso nuevo (reemplaza `"PreviousStep"` por el nombre del paso anterior):
```m
#"Quitar NBSP" = Table.ReplaceValue(
    PreviousStep,
    " ",               // aquí hay un non-breaking space (copia/pega este carácter)
    "",
    Replacer.ReplaceText,
    {"Sales","Profit","Shipping Cost","Discount"}  // lista de columnas a limpiar
)
```

> Nota: el primer argumento de ReplaceValue es el carácter NBSP (parece un espacio pero no lo es). Si no puedes pegarlo, puedes usar la función Character.FromNumber(160) en M (ver el snippet al final).

- **Por qué:** NBSP y otros caracteres invisibles impiden que Power Query convierta texto a número.

### C) Transformar campos numéricos que están como texto
Después de Trim/Clean/Replace:
- Selecciona las columnas numéricas (Sales, Profit, Shipping Cost, Quantity, Discount).
- **Si aparecen como texto**, usa: **Transformar > Tipo de datos > Usar local (Using Locale)** → elige **Decimal Number** (o _Whole Number_ para Quantity) y **Locale = English (United States)** si tu CSV usa `.` como separador decimal (por la muestra que me diste, usan punto).
    - Si tu CSV usara coma decimal (p. ej. `1.234,56`), usa Locale `Spanish (Spain)`.
- **Por qué:** Using Locale fuerza a interpretar correctamente punto/coma decimal y separadores de miles según el país. Esto evita conversiones erróneas.

**Si falla la conversión** (aún te quejan que es texto), puedes forzar con M:
```m
#"Sales a número" = Table.TransformColumns(PreviousStep,
    {{"Sales", each Number.FromText(Text.Replace(_, " ", "")), type number}})
```

(la función Number.FromText respeta el formato de número en la cultura; si necesitas especificar cultura: Number.FromText(text, "en-US").)

---

## 4) Fechas: conversión controlada por formato / locale
En tu CSV las fechas son `7/31/2012` (formato mm/dd/yyyy — formato US). Haz esto:
- Selecciona `Order Date` y `Ship Date` → **Transformar > Tipo de datos > Usar local (Using Locale)** → elige **Date** y **Locale = English (United States)**.
    - Alternativa M (avanzado):
```m
#"Fechas con locale" = Table.TransformColumnTypes(PreviousStep,
    {{"Order Date", type date}, {"Ship Date", type date}}, "en-US")
```

- **Por qué:** si tu Power BI está en configuración regional ES, la interpretación por defecto puede ser dd/mm/yyyy y dará error o fechas invertidas. Using Locale evita eso.

---

## 5) Quitar filas vacías, duplicados y valores erróneos
- Revisa columnas clave (Order ID, Product ID, Customer ID). Si ves filas con Order ID en blanco, analiza si borrarlas.
- Para dimensiones: crea **Reference** de la tabla y en esa referencia elimina columnas no necesarias y **Inicio > Quitar duplicados** para obtener un registro único por cliente/producto/territorio.

**Cómo crear Dimensiones:**
1. En Power Query, clic derecho en la consulta principal → **Referencia** (esto crea una nueva consulta ligada). Renómbrala `DimClientes`.
2. En `DimClientes` deja solo columnas de cliente (Customer ID, Customer Name, Segment, City, State, Country, Postal Code, Market, Region).
3. **Inicio > Quitar columnas > Quitar duplicados** (asegúrate de que Customer ID sea la clave).
4. Repite para `DimProductos` (Product ID, Category, Sub-Category, Product Name) y `DimTerritorios` (Market, Country, Region, City si lo deseas).

- **Verificación:** en la esquina inferior izquierda del editor de Power Query verás el número de filas de cada consulta; compara con los números esperados del enunciado:
    - Dim Clientes: **1.590** (si no coincide, revisa duplicados y si tienes clientes con distintas grafías por tildes o espacios)
    - Dim Productos: **10.292**
    - Dim Territorios: **3.812**
    - Tabla Ventas (hechos): **51.290**

Si tus números no coinciden, causas típicas:
- **Diferencias por tildes/espacios:** dos filas parecidas (ej. “García” vs “Garcia” o diferencias en mayúsculas) cuentan como distintos → limpia Trim + Clean y, si hace falta, unifica mayúsculas/minúsculas (Transformar > Formato > Minúsculas / Mayúsculas).
- **Errores de codificación:** si la ñ/á se interpreta mal, el mismo cliente aparecerá con distinta cadena → vuelve a revisar el File Origin y reimporta si es necesario.

---

## 6) Creaciones recomendadas pre-modelo
- **Columna de localización para mapas:** crea una columna calculada en Power Query (Add Column > Custom Column):
```m
[City] & ", " & [Country]
```

Renómbrala `LocationForMap`. Esto ayuda al visual de Mapas a geolocalizar mejor.
- **Data Category:** una vez cargado el modelo, selecciona `LocationForMap` en Data view → _Column tools_ → _Data category_ → `City` o `Place`. Para `Country` define categoría `Country/Region`. Esto mejora la precisión del mapa.

---

## 7) Comprobar y aplicar cambios
1. Revisa todas las columnas en la vista previa (tipos, muestra de valores).
2. Pulsa **Cerrar y aplicar**. Power BI cargará las tablas.
3. En Power BI Desktop → **Vista de datos** comprueba tipos y filas. Si te sale algún error en la carga (warning) vuelve a Power Query y arréglalo.

---

# Snippets M útiles (copiar/pegar en Advanced Editor)
### Reemplazar NBSP con Character.FromNumber(160)
Si no puedes pegar el carácter NBSP, usa this:
```m
let
    Source = Csv.Document(File.Contents("C:\ruta\store_data.csv"), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    // Reemplazar NBSP por nada en varias columnas
    QuitarNBSP = Table.TransformColumns(Promoted,
        {{"Sales", each Text.Replace(_, Character.FromNumber(160), ""), type text},
         {"Profit", each Text.Replace(_, Character.FromNumber(160), ""), type text},
         {"Shipping Cost", each Text.Replace(_, Character.FromNumber(160), ""), type text}
        }),
    // Trim y Clean antes de convertir
    TrimClean = Table.TransformColumns(QuitarNBSP,
        {{"Sales", each Text.Trim(Text.Clean(_)), type text},
         {"Profit", each Text.Trim(Text.Clean(_)), type text},
         {"Shipping Cost", each Text.Trim(Text.Clean(_)), type text}
        }),
    // Convertir a número usando locale en-US (punto decimal)
    ToNumbers = Table.TransformColumnTypes(TrimClean,
        {{"Sales", type number}, {"Profit", type number}, {"Shipping Cost", type number}}, "en-US"),
    // Fechas con locale en-US (mm/dd/yyyy)
    ToDates = Table.TransformColumnTypes(ToNumbers,
        {{"Order Date", type date}, {"Ship Date", type date}}, "en-US")
in
    ToDates
```

Ajusta la ruta del archivo y las columnas a limpiar.

### Forzar conversión de fechas sólo (ejemplo corto)
```m
#"Changed Type Using Locale" = Table.TransformColumnTypes(PreviousStep,
    {{"Order Date", type date}, {"Ship Date", type date}}, "en-US")
```

---

# Comprobaciones que debes hacer (lista para seguir)
1. **Acentos/ñ:** en Power Query, mira columnas `Customer Name`, `City`, `Product Name`. Si hay caracteres raros, reimporta con otro File Origin o convert CSV a UTF-8.
2. **No hay paso “Changed Type” automático** (lo has eliminado).
3. **Sales/Profit/Shipping Cost** aparecen como _Decimal Number_ en Power Query y en Power BI. Puedes hacer una tarjeta en Informe con `SUM(Sales)` y verificar que el número parece razonable.
4. **Order Date** es tipo `Date` y al ordenar por año/mes el calendario se comporta bien.
5. **DimClientes** → número de filas ≈ **1.590** (si no coincide: revisar duplicados por diferencias en acentos/espacios).
6. **DimProductos** → filas ≈ **10.292**.
7. **DimTerritorios** → filas ≈ **3.812**.
8. **Tabla Ventas** → filas ≈ **51.290**.

Si los conteos difieren ligeramente (p. ej. DimClientes un poco más), repasa si hay **clientes repetidos por typo** o variación de nombre; puedes usar una tabla en Power Query para agrupar por Customer ID y contar.

---

# Trucos y consejos prácticos (errores reales que verás)
- Si tras hacer todo sigue apareciendo “Error” en la conversión a número, selecciona una de las celdas con error, mira _Error_ → _View Errors_ (en la cinta) para ver el texto problemático. Frecuentemente es un carácter extraño (NBSP, comillas, símbolo de moneda).
- Si la columna `Postal Code` (cód. postal) aparece como número y tiene ceros a la izquierda (ej. 01234), conviértela a texto (no la forces a número).
- Para encontrar filas donde Product Name difiere por acento/espacio, puedes crear una columna auxiliar `NormalizedName = Text.Lower(Text.Trim(Text.Clean([Product Name])))` y luego agrupar por `NormalizedName` para detectar duplicados sospechosos.
- **Siempre** haz los cambios en Power Query **antes** de crear las dimensiones y relaciones: si corriges después, tendrás que volver a generar relaciones o limpiar duplicados otra vez.

---

# Resumen final y próximos pasos
- Reimporta el CSV probando **File Origin** (UTF-8, 1252, 28591) hasta que los acentos se vean bien.
- En Power Query **elimina la etapa automática “Changed Type”** y fija tú manualmente los tipos, usando **Using Locale** para fechas (en-US) y números (en-US).
- Haz **Trim + Clean** y reemplaza NBSP si procede (snippet M o Replace Values).
- Crea las **Dimensiones por Referencia** y **quítales duplicados**; verifica los recuentos esperados.
- Crea columna de localización para mapas y fija la categoría de datos en el modelo.

---

Si quieres, ahora mismo puedo:
- Prepararte el script M ligeramente personalizado con los nombres exactos de columnas que me diste (p. ej. aplicar `Table.ReplaceValue` en las columnas que aparecen con espacios), o
- Generar una **lista exacta de comprobaciones** para mirar tras cerrar y aplicar (capturas de pantalla que pedirte que me digas si sale tal o cual error), o
- Orientarte con comandos concretos para arreglar nombres de clientes duplicados por acentos (ej.: normalizar y agrupar).

Dime cuál prefieres que genere ahora y te lo preparo al instante (por ejemplo, el script M ya adaptado a `Sales`, `Profit`, `Shipping Cost`, `Order Date`, `Ship Date` y los pasos de limpieza).