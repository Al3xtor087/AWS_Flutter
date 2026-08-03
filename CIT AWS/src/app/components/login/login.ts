import { Component, inject, OnDestroy, OnInit, Renderer2, signal } from '@angular/core';
import { CardInstitucional } from "../../shared/components/card-institucional/card-institucional";
import { ButtonPrimary } from "../../shared/components/button-primary/button-primary";
import { AuthService } from '../../core/services/auth-service/auth.service';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink } from "@angular/router";
import { ToastrService } from 'ngx-toastr';
import { NgClass } from '@angular/common';

@Component({
  selector: 'app-login',
  imports: [CardInstitucional, ButtonPrimary, ReactiveFormsModule, RouterLink, NgClass],
  templateUrl: './login.html',
  styleUrl: './login.scss',
})
// Componente que controla la pantalla principal de Inicio de Sesión.
// Maneja el acceso manual (correo/contraseña), el acceso con Google, y las preferencias visuales del usuario.
export class Login {

  // El constructor se ejecuta apenas se carga la pantalla de login.
  // Aquí recuperamos las preferencias de accesibilidad que el usuario guardó previamente en su navegador.
  constructor(private renderer: Renderer2) {
    // 1. Recupera y aplica el modo oscuro si estaba activado.
    const darkGuardado = localStorage.getItem('darkMode');
    if (darkGuardado !== null) {
      this.isDarkMode = darkGuardado === 'false';
      this.toggleDarkMode();
    }

    // 2. Recupera y aplica el tipo de letra (fuente) elegido por el usuario.
    const fuenteGuardada = localStorage.getItem('userFont');
    if (fuenteGuardada) {
      this.aplicarFuente(fuenteGuardada);
    }

    // 3. Recupera y aplica el tamaño de letra personalizado.
    const tamanoGuardado = localStorage.getItem('userFontSize');
    if (tamanoGuardado) {
      this.aplicarTamano(tamanoGuardado);
    }

    // Lógica UX: Si el usuario se equivocó de contraseña y empieza a escribir de nuevo,
    // borramos el mensaje de error automáticamente de la pantalla para que no estorbe.
    this.loginForm.valueChanges.subscribe(() => {
      if (this.errorLogin()) {
        this.errorLogin.set(null);
      }
    });
  }

  // Inyección de herramientas necesarias (Servicio de Autenticación, creador de formularios y alertas)
  private authService = inject(AuthService);
  private fb = inject(FormBuilder);
  private toastr = inject(ToastrService);

  // Signals reactivos para mostrar errores o estados de carga en el HTML en tiempo real
  public errorLogin = signal<string | null>(null);
  mostrarPass = signal(false); // Alterna la visibilidad de la contraseña en el input
  loadingGoogle = signal(false); // Activa la animación de carga mientras Google responde

  // Configuración del formulario reactivo con sus validaciones obligatorias
  loginForm = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]]
  });

  isDarkMode = false;

  // Cambia entre modo claro y oscuro, y guarda la elección en la memoria del navegador (localStorage)
  toggleDarkMode() {
    this.isDarkMode = !this.isDarkMode;
    const theme = this.isDarkMode ? 'dark' : 'light';
    localStorage.setItem('darkMode', String(this.isDarkMode));
    
    // Aplica el tema directamente al HTML principal mediante el Renderer2 de Angular
    this.renderer.setAttribute(document.documentElement, 'data-bs-theme', theme);
  }

  // Cambia la fuente (tipo de letra) de toda la aplicación
  changeFont(event: Event) {
    const select = event.target as HTMLSelectElement;
    const font = select.value;
    localStorage.setItem('userFont', font);
    this.renderer.setStyle(document.body, 'font-family', font === 'predeterminada' ? '' : font);
  }

  private aplicarFuente(font: string) {
    this.renderer.setStyle(document.body, 'font-family', font === 'predeterminada' ? '' : font);
  }

  // Cambia el tamaño de la letra de la aplicación (útil para accesibilidad visual)
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

  // Se ejecuta cuando el usuario presiona el botón de "Iniciar Sesión" (manual)
  onSubmit() {
    // Solo intentamos loguear si el formulario pasó las validaciones
    if (this.loginForm.valid) {
      this.errorLogin.set(null);

      // Llamamos al servicio de autenticación enviando el correo y contraseña capturados
      this.authService.loginManual(this.loginForm.value).subscribe({
        next: () => {
          this.toastr.success('¡Bienvenido de vuelta!', 'Inicio de sesión exitoso');
        },
        error: (err) => {
          // Si el backend rechaza el inicio de sesión, mostramos el error general en el HTML
          this.errorLogin.set('Correo o contraseña incorrectos. Inténtalo de nuevo.');

          // Si el error es 0 o mayor a 500, significa que el servidor backend 
          // está apagado o fallando internamente.
          if (err.status === 0 || err.status >= 500) {
            this.toastr.error('No se pudo conectar con el servidor. Intenta más tarde.', 'Error de red');
          } else {
            this.toastr.warning('Verifica tus credenciales', 'Acceso denegado');
          }
        }
      });
    }
  }

  // Dispara el flujo del servicio de autenticación para abrir la ventana emergente oficial de Google
  async loginGoogle() {
    this.loadingGoogle.set(true); // Enciende el spinner en el botón
    try {
      await this.authService.login();
    } catch (error) {
      this.toastr.error('Error al conectar con Google', 'Error');
    } finally {
      this.loadingGoogle.set(false); // Apaga el spinner sin importar si fue exitoso o cancelado
    }
  }

}