class Tarea {
  const Tarea({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.completada,
    required this.fechaCreacion,
  });

  final int id;
  final String titulo;
  final String? descripcion;
  final bool completada;
  final DateTime fechaCreacion;

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      completada: json['completada'] as bool? ?? false,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
    );
  }
}
