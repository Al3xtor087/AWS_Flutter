import { Component, inject, Renderer2 } from '@angular/core';
import { CardInstitucional } from "../../shared/components/card-institucional/card-institucional";
import { Router } from '@angular/router';
import { AuthService } from '../../core/services/auth-service/auth.service';

@Component({
  selector: 'app-not-found',
  imports: [],
  templateUrl: './not-found.html',
  styleUrl: './not-found.scss',
})
export class NotFound {
  private router = inject(Router);
  public authService = inject(AuthService);
  private renderer = inject(Renderer2);

  public isDarkMode = false;

  ngOnInit() {
    const darkGuardado = localStorage.getItem('darkMode');
    if (darkGuardado !== null) {
      this.isDarkMode = darkGuardado === 'false';
      this.toggleDarkMode();
    }

    const fuenteGuardada = localStorage.getItem('userFont');
    if (fuenteGuardada) {
      this.aplicarFuente(fuenteGuardada);
    }

    const tamanoGuardado = localStorage.getItem('userFontSize');
    if (tamanoGuardado) {
      this.aplicarTamano(tamanoGuardado);
    }
  }

  toggleDarkMode() {
    this.isDarkMode = !this.isDarkMode;
    const theme = this.isDarkMode ? 'dark' : 'light';
    localStorage.setItem('darkMode', String(this.isDarkMode));
    this.renderer.setAttribute(document.documentElement, 'data-bs-theme', theme);
  }

  changeFont(event: Event) {
    const select = event.target as HTMLSelectElement;
    const font = select.value;
    localStorage.setItem('userFont', font);
    this.renderer.setStyle(document.body, 'font-family', font === 'predeterminada' ? '' : font);
  }

  private aplicarFuente(font: string) {
    this.renderer.setStyle(document.body, 'font-family', font === 'predeterminada' ? '' : font);
  }

  changeFontSize(event: Event) {
    const size = (event.target as HTMLSelectElement).value;
    localStorage.setItem('userFontSize', size);
    this.aplicarTamano(size);
  }

  private aplicarTamano(size: string) {
    const sizes: { [key: string]: string } = {
      'small': '14px',
      'normal': '16px',
      'large': '20px'
    };
    this.renderer.setStyle(document.body, 'font-size', sizes[size]);
  }

  irAlInicio() {
    const rol = this.authService.userProfile()?.rol;

    if (rol === 'MAESTRO') {
      this.router.navigate(['/incidencias']);
    } else if (rol === 'ALUMNO') {
      this.router.navigate(['/asistencia']);
    } else {
      this.router.navigate(['/login']);
    }
  }

  cerrarSesion() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
