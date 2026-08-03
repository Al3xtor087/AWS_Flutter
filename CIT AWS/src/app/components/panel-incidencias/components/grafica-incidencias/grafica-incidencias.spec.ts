import { ComponentFixture, TestBed } from '@angular/core/testing';

import { GraficaIncidencias } from './grafica-incidencias';

describe('GraficaIncidencias', () => {
  let component: GraficaIncidencias;
  let fixture: ComponentFixture<GraficaIncidencias>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [GraficaIncidencias],
    }).compileComponents();

    fixture = TestBed.createComponent(GraficaIncidencias);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
