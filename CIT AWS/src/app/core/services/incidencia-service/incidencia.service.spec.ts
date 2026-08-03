import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';

import { IncidenciaService } from './incidencia.service';
import { environment } from '../../../../environments/environment.development';

describe('IncidenciaService', () => {
  let service: IncidenciaService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
    });
    service = TestBed.inject(IncidenciaService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should request incidencias from the fecha endpoint', () => {
    service.obtenerIncidencias('2026-07-14');

    const req = httpMock.expectOne(`${environment.api}incidencias/fecha/2026-07-14`);
    expect(req.request.method).toBe('GET');
    req.flush([]);
  });
});
