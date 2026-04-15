class TareaFlexible {
  const TareaFlexible({
    required this.id,
    required this.titulo,
    required this.detalle,
    required this.prioridad,
    required this.duracionMinutos,
    required this.sesionesPorSemana,
    required this.fechaLimite,
    required this.completado,
  });

  final int id;
  final String titulo;
  final String? detalle;
  final int prioridad;
  final int duracionMinutos;
  final int sesionesPorSemana;
  final String? fechaLimite;
  final bool completado;

  factory TareaFlexible.fromJson(Map<String, dynamic> json) {
    return TareaFlexible(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      detalle: json['detalle'] as String?,
      prioridad: json['prioridad'] as int? ?? 3,
      duracionMinutos: json['duracion_minutos'] as int? ?? 60,
      sesionesPorSemana: json['sesiones_por_semana'] as int? ?? 1,
      fechaLimite: json['fecha_limite'] as String?,
      completado: json['completado'] as bool? ?? false,
    );
  }
}
