import { HttpClient, HttpParams } from '@angular/common/http';
import { computed, inject, Injectable, signal } from '@angular/core';
import { environment } from '../../../../environments/environment.development';
import { IncidenciaInterface } from '../../../interfaces/incidencia.interface';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
// Servicio encargado de la comunicación con el backend para todo lo relacionado a las incidencias.
export class IncidenciaService {
  private readonly API_URL = environment.api;
  private http = inject(HttpClient);

  // Signal reactivo que almacena la lista de incidencias. 
  // Cuando este valor cambia, la tabla en la interfaz gráfica se actualiza automáticamente.
  public incidencias = signal<IncidenciaInterface[]>([]);

  // Pide al backend todas las incidencias de una fecha específica y actualiza el Signal.
  // Si ocurre un error (como que no haya datos), vacía la lista para no mostrar datos fantasmas.
  obtenerIncidencias(fecha: string) {
    this.http.get<IncidenciaInterface[]>(`${this.API_URL}incidencias/fecha/${encodeURIComponent(fecha)}`).subscribe({
      next: (datos) => {
        this.incidencias.set(datos ?? []);
      },
      error: () => {
        this.incidencias.set([]);
      }
    });
  }

  // Envía una petición para cambiar el estado de una incidencia (por ejemplo, para justificarla).
  actualizarIncidencia(id: number) {
    return this.http.put<void>(`${this.API_URL}incidencias/${id}`, {});
  }

  // Solicita la eliminación permanente de una incidencia en la base de datos.
  eliminarIncidencia(id: number): Observable<void> {
    return this.http.delete<void>(`${this.API_URL}incidencias/${id}`);
  }

  // Trae la información ya agrupada desde el backend para poder dibujar las gráficas del dashboard.
  getGraficaTipo(fecha: string, tipo: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.API_URL}incidencias/grafica-por-tipo?fechaSeleccionada=${fecha}&tipoId=${tipo}`);
  }

  // Buscador avanzado: Construye dinámicamente la URL con los filtros que el administrador haya seleccionado.
  getFiltrado(buscar?: string, carreraId?: number, proyectoId?: number, tipoParticipacionId?: number, fecha?: string) {
    let params = new HttpParams();
    
    // Solo agrega a la URL los filtros que realmente tienen un valor
    if (buscar) params = params.set('buscar', buscar);
    if (carreraId) params = params.set('carreraId', carreraId);
    if (proyectoId) params = params.set('proyectoId', proyectoId);
    if (tipoParticipacionId) params = params.set('tipoParticipacionId', tipoParticipacionId);
    if (fecha) params = params.set('fecha', fecha);

    // Ejecuta la petición enviando el paquete de parámetros armados
    return this.http.get<IncidenciaInterface[]>(`${this.API_URL}incidencias/listado`, { params });
  }
  
}