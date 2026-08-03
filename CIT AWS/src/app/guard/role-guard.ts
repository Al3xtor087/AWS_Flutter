import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../core/services/auth-service/auth.service';
import { toObservable } from '@angular/core/rxjs-interop';
import { filter, map, take } from 'rxjs';

// Guard funcional que actúa como el cadenero de las rutas en Angular.
// Protege las pantallas verificando que el usuario tenga sesión activa y el rol correcto.
export const roleGuard: CanActivateFn = (route, state) => { // Función flecha
  // Inyectamos las herramientas que vamos a usar
  const authService = inject(AuthService);
  const router = inject(Router);

  // Leemos qué rol exige la pantalla que intentan abrir (viene desde app.routes.ts)
  const rolEsperado = route.data['rol'];

  // Primer filtrp: Si no hay token en el navegador, mandamos al usuario a que inicie sesión
  if (!authService.estaLogueado()) {
    return router.parseUrl('/login');
    // return true;
  }

  // Segundo filtro: Si hay token, revisamos qué permisos tiene.
  return toObservable(authService.userProfile).pipe(

    // El filter pausa el Guard hasta que el perfil ya tenga datos reales (que ya no sea nulo)
    filter(perfil => perfil !== null), // Función flecha

    // El take(1) hace que una vez que recibimos el perfil, se cierre la suscripción 
    // para no gastar memoria innecesaria en el navegador.
    take(1),

    // Por último, ya con el perfil seguro, evaluamos si lo dejamos pasar
    map(perfil => {
      // Si el rol coincide con el esperado (ej. ADMINISTRADOR), le abrimos la puerta
      if (perfil?.rol === rolEsperado) {
        return true;
      } 

      // Si es un ALUMNO queriendo entrar a una ruta de admin, lo rebotamos a la página de error
      return router.parseUrl('/404');
    }) // Función flecha
  );
};