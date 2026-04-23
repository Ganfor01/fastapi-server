class Habito {
  const Habito({
    required this.id,
    required this.titulo,
    required this.detalle,
    required this.prioridad,
    required this.duracionMinutos,
    required this.sesionesPorSemana,
    required this.sesionesCompletadasSemana,
    required this.completado,
  });

  final int id;
  final String titulo;
  final String? detalle;
  final int prioridad;
  final int duracionMinutos;
  final int sesionesPorSemana;
  final int sesionesCompletadasSemana;
  final bool completado;

  factory Habito.fromJson(Map<String, dynamic> json) {
    return Habito(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      detalle: json['detalle'] as String?,
      prioridad: json['prioridad'] as int? ?? 3,
      duracionMinutos: json['duracion_minutos'] as int? ?? 60,
      sesionesPorSemana: json['sesiones_por_semana'] as int? ?? 1,
      sesionesCompletadasSemana: json['sesiones_completadas_semana'] as int? ?? 0,
      completado: json['completado'] as bool? ?? false,
    );
  }
}
