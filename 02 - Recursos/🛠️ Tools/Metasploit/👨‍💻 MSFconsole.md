---
tags:
  - Linux
  - Introduccion
  - Pentesting
Fecha de actualización: 2025-11-13
Nota previa: "[[Ⓜ️🧨 Metasploit]]"
Nota siguiente:
Area: "[[Ⓜ️🧨 Metasploit]]"
---
---

Al lanzar el `msfconsole`, nos encontramos con su arte de salpicadura acuñado y el mensaje de línea de comando, esperando nuestro primer comando.
```shell-session
$ msfconsole
                                                  
                                              `:oDFo:`                            
                                           ./ymM0dayMmy/.                          
                                        -+dHJ5aGFyZGVyIQ==+-                    
                                    `:sm⏣~~Destroy.No.Data~~s:`                
                                 -+h2~~Maintain.No.Persistence~~h+-              
                             `:odNo2~~Above.All.Else.Do.No.Harm~~Ndo:`          
                          ./etc/shadow.0days-Data'%20OR%201=1--.No.0MN8'/.      
                       -++SecKCoin++e.AMd`       `.-://///+hbove.913.ElsMNh+-    
                      -~/.ssh/id_rsa.Des-                  `htN01UserWroteMe!-  
                      :dopeAW.No<nano>o                     :is:TЯiKC.sudo-.A:  
                      :we're.all.alike'`                     The.PFYroy.No.D7:  
                      :PLACEDRINKHERE!:                      yxp_cmdshell.Ab0:    
                      :msf>exploit -j.                       :Ns.BOB&ALICEes7:    
                      :---srwxrwx:-.`                        `MS146.52.No.Per:    
                      :<script>.Ac816/                        sENbove3101.404:    
                      :NT_AUTHORITY.Do                        `T:/shSYSTEM-.N:    
                      :09.14.2011.raid                       /STFU|wall.No.Pr:    
                      :hevnsntSurb025N.                      dNVRGOING2GIVUUP:    
                      :#OUTHOUSE-  -s:                       /corykennedyData:    
                      :$nmap -oS                              SSo.6178306Ence:    
                      :Awsm.da:                            /shMTl#beats3o.No.:    
                      :Ring0:                             `dDestRoyREXKC3ta/M:    
                      :23d:                               sSETEC.ASTRONOMYist:    
                       /-                        /yo-    .ence.N:(){ :|: & };:    
                                                 `:Shall.We.Play.A.Game?tron/    
	                                                 -ooy.if1ghtf0r+ehUser5    
                                               ..th3.H1V3.U2VjRFNN.jMh+.          
                                              MjM~~WE.ARE.se~~MMjMs              
                                               +~KANSAS.CITY's~-`                  
                                                J~HAKCERS~./.`                    
                                                .esc:wq!:`                        
                                                 +++ATH`                            
                                                  `


       =[ metasploit v6.1.9-dev                           ]
+ -- --=[ 2169 exploits - 1149 auxiliary - 398 post       ]
+ -- --=[ 592 payloads - 45 encoders - 10 nops            ]
+ -- --=[ 9 evasion                                       ]

Metasploit tip: Use sessions -1 to interact with the last opened session

msf6 > 
```

Alternativamente, podemos utilizar la opción `-q`, que <mark style="background: #FFB8EBA6;">no muestra el banner</mark>.
```shell-session
$ msfconsole -q

msf6 > 
```

Para <mark style="background: #FFB86CA6;">ver mejor todos los comandos disponibles, podemos escribir el comando </mark>`help`. 

> [!important]+
> Una de las primeras cosas que debemos hacer es **asegurarnos de que los módulos que componen el marco estén actualizados y que se puedan importar los nuevos disponibles** para el público.
> - Podemos ejecutar `msfupdate`.
> - Con `apt` actualmente también podemos gestionar la actualización de módulos.

# Instalación de MSF
```shell-session
$ sudo apt update && sudo apt install metasploit-framework

<SNIP>

(Reading database ... 414458 files and directories currently installed.)
Preparing to unpack .../metasploit-framework_6.0.2-0parrot1_amd64.deb ...
Unpacking metasploit-framework (6.0.2-0parrot1) over (5.0.88-0kali1) ...
Setting up metasploit-framework (6.0.2-0parrot1) ...
Processing triggers for man-db (2.9.1-1) ...
Scanning application launchers
Removing duplicate launchers from Debian
Launchers are updated
```

---

# Estructura de participación de MSF
La estructura de participación de *MSF* se puede dividir en cinco categorías principales.
- **Enumeración**
- **Preparación**
- **Explotación**
- **Escalada de privilegios**
- **Post-explotación**

Esta división <mark style="background: #ADCCFFA6;">nos facilita encontrar y seleccionar las funciones *MSF* adecuadas de una manera más estructurada y trabajar con ellas en consecuencia</mark>. Cada una de estas categorías tiene diferentes <mark style="background: #FFB8EBA6;">subcategorías que están destinadas a fines específicos</mark>.
![[msfconsole_struct.png]]

---

# Componentes de MSF
- [[Módulos]]
- [[Payloads]]
- [[Encoders]]