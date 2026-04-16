import 'bloque_plan.dart';
import 'disponibilidad.dart';
import 'evento_fijo.dart';
import 'habito.dart';
import 'objetivo.dart';

class PlanSemanal {
  const PlanSemanal({
    required this.objetivos,
    required this.habitos,
    required this.eventosFijos,
    required this.disponibilidad,
    required this.dias,
    required this.weekOffset,
    required this.semanaInicio,
    required this.estadisticas,
  });

  final List<Objetivo> objetivos;
  final List<Habito> habitos;
  final List<EventoFijo> eventosFijos;
  final List<Disponibilidad> disponibilidad;
  final List<DiaPlan> dias;
  final int weekOffset;
  final String semanaInicio;
  final EstadisticasPlan estadisticas;

  factory PlanSemanal.fromJson(Map<String, dynamic> json) {
    return PlanSemanal(
      objetivos: (json['objetivos'] as List<dynamic>? ?? [])
          .map((item) => Objetivo.fromJson(item as Map<String, dynamic>))
          .toList(),
      habitos: (json['habitos'] as List<dynamic>? ?? [])
          .map((item) => Habito.fromJson(item as Map<String, dynamic>))
          .toList(),
      eventosFijos: (json['eventos_fijos'] as List<dynamic>? ?? [])
          .map((item) => EventoFijo.fromJson(item as Map<String, dynamic>))
          .toList(),
      disponibilidad: (json['disponibilidad'] as List<dynamic>? ?? [])
          .map((item) => Disponibilidad.fromJson(item as Map<String, dynamic>))
          .toList(),
      dias: (json['dias'] as List<dynamic>? ?? [])
          .map((item) => DiaPlan.fromJson(item as Map<String, dynamic>))
          .toList(),
      weekOffset: json['week_offset'] as int? ?? 0,
      semanaInicio: json['semana_inicio'] as String? ?? '',
      estadisticas: EstadisticasPlan.fromJson(
        json['estadisticas'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class DiaPlan {
  const DiaPlan({
    required this.diaSemana,
    required this.nombreDia,
    required this.fecha,
    required this.bloques,
  });

  final int diaSemana;
  final String nombreDia;
  final String fecha;
  final List<BloquePlan> bloques;

  factory DiaPlan.fromJson(Map<String, dynamic> json) {
    return DiaPlan(
      diaSemana: json['dia_semana'] as int,
      nombreDia: json['nombre_dia'] as String,
      fecha: json['fecha'] as String,
      bloques: (json['bloques'] as List<dynamic>? ?? [])
          .map((item) => BloquePlan.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EstadisticasPlan {
  const EstadisticasPlan({
    required this.objetivosActivos,
    required this.bloquesPendientes,
    required this.bloquesHechos,
  });

  final int objetivosActivos;
  final int bloquesPendientes;
  final int bloquesHechos;

  factory EstadisticasPlan.fromJson(Map<String, dynamic> json) {
    return EstadisticasPlan(
      objetivosActivos: json['objetivos_activos'] as int? ?? 0,
      bloquesPendientes: json['bloques_pendientes'] as int? ?? 0,
      bloquesHechos: json['bloques_hechos'] as int? ?? 0,
    );
  }
}
