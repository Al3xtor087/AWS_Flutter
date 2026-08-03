class AlumnoDisponible {
  final String id;
  final String nombreCompleto;
  final String numeroControl;

  AlumnoDisponible({
    required this.id,
    required this.nombreCompleto,
    required this.numeroControl,
  });

  factory AlumnoDisponible.fromJson(Map<String, dynamic> json) {
    return AlumnoDisponible(
      id: json['id'],
      nombreCompleto: json['nombreCompleto'],
      numeroControl: json['numeroControl'],
    );
  }

  @override
  String toString() => nombreCompleto;
}