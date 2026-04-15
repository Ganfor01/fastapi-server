class Objetivo {
  const Objetivo({
    required this.id,
    required this.titulo,
    required this.detalle,
    required this.tipo,
    required this.prioridad,
    required this.duracionMinutos,
    required this.sesionesPorSemana,
    required this.fechaLimite,
    required this.completado,
  });

  final int id;
  final String titulo;
  final String? detalle;
  final String tipo;
  final int prioridad;
  final int duracionMinutos;
  final int sesionesPorSemana;
  final String? fechaLimite;
  final bool completado;

  factory Objetivo.fromJson(Map<String, dynamic> json) {
    return Objetivo(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      detalle: json['detalle'] as String?,
      tipo: json['tipo'] as String,
      prioridad: json['prioridad'] as int,
      duracionMinutos: json['duracion_minutos'] as int,
      sesionesPorSemana: json['sesiones_por_semana'] as int,
      fechaLimite: json['fecha_limite'] as String?,
      completado: json['completado'] as bool? ?? false,
    );
  }
}
