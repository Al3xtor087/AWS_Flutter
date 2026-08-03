import { Component, inject, OnInit, Renderer2, signal } from '@angular/core';
import { AsistenciaService } from '../../core/services/asistencia/asistencia.service';
import { AuthService } from '../../core/services/auth-service/auth.service';
import { Router } from '@angular/router';
import { AsistenciaInterface } from '../../interfaces/asistencia.interface';
import { SlicePipe } from '@angular/common';
import { CardInstitucional } from '../../shared/components/card-institucional/card-institucional';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-asistencia',
  imports: [SlicePipe, CardInstitucional],
  templateUrl: './asistencia.html',
  styleUrl: './asistencia.scss',
})
export class Asistencia implements OnInit {

  private readonly router = inject(Router);
  private readonly _asistenciaService = inject(AsistenciaService)
  private readonly _authService = inject(AuthService);
  private readonly toastr = inject(ToastrService);

  public ultimoRegistro = signal<AsistenciaInterface | null>(null);

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

  marcarEntrada() {
    const perfil = this._authService.userProfile();
    console.log("🚀 El objeto perfil completo es:", perfil);

    const id = perfil?.alumnoId;
    console.log("🆔 El ID que Angular le va a mandar a la Lambda es:", id);
    if (id) {
      this._asistenciaService.registrarAsistencia(id).subscribe({
        next: (datos) => {
          this.ultimoRegistro.set(datos);

          this.toastr.success('Tu registro se ha guardado correctamente.', '¡Asistencia Marcada!');

          setTimeout(() => {
            this.cerrarSesion();
          }, 30000);
        },
        error: (err) => {
          const mensajeAPI = err.error?.mensaje || 'Hubo un problema al registrar tu asistencia. Intenta de nuevo.';
          this.toastr.error(mensajeAPI, 'Error de Registro');
        }
      });
    } else {
      this.toastr.warning(
        'Tu cuenta no tiene un estudiante vinculado. Pide a tu administrador que la configure.',
        'Acción denegada'
      );
    }
  }

  cerrarSesion() {
    this._authService.logout();
    this.router.navigate(['/login']);
  }

}
