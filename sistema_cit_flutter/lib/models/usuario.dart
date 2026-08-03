class Usuario {
  final String id;
  final String email;
  final String rol;
  final String? alumno; // Nombre del alumno
  final String? numeroControl;
  final String? alumnoId;

  Usuario({
    required this.id,
    required this.email,
    required this.rol,
    this.alumno,
    this.numeroControl,
    this.alumnoId,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? 'No email',
      rol: json['rol']?.toString() ?? 'No rol',
      // Si el objeto 'alumno' existe y es un mapa, extraemos sus propiedades.
      alumno: (json['alumno'] is Map)
          ? json['alumno']['nombreCompleto']?.toString()
          : json['alumno']?.toString(),
      numeroControl: (json['alumno'] is Map)
          ? json['alumno']['numeroControl']?.toString()
          : json['numeroControl']?.toString(),
      alumnoId: json['alumnoId']?.toString(),
    );
  }

  Usuario copyWith({
    String? rol,
    String? alumno,
    String? numeroControl,
    String? alumnoId,
  }) {
    return Usuario(
      id: id,
      email: email,
      rol: rol ?? this.rol,
      // Si no se provee un nuevo valor, se mantiene el existente.
      // Se usa `null` explícitamente si se quiere borrar el valor.
      alumno: alumno ?? this.alumno,
      numeroControl: numeroControl ?? this.numeroControl,
      alumnoId: alumnoId ?? this.alumnoId,
    );
  }
}