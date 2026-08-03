
            SISTEMA DE CONTROL DE ASISTENCIA E INCIDENCIAS (CIT)

Este repositorio contiene el codigo fuente de un sistema integral para la gestion 
de asistencias e incidencias de alumnos. El proyecto esta disenado con una 
arquitectura moderna y desacoplada.

El sistema se compone de dos partes principales:
1. Backend Serverless (AWS): Construido con Python y el AWS Serverless 
   Application Model (SAM), gestiona toda la logica de negocio, autenticacion 
   y persistencia de datos.
2. Aplicacion Movil (Flutter): Una aplicacion multiplataforma para que los 
   alumnos registren su asistencia y para llevar a cabo 
   la gestion del panel de administracion.


--------------------------------------------------------------------------------
ARQUITECTURA
--------------------------------------------------------------------------------

El sistema utiliza una arquitectura serverless basada en eventos. La aplicacion 
cliente en Flutter se comunica con un API Gateway que actua como fachada segura. 
La autenticacion y autorizacion se delegan a AWS Cognito. Cada endpoint del API 
invoca una funcion AWS Lambda especifica que contiene la logica de negocio. 
Finalmente, los datos se almacenan y consultan en Amazon DynamoDB. 
Adicionalmente, se utiliza Amazon EventBridge para procesos programados.

 Diagrama de flujo:
 [ Cliente Flutter ] ---> [ API Gateway ] ---> [ AWS Lambda ] ---> [ Amazon DynamoDB ]
                               |                      |
                               +-> [ AWS Cognito ] <--+


--------------------------------------------------------------------------------
CARACTERISTICAS PRINCIPALES
--------------------------------------------------------------------------------

[ Backend (AWS SAM + Python) ]
- Autenticacion Segura: Integracion con AWS Cognito para registro, inicio de 
  sesion y gestion de perfiles de usuario.
- Gestion de Roles: Roles definidos con permisos especificos a nivel administrativo.
- API RESTful: Endpoints para CRUD de alumnos, proyectos, carreras y docentes.
- Logica Automatica de Incidencias: Generacion automatica de incidencias (faltas, 
  retardos, salidas anticipadas) basada en el cruce de horarios y asistencia 
  mediante un cronograma nocturno.
- Despliegue Serverless: Infraestructura como Codigo (IaC) definida en 
  template.yaml para un despliegue facil y repetible.

[ Aplicacion Movil (Flutter) ]
- Inicio de Sesion y Registro: Flujo completo de autenticacion contra Cognito.
- Registro de Asistencia: Interfaz para que los alumnos marquen su entrada y salida.
- Consulta de Incidencias: Historial de asistencias e incidencias.
- Panel de Administracion: Funcionalidades de gestion de usuarios como cambiar 
  rol o vincular cuentas para administradores.


--------------------------------------------------------------------------------
TECNOLOGIAS UTILIZADAS
--------------------------------------------------------------------------------

- Backend:
  * Python 3.12
  * AWS SAM CLI
  * Boto3 (AWS SDK for Python)
  * Servicios AWS: Lambda, API Gateway, DynamoDB, Cognito, EventBridge

- Frontend Movil:
  * Flutter 3.x
  * Dart
  * http


--------------------------------------------------------------------------------
CONFIGURACION Y PUESTA EN MARCHA
--------------------------------------------------------------------------------

1. BACKEND (AWS)
El backend esta definido como una aplicacion serverless en su respectivo directorio.

Prerrequisitos:
- AWS CLI configurado con credenciales.
- AWS SAM CLI.
- Python 3.12.

Despliegue en AWS:
1. Construye el proyecto:
   sam build

2. Despliega la aplicacion en tu cuenta de AWS de forma guiada:
   sam deploy --guided

   SAM te guiara para configurar los parametros del stack y te proporcionara la 
   URL base del API Gateway al finalizar el proceso.


2. APLICACION MOVIL (FLUTTER)
El codigo fuente se encuentra en el directorio del proyecto movil.

Prerrequisitos:
- Flutter SDK.

Instalacion y Ejecucion:
1. Configura la URL del API: Abre el archivo de configuracion de entorno y 
   actualiza la variable baseUrl con la URL obtenida del despliegue de SAM.
2. Instala las dependencias:
   flutter pub get
3. Ejecuta la aplicacion en un emulador o dispositivo fisico:
   flutter run


--------------------------------------------------------------------------------
API ENDPOINTS
--------------------------------------------------------------------------------

El archivo template.yaml define todos los endpoints. Aqui hay un resumen de los 
mas importantes:

- POST /auth/registrar       : Registra un nuevo usuario en Cognito y DynamoDB.
- POST /auth/login           : Autentica a un usuario y devuelve un token JWT.
- GET  /auth/perfil          : Obtiene el perfil del usuario autenticado.
- GET  /incidencias/listado  : Lista incidencias generales.
- GET  /incidencias/fecha/{fecha} : Obtiene todas las incidencias de una fecha especifica.
- PATCH / PUT / DELETE /incidencias/{id} : Modifica, actualiza o elimina una incidencia.
- POST /asistencias          : Registra una nueva asistencia diaria para un alumno.
- GET  /usuarios             : Lista todos los usuarios del sistema.
- ANY  /admin/{proxy+}       : Endpoints comodin para acciones de administracion 
                               como cambiar rol o vincular alumno.
================================================================================
