import { AuthConfig } from 'angular-oauth2-oidc';
import { environment } from '../../environments/environment';

export const googletAuthConfig: AuthConfig = {
    issuer: 'https://accounts.google.com',

    redirectUri: window.location.origin,

    clientId: environment.googleClientId,
    
    scope: 'openid profile email',

    strictDiscoveryDocumentValidation: false,

    useSilentRefresh: true,
    showDebugInformation: true,

    customQueryParams: {
        prompt: 'select_account'
    }
}

export const cognitoAuthConfig: AuthConfig = {
    // El emisor debe apuntar a la ruta de tu User Pool en AWS
    issuer: 'https://cognito-idp.us-east-1.amazonaws.com/us-east-1_qRXCPRfAr', // 👈 Cambia la región si no es us-east-1 y pon tu User Pool ID

    // Redirecciona a la raíz de tu app tras loguearse (http://localhost:4200)
    redirectUri: window.location.origin,

    // Tu nuevo App Client ID que acabas de copiar
    clientId: '4j2jmr8chi2u1o89tdg1q661h8', // 👈 ¡Aquí pega tu App Client ID!
    
    // Los atributos estándar requeridos
    scope: 'openid profile email',

    // Cognito maneja sus metadatos de manera compatible con OpenID, desactivamos validación estricta
    strictDiscoveryDocumentValidation: false,

    showDebugInformation: true,
    
    responseType: 'code', // Requerido para flujo seguro PKCE en aplicaciones SPA
}

