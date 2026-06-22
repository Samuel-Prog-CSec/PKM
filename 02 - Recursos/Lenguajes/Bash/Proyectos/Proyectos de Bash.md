# Proyectos para principiantes
## 1. Ping Sweeper para Enumeración de Hosts Activos
### "Operación Hydra"
- **Significado**: La hydra, símbolo de la Legión Alpha, representa versatilidad y multiplicidad. Este nombre es ideal para el script que detecta hosts activos porque simboliza cómo puedes "revelar" múltiples cabezas (dispositivos) en una red.
- **Conexión**: La operación recuerda las estrategias de la Legión Alpha, donde cada victoria parece abrir múltiples frentes.
### Descripción Detallada:
Este script utiliza `ping` para verificar la conectividad de un rango de direcciones IP, permitiendo identificar qué dispositivos están activos en la red. Es útil en la fase de reconocimiento de red, especialmente para redes locales.
### Funcionalidades adicionales sugeridas 
- Opción de exportar resultados en formatos `CSV` o `JSON`.
- Agregar una funcionalidad de multithreading con `xargs` para mejorar la velocidad.
- Añadir detección de sistemas operativos básicos mediante TTL.
- Resumen final indicando el número total de hosts activos.
### Herramientas/Requisitos:
- Comandos: `ping`, `awk`, `xargs`.
- Documentación: Ping, xargs.
### Referencias:
- Proyecto similar: [PingSweep en GitHub](https://github.com/topics/ping-sweep).


## 2. Port Scanner Simple
### "El Manto de Alpharius"
- **Significado**: El título refleja cómo la Legión Alpha se oculta en las sombras, con todos sus miembros afirmando ser Alpharius. Esto encaja con el script que detecta cambios en configuraciones sensibles, actuando como un protector silencioso del sistema.
- **Conexión**: Se relaciona con la vigilancia constante y la protección secreta.
### Descripción Detallada:  
Este script verifica qué puertos están abiertos en un rango específico para una dirección IP. Utiliza `nc` (Netcat) o sockets de Bash para establecer conexiones. Ideal para comprender cómo funcionan los escaneos de puertos básicos.
### Funcionalidades adicionales sugeridas**:
- Agregar un temporizador para calcular el tiempo total del escaneo.
- Clasificar los puertos detectados como "común" o "inusual".
- Incluir escaneo de puertos UDP además de TCP.
- Detectar banners simples con `nc`.
### Herramientas/Requisitos:
- Comandos: `nc`, `bash sockets`.
- Documentación: Netcat.
### Referencias:
- [Script básico de escaneo en Bash](https://github.com/jivoi/awesome-osint).


## 3. Scraper de Información Pública de Dominio
### "Espía Dormido"
- **Significado**: Hace referencia a los agentes encubiertos que la Legión Alpha infiltra en organizaciones para actuar en el momento adecuado. Este nombre es perfecto para el script que detecta procesos maliciosos en segundo plano.
- **Conexión**: Resalta la vigilancia y la detección de amenazas antes de que causen daño.
### Descripción Detallada:  
Automatiza la recopilación de información de un dominio, usando herramientas como `whois`, `dig`, `nslookup` y consultas a `crt.sh`. Muy útil para OSINT en fases iniciales.
### Funcionalidades adicionales sugeridas:
- Extraer registros DNS adicionales (MX, TXT, SOA).
- Identificar subdominios mediante diccionarios (bruteforce).
- Integrar búsquedas en fuentes públicas como `crt.sh` para certificados SSL.
- Generar un informe con detalles como propietario, ubicación y servidores DNS asociados.
### Herramientas/Requisitos:
- Comandos: `whois`, `dig`, `nslookup`, `curl`.
- Documentación: Whois, [crt.sh](https://crt.sh/).
### Referencias:
- Proyecto similar: [Domain-Info](https://github.com/topics/domain-info).


# Proyectos Intermedios
## 4. Generador de Diccionarios Personalizados
### "Corte de Hydra"
- **Significado**: Inspirado en la frase "corta una cabeza, dos tomarán su lugar", representa cómo la Legión Alpha aborda los problemas de manera fragmentada y estratégica. Este nombre encaja perfectamente con el script de fuerza bruta sobre contraseñas.
- **Conexión**: Cada intento es como un corte, que abre nuevas posibilidades de éxito.
    - **Descripción Detallada**:  
        Este script genera listas de contraseñas personalizadas, aplicando reglas como combinaciones de nombres, fechas, números y símbolos, que se pueden usar en ataques de fuerza bruta.
    - **Funcionalidades adicionales sugeridas**:
        - Permitir añadir reglas predefinidas como permutaciones (e.g., `admin123`, `Admin@123`).
        - Soporte para combinaciones específicas por patrones como `regex`.
        - Exportar los resultados comprimidos (`gzip`) para reducir el tamaño.
        - Integrar opciones de generación en base a listas de cumpleaños o datos personales.
    - **Herramientas/Requisitos**:
        - Comandos: `awk`, `sed`, `gzip`.
        - Documentación: [Wordlists en GitHub](https://github.com/topics/wordlist).
    - **Referencias**:
        - Proyecto similar: [CUPP (Common User Passwords Profiler)](https://github.com/Mebus/cupp).
    
    ---
    
## 5. Detector de Cambios en Archivos y Directorios Críticos
### "Ojos de Omegon"
- **Significado**: Omegon, uno de los primarcas gemelos, representa la vigilancia sutil y la capacidad de ver patrones ocultos. Este título refleja cómo el script analiza puertos y servicios de forma detallada.
- **Conexión**: La inspección y el análisis encajan con el ojo crítico de la Legión.
    - **Descripción Detallada**:  
        Monitorea directorios y archivos importantes para identificar cambios, como modificaciones, creaciones o eliminaciones, que puedan indicar actividad maliciosa.
    - **Funcionalidades adicionales sugeridas**:
        - Registrar todos los cambios en un archivo de log estructurado.
        - Enviar alertas mediante correo o Slack usando `mail` o `curl`.
        - Integrar con herramientas de cifrado para proteger logs generados.
        - Añadir soporte para múltiples directorios en paralelo.
    - **Herramientas/Requisitos**:
        - Librerías: `inotify-tools`, `mail`.
        - Documentación: Inotify.
    - **Referencias**:
        - Proyecto similar: AuditD.
    
    ---
    
## 6. Exfiltración de Datos Simulada con Bash
 ### "Velos de la Hydra"
- **Significado**: Este nombre simboliza las múltiples capas de la Legión Alpha y su habilidad para ocultar sus verdaderos movimientos. Es adecuado para el script que configura un proxy local.
- **Conexión**: Un proxy actúa como un velo, ocultando el tráfico y añadiendo anonimato.
    - **Descripción Detallada**:  
        Emula la extracción de datos sensibles desde un sistema comprometido hacia un servidor remoto, usando herramientas comunes como `scp` o `curl`.
    - **Funcionalidades adicionales sugeridas**:
        - Añadir cifrado con `openssl` antes de la transferencia.
        - Permitir definir tamaños específicos para los archivos exfiltrados (simulando limitaciones reales).
        - Registrar actividades en logs ofuscados.
        - Opción de ejecutar en modo "silencioso" sin salida visible.
    - **Herramientas/Requisitos**:
        - Comandos: `scp`, `curl`, `openssl`.
        - Documentación: OpenSSL.
    - **Referencias**:
        - Proyecto similar: [Data-Exfiltration-Bash](https://github.com/topics/exfiltration).
    
    ---
    
    ### **Proyectos Avanzados**
    
## 7. Automatizador de Búsqueda de Vulnerabilidades Web
### "Alpharius Resurge"
- **Significado**: Este título representa el regreso inesperado de la Legión Alpha o su primarca en el momento crucial. Es ideal para el script que orquesta múltiples ataques en cadena, ya que sugiere una revelación impactante.
- **Conexión**: El "resurgir" se refleja en cómo un ataque coordinado emerge de forma calculada.
    - **Descripción Detallada**:  
        Automatiza pruebas en aplicaciones web, verificando configuraciones inseguras o vulnerabilidades simples como falta de cabeceras de seguridad, páginas expuestas o errores en formularios.
    - **Funcionalidades adicionales sugeridas**:
        - Verificar cabeceras HTTP de seguridad como `CSP`, `X-Frame-Options`.
        - Detectar directorios ocultos con diccionarios personalizados (`robots.txt`, bruteforce).
        - Integrar detecciones de SQL Injection básicas mediante parámetros comunes.
    - **Herramientas/Requisitos**:
        - Comandos: `curl`, `grep`, `awk`.
        - Documentación: [HTTP Headers Scanner](https://github.com/topics/http-security).
    - **Referencias**:
        - Proyecto similar: OWASP ZAP.
    
    ---
    
## 8. Simulador de Ataques por Fuerza Bruta SSH
### "La Paradoja del Primarca"
- **Significado**: Alpharius y Omegon son gemelos y, a menudo, imposibles de distinguir, lo que genera una paradoja. Este nombre se adapta al script de análisis avanzado de logs que resuelve problemas aparentemente contradictorios en la actividad del sistema.
- **Conexión**: El análisis de patrones ambiguos se alinea con el misterio de los primarcas gemelos.
    - **Descripción Detallada**:  
        Este script prueba credenciales contra un servidor SSH, simulando ataques por fuerza bruta para evaluar políticas de seguridad.
    - **Funcionalidades adicionales sugeridas**:
        - Soporte para retrasos configurables entre intentos.
        - Registro detallado de intentos exitosos y fallidos.
        - Validar contraseñas reutilizadas desde bases de datos públicas.
    - **Herramientas/Requisitos**:
        - Librerías: `sshpass`, `ssh`.
        - Documentación: SSH.
    - **Referencias**:
        - Proyecto similar: [Hydra](https://github.com/vanhauser-thc/thc-hydra).
    
    ---
    
## 9. Framework Minimalista de Red Team en Bash
### "Eco de la Herejía"
- **Significado**: Este nombre hace referencia al impacto duradero de la Legión Alpha después de la Herejía de Horus. Es ideal para el script que rastrea rastros digitales.
- **Conexión**: Los rastros en un sistema pueden considerarse ecos de actividades pasadas, como la Herejía.
    - **Descripción Detallada**:  
        Una suite integrada con múltiples scripts que cubran fases clave de un ataque: reconocimiento, explotación y persistencia básica.
    - **Funcionalidades adicionales sugeridas**:
        - Escaneo de red con mapeo visual de hosts activos.
        - Automatización de carga de claves SSH en servidores comprometidos.
        - Módulo para recopilar hashes de contraseñas en sistemas locales.
    - **Herramientas/Requisitos**:
        - Comandos: `ssh`, `scp`, `nmap`, `curl`.
        - Documentación: [Red Team Toolkit](https://github.com/topics/red-team).
    - **Referencias**:
        - Proyecto similar: [PowerShell Empire](https://github.com/EmpireProject/Empire).


# Extras
## Proxy Simple para Análisis de Tráfico HTTP
### "Sombra de Hydra"
- **Significado**: Representa las operaciones encubiertas de la Legión, donde trabajan sin ser detectados. Ideal para un script que analice conexiones salientes.
- **Conexión**: El análisis silencioso del tráfico refleja la naturaleza encubierta de la Legión.
- **Descripción**: Crear un proxy que capture solicitudes HTTP y registre detalles como cabeceras y datos de los formularios.
- **Documentación**: Burp Suite Community.
## Automatización de Payloads para Ingeniería Social
## "La Hydra Persuasiva"
- **Significado**: La _Hydra_, símbolo de la Legión Alpha, representa astucia, resiliencia y la capacidad de adaptarse. El adjetivo "Persuasiva" alude a la habilidad de la ingeniería social para influir en las decisiones humanas mediante el engaño y la manipulación sutil.
- **Conexión con la Legión Alpha**: Este nombre encapsula el espíritu de la Legión, conocida por su capacidad para infiltrarse y sembrar desinformación con un propósito mayor. Al igual que ellos adaptan sus estrategias según las circunstancias, este proyecto podría personalizar payloads para maximizar su eficacia.
--- 
- **Descripción**: Un script que genere y envíe correos de phishing automatizados (usando `sendmail` o `msmtp`) como parte de una prueba controlada.
- Referencias: [Phishing-Toolkit](https://github.com/topics/phishing).**"La Hydra Persuasiva"**
---
### Sugerencias de funcionalidades para este proyecto
1. **Selección dinámica de payloads**:
    - Basado en el perfil de la víctima (por ejemplo, tipo de sistema operativo, vectores de acceso más probables, etc.).
    - Compatibilidad con diferentes formatos de entrega (PDF, scripts en VBA, .exe, etc.).
2. **Integración con APIs externas**:
    - Para personalizar mensajes de phishing en función de información pública (como redes sociales o perfiles en LinkedIn).
3. **Módulo de creación de plantillas**:
    - Generar mensajes convincentes automáticamente, como correos electrónicos o mensajes en plataformas de mensajería, simulando eventos reales o urgencias específicas.
4. **Automatización del empaquetado**:
    - Incluir opciones para incrustar payloads en documentos comunes, como hojas de cálculo o archivos PDF, utilizando herramientas como `msfvenom`.
5. **Pruebas locales de payloads**:
    - Un entorno sandbox para verificar la funcionalidad y evitar fallos antes de desplegarlos.
6. **Evasión de detección**:
    - Opciones para ofuscar el payload y evitar herramientas de detección como antivirus o sistemas de detección de intrusos (IDS).
7. **Gestión de campañas**:
    - Crear, gestionar y realizar un seguimiento de múltiples campañas de ingeniería social.
---
### Referencias útiles para el proyecto
1. **Herramientas de generación de payloads**:
    - `msfvenom` (Metasploit Framework).
    - `Empire` (framework de post-explotación).
    - `Veil-Evasion` (para ofuscar payloads).
2. **Recursos para ingeniería social**:
    - Libros: _The Art of Deception_ de Kevin Mitnick.
    - Proyectos similares: _King Phisher_ (herramienta para campañas de phishing).
3. **Herramientas de automatización**:
    
    - `AutoIt` o `Powershell` para tareas específicas en sistemas Windows.
    - Scripts en Python para integrar y coordinar las acciones.
4. **Herramientas de evasión**:
    - `Shellter` para añadir ofuscación a payloads.
    - `Obfuscator.IO` para JavaScript y otros lenguajes.
5. **Frameworks adicionales**:
    - `PhishTool` o `GoPhish` para campañas más enfocadas en phishing.