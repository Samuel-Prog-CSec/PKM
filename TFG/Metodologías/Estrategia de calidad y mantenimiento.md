# Estrategia de Calidad de Software (SQA) y Mantenibilidad
Para garantizar la robustez, escalabilidad y mantenibilidad del proyecto a largo plazo, se ha implementado una arquitectura de **Defensa en Profundidad** para la calidad del código. Esta estrategia automatiza la detección de errores en múltiples etapas del ciclo de vida del desarrollo (SDLC).

## A. Análisis Estático y Formateo Local (Pre-Commit)
Se han configurado herramientas de análisis estático que se ejecutan localmente para asegurar que el código cumpla con los estándares de la industria antes de ingresar al repositorio.
- **ESLint (con Flat Config):** Utilizado para identificar patrones problemáticos y errores de lógica en JavaScript. Se han integrado plugins de seguridad (`eslint-plugin-security`) y calidad (`eslint-plugin-sonarjs`) para detectar vulnerabilidades comunes (OWASP Top 10) y complejidad cognitiva excesiva.
- **Prettier:** Garantiza un estilo de código consistente (indentación, comillas, espaciado), eliminando debates subjetivos sobre estilo y facilitando la lectura por terceros.
- **Justificación:** Según Google Engineering Practices, la consistencia en el código reduce la carga cognitiva al leerlo y facilita el mantenimiento colaborativo.

## B. Gestión de Hooks y Estandarización de Commits
La disciplina en el control de versiones es crítica para la trazabilidad.
- **Husky & Lint-staged:** Orquestan la ejecución de scripts antes de confirmar cambios (`pre-commit`). Esto impide técnicamente que código con errores de sintaxis o tests fallidos sea confirmado ("commiteado"). `Lint-staged` optimiza este proceso analizando solo los archivos modificados.
- **Commitlint & Conventional Commits:** Se obliga al uso de una convención semántica en los mensajes de commit (ej. `feat:`, `fix:`, `docs:`).
- **Beneficio:** Permite la generación automática de _Changelogs_ y facilita la comprensión histórica de los cambios.
- _Fuente:_ [Conventional Commits Specification](https://www.conventionalcommits.org/).

## C. Integración Continua (CI) y Quality Gates
Se ha implementado un pipeline de CI/CD mediante **GitHub Actions** que actúa como "juez imparcial" en la nube.
1. **Build & Test:** En cada _Push_ o _Pull Request_, se levanta un entorno limpio (Ubuntu Latest), se instala MongoDB y se ejecutan los tests unitarios e integración (Jest).
2. **SonarCloud (Análisis Continuo):** El código es enviado a SonarCloud para evaluar métricas profundas: Deuda Técnica, Cobertura de Tests (Code Coverage) y "Code Smells". Se establecen **Quality Gates** que bloquean la fusión de código si no cumple con los umbrales mínimos (ej. 80% de cobertura).
    - _Fuente:_ [Martin Fowler sobre Continuous Integration](https://martinfowler.com/articles/continuousIntegration.html).

## D. Mantenimiento Automatizado
- **Dependabot:** Herramienta nativa de GitHub configurada para escanear semanalmente las dependencias (npm) en busca de vulnerabilidades de seguridad (CVEs) y actualizaciones. Genera Pull Requests automáticos, reduciendo el riesgo de obsolescencia tecnológica.

---

## E. Dockerización (Infraestructura como Código)
Actualmente, tu CI instala Mongo y Node "a mano".
- **Mejora:** Crea un `Dockerfile` y un `docker-compose.yml`.
- **Beneficio:** Permite que cualquiera (incluido el tribunal) ejecute tu proyecto con un solo comando (`docker-compose up`) sin instalar Node ni Mongo en su PC. Esto garantiza que el entorno de desarrollo es idéntico al de producción.

## F. Pruebas End-to-End (E2E)
Tienes tests unitarios (Jest) en el backend. Pero, ¿quién prueba que si clico el botón "Jugar" en React realmente empieza la partida?
- **Herramienta:** **Cypress** o **Playwright**.
- **Acción:** Crear un test que abra un navegador real, se loguee y simule una partida.
- **Valor:** Es el nivel más alto de testing automatizado.

## G. Versionado Semántico Automático (posible -> revisar)
Ya usas "Conventional Commits" (`feat`, `fix`).
- **Herramienta:** **Semantic Release**.
- **Acción:** Configurar un paso extra en GitHub Actions.
- **Resultado:** Si haces un commit `feat`, el sistema sube la versión de la v1.0.0 a la v1.1.0 automáticamente, crea un Git Tag y genera el archivo `CHANGELOG.md` con las novedades. ¡Automatización total!

## H. Documentación de API Viva
- **Herramienta:** **Swagger / OpenAPI**.
- **Acción:** Documentar tus endpoints automáticamente.
- **Valor:** En lugar de tener archivos `.md` manuales (que se quedan obsoletos), Swagger genera una web donde se puede probar la API en tiempo real.
