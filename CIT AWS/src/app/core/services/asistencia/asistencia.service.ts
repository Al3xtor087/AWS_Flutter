import { HttpClient, HttpHeaders } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { environment } from '../../../../environments/environment.development';
import { AsistenciaInterface } from '../../../interfaces/asistencia.interface';
import { AsistenciaCreacionInterface } from '../../../interfaces/asistencia-creacion.interface';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class AsistenciaService {
  private readonly API_URL = environment.api;
  private http = inject(HttpClient);

  registrarAsistencia(id: number): Observable<AsistenciaInterface> {
    const body: AsistenciaCreacionInterface = { alumnoId: id };
    
    // Recuperar el token del almacenamiento local
    const token = localStorage.getItem('token') || ''; 
    const headers = new HttpHeaders().set('Authorization', `Bearer ${token}`);

    return this.http.post<AsistenciaInterface>(`${this.API_URL}asistencias`, body, { headers });
  }
}