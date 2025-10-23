**Columnas Identificadas (basado en tu PDF y asumiendo que son las primeras N columnas del CSV original):**
1. order_id
2. order_date
3. ship_date
4. ship_mode
5. customer_na (Probablemente Customer Name)
6. segment
7. state
8. country
9. market
10. region
11. product_id
12. category
13. sub_category
14. product_nam (Probablemente Product Name)
15. sales
16. quantity
17. discount
18. profit
19. shipping_cos (Probablemente Shipping Cost)
20. order_priorit (Probablemente Order Priority)
21. year (Parece que es el año del pedido, probablemente derivado de order_date. Es redundante si tenemos order_date, pero lo podemos manejar).

# Paso 1.1: Importar y Transformar en Power Query
1. **Abrir Power BI Desktop.**
2. En la pestaña Inicio, haz clic en Obtener datos.
3. Selecciona Texto/CSV.
4. Busca y selecciona tu archivo StoreOrders.csv.
5. **Ventana de Previsualización:**
    - Aquí es donde aparece el CONSEJO del enunciado. Busca "Detección del tipo de datos" (suele estar abajo, donde dice "Origen de archivo", "Delimitador").
    - Cámbialo a **"No detectar tipos de datos"**.
    - Haz clic en **Transformar datos**. Esto abrirá el Editor de Power Query.

## Dentro del Editor de Power Query:
Ahora tenemos una consulta, probablemente llamada StoreOrders o el nombre de tu archivo.
1. **Renombrar Columnas (Paso crucial para claridad):**
    - El archivo CSV, según tu imagen, tiene nombres de columna genéricos "Column1", "Column2", etc., en las primeras filas si los encabezados no se detectaron bien o nombres con abreviaturas. Vamos a asumir que Power Query sí pudo detectar los encabezados correctamente a partir de la primera fila del CSV (como order_id, order_date, etc.). Si no fue así, usa la opción Usar la primera fila como encabezado en la pestaña Inicio o Transformar.
    - Luego, renombra las columnas para que sean más descriptivas y consistentes
        - order_id -> OrderID
        - order_date -> OrderDate
        - ship_date -> ShipDate
        - ship_mode -> ShipMode
        - customer_na -> CustomerName
        - segment -> Segment
        - state -> State
        - country -> Country
        - market -> Market
        - region -> Region
        - product_id -> ProductID
        - category -> Category
        - sub_category -> SubCategory
        - product_nam -> ProductName
        - sales -> Sales
        - quantity -> Quantity
        - discount -> Discount
        - profit -> Profit
        - shipping_cos -> ShippingCost
        - order_priorit -> OrderPriority
        - year -> OrderYear (Para distinguirlo del año que podríamos extraer después para jerarquías de fecha)
Para renombrar una columna, haz doble clic en su encabezado o clic derecho -> Cambiar nombre.

2. **Cambiar Tipos de Datos (MANUALMENTE):**
    
    - Selecciona cada columna y, en la pestaña Transformar (grupo Cualquier columna) o en la pestaña Inicio (grupo Transformar), elige el tipo de dato correcto desde el desplegable Tipo de dato:
        
        - OrderID: Texto
            
        - OrderDate: Fecha
            
        - ShipDate: Fecha
            
        - ShipMode: Texto
            
        - CustomerName: Texto
            
        - Segment: Texto
            
        - State: Texto
            
        - Country: Texto
            
        - Market: Texto
            
        - Region: Texto
            
        - ProductID: Texto
            
        - Category: Texto
            
        - SubCategory: Texto
            
        - ProductName: Texto
            
        - Sales: Número decimal (Si Power BI tiene problemas con el punto/coma, después de cambiar el tipo, si ves errores, haz clic derecho en el paso "Tipo cambiado", elige "Editar configuración" y en la ventana "Cambiar tipo con configuración regional", indica el formato correcto, p.ej., "Inglés (Estados Unidos)" para puntos decimales, o "Español (España)" para comas).
            
        - Quantity: Número entero
            
        - Discount: Número decimal (o Porcentaje si prefieres, aunque Número decimal es más flexible para cálculos iniciales. Revisa si el valor es 0.5 para 50% o 50 para 50%). Por las capturas, parece ser un valor tipo 0.1, 0.45 etc, así que Número Decimal está bien.
            
        - Profit: Número decimal
            
        - ShippingCost: Número decimal
            
        - OrderPriority: Texto
            
        - OrderYear: Número entero (aunque lo quitaremos si es redundante).
            
    - Eliminar la columna OrderYear si consideras que no añade valor, ya que el año se puede extraer de OrderDate. Clic derecho sobre la columna -> Quitar.

3. **Creación de Tablas de Dimensiones:**
    
    - Haz clic derecho en la consulta StoreOrders en el panel de Consultas (izquierda) y selecciona Duplicar. Harás esto varias veces.
        
    - **DimCliente:**
        
        1. Duplica StoreOrders. Renombra la nueva consulta a DimCliente.
            
        2. Selecciona DimCliente. En la pestaña Inicio, haz clic en Elegir columnas.
            
        3. Selecciona solo CustomerName y Segment. Haz clic en Aceptar.
            
        4. Con ambas columnas seleccionadas (Ctrl+clic), haz clic derecho en uno de los encabezados y elige Quitar duplicados.
            
        5. Añade una clave primaria: Ve a la pestaña Agregar columna -> Columna de índice (puedes empezar desde 1).
            
        6. Renombra esta nueva columna de índice a CustomerID.
            
        7. Arrastra CustomerID para que sea la primera columna (opcional, por orden).
            
    - **DimProducto:**
        
        1. Duplica StoreOrders original de nuevo. Renombra la nueva consulta a DimProducto.
            
        2. Selecciona DimProducto. Haz clic en Elegir columnas.
            
        3. Selecciona ProductID, ProductName, SubCategory, Category. Haz clic en Aceptar.
            
        4. Selecciona la columna ProductID, haz clic derecho en su encabezado y elige Quitar duplicados (esto asume que un ProductID siempre tiene el mismo nombre, categoría y subcategoría).
            
        5. No es necesario un índice si ProductID es único y ya sirve como clave.
            
    - **DimGeografia:**
        
        1. Duplica StoreOrders original. Renombra a DimGeografia.
            
        2. Elegir columnas: Market, Region, Country, State.
            
        3. Selecciona las cuatro columnas, clic derecho -> Quitar duplicados.
            
        4. Agregar columna -> Columna de índice (desde 1). Renómbrala a GeographyID.
            
        5. Arrastra GeographyID para que sea la primera columna.
            
    - **DimModoEnvio:**
        
        1. Duplica StoreOrders original. Renombra a DimModoEnvio.
            
        2. Elegir columnas: ShipMode.
            
        3. Selecciona la columna ShipMode, clic derecho -> Quitar duplicados.
            
        4. Agregar columna -> Columna de índice (desde 1). Renómbrala a ShipModeID.
            
        5. Arrastra ShipModeID para que sea la primera columna.
            
    - **DimPrioridadPedido:**
        
        1. Duplica StoreOrders original. Renombra a DimPrioridadPedido.
            
        2. Elegir columnas: OrderPriority.
            
        3. Selecciona la columna OrderPriority, clic derecho -> Quitar duplicados.
            
        4. Agregar columna -> Columna de índice (desde 1). Renómbrala a OrderPriorityID.
            
        5. Arrastra OrderPriorityID para que sea la primera columna.

4. **Creación de Tabla de Hechos (FactVentas):**
    
    - Ahora modifica la consulta original StoreOrders. Renómbrala a FactVentas.
        
    - El objetivo es reemplazar las columnas de texto descriptivas con las IDs de las dimensiones que acabamos de crear.
        
    - **Fusionar Consultas:**
        
        - Con FactVentas seleccionada, ve a Inicio -> Combinar -> Fusionar consultas (elige "Fusionar consultas" no "Fusionar consultas como nuevas").
            
        - **Fusionar con DimCliente:**
            
            - Tabla superior: FactVentas. Selecciona las columnas CustomerName y Segment (mantén Ctrl para seleccionar ambas).
                
            - Tabla inferior: DimCliente. Selecciona las columnas CustomerName y Segment.
                
            - Tipo de combinación: Externa izquierda. Haz clic en Aceptar.
                
            - Verás una nueva columna DimCliente de tipo Table. Haz clic en el icono de expansión (dos flechas opuestas) en el encabezado de esta columna. Desmarca todas las casillas excepto CustomerID. Desmarca también "Usar nombre de columna original como prefijo". Haz clic en Aceptar.
                
        - **Repite la fusión para las otras dimensiones:**
            
            - **Fusionar con DimGeografia:** En FactVentas selecciona Market, Region, Country, State. En DimGeografia selecciona las mismas. Expande solo GeographyID.
                
            - **Fusionar con DimModoEnvio:** En FactVentas selecciona ShipMode. En DimModoEnvio selecciona ShipMode. Expande solo ShipModeID.
                
            - **Fusionar con DimPrioridadPedido:** En FactVentas selecciona OrderPriority. En DimPrioridadPedido selecciona OrderPriority. Expande solo OrderPriorityID.
                
    - **Limpiar FactVentas:**
        
        1. Ahora que tienes las IDs, puedes quitar las columnas de texto originales. Selecciona FactVentas.
            
        2. Ve a Inicio -> Elegir columnas.
            
        3. Selecciona SOLO las siguientes columnas:
            
            - OrderID
                
            - OrderDate
                
            - ShipDate
                
            - ProductID (ya es una clave, la de DimProducto)
                
            - CustomerID (la que obtuviste de la fusión con DimCliente)
                
            - GeographyID (de la fusión con DimGeografia)
                
            - ShipModeID (de la fusión con DimModoEnvio)
                
            - OrderPriorityID (de la fusión con DimPrioridadPedido)
                
            - Sales
                
            - Quantity
                
            - Discount
                
            - Profit
                
            - ShippingCost
                
        4. Asegúrate de que no quede ninguna columna descriptiva de texto que ya esté en las dimensiones (como CustomerName, Category, State, ShipMode, OrderPriority, etc.).
            
        5. Si la columna OrderYear sigue ahí, quítala también.

5. **Deshabilitar Carga para la Consulta Original (si la duplicaste y renombraste):**
    
    - Si en el paso 3, duplicaste StoreOrders y la consulta original sigue ahí con ese nombre, o si ahora tienes una consulta intermedia que ya no necesitas cargar al modelo:
        
    - Haz clic derecho sobre esa consulta intermedia (por ejemplo, si StoreOrders fue la base y FactVentas es una copia que transformaste) en el panel de Consultas.
        
    - Desmarca Habilitar carga. Su icono se volverá cursiva. Esto significa que se usa para transformaciones pero no se carga como una tabla separada en el modelo de Power BI, ahorrando memoria y evitando confusión. Lo ideal es que FactVentas sea la transformación directa de la StoreOrders original, sin una copia extra. Así que esta paso puede no ser necesario si renombraste la original directamente.

6. **Revisión Final:**
    
    - Comprueba rápidamente los tipos de datos en FactVentas de nuevo, especialmente para las IDs (deberían ser números enteros) y las métricas (números decimales).
        
    - CustomerID, GeographyID, ShipModeID, OrderPriorityID deberían ser tipo Número entero. ProductID sigue siendo Texto.

7. **Cerrar y Aplicar:**
    
    - En el Editor de Power Query, ve a la pestaña Inicio y haz clic en Cerrar y aplicar.
