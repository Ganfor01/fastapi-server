class EventoFijo {
  const EventoFijo({
    required this.id,
    required this.titulo,
    required this.detalle,
    required this.fecha,
    required this.fechaFin,
    required this.nombreDia,
    required this.inicioMinutos,
    required this.finMinutos,
    required this.inicioHora,
    required this.finHora,
    required this.duracionMinutos,
    required this.prioridad,
    required this.completado,
    required this.notasPorDia,
  });

  final int id;
  final String titulo;
  final String? detalle;
  final String fecha;
  final String fechaFin;
  final String nombreDia;
  final int inicioMinutos;
  final int finMinutos;
  final String inicioHora;
  final String finHora;
  final int duracionMinutos;
  final int prioridad;
  final bool completado;
  final Map<String, String> notasPorDia;

  bool get esVariosDias => fechaFin != fecha;
  bool get esTodoElDia => inicioMinutos == 0 && finMinutos == 1440;
  int get totalNotas => notasPorDia.values.where((nota) => nota.trim().isNotEmpty).length;

  String get horarioLabel =>
      esVariosDias
          ? 'Varios días'
          : esTodoElDia
          ? 'Todo el día'
          : '$inicioHora - $finHora';

  factory EventoFijo.fromJson(Map<String, dynamic> json) {
    return EventoFijo(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      detalle: json['detalle'] as String?,
      fecha: json['fecha'] as String,
      fechaFin: json['fecha_fin'] as String? ?? json['fecha'] as String,
      nombreDia: json['nombre_dia'] as String? ?? '',
      inicioMinutos: json['inicio_minutos'] as int? ?? 0,
      finMinutos: json['fin_minutos'] as int? ?? 0,
      inicioHora: json['inicio_hora'] as String? ?? '',
      finHora: json['fin_hora'] as String? ?? '',
      duracionMinutos: json['duracion_minutos'] as int? ?? 0,
      prioridad: json['prioridad'] as int? ?? 3,
      completado: json['completado'] as bool? ?? false,
      notasPorDia: ((json['notas_por_dia'] as Map<String, dynamic>?) ?? {})
          .map((key, value) => MapEntry(key, value as String)),
    );
  }
}

