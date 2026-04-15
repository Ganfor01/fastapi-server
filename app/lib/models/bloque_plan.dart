class BloquePlan {
  const BloquePlan({
    required this.id,
    required this.objetivoId,
    required this.esFijo,
    required this.tituloObjetivo,
    required this.tipoObjetivo,
    required this.detalleObjetivo,
    required this.diaSemana,
    required this.nombreDia,
    required this.fecha,
    required this.inicioMinutos,
    required this.finMinutos,
    required this.inicioHora,
    required this.finHora,
    required this.duracionMinutos,
    required this.estado,
    required this.replanificado,
  });

  final int id;
  final int objetivoId;
  final bool esFijo;
  final String tituloObjetivo;
  final String tipoObjetivo;
  final String? detalleObjetivo;
  final int diaSemana;
  final String nombreDia;
  final String fecha;
  final int inicioMinutos;
  final int finMinutos;
  final String inicioHora;
  final String finHora;
  final int duracionMinutos;
  final String estado;
  final bool replanificado;

  factory BloquePlan.fromJson(Map<String, dynamic> json) {
    return BloquePlan(
      id: json['id'] as int,
      objetivoId: json['objetivo_id'] as int,
      esFijo: json['es_fijo'] as bool? ?? false,
      tituloObjetivo: json['titulo_objetivo'] as String,
      tipoObjetivo: json['tipo_objetivo'] as String? ?? '',
      detalleObjetivo: json['detalle_objetivo'] as String?,
      diaSemana: json['dia_semana'] as int,
      nombreDia: json['nombre_dia'] as String,
      fecha: json['fecha'] as String,
      inicioMinutos: json['inicio_minutos'] as int? ?? 0,
      finMinutos: json['fin_minutos'] as int? ?? 0,
      inicioHora: json['inicio_hora'] as String,
      finHora: json['fin_hora'] as String,
      duracionMinutos: json['duracion_minutos'] as int,
      estado: json['estado'] as String,
      replanificado: json['replanificado'] as bool? ?? false,
    );
  }
}
