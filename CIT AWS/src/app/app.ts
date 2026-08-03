import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { NavigationEnd, Router, RouterOutlet } from '@angular/router';
import { Navbar } from './core/components/navbar/navbar';
import { filter, map } from 'rxjs';
import { toSignal } from '@angular/core/rxjs-interop';
import { PanelIncidencias } from './components/panel-incidencias/panel-incidencias';
import { Asistencia } from "./components/asistencia/asistencia";
import { AuthService } from './core/services/auth-service/auth.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Navbar, PanelIncidencias, Asistencia],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App implements OnInit {
  protected readonly title = signal('CIT');
  public readonly authService = inject(AuthService);
  private router = inject(Router);

  isLoading = signal(true);

  ngOnInit() {
    setTimeout(() => {
      const isLoggedIn = !!localStorage.getItem('token');

      if (isLoggedIn && this.router.url === '/login') {
        this.router.navigate(['/incidencias']);
      }

      this.isLoading.set(false);
    }, 500);
  }

  private currentUrl = toSignal(


    this.router.events.pipe(
      filter(event => event instanceof NavigationEnd),
      map(event => (event as NavigationEnd).urlAfterRedirects)
    ),
    { initialValue: '/' }
  );
  showNavbar = computed(() => {
    const url = this.currentUrl();
    return url !== '/login' && url !== '/register' && url !== '/asistencia' && url !== '/404';
  });


}
