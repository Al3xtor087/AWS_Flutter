import { inject, Injectable, signal } from '@angular/core';
import { OAuthService } from 'angular-oauth2-oidc';
import { googletAuthConfig } from '../../../config/auth.config';
import { HttpClient, HttpHeaders } from '@angular/common/http'; // 👈 Importamos HttpHeaders
import { environment } from '../../../../environments/environment.development';
import { Router } from '@angular/router';
import { Observable } from 'rxjs/internal/Observable';
import { tap } from 'rxjs/internal/operators/tap';
import { switchMap } from 'rxjs/internal/operators/switchMap';
import { filter } from 'rxjs/internal/operators/filter';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private readonly API_URL = environment.api;
  private http = inject(HttpClient);
  private oauthService = inject(OAuthService);
  private router = inject(Router);

  #isAuthenticated = signal<boolean>(false);
  public isAuthenticated = this.#isAuthenticated.asReadonly();
  public userProfile = signal<any>(null);

  constructor() {
    this.configurarLogin();
    this.recuperarSesion();
  }

  // Se ejecuta si el usuario presiona F5. 
  // Aquí también aseguramos el tiro inyectando el header manualmente.
  private recuperarSesion() {
    const token = localStorage.getItem('token');
    if (token) {
      this.#isAuthenticated.set(true);

      if (!this.userProfile()) {
        const headers = new HttpHeaders({
          'Authorization': `Bearer ${token}`
        });

        this.http.get(`${this.API_URL}auth/perfil`, { headers }).subscribe({
          next: (perfil) => this.userProfile.set(perfil),
          error: () => this.logout()
        });
      }
    }
  }

  // 🔥 SOLUCIÓN: Quitamos '?token=' de la URL e inyectamos el HttpHeader de forma segura
  private cargarPerfilYRedirigir(): Observable<any> {
    const tokenId = localStorage.getItem('token');
    
    const headers = new HttpHeaders({
      'Authorization': `Bearer ${tokenId}`
    });

    return this.http.get(`${this.API_URL}auth/perfil`, { headers }).pipe(
      tap({
        next: (perfil: any) => {
          this.userProfile.set(perfil);
          this.#isAuthenticated.set(true);
          const rutaActual = window.location.pathname;

          if (rutaActual === '/login' || rutaActual === '/' || rutaActual === '/register') {
            let destino = '';
            if (perfil.rol === 'ADMINISTRADOR') {
              destino = '/incidencias';
            } else if (perfil.rol === 'ALUMNO') {
              destino = '/asistencia';
            } else {
              destino = '/404';
            }
            this.router.navigate([destino]);
          }
        },
        error: (err) => {
          this.logout();
        }
      })
    );
  }

  loginManual(credenciales: any): Observable<any> {
    return this.http.post(`${this.API_URL}auth/login`, credenciales).pipe(
      tap((res: any) => localStorage.setItem('token', res.token)),
      switchMap(() => this.cargarPerfilYRedirigir())
    );
  }

  registroAlumno(datos: any): Observable<any> {
    return this.http.post(`${this.API_URL}auth/registrar`, datos);
  }

  private async configurarLogin() {
    const tokenManual = localStorage.getItem('token');

    if (tokenManual) {
      this.cargarPerfilYRedirigir().subscribe();
      return;
    }

    this.oauthService.configure(googletAuthConfig);

    this.oauthService.events
      .pipe(
        filter(e => e.type === 'token_received'),
        switchMap(() => {
          const googleToken = this.oauthService.getIdToken();
          return this.http.post(`${this.API_URL}auth/google`, { idToken: googleToken });
        }),
        tap((res: any) => {
          localStorage.setItem('token', res.token);
        }),
        switchMap(() => this.cargarPerfilYRedirigir())
      )
      .subscribe();

    await this.oauthService.loadDiscoveryDocumentAndTryLogin();

    if (this.oauthService.hasValidAccessToken() && !localStorage.getItem('token')) {
      const googleToken = this.oauthService.getIdToken();

      this.http.post(`${this.API_URL}auth/google`, { idToken: googleToken }).pipe(
        tap((res: any) => localStorage.setItem('token', res.token)),
        switchMap(() => this.cargarPerfilYRedirigir())
      ).subscribe();
    }
  }

  obtenerIdDelToken(): number | null {
    const token = localStorage.getItem('token');
    if (!token) return null;

    try {
      const base64Url = token.split('.')[1];
      const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(window.atob(base64).split('').map(function (c) {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
      }).join(''));

      const payload = JSON.parse(jsonPayload);
      return payload.id ? Number(payload.sub) : null;
    } catch (error) {
      return null;
    }
  }

  login() {
    sessionStorage.setItem('identity_provider', 'google');
    this.oauthService.configure(googletAuthConfig);
    this.oauthService.loadDiscoveryDocumentAndTryLogin().then(() => {
      this.oauthService.initCodeFlow();
    });
  }

  logout() {
    this.cerrarModal();
    this.oauthService.logOut();
    this.#isAuthenticated.set(false);
    this.userProfile.set(null);
    localStorage.removeItem('token');
    sessionStorage.clear();
    this.router.navigate(['/login']);
  }

  private cerrarModal() {
    const modalElement = document.getElementById('cerrarSesionModal');
    if (modalElement) {
      const modalInstance = (window as any).bootstrap.Modal.getInstance(modalElement);
      modalInstance?.hide();
    }
  }

  get identityClaims() {
    return this.oauthService.getIdentityClaims();
  }

  estaLogueado(): boolean {
    return this.oauthService.hasValidAccessToken() || !!localStorage.getItem('token');
  }
}