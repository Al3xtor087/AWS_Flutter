import json
import os
import boto3

cognito_client = boto3.client('cognito-idp')

USER_POOL_ID = os.environ.get('USER_POOL_ID')
COGNITO_CLIENT_ID = os.environ.get('COGNITO_CLIENT_ID')

def lambda_handler(event, context):
    try:
        if not event.get('body'):
            return {
                "statusCode": 400,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"mensaje": "El cuerpo de la petición no puede estar vacío"})
            }

        body = json.loads(event['body'])
        email = body.get('email')
        password = body.get('password')

        if not email or not password:
            return {
                "statusCode": 400,
                "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                "body": json.dumps({"mensaje": "Email y password son obligatorios"})
            }

        # Autenticar directo contra el User Pool de Cognito
        respuesta = cognito_client.initiate_auth(
            ClientId=COGNITO_CLIENT_ID,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': str(email),
                'PASSWORD': str(password)
            }
        )

        # Extraemos el IdToken (el JWT que contiene los custom attributes como alumnoId y rol)
        token = respuesta['AuthenticationResult']['IdToken']

        # Retornamos el token con la estructura exacta que espera tu loginManual en Angular
        return {
            "statusCode": 200,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({
                "token": token
            })
        }

    except cognito_client.exceptions.NotAuthorizedException:
        return {
            "statusCode": 401,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"mensaje": "Correo o contraseña incorrectos"})
        }
    except cognito_client.exceptions.UserNotConfirmedException:
        return {
            "statusCode": 400,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"mensaje": "La cuenta de usuario aún no ha sido confirmada"})
        }
    except Exception as e:
        print(f"Error en login: {e}")
        return {
            "statusCode": 500,
            "headers": { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            "body": json.dumps({"mensaje": "Error interno al iniciar sesión", "error": str(e)})
        }