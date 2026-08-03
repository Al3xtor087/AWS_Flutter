import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { environment } from '../../../../environments/environment.development';
import { CarreraInterface } from '../../../interfaces/carrera.interface';

@Injectable({
  providedIn: 'root',
})
export class CarreraService {
  private readonly API_URL = environment.api;
  private http = inject(HttpClient);

  obtenerCarreras() {
    return this.http.get<CarreraInterface[]>(`${this.API_URL}carreras`);
  }
}
