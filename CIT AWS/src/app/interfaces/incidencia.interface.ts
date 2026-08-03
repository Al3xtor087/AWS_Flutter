export interface IncidenciaInterface {
    id: number;
    fecha: string;
    alumnoId: number;
    alumnoNombre: string;
    numeroControl: string;
    carreraNombre: string;
    tipoParticipacion: string;
    horaAsistencia?: string | null;
    horaChecada?: string | null;
    hora?: string | null;
    tipoIncidenciaId: number;
    tipoIncidencia: string;
    estadoIncidencia?: string | null;
    horaEntrada: string | null;
    horaSalida: string | null;
    proyectoNombre: string | null;
    docenteResponsable: string | null;
    horaEntradaEsperada: string | null;
    horaSalidaEsperada: string | null;
}
