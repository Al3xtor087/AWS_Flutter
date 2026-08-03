import { TestBed } from '@angular/core/testing';

import { TipoParticipacionService } from './tipo-participacion.service';

describe('TipoParticipacionService', () => {
  let service: TipoParticipacionService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(TipoParticipacionService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
