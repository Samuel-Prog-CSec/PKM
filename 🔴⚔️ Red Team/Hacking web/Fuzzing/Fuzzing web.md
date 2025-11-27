---
tags:
  - Introduccion
  - Pentesting
  - Web/Red-Team
  - Pentesting/Enumeracion
Fecha de actualización: 2025-10-08
Nota previa:
Nota siguiente: "[[Herramientas]]"
Area: "[[Web Pentesting.base|Web Pentesting]]"
---

---

<mark style="background: #ADCCFFA6;">Implica pruebas automatizadas de aplicaciones web proporcionando datos inesperados o aleatorios para detectar posibles fallas que los atacantes podrían explotar</mark>.

# Fuzzing vs fuerza bruta
- **Fuzzing** lanza una red más amplia. Implica alimentar la aplicación web con entradas inesperadas, incluidos datos mal formados, caracteres no válidos y combinaciones sin sentido. El objetivo es ver cómo reacciona la aplicación a estas entradas extrañas y descubrir posibles vulnerabilidades en el manejo de datos inesperados. Las herramientas de fuzzing a menudo aprovechan listas de palabras que contienen patrones comunes, mutaciones de parámetros existentes o incluso secuencias de caracteres aleatorias para generar un conjunto diverso de cargas útiles.
- La **fuerza bruta**, por otro lado, es un enfoque más específico. Se centra en probar sistemáticamente muchas posibilidades para un valor específico, como una contraseña o un número de identificación. Las herramientas de fuerza bruta generalmente se basan en listas o diccionarios predefinidos (como diccionarios de contraseñas) para adivinar el valor correcto mediante prueba y error.

## ¿Por qué Fuzzing?
Las aplicaciones web se han convertido en la columna vertebral de los negocios y la comunicación modernos, manejando grandes cantidades de datos confidenciales y permitiendo interacciones críticas en línea. Sin embargo, su complejidad e interconexión también los convierten en objetivos principales de los ciberataques. Las pruebas manuales, si bien son esenciales, sólo pueden llegar hasta cierto punto a la hora de identificar vulnerabilidades. Aquí es donde brilla el fuzzing web:
- `Uncovering Hidden Vulnerabilities`: El fuzzing puede descubrir vulnerabilidades que los métodos tradicionales de pruebas de seguridad podrían pasar por alto. Al bombardear una aplicación web con entradas inesperadas e inválidas, el fuzzing puede desencadenar comportamientos inesperados que revelan fallas ocultas en el código.
- `Automating Security Testing`: Fuzzing automatiza la generación y el envío de entradas de prueba, ahorrando tiempo y recursos valiosos. Esto permite a los equipos de seguridad centrarse en analizar los resultados y abordar las vulnerabilidades encontradas.
- `Simulating Real-World Attacks`: Los fuzzers pueden imitar las técnicas de los atacantes, ayudándole a identificar debilidades antes de que actores maliciosos las exploten. Este enfoque proactivo puede reducir significativamente el riesgo de un ataque exitoso.
- `Strengthening Input Validation`: El fuzzing ayuda a identificar debilidades en los mecanismos de validación de entrada, que son cruciales para prevenir vulnerabilidades comunes como `SQL injection` y `cross-site scripting` (`XSS`).
- `Improving Code Quality`: Fuzzing mejora la calidad general del código al descubrir errores y fallos. Los desarrolladores pueden utilizar los comentarios de fuzzing para escribir código más sólido y seguro.
- `Continuous Security`: El fuzzing se puede integrar en el `software development lifecycle` (`SDLC`) como parte de `continuous integration and continuous deployment` (`CI/CD`) canalizaciones, lo que garantiza que las pruebas de seguridad se realicen periódicamente y que las vulnerabilidades se detecten en las primeras etapas del proceso de desarrollo.

# Conceptos esenciales
Antes de profundizar en los aspectos prácticos del fuzzing web, es importante comprender algunos conceptos clave:

| Concepto            | Descripción                                                                                                                                                                                         | Ejemplo                                                                                                                           |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `Wordlist`          | Un diccionario o lista de palabras, frases, nombres de archivos, nombres de directorios o valores de parámetros utilizados como entrada durante el fuzzing.                                         | Genérico: `admin`, `login`, `password`, `backup`, `config`  <br>Específico de la aplicación: `productID`, `addToCart`, `checkout` |
| `Payload`           | Los datos reales enviados a la aplicación web durante el fuzzing. Puede ser una cadena simple, un valor numérico o una estructura de datos compleja.                                                | `' OR 1=1 --`(para inyección SQL)                                                                                                 |
| `Response Analysis` | Examinar las respuestas de la aplicación web (por ejemplo, códigos de respuesta, mensajes de error) a las cargas útiles del fuzzer para identificar anomalías que podrían indicar vulnerabilidades. | Normal: 200 OK  <br>Error (posible SQLi): 500 Error interno del servidor con un mensaje de error de base de datos                 |
| `Fuzzer`            | Una herramienta de software que automatiza la generación y el envío de cargas útiles a una aplicación web y el análisis de las respuestas.                                                          | `ffuf`, `wfuzz`, `Burp Suite Intruder`                                                                                            |
| `False Positive`    | Un resultado que el fuzzer identifica incorrectamente como vulnerabilidad.                                                                                                                          | Un error 404 No encontrado para un directorio inexistente.                                                                        |
| `False Negative`    | Una vulnerabilidad que existe en la aplicación web pero que el fuzzer no detecta.                                                                                                                   | Una falla lógica sutil en una función de procesamiento de pagos.                                                                  |
| `Fuzzing Scope`     | Las partes específicas de la aplicación web a las que se dirige con sus esfuerzos de fuzzing.                                                                                                       | Solo fuzear la página de inicio de sesión o centrarse en un punto final de API en particular.                                     |
