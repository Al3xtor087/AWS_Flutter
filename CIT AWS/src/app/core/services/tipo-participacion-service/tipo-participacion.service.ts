import { inject, Injectable } from '@angular/core';
import { ParticipacionInterface } from '../../../interfaces/participacion.interface';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../environments/environment.development';

@Injectable({
  providedIn: 'root',
})
export class TipoParticipacionService {
  private readonly API_URL = environment.api;
  private http = inject(HttpClient);

  obtenerTipoParticipacion() {
    return this.http.get<ParticipacionInterface[]>(`${this.API_URL}tipo-participacion`);
  }
}
