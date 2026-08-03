import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { OAuthService } from 'angular-oauth2-oidc';
import { environment } from '../../environments/environment.development';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const oauthService = inject(OAuthService);
  const API_URL = environment.api;

  // 1. Si la petición va al login, no le metas nada y déjala pasar limpia
  if (req.url.includes('/auth/login')) {
    return next(req);
  }

  // Medida de seguridad: Verificar si va a nuestro propio backend
  if (!req.url.startsWith(API_URL)) {
    return next(req);
  }
  
  // 2. Intentamos obtener primero el token de Google, y si no hay, el del localStorage
  const idToken = oauthService.getIdToken() || localStorage.getItem('token');

  // Si cualquiera de los dos tokens existe, clonamos con la cabecera
  if (idToken) {
    const cloned = req.clone({
      setHeaders: {
        Authorization: `Bearer ${idToken}`
      }
    });
    return next(cloned);
  }

  // Si no hay token activo, continúa sin cabecera
  return next(req);
};