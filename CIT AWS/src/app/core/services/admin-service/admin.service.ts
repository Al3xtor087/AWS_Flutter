import { HttpClient } from '@angular/common/http';
import { inject, Injectable, signal } from '@angular/core';
import { tap } from 'rxjs';
import { environment } from '../../../../environments/environment.development';

@Injectable({
  providedIn: 'root',
})
// Servicio dedicado exclusivamente a las tareas del panel de administración.
// Maneja la consulta de usuarios, asignación de roles y la vinculación de cuentas.
export class AdminService {
  private http = inject(HttpClient);
  private API_URL = environment.api;

  // Signals para manejar el estado reactivo.
  // Al usar Signals, cuando estas listas se actualizan, la tabla en tu HTML se actualiza automáticamente.
  public usuarios = signal<any[]>([]);
  public alumnosDisponibles = signal<any[]>([]);

  // Llama al backend para traer la lista de todos los usuarios registrados y sus roles actuales.
  cargarUsuarios() {
    this.http.get<any[]>(`${this.API_URL}usuarios`).subscribe({
      next: (data) => this.usuarios.set(data),
      error: (err) => console.error('Error cargando usuarios', err)
    });
  }

  // Trae la lista de alumnos que existen en la base de datos pero que aún no tienen una cuenta de sistema vinculada.
  cargarAlumnosSinCuenta() {
    this.http.get<any[]>(`${this.API_URL}alumnos`).subscribe({
      next: (data) => this.alumnosDisponibles.set(data)
    });
  }

  // Permite cambiar los permisos de un usuario (por ejemplo, ascenderlo de ALUMNO a ADMINISTRADOR).
  cambiarRol(email: string, nuevoRol: string) {
    return this.http.put(`${this.API_URL}admin/cambiar-rol`, { email, nuevoRol });
  }

  // Enlaza una cuenta de correo (Identity) con un registro de alumno real de la base de datos.
  // ✅ CORRECCIÓN: El ID del alumno es un UUID (string), no un número.
  vincularAlumno(email: string, alumnoId: string) {
    return this.http.put<any>(`${this.API_URL}admin/vincular-alumno`, { email, alumnoId }).pipe(
      // 🚀 Usamos tap para interceptar la respuesta y actualizar la tabla del frontend
      // sin afectar al componente que llama al método.
      tap(usuarioActualizado => {
        this.usuarios.update(listaUsuarios => {
          // Buscamos el índice del usuario que acabamos de vincular
          const index = listaUsuarios.findIndex(u => u.email === email);
          // Si lo encontramos, lo reemplazamos con la versión actualizada que nos devolvió el backend
          if (index !== -1) listaUsuarios[index] = usuarioActualizado;
          return [...listaUsuarios];
        });
      })
    );
  }

  // Borra permanentemente la cuenta de un usuario del sistema utilizando su ID único.
  eliminarUsuario(id: string) {
    return this.http.delete(`${this.API_URL}admin/usuario/${id}`);
  }
}