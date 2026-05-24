Práctica Final
Internet: Arquitectura y Protocolos
Departamento de Informática y Sistemas Universidad EAFIT 2025-2
Objetivo: Desplegar un servicio telemático en Cloud con el fin de desarrollar habilidades en el
diseño y configuración de un servicio web seguro, base de datos, así como para un servicio de
balanceo de carga.
DESCRIPCIÓN DE LA PROBLEMÁTICA
Se requiere desplegar una aplicación web en una infraestructura de tecnologías de información
(ver Figura 1). Apoyados en los conceptos de virtualización y contenedores (ver Figura 2), se desea
que ustedes implementen y configuren un esquema que conste de dos servidores web, con
certificado de sitio, base de datos y un balanceador de cargas. Deben utilizar DOCKER.
Figura 1. Arquitectura general del servicio a implementar.
En relación con los componentes que se observa en la Figura 2, para efectos de pruebas; el sistema
operativo host del cliente es el sistema operativo que usted tiene en su máquina (PC o laptop). En
relación con la capa de Hypervisor en la nube, se desplieguen cuatro máquinas virtuales con
sistema operativo Linux o los que deseen. A nivel de aplicación y para efectos del web server se
puede utilizar Apache o el que deseen; mientras que para efectos del balanceador un servidor
NGINX ; usted debe desarrollar una aplicación de proxy inverso y balanceador de carga que permita
recibir las peticiones https y distribuirlas utilizando una política de round robin. Se debe tener una
página con idioma fijo en español y otra en inglés, NO es que se escoja el idioma al entrar
Finalmente, para efectos de pruebas, debe desplegar una aplicación web desarrollada por el
equipo ya sea en lenguaje C ó Phython y desplegada en los servidores web. El sitio Web debe
tener certificado y soportar SSL. De tal forma, que el balanceador de carga sea configurado para
distribuir las peticiones entrantes entre los dos servidores web que se tienen y los usuarios
puedan tener acceso a la aplicación web desplegada. Se debe otra aplicación, en el lenguaje de
preferencia del equipo, para las estadísticas que envía por correo. Las estadísticas debe tener
gráficas donde se evidencie las mismas.
Figura 2. Componentes generales l del servicio a implementar.
Al final todo desplegarse en la nube de AMAZON (aprovechando los beneficios de una cuenta
amazon educate).
CONDICIONES PARA LA REALIZACIÓN DEL TRABAJO
La práctica tiene como principal objetivo desarrollar habilidades para el trabajo en grupo y
colaborativo entre los diferentes participantes de un grupo, el cual debe estar conformado por un
máximo de cuatro estudiantes y un mínimo de dos. De igual forma se busca con el desarrollo de
este trabajo la aplicación de los conceptos teóricos desarrollados en la asignatura INTERNET:
Arquitectura y Protocolos, al igual que el fomento por las actividades investigativas de carácter
formativo.
ENTREGABLES
Operacionales
1. Los Usuarios desde Internet deben accesar a un sitio en Internet, por URL. Donde se tiene
una aplicación que registra el nombre, la zona de la comuna (la ciudad tiene 10 comunas),
fecha de ingreso de información y si está interesada en estudiar una de cuatro carreras de
pregrado (Medicina, Ingeniería, Abogacía y Licenciatura)
2. Se debe crear un dominio en Internet. Se registra el dominio en página donde en forma
gratuita den un dominio por 3 o más meses. Se debe crear un registro A, en el DNS que
apunte al sitio donde tenga la aplicación.
3. En un sitio Cloud se debe hacer por medio de DOCKER un balanceador de tráfico (por round
robin) y que haga las veces de proxy reservo.
4. Desde el Balanceador de tráfico, se debe enviar hacia uno de los servidores de aplicación,
cada servidor de aplicaciones se utilizan DOCKER para definirlos.
5. La aplicación es una página en español y otra en Ingles, desplegando la aplicación para
registrar a los usuarios.
6. Se debe crear un servicio de base de datos para guardar los datos que se ingresan por web.
Debe crearse en DOCKER.
7. Se debe crear una aplicación que, a solicitud del administrador, envié un correo a
ialondonoo@eafit.edu.co con las estadísticas acumuladas de cuantos usuarios por comuna,
cuantos por comuna quieren estudiar cada alternativa.
8. Desde los Clientes deben funcionar las aplicaciones. Los Usuarios utilizan un navegador
comercial por https. Puede haber simultaneidad en la entrada a registrar la información.
Documentales
Para efectos de la evaluación de la práctica se requieren los siguientes entregables, los cuales deben
ser enviados hasta el 27 de mayo a las 23:59 por correo de interactiva y soportarse presencial el
día 28 de Mayo en el horario de 6 am – 9am.
1. Documentación del proceso de configuración del despliegue de los servicios
implementados (p.ej., web y balanceador de carga).
2. Documentación de las aplicaciones balanceador de carga (NGINX), aplicación de reporte de
estadísticas, así como webs desarrolladas por ustedes. La aplicación en WEB SERVER1
debe desplegarse en inglés y la aplicación en WEB SERVER 2 en español.
3. Obtener el certificado de sitio.
4. El procedimiento para la entrega del trabajo es el siguiente:
a. Se debe entregar por correo vía EAFIT interactiva.
b. Por Github, Se debe entregar un documento donde describa todos los aspectos
necesarios para la configuración y despliegue del servicio propuesto. El archivo se
debe entregar en formato PDF. El nombre del archivo debe estar conformado por
el primer apellido de los integrantes del grupo.
5. La fecha de sustentación es jueves 28, de 6:00 am 9 a m. Tienen 20 minutos para sustentar
cada equipo