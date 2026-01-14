# Contexto 
**¿Por qué el enfoque actual “SerialPort en backend” no vale en cloud?** En local funciona porque el backend tiene acceso a COMx/ttyUSBx. En hosting tipo Heroku/Railway/Render el contenedor no tiene USB, ni acceso al puerto serie del PC del profesor.

Por tanto: **si el backend está desplegado en cloud, no puede leer directamente el lector conectado al PC del profesor.**

# Arquitectura objetivo (posible)
El lector se conecta al PC del profesor, el navegador lee del puerto serie y reenvía al backend por Socket.IO.
```
Sensor RFID ─[USB]─► PC Profesor ─[Web Serial API]─► Frontend (Chrome/Edge) ─[Socket.IO]─► Backend cloud
```

## Componentes del diseño
### A) Frontend (Web Serial)
Servicio *WebSerialService*:
- `connect()` → navigator.serial.requestPort() + port.open({ baudRate })
- `disconnect()` → cerrar reader/port con cleanup robusto
- `startReading()` → loop asíncrono leyendo el stream
- Parser de mensajes
- Emite a `Socket.IO` eventos como `rfid_scan_from_client`

### B) Backend
Mantiene el motor de juego (`GameEngine`) igual: el backend sigue siendo “*source of truth*”.

Cambia el origen de eventos:
- **Modo dev**: `rfidService` (*SerialPort* en servidor)
- **Modo prod**: eventos llegan por `Socket.IO` desde el cliente
- **Regla clave**: nunca confiar 100% en el cliente → validar y autorizar eventos.
- **Framing** (punto importante)
- En serial casi siempre recibes “trozos” de texto, no JSON perfecto por lectura.

### Mejor práctica:
- Firmware envía JSON por línea (NDJSON): cada evento termina con `\n`.
- En frontend, acumulas buffer hasta `\n`, parseas línea a línea.
- **Mejora recomendada**: “line splitter” (buffer) para evitar `JSON.parse` sobre fragmentos.

### Seguridad / Autorización (imprescindible)
Si el cliente manda eventos RFID al backend: Autenticación WS obligatoria (token en handshake).

#### Autorización
Solo permitir `rfid_scan_from_client` si el socket pertenece a un profesor autorizado.

**Enlazar “sensor” ↔ “sesión”/“partida”**:
- O bien por `sensorId` (configurado) y asignado a la sesión.
- O bien por “modo” y “room” (ej. `card_registration` vs `play_<id>`).

No broadcast global de eventos RFID:
Emitir a la room de la partida o de registro, nunca io.emit.
Fiabilidad / UX
Botón “Conectar sensor” + estado:
Desconectado / Conectando... / Conectado / Error

Manejo de desconexión:
Detectar reader.read() done / exceptions
Mostrar CTA: “Reconectar”
Rate limiting del lado servidor para rfid_scan_from_client (anti spam)
Debounce opcional en frontend:
Si el firmware manda card_detected repetidos, evitar duplicados a 100ms.
Multi-sensor realista
Con Web Serial, el “multi-sensor” suele ser “multi-profesor” (cada uno con su lector).

En producción, normalmente un profesor ↔ un lector en su PC.
Si quieres múltiples lectores en un PC: Web Serial puede abrir distintos puertos, pero la UX se complica.
Recomiendo:
sensorId lógico (configurable en firmware o asignado en UI),
sensorId se asocia a la sesión/partida al iniciar.
Modos RFID (control de flujo)
Para evitar lecturas fuera de contexto:

idle: ignorar eventos
card_registration: aceptar UID y mostrarlo para registrar tarjeta
gameplay: aceptar solo si hay partida activa y el profesor está jugando esa partida
Esto reduce errores “random scans” y facilita que el profesor entienda qué está ocurriendo.