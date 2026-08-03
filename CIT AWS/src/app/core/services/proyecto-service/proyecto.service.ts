import { inject, Injectable } from '@angular/core';
import { environment } from '../../../../environments/environment.development';
import { HttpClient } from '@angular/common/http';
import { ProyectoInterface } from '../../../interfaces/proyecto.interface';

@Injectable({
  providedIn: 'root',
})
export class ProyectoService {
  private readonly API_URL = environment.api;
  private http = inject(HttpClient);

  obtenerProyectos() {
    return this.http.get<ProyectoInterface[]>(`${this.API_URL}proyectos`);
  }
}
