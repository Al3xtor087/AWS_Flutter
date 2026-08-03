import { Component, inject, OnInit, Renderer2 } from '@angular/core';
import { Router, RouterLink, RouterLinkActive } from "@angular/router";
import { AuthService } from '../../services/auth-service/auth.service';
import { UpperCasePipe } from '@angular/common';

@Component({
  selector: 'app-navbar',
  imports: [RouterLink, RouterLinkActive],
  templateUrl: './navbar.html',
  styleUrl: './navbar.scss',
})
export class Navbar implements OnInit {
  private readonly router = inject(Router);
  private renderer = inject(Renderer2);
  public authService = inject(AuthService);

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

  onLogout() {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
