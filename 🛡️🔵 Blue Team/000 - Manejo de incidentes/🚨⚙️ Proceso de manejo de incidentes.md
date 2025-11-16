Ahora que estamos familiarizados con la cadena de muerte cibernética y sus etapas, podemos predecir/anticipar mejor los próximos pasos en un ataque y también sugerir medidas apropiadas contra ellos.

Al igual que la cadena de muerte cibernética, hay diferentes etapas, al responder a un incidente, definidas como `incident handling process`. El `incident handling process` define una capacidad para que las organizaciones preparen, detecten y respondan a eventos maliciosos. Tenga en cuenta que este proceso es adecuado para responder a eventos de seguridad de TI, pero sus etapas no corresponden a las etapas de la cadena de muerte cibernética de una manera uno a uno.

Según lo definido por el NIST, el proceso de manejo de incidentes consta de las siguientes cuatro (4) etapas distintas: ![Diagrama de flujo del proceso de respuesta a incidentes: Preparación, Detección y Análisis, Erradicación y Recuperación de Contención, Actividad Post-Incidente.](https://academy.hackthebox.com/storage/modules/148/handling_process.png)

Los manejadores de incidentes pasan la mayor parte de su tiempo en las dos primeras etapas `preparation` y `detection & analysis`. Aquí es donde pasamos mucho tiempo mejorándonos y buscando el próximo evento malicioso. Cuando se detecta un evento malicioso, pasamos a la siguiente etapa y respondemos al evento.

> [!important]+
> But there should always be resources operating on the first two stages, so that there is no disruption of preparation and detection capabilities.

Como puede ver en la imagen, el proceso no es lineal sino cíclico. El punto principal a entender en este punto es que a medida que se descubre nueva evidencia, los próximos pasos también pueden cambiar. Es vital asegurarse de no omitir los pasos en el proceso y completar un paso antes de pasar al siguiente. Por ejemplo, si descubre diez máquinas infectadas, ciertamente no debe proceder a contener solo cinco de ellas y comenzar la erradicación mientras las cinco restantes permanecen en un estado infectado. Tal enfoque puede ser ineficaz porque, como mínimo, está notificando a un atacante que los ha descubierto y que los está cazando, lo que, como podría imaginar, puede tener consecuencias impredecibles.

Por lo tanto, el manejo de incidentes tiene dos actividades principales, que son `investigating` y `recovering`. La investigación tiene como objetivo:

- Descubra la víctima inicial de 'paciente cero' y cree una línea de tiempo de incidentes (en curso si aún está activa)
- Determine qué herramientas y malware utilizó el adversario
- Documente los sistemas comprometidos y lo que el adversario ha hecho

Después de la investigación, la actividad de recuperación implica crear e implementar un plan de recuperación. Cuando se implementa el plan, la empresa debe reanudar las operaciones comerciales normales, si el incidente causó interrupciones.

Cuando un incidente se maneja completamente, se emite un informe que detalla la causa y el costo del incidente. Además, se realizan actividades de "lecciones aprendidas", entre otras, para comprender qué debe hacer la organización para evitar que vuelvan a ocurrir incidentes de tipo similar.

Permítanos ahora guiarlo a través de todas las etapas del `incident handling process`.