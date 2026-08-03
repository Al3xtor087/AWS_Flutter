import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { AdminService } from '../../../core/services/admin-service/admin.service';
import { AuthService } from '../../../core/services/auth-service/auth.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-panel-admin',
  imports: [CommonModule, FormsModule],
  templateUrl: './panel-admin.html',
  styleUrl: './panel-admin.scss',
})
// Componente que controla la pantalla de Administración de Usuarios.
// Aquí el administrador puede ver las cuentas, cambiar roles, vincular alumnos y eliminar registros.
export class PanelAdmin implements OnInit {
  private adminService = inject(AdminService);
  private authService = inject(AuthService);
  private toastr = inject(ToastrService);

  // Estado del Componente (Signals)
  // Estas variables reactivas actualizan el HTML automáticamente cuando su valor cambia.
  public cargando = signal<boolean>(false);
  public error = signal<string>('');
  public filtroBusqueda = signal<string>('');
  public filtroRol = signal<string>('');

  // Signals para controlar qué datos se muestran dentro de las ventanas modales emergentes.
  public usuarioSeleccionado = signal<any>(null);
  public nuevoRol = signal<string>('ALUMNO');
  // ✅ CORRECCIÓN: El ID del alumno es un UUID (string), no un número.
  public alumnoIdVincular = signal<string | null>(null);

  public usuarioAEliminar = signal<any>(null);

  // Signals Computados (Derivados)
  // Son variables que se calculan automáticamente basándose en otros Signals.

  // Guarda el email de quien está usando el sistema en este momento 
  // para evitar que el administrador se quite los permisos a sí mismo por accidente.
  public emailActual = computed(() => this.authService.userProfile()?.email);

  // Lista de los alumnos que aún no tienen cuenta (para el modal de vinculación)
  public alumnosDisponibles = computed(() => this.adminService.alumnosDisponibles());

  // Lógica de filtrado reactiva para la tabla.
  // Filtra los usuarios en la pantalla (usando Javascript) sin necesidad de volver a consultar la API.
  public usuariosFiltrados = computed(() => {
    const lista = this.adminService.usuarios();
    const busqueda = this.filtroBusqueda().toLowerCase();
    const rol = this.filtroRol();

    return lista.filter(u => {
      const coincideBusqueda = u.email.toLowerCase().includes(busqueda) ||
        (u.alumno && u.alumno.toLowerCase().includes(busqueda)) || (u.numeroControl && u.numeroControl.toLowerCase().includes(busqueda));
      const coincideRol = rol === '' || u.rol === rol;

      return coincideBusqueda && coincideRol;
    });
  });

  ngOnInit(): void {
    this.cargarDatosIniciales();
  }

  cargarDatosIniciales() {
    this.cargarUsuarios();
    this.adminService.cargarAlumnosSinCuenta();
  }

  // Pide al servicio que traiga la lista de usuarios y maneja un pequeño retraso visual (cargando).
  cargarUsuarios() {
    this.cargando.set(true);
    this.error.set('');

    this.adminService.cargarUsuarios();

    setTimeout(() => this.cargando.set(false), 500);
  }

  // Prepara los datos del usuario que se va a editar y los carga en el modal de Cambio de Rol.
  prepararCambioRol(usuario: any) {
    this.usuarioSeleccionado.set(usuario);
    this.nuevoRol.set(usuario.rol);
  }

  // Envía la petición al backend para guardar el nuevo rol asignado al usuario.
  guardarCambioRol() {
    const u = this.usuarioSeleccionado();
    if (!u) return;

    this.adminService.cambiarRol(u.email, this.nuevoRol()).subscribe({
      next: () => {
        this.cargarUsuarios(); // Recargamos la lista
        this.usuarioSeleccionado.set(null);
        this.toastr.success(`Rol cambiado a ${this.nuevoRol()} exitosamente.`, 'Rol Actualizado');
      },
      error: (err) => {
        this.error.set('No se pudo actualizar el rol del usuario.');

        this.toastr.error('Hubo un problema al cambiar el rol. Intenta de nuevo.', 'Error');
      }
    });
  }

  // Lógica de Vinculación (Cuentas Google)

  // Carga la información en el modal cuando el administrador quiere enlazar un correo a un alumno físico.
  prepararVinculacion(usuario: any) {
    this.usuarioSeleccionado.set(usuario);
    this.alumnoIdVincular.set(null);
    this.adminService.cargarAlumnosSinCuenta();
  }

  // Confirma la vinculación enviando el correo del usuario y el ID del alumno al backend.
  guardarVinculacion() {
    const u = this.usuarioSeleccionado();
    const alumnoId = this.alumnoIdVincular();

    if (!u || !alumnoId) return;

    this.adminService.vincularAlumno(u.email, alumnoId).subscribe({
      next: () => {
        // 🚀 CORRECCIÓN: Se elimina la llamada a `cargarUsuarios()`.
        // El método `vincularAlumno` en el servicio ya usa `tap` para actualizar reactivamente
        // la lista de usuarios, lo cual es más eficiente y evita problemas de sincronización.
        this.adminService.cargarAlumnosSinCuenta();
        this.usuarioSeleccionado.set(null);

        this.toastr.success('La cuenta ha sido vinculada al estudiante.', 'Vinculación Exitosa');
      },
      error: (err) => {
        this.error.set('Error al vincular el alumno con esta cuenta.');

        this.toastr.error('No se pudo vincular la cuenta. Verifica los datos.', 'Error de Vinculación');
      }
    });
  }

  // Método de eliminación rápida (con la alerta nativa del navegador).
  eliminar(id: string) {
    if (confirm('¿Estás seguro de que deseas eliminar este usuario? Esta acción no se puede deshacer.')) {
      this.adminService.eliminarUsuario(id).subscribe({
        next: () => {
          // Recargamos la lista para que desaparezca visualmente
          this.adminService.cargarUsuarios();
          this.toastr.warning("Usuario eliminado correctamente", "Usuario eliminado")
        },
        error: (err) => {
          this.toastr.error("Ha ocurrido un error al eliminar el usuario")
        }
      });
    }
  }

  // Carga el usuario en memoria para mostrar sus datos en un modal de confirmación más estructurado.
  prepararEliminacion(usuario: any) {
    this.usuarioAEliminar.set(usuario);
  }

  // Ejecuta la petición HTTP DELETE para borrar la cuenta de forma definitiva.
  confirmarEliminacion() {
    const u = this.usuarioAEliminar();
    if (!u) return;

    this.adminService.eliminarUsuario(u.id).subscribe({
      next: () => {
        this.cargarUsuarios(); // Recargamos la lista
        this.usuarioAEliminar.set(null); // Limpiamos la signal

        this.toastr.info('La cuenta de usuario ha sido eliminada permanentemente.', 'Usuario Eliminado');
      },
      error: (err) => {
        this.error.set('Ocurrió un error al intentar eliminar la cuenta.');
        // Toast de Error
        this.toastr.error('No se pudo eliminar el usuario. Es posible que tenga registros asociados.', 'Error al Eliminar');
      }
    });
  }
}