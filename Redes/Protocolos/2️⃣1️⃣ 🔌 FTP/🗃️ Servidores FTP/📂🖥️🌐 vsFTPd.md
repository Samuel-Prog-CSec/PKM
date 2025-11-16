# Configuración de servidores FTP
Uno de los **servidores FTP más utilizados en distribuciones basadas en Linux es [vsFTPd](https://security.appspot.com/vsftpd.html)**. La configuración predeterminada de vsFTPd se puede encontrar en `/etc/vsftpd.conf`, y algunas configuraciones ya están predefinidas de manera predeterminada. 

```shell
sudo apt install vsftpd 
```

Existen muchas alternativas diferentes, que además aportan, entre otras cosas, muchas más funciones y opciones de configuración. Utilizaremos el servidor vsFTPd porque es una excelente manera de mostrar las ==posibilidades de configuración de un servidor FTP de una forma sencilla y fácil de entender== sin entrar en los detalles de las páginas del manual. 

Si observamos el archivo de configuración de vsFTPd, veremos muchas opciones y configuraciones que están comentadas o no. Sin embargo, **el archivo de configuración no contiene todas las configuraciones posibles que se pueden realizar**. Las existentes y las que faltan se pueden encontrar en la [página del manual](http://vsftpd.beasts.org/vsftpd_conf.html).
 

## vsFTPd archivo de configuración
```shell
cat /etc/vsftpd.conf | grep -v "#"
```

| ==Ajustes==                                                   | ==Descripción==                                                                                          |
| ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `listen=NO`                                                   | Run from inetd or as a standalone daemon?                                                                |
| `listen_ipv6=YES`                                             | Listen on IPv6 ?                                                                                         |
| `anonymous_enable=NO`                                         | Enable Anonymous access?                                                                                 |
| `local_enable=YES`                                            | Allow local users to login?                                                                              |
| `dirmessage_enable=YES`                                       | Display active directory messages when users go into certain directories?                                |
| `use_localtime=YES`                                           | Use local time?                                                                                          |
| `xferlog_enable=YES`                                          | Activate logging of uploads/downloads?                                                                   |
| `connect_from_port_20=YES`                                    | Connect from port 20?                                                                                    |
| `secure_chroot_dir=/var/run/vsftpd/empty`                     | Name of an empty directory                                                                               |
| `pam_service_name=vsftpd`                                     | This string is the name of the PAM service vsftpd will use.                                              |
| `rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem`          | The last three options specify the location of the RSA certificate to use for SSL encrypted connections. |
| `rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key` |                                                                                                          |
| `ssl_enable=NO`                                               |                                                                                                          |


## FTPUSERS
Además, hay un archivo llamado `/etc/ftpusers` al que también debemos prestar atención, ya que **este archivo se utiliza para denegar a determinados usuarios el acceso al servicio FTP**. En el siguiente ejemplo, los usuarios guest, john y kevin no tienen permiso para iniciar sesión en el servicio FTP:

```shell
cat /etc/ftpusers

guest
john
kevin
```

