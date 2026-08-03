class Incidencia {
  final String id;
  final String fecha;
  final int alumnoId;
  final String alumnoNombre;
  final String numeroControl;
  final String carreraNombre;
  final String tipoParticipacion;
  final String horaAsistencia;
  final int tipoIncidenciaId;
  final String tipoIncidencia;

  final String? horaEntrada;
  final String? horaSalida;
  final String? proyectoNombre;
  final String? docenteResponsable;
  final String? horaEntradaEsperada;
  final String? horaSalidaEsperada;

  Incidencia({
    required this.id,
    required this.fecha,
    required this.alumnoId,
    required this.alumnoNombre,
    required this.numeroControl,
    required this.carreraNombre,
    required this.tipoParticipacion,
    required this.horaAsistencia,
    required this.tipoIncidenciaId,
    required this.tipoIncidencia,
    this.horaEntrada,
    this.horaSalida,
    this.proyectoNombre,
    this.docenteResponsable,
    this.horaEntradaEsperada,
    this.horaSalidaEsperada,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) {
    return Incidencia(
      id: json['id']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      alumnoId: json['alumnoId'] is int ? json['alumnoId'] as int : int.tryParse(json['alumnoId'].toString()) ?? 0,
      alumnoNombre: json['alumnoNombre']?.toString() ?? 'Sin nombre',
      numeroControl: json['numeroControl']?.toString() ?? 'Sin número',
      carreraNombre: json['carreraNombre']?.toString() ?? 'Sin carrera',
      tipoIncidencia: json['tipoIncidencia']?.toString() ?? 'Sin tipo',
      tipoIncidenciaId: json['tipoIncidenciaId'] is int ? json['tipoIncidenciaId'] as int : int.tryParse(json['tipoIncidenciaId'].toString()) ?? 0,
      horaAsistencia: json['horaAsistencia']?.toString() ?? '--:--',
      horaEntrada: json['horaEntrada']?.toString(),
      horaSalida: json['horaSalida']?.toString(),
      horaEntradaEsperada: json['horaEntradaEsperada']?.toString(),
      horaSalidaEsperada: json['horaSalidaEsperada']?.toString(),
      proyectoNombre: json['proyectoNombre']?.toString(),
      docenteResponsable: json['docenteResponsable']?.toString(),
      tipoParticipacion: json['tipoParticipacion']?.toString() ?? 'Sin participación',
    );
  }
}
