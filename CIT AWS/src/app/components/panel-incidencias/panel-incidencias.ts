import { Component, computed, inject, OnInit, signal } from '@angular/core';
import { IncidenciaService } from '../../core/services/incidencia-service/incidencia.service';
import { CardInstitucional } from "../../shared/components/card-institucional/card-institucional";
import { GraficaIncidencias } from "./components/grafica-incidencias/grafica-incidencias";
import { IncidenciaInterface } from '../../interfaces/incidencia.interface';
import { ToastrService } from 'ngx-toastr';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { CarreraService } from '../../core/services/carrera-service/carrera.service';
import { ProyectoService } from '../../core/services/proyecto-service/proyecto.service';
import { TipoParticipacionService } from '../../core/services/tipo-participacion-service/tipo-participacion.service';
import { CarreraInterface } from '../../interfaces/carrera.interface';
import { ProyectoInterface } from '../../interfaces/proyecto.interface';
import { ParticipacionInterface } from '../../interfaces/participacion.interface';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

@Component({
  selector: 'app-panel-incidencias',
  imports: [CardInstitucional, GraficaIncidencias, ReactiveFormsModule],
  templateUrl: './panel-incidencias.html',
  styleUrl: './panel-incidencias.scss',
})
// Componente principal del Dashboard Administrativo.
// Orquesta los filtros de búsqueda, la paginación, las gráficas y las acciones sobre las incidencias.
export class PanelIncidencias implements OnInit {
  public esMovil = signal(false);

  // Inicializa la fecha por defecto para buscar las incidencias del día de ayer.
  fechaFiltro = signal<string>((() => {
    const fecha = new Date();
    // const fecha = new Date(2026, 3, 23, 10, 30, 0);
    fecha.setDate(fecha.getDate() - 1);
    return fecha.toISOString().split('T')[0];
  })());

  // Inyección de dependencias
  private _incidenciaService = inject(IncidenciaService);
  private _carreraService = inject(CarreraService);
  private _proyectoService = inject(ProyectoService);
  private _tipoParticipacionService = inject(TipoParticipacionService);
  private toastr = inject(ToastrService);

  // Conexión directa al Signal del servicio. Si el servicio se actualiza, la tabla se actualiza sola.
  public incidencias = this._incidenciaService.incidencias;

  // Estado local para controlar la tabla y la paginación
  public paginaActual = signal(1);
  public itemsPorPagina = signal(8);
  public enTransicion = signal(false);
  confirmandoJustificacion = signal(false);

  // Controles reactivos (Reactive Forms) para capturar lo que el usuario escribe o selecciona
  buscarControl = new FormControl('');
  carreraControl = new FormControl('');
  proyectoControl = new FormControl('');
  tipoPartControl = new FormControl('');

  fRetardo = new FormControl(true);
  fFalta = new FormControl(true);
  fSalida = new FormControl(true);
  fFueraHorario = new FormControl(true);
  fJustificado = new FormControl(true);

  terminoBusqueda = signal<string>('');
  proyectos = signal<any[]>([]);
  carreras = signal<any[]>([]);
  tiposParticipacion = signal<any[]>([]);

  // Propiedades calculadas. 
  datosRetardos = computed(() => this.generarDatosGrafica('Retardo'));
  datosFaltas = computed(() => this.generarDatosGrafica('Falta'));
  datosSalidas = computed(() => this.generarDatosGrafica('Salida Anticipada'));
  datosFueraHorario = computed(() => this.generarDatosGrafica('Fuera de Horario'));

  labelsRetardos = signal<string[]>([]);
  labelsFaltas = signal<string[]>([]);
  labelsSalidas = signal<string[]>([]);
  labelsFueraHorario = signal<string[]>([]);

  totalRetardos = computed(() =>
    this.incidencias().filter(i => i.tipoIncidencia === 'Retardo').length
  );

  totalFaltas = computed(() =>
    this.incidencias().filter(i => i.tipoIncidencia === 'Falta').length
  );

  totalSalidas = computed(() =>
    this.incidencias().filter(i => i.tipoIncidencia === 'Salida Anticipada').length
  );

  totalFueraHorario = computed(() =>
    this.incidencias().filter(i => i.tipoIncidencia === 'Fuera de Horario').length
  );

  public proyecto: ProyectoInterface | null = null;
  public carrera: CarreraInterface | null = null;
  public participacion: ParticipacionInterface | null = null;

  constructor() {
    // Optimización de busqueda: Escucha lo que el usuario teclea.
    // debounceTime(400): Espera 400 milisegundos después de que el usuario deja de escribir 
    // antes de ir al backend. Esto evita saturar la base de datos con una petición por cada letra.
    this.buscarControl.valueChanges.pipe(
      debounceTime(400),
      distinctUntilChanged(),
      takeUntilDestroyed() // Previene fugas de memoria si el componente se destruye
    ).subscribe(() => this.cargarDatos());

    // Escuchadores para los combos desplegables
    this.carreraControl.valueChanges.subscribe(() => this.cargarDatos());
    this.proyectoControl.valueChanges.subscribe(() => this.cargarDatos());
    this.tipoPartControl.valueChanges.subscribe(() => this.cargarDatos());

    // Escuchadores para los checkboxes rápidos
    const filtrosCheck = [this.fRetardo, this.fFalta, this.fSalida, this.fFueraHorario, this.fJustificado];
    filtrosCheck.forEach(control => {
      control.valueChanges.subscribe(() => this.cargarDatos());
    });
  }

  ngOnInit() {
    // Al abrir la pantalla, cargamos los datos con la fecha por defecto
    const fechaAyer = this.fechaFiltro();
    this._incidenciaService.obtenerIncidencias(fechaAyer);

    const modalElement = document.getElementById('detalleIncidenciaModal');

    // nos aseguramos de limpiar la pantalla gris de fondo (backdrop) y devolverle el scroll a la página.
    modalElement?.addEventListener('hidden.bs.modal', () => {
      this.incidenciaSeleccionada = null;

      const backdrop = document.querySelector('.modal-backdrop');
      if (backdrop) {
        backdrop.remove();
      }

      document.body.classList.remove('modal-open');
      document.body.style.overflow = 'auto';
    });

    this.cargarCatalogos();
  }


  onFechaChange(event: Event) {
    const input = event.target as HTMLInputElement;
    const valor = input.value;

    if (valor) {
      this.fechaFiltro.set(valor);
      this.cargarDatos();
    }
  }

  // Corta la lista completa en pedazos pequeños para mostrar en la tabla según la página actual.
  public incidenciasPaginadas = computed(() => {
    const inicio = (this.paginaActual() - 1) * this.itemsPorPagina();
    const fin = inicio + this.itemsPorPagina();
    return this.incidencias().slice(inicio, fin);
  });

  public obtenerHoraRegistro(incidencia: IncidenciaInterface | null | undefined): string {
    if (!incidencia) {
      return '--:--';
    }

    const candidatos = [
      incidencia.horaChecada,
      incidencia.hora,
      incidencia.horaAsistencia,
      incidencia.horaEntrada,
      incidencia.horaSalida,
      incidencia.horaEntradaEsperada,
      incidencia.horaSalidaEsperada,
    ];

    for (const valor of candidatos) {
      if (!valor) {
        continue;
      }

      const texto = String(valor).trim();
      if (!texto) {
        continue;
      }

      if (texto.includes('T') || texto.includes(' ')) {
        const parteTiempo = texto.includes('T') ? texto.split('T')[1] : texto.split(' ')[1];
        if (parteTiempo) {
          return parteTiempo.split('.')[0];
        }
      }

      return texto.split('.')[0];
    }

    return '--:--';
  }

  public totalPaginas = computed(() =>
    Math.ceil(this.incidencias().length / this.itemsPorPagina())
  );

  // Lógica de transformación: Convierte el listado crudo de incidencias en arreglos numéricos 
  // segmentados por hora, para que el componente de la gráfica pueda interpretarlos y dibujarlos.
  private generarDatosGrafica(tipo: string): number[] {
    const lista = this.incidencias().filter(i => i.tipoIncidencia === tipo);
    const conteo = new Array(14).fill(0);

    lista.forEach(inc => {
      let horaStr: string | null = null;

      // Evaluamos la hora según la lógica de incidencias reportada
      if (tipo === 'Retardo') {
        // CASO 1: Usar hora de entrada
        horaStr = inc.horaEntrada;
      } else if (tipo === 'Salida Anticipada') {
        // CASO 3: Usar hora de salida
        horaStr = inc.horaSalida;
      } else if (tipo === 'Fuera de Horario') {
        // CASO 5: Cualquiera disponible
        horaStr = inc.horaEntrada || inc.horaSalida;
      } else if (tipo === 'Falta') {
        // CASOS 2 y 4: Faltas por entrada tardía o salida temprana
        if (inc.horaEntrada && !inc.horaSalida) {
          horaStr = inc.horaEntrada;
        } else if (!inc.horaEntrada && inc.horaSalida) {
          horaStr = inc.horaSalida;
        } else if (inc.horaEntrada && inc.horaSalida) {
          horaStr = inc.horaAsistencia || inc.horaEntrada;
        } else {
          horaStr = inc.horaEntradaEsperada;
        }
      }

      // Respaldo global por si algún dato esperado viene vacío
      if (!horaStr) {
        horaStr = inc.horaAsistencia || inc.horaEntrada || inc.horaSalida || inc.horaEntradaEsperada;
      }

      if (horaStr) {
        let hora = -1;
        
        // Forzamos conversión a string para que no falle el tipado o si el backend manda un objeto
        const horaString = String(horaStr);

        if (horaString.includes('T') || horaString.includes(' ')) {
          const timePart = horaString.includes('T') ? horaString.split('T')[1] : horaString.split(' ')[1];
          if (timePart) {
            hora = parseInt(timePart.split(':')[0], 10);
          }
        } else {
          // Formato de hora simple "08:30"
          hora = parseInt(horaString.split(':')[0], 10);
        }

        // Agrupamos en los bloques horarios desde las 7 AM hasta las 8 PM (20:00)
        if (hora >= 7 && hora <= 20) {
          conteo[hora - 7]++;
        }
      }
    });
    return conteo;
  }

  refrescarDatos() {
    this.cargarDatos();
    this.toastr.info('Actualizando listado de incidencias...', 'Sincronizando');
  }

  incidenciaEnEspera = signal<number | null>(null);

  solicitarEliminar(id: number) {
    this.incidenciaEnEspera.set(id);
  }

  cancelarEliminar() {
    this.incidenciaEnEspera.set(null);
  }

  confirmalEliminar(id: number) {
    this._incidenciaService.eliminarIncidencia(id).subscribe({
      next: () => {
        // Si el backend borra con éxito, quitamos el registro de la lista local sin recargar toda la página
        this.incidencias.update(list => list.filter(i => i.id !== id));
        this.incidenciaEnEspera.set(null);

        this.toastr.success('La incidencia ha sido eliminada correctamente.', 'Operación Exitosa');
      },
      error: (err) => {
        this.toastr.error('No se pudo eliminar el registro. Intenta de nuevo.', 'Error al Eliminar');
        this.incidenciaEnEspera.set(null);
      }
    });
  }

  public incidenciaSeleccionada: IncidenciaInterface | null = null;

  abrirDetalles(item: IncidenciaInterface): void {
    this.incidenciaSeleccionada = item;
    this.confirmandoJustificacion.set(false);

    const modalElement = document.getElementById('detalleIncidenciaModal');
    if (modalElement) {
      const modal = new (window as any).bootstrap.Modal(modalElement);
      modal.show();
    }
  }

  cerrarModal() {
    const modalElement = document.getElementById('detalleIncidenciaModal');
    if (modalElement) {
      const modalInstance = (window as any).bootstrap.Modal.getInstance(modalElement);

      if (modalInstance) {
        modalInstance.hide();
      } else {
        const newModal = new (window as any).bootstrap.Modal(modalElement);
        newModal.hide();
      }
    }
    this.confirmandoJustificacion.set(false);
  }

  private actualizarIncidenciaLocal(id: number, respuesta: any) {
    const incidenciaActualizada = respuesta?.incidencia;

    if (!incidenciaActualizada) {
      return;
    }

    const tipo = incidenciaActualizada?.tipoIncidencia ?? null;
    const tipoNombre = typeof tipo === 'string' ? tipo : tipo?.nombre;
    const tipoId = typeof tipo === 'string' ? null : tipo?.id;

    this.incidencias.update(lista => lista.map(item => {
      if (item.id !== id) {
        return item;
      }

      return {
        ...item,
        tipoIncidencia: tipoNombre ?? item.tipoIncidencia,
        tipoIncidenciaId: tipoId ?? item.tipoIncidenciaId,
        estadoIncidencia: incidenciaActualizada.estadoIncidencia ?? item.estadoIncidencia,
      };
    }));

    if (this.incidenciaSeleccionada?.id === id) {
      this.incidenciaSeleccionada = {
        ...this.incidenciaSeleccionada,
        tipoIncidencia: tipoNombre ?? this.incidenciaSeleccionada.tipoIncidencia,
        tipoIncidenciaId: tipoId ?? this.incidenciaSeleccionada.tipoIncidenciaId,
        estadoIncidencia: incidenciaActualizada.estadoIncidencia ?? this.incidenciaSeleccionada.estadoIncidencia,
      };
    }
  }

  justificar() {
    if (this.incidenciaSeleccionada) {
      this._incidenciaService.actualizarIncidencia(this.incidenciaSeleccionada.id).subscribe({
        next: (respuesta: any) => {
          this.actualizarIncidenciaLocal(this.incidenciaSeleccionada!.id, respuesta);
          this.cargarDatos();
          this.cerrarModal();
          this.toastr.success('La incidencia ha sido justificada correctamente.', 'Operación Exitosa');
        },
        error: (err) => {
          this.toastr.error('No se pudo comunicar con el servidor.', 'Error de Sistema');
        }
      });
    }
    this.confirmandoJustificacion.set(false);
  }

  // ESTRATEGIA DE FILTRADO HÍBRIDO:
  // 1. Envía los filtros fuertes (Texto, Combos y Fecha) al servidor para traer la data base.
  // 2. Aplica un filtro local (Javascript) para los checkboxes rápidos, ahorrando llamadas innecesarias al backend.
  cargarDatos() {
    const fecha = this.fechaFiltro();
    const buscar = this.buscarControl.value || '';
    const carreraId = this.carreraControl.value ? Number(this.carreraControl.value) : undefined;
    const proyectoId = this.proyectoControl.value ? Number(this.proyectoControl.value) : undefined;
    const tipoPartId = this.tipoPartControl.value ? Number(this.tipoPartControl.value) : undefined;

    this._incidenciaService.getFiltrado(buscar, carreraId, proyectoId, tipoPartId, fecha).subscribe({
      next: (res) => {
        // Filtro local según el estado de los checkboxes de la interfaz
        const filtradas = res.filter(i => {
          if (i.tipoIncidencia === 'Retardo' && !this.fRetardo.value) return false;
          if (i.tipoIncidencia === 'Falta' && !this.fFalta.value) return false;
          if (i.tipoIncidencia === 'Salida Anticipada' && !this.fSalida.value) return false;
          if (i.tipoIncidencia === 'Fuera de Horario' && !this.fFueraHorario.value) return false;
          if (i.tipoIncidencia === 'Justificado' && !this.fJustificado.value) return false;
          return true;
        });

        this.incidencias.set(filtradas);
        this.paginaActual.set(1); // Regresamos a la página 1 cada que se busca algo nuevo
      },
      error: (err) => {
        this.toastr.error('Hubo un problema al aplicar los filtros. Revisa tu conexión al servidor.', 'Error de Búsqueda');
      }
    });
  }

  cargarCatalogos() {
    this._carreraService.obtenerCarreras().subscribe(res => this.carreras.set(res));
    this._proyectoService.obtenerProyectos().subscribe(res => this.proyectos.set(res));
    this._tipoParticipacionService.obtenerTipoParticipacion().subscribe(res => this.tiposParticipacion.set(res));
  }

  limpiarFiltros() {
    // Usamos { emitEvent: false } para evitar que cada reseteo dispare una búsqueda individual a la API
    const config = { emitEvent: false };

    this.buscarControl.setValue('', config);
    this.carreraControl.setValue('', config);
    this.proyectoControl.setValue('', config);
    this.tipoPartControl.setValue('', config);

    this.fRetardo.setValue(true, config);
    this.fFalta.setValue(true, config);
    this.fSalida.setValue(true, config);
    this.fFueraHorario.setValue(true, config);
    this.fJustificado.setValue(true, config);

    this.terminoBusqueda.set('');
    this.paginaActual.set(1);

    // Hacemos una única llamada general al final
    this.cargarDatos();

    this.toastr.info('Se han restablecido los criterios de búsqueda.', 'Filtros Limpios');
  }

  anteriorPagina() {
    if (this.enTransicion() || this.paginaActual() === 1) return;
    this.ejecutarCambioPagina(this.paginaActual() - 1);
  }

  siguientePagina() {
    if (this.enTransicion() || this.paginaActual() === this.totalPaginas()) return;
    this.ejecutarCambioPagina(this.paginaActual() + 1);
  }

  // Previene que el usuario dé clics múltiples rápidos que puedan desfasar la vista,
  // bloqueando temporalmente la interfaz mientras ocurre la transición de página.
  private ejecutarCambioPagina(nuevaPagina: number) {
    // 1. Bloqueamos los botones
    this.enTransicion.set(true);

    // 2. Cambiamos la página
    this.paginaActual.set(nuevaPagina);

    // 3. Liberamos los botones después de 300 milisegundos (puedes ajustar este tiempo)
    setTimeout(() => {
      this.enTransicion.set(false);
    }, 300);
  }

}