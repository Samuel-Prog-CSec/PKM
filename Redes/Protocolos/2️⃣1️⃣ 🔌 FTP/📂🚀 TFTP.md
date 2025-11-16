**Trivial File Transfer Protocol** (`TFTP`) es ==más sencillo que el FTP== y realiza transferencias de archivos entre procesos de cliente y servidor. Sin embargo, **no proporciona autenticación de usuario ni otras funciones valiosas** admitidas por FTP. Además, mientras que FTP utiliza TCP, ==TFTP utiliza UDP==, lo que lo convierte en un protocolo poco fiable y hace que utilice la recuperación de capa de aplicación asistida por UDP.

No admite el inicio de sesión protegido mediante contraseñas y establece límites de acceso basados ​​únicamente en los permisos de lectura y escritura de un archivo en el sistema operativo. En la práctica, esto lleva a que ==TFTP funcione exclusivamente en directorios y con archivos que se han compartido con todos los usuarios y se pueden leer y escribir de forma global==. Debido a la falta de seguridad, TFTP, a diferencia de FTP, **solo se puede utilizar en redes locales y protegidas**.

A continuación, se muestran algunos comandos de TFTP:

| ==Commands== | ==Description==                                                                                                                                            |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `connect`    | **Establece el host remoto**, y ==opcionalmente el puerto== (para transferencias de archivos)                                                              |
| `get`        | **Transfiere un archivo** (o un set de estos) desde el ==host remoto al host local==                                                                       |
| `put`        | **Transfiere un archivo** (o un set de estos) desde el ==host local al host remoto==                                                                       |
| `quit`       | **Salir** de TFTP                                                                                                                                          |
| `status`     | **Muestra el estado** de TFTP, incluyendo el modo de transporte actual que esté activado (ascii o binario), estado de la conexión, valor del time-out, etc |
| `verbose`    | **Activa o desactiva el modo verbose**, el cual muestra información adicional durante la transferencia de archivos.                                        |
A diferencia del ==cliente== FTP, **TFTP no tiene funcionalidad de listado de directorios**.