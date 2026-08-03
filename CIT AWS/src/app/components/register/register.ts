import { Component, computed, inject, OnInit, Renderer2, signal } from '@angular/core';
import { ButtonPrimary } from '../../shared/components/button-primary/button-primary';
import { ReactiveFormsModule, FormBuilder, Validators, ValidationErrors, AbstractControl, ValidatorFn } from '@angular/forms';
import { AuthService } from '../../core/services/auth-service/auth.service';
import { CardInstitucional } from '../../shared/components/card-institucional/card-institucional';
import { CarreraService } from '../../core/services/carrera-service/carrera.service';
import { Router, RouterLink } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import { AdminService } from '../../core/services/admin-service/admin.service';
import { NgClass } from '@angular/common';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [ReactiveFormsModule, CardInstitucional, RouterLink, NgClass],
  templateUrl: './register.html',
  styleUrl: './register.scss',
})
// Componente encargado de la pantalla de Registro de nuevos alumnos.
// Implementa validaciones estrictas de contraseña, un buscador con autocompletado y opciones de accesibilidad.
export class Register implements OnInit {
  private authService = inject(AuthService);
  private adminService = inject(AdminService);
  private fb = inject(FormBuilder);
  private router = inject(Router);
  private _carreraService = inject(CarreraService);
  private toastr = inject(ToastrService);
  private renderer = inject(Renderer2);

  public isDarkMode = false;

  // Variables reactivas (Signals) para controlar el estado de la interfaz gráfica
  loading = signal(false);
  busqueda = signal('');
  mostrarDropdown = signal(false);
  mostrarPass = signal(false);
  mostrarRepeatPass = signal(false);


  // Computed Signal: Filtra en tiempo real la lista de alumnos disponibles basándose en lo que el usuario escribe.
  alumnosFiltrados = computed(() => {
    const termino = this.busqueda().toLowerCase().trim();
    const listaCompleta = this.adminService.alumnosDisponibles(); //

    if (!termino) return listaCompleta;

    return listaCompleta.filter(a =>
      a.nombreCompleto.toLowerCase().includes(termino) ||
      a.numeroControl.toLowerCase().includes(termino)
    );
  });

  // Formulario reactivo para capturar los datos. 
  registerForm = this.fb.group({
    nombreCompleto: ['', [Validators.required]],
    // ✅ CORRECCIÓN: El ID del alumno es un UUID (string), no un número.
    alumnoId: [null as string | null], 
    numeroControl: ['', [Validators.required]],
    email: ['', [Validators.required, Validators.email]],
    password: ['', [
      Validators.required,
      Validators.minLength(6),
      Validators.pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>\-_]).+$/)
    ]],
    repeatPassword: ['', Validators.required]
  }, {
    // Se inyecta una validación personalizada a nivel de formulario para comparar que las contraseñas coincidan
    validators: passwordMatchValidator
  });

  // Extrae el valor actual de la contraseña escrita en el input
  get passValue(): string {
    return this.registerForm.get('password')?.value || '';
  }

  // Batería de Getters que evalúan en tiempo real si la contraseña cumple con los requisitos de seguridad.
  // Esto permite pintar de verde/rojo los indicadores visuales en el HTML instantáneamente.
  get reqMinLength(): boolean { return this.passValue.length >= 6; }
  get reqUpper(): boolean { return /[A-Z]/.test(this.passValue); }
  get reqLower(): boolean { return /[a-z]/.test(this.passValue); }
  get reqNumber(): boolean { return /[0-9]/.test(this.passValue); }
  get reqSymbol(): boolean { return /[!@#$%^&*(),.?":{}|<>\-_]/.test(this.passValue); }

  ngOnInit(): void {
    // Solicitamos al backend la lista de alumnos que aún no tienen cuenta
    this.adminService.cargarAlumnosSinCuenta();

    // Restauramos las preferencias de accesibilidad del usuario (Modo oscuro, tipo y tamaño de letra)
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

  // --- MÉTODOS DE ACCESIBILIDAD ---

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

  // --- MÉTODOS DEL BUSCADOR DE ALUMNOS (AUTOCOMPLETADO) ---

  onBusquedaInput(event: Event) {
    const input = event.target as HTMLInputElement;
    this.busqueda.set(input.value);
    this.mostrarDropdown.set(true); // Despliega la lista de opciones al escribir
  }

  // Cuando el usuario hace clic en un nombre de la lista, autocompleta los datos ocultos en el formulario
  seleccionarAlumno(alumno: any) {
    this.busqueda.set(alumno.nombreCompleto);

    this.registerForm.patchValue({
      numeroControl: alumno.numeroControl,
      nombreCompleto: alumno.nombreCompleto,
      alumnoId: alumno.id // 👈 GUARDAMOS EL ID DEL ALUMNO
    });

    this.mostrarDropdown.set(false);
  }

  abrirDropdown() {
    this.mostrarDropdown.set(true);
  }

  cerrarDropdown() {
    // Retraso de 200ms para permitir que el clic en 'seleccionarAlumno' se registre antes de ocultar la lista
    setTimeout(() => this.mostrarDropdown.set(false), 200);
  }

  // --- ENVÍO DE DATOS AL BACKEND ---

  onSubmit() {
    if (this.registerForm.valid) {
      this.loading.set(true);

      // 🚀 CORRECCIÓN: Construimos un objeto limpio para enviar a la API.
      // La API de registro solo necesita los datos de la cuenta y el ID del alumno a vincular.
      // Los campos 'nombreCompleto' y 'numeroControl' son solo para la UI y no deben enviarse.
      const datosEnvio = {
        email: this.registerForm.value.email,
        password: this.registerForm.value.password,
        alumnoId: this.registerForm.value.alumnoId
      };
      
      this.authService.registroAlumno(datosEnvio).subscribe({
        next: () => {
          this.toastr.success('Cuenta creada correctamente, ya puedes iniciar sesión.', '¡Registro Exitoso!');
          this.router.navigate(['/login']); // Redirigimos al usuario al login tras el éxito
        },
        error: (err) => {
          // Captura mensajes de error específicos desde el backend (ej. "El correo ya existe")
          const mensajeError = err.error?.mensaje || 'Hubo un problema al procesar tu registro. Intenta de nuevo.';
          this.toastr.error(mensajeError, 'Error en el registro');
          this.loading.set(false);
          // 🚀 CORRECCIÓN: Si el registro falla, es probable que el backend haya vinculado al alumno
          // pero no haya podido crear la cuenta. Recargamos la lista de alumnos disponibles
          // para que el frontend refleje la realidad del backend y el alumno "desaparezca"
          // de la lista, evitando que se intente registrar de nuevo.
          this.adminService.cargarAlumnosSinCuenta();
        }
      });
    } 
  }
}

// Revisa ambos campos de contraseña a la vez para asegurar que sean idénticos.
// Si no coinciden, inyecta un error de tipo 'passwordMismatch' en el formulario.
export const passwordMatchValidator: ValidatorFn = (control: AbstractControl): ValidationErrors | null => {
  const password = control.get('password');
  const repeatPassword = control.get('repeatPassword');

  return password && repeatPassword && password.value !== repeatPassword.value
    ? { passwordMismatch: true }
    : null;
};