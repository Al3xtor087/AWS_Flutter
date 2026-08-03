import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PanelIncidencias } from './panel-incidencias';
import { IncidenciaInterface } from '../../interfaces/incidencia.interface';

describe('PanelIncidencias', () => {
  let component: PanelIncidencias;
  let fixture: ComponentFixture<PanelIncidencias>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PanelIncidencias],
    }).compileComponents();

    fixture = TestBed.createComponent(PanelIncidencias);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('debe mostrar la hora de checada cuando viene en horaChecada', () => {
    const incidencia = {
      id: 1,
      fecha: '2026-07-12',
      alumnoId: 1,
      alumnoNombre: 'Ana',
      numeroControl: '12345',
      carreraNombre: 'Sistemas',
      tipoParticipacion: 'Asistente',
      horaChecada: '2026-07-12T09:15:00',
      tipoIncidenciaId: 1,
      tipoIncidencia: 'Retardo',
      horaEntrada: null,
      horaSalida: null,
      proyectoNombre: 'Proyecto',
      docenteResponsable: 'Docente',
      horaEntradaEsperada: '08:30',
      horaSalidaEsperada: '18:00'
    } as IncidenciaInterface;

    const resultado = component['obtenerHoraRegistro'](incidencia);

    expect(resultado).toBe('09:15:00');
  });

  it('debe actualizar localmente el tipo de incidencia tras justificar', () => {
    const incidencia = {
      id: 1,
      fecha: '2026-07-12',
      alumnoId: 1,
      alumnoNombre: 'Ana',
      numeroControl: '12345',
      carreraNombre: 'Sistemas',
      tipoParticipacion: 'Asistente',
      tipoIncidenciaId: 1,
      tipoIncidencia: 'Retardo',
      horaEntrada: null,
      horaSalida: null,
      proyectoNombre: 'Proyecto',
      docenteResponsable: 'Docente',
      horaEntradaEsperada: '08:30',
      horaSalidaEsperada: '18:00'
    } as IncidenciaInterface;

    component.incidencias.set([incidencia]);
    component.incidenciaSeleccionada = incidencia;

    component['actualizarIncidenciaLocal'](1, {
      incidencia: {
        id: 1,
        estadoIncidencia: 'JUSTIFICADA',
        tipoIncidencia: { id: 5, nombre: 'Justificado' }
      }
    });

    expect(component.incidencias()[0].tipoIncidencia).toBe('Justificado');
    expect(component.incidencias()[0].tipoIncidenciaId).toBe(5);
    expect(component.incidenciaSeleccionada?.tipoIncidencia).toBe('Justificado');
  });
});
