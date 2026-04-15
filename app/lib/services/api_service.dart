import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/plan_semanal.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) {
      return override;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<PlanSemanal> obtenerPlanSemanal() async {
    final response = await _client.get(_uri('/plan-semanal'));
    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el plan semanal');
    }
    return PlanSemanal.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> crearObjetivo({
    required String titulo,
    required String tipo,
    String? detalle,
    String? fechaLimite,
    required int prioridad,
    required int duracionMinutos,
    required int sesionesPorSemana,
  }) async {
    final response = await _client.post(
      _uri('/objetivos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titulo': titulo,
        'detalle': detalle?.trim().isEmpty ?? true ? null : detalle!.trim(),
        'tipo': tipo,
        'prioridad': prioridad,
        'duracion_minutos': duracionMinutos,
        'sesiones_por_semana': sesionesPorSemana,
        'fecha_limite': fechaLimite,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(response.body, 'No se pudo crear el objetivo'),
      );
    }
  }

  Future<void> crearTareaFlexible({
    required String titulo,
    String? detalle,
    required String fechaLimite,
    required int prioridad,
    required int duracionMinutos,
    required int sesionesPorSemana,
  }) async {
    final response = await _client.post(
      _uri('/tareas-flexibles'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titulo': titulo,
        'detalle': detalle?.trim().isEmpty ?? true ? null : detalle!.trim(),
        'fecha_limite': fechaLimite,
        'prioridad': prioridad,
        'duracion_minutos': duracionMinutos,
        'sesiones_por_semana': sesionesPorSemana,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(response.body, 'No se pudo crear la tarea flexible'),
      );
    }
  }

  Future<void> crearHabito({
    required String titulo,
    String? detalle,
    required int prioridad,
    required int duracionMinutos,
    required int sesionesPorSemana,
  }) async {
    final response = await _client.post(
      _uri('/habitos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titulo': titulo,
        'detalle': detalle?.trim().isEmpty ?? true ? null : detalle!.trim(),
        'prioridad': prioridad,
        'duracion_minutos': duracionMinutos,
        'sesiones_por_semana': sesionesPorSemana,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(response.body, 'No se pudo crear el habito'),
      );
    }
  }

  Future<void> crearEventoFijo({
    required String titulo,
    String? detalle,
    required String fecha,
    required int inicioMinutos,
    required int finMinutos,
    required int prioridad,
  }) async {
    final response = await _client.post(
      _uri('/eventos-fijos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titulo': titulo,
        'detalle': detalle?.trim().isEmpty ?? true ? null : detalle!.trim(),
        'fecha': fecha,
        'inicio_minutos': inicioMinutos,
        'fin_minutos': finMinutos,
        'prioridad': prioridad,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(response.body, 'No se pudo crear el evento fijo'),
      );
    }
  }

  Future<void> actualizarEventoFijo({
    required int id,
    required String titulo,
    String? detalle,
    required String fecha,
    required int inicioMinutos,
    required int finMinutos,
    required int prioridad,
  }) async {
    final response = await _client.put(
      _uri('/eventos-fijos/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titulo': titulo,
        'detalle': detalle?.trim().isEmpty ?? true ? null : detalle!.trim(),
        'fecha': fecha,
        'inicio_minutos': inicioMinutos,
        'fin_minutos': finMinutos,
        'prioridad': prioridad,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(
          response.body,
          'No se pudo actualizar el evento fijo',
        ),
      );
    }
  }

  Future<void> eliminarEventoFijo(int id) async {
    final response = await _client.delete(_uri('/eventos-fijos/$id'));
    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(response.body, 'No se pudo eliminar el evento fijo'),
      );
    }
  }

  Future<void> guardarDisponibilidad({
    required List<int> diasSeleccionados,
    required int inicioMinutos,
    required int finMinutos,
  }) async {
    final response = await _client.post(
      _uri('/disponibilidad'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'slots': diasSeleccionados
            .map(
              (dia) => {
                'dia_semana': dia,
                'inicio_minutos': inicioMinutos,
                'fin_minutos': finMinutos,
              },
            )
            .toList(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(
          response.body,
          'No se pudo guardar la disponibilidad',
        ),
      );
    }
  }

  Future<PlanSemanal> planificarSemana() async {
    final response = await _client.post(_uri('/planificar-semana'));
    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(response.body, 'No se pudo planificar la semana'),
      );
    }
    return PlanSemanal.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> marcarBloqueHecho(int id) async {
    final response = await _client.patch(_uri('/bloques/$id/hecho'));
    if (response.statusCode != 200) {
      throw Exception('No se pudo marcar el bloque como hecho');
    }
  }

  Future<void> replanificarBloque(int id) async {
    final response = await _client.patch(_uri('/bloques/$id/fallado'));
    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(response.body, 'No se pudo replanificar el bloque'),
      );
    }
  }

  Future<void> completarObjetivo(int id) async {
    final response = await _client.patch(_uri('/objetivos/$id/completar'));
    if (response.statusCode != 200) {
      throw Exception('No se pudo completar el objetivo');
    }
  }

  Future<void> eliminarObjetivo(int id) async {
    final response = await _client.delete(_uri('/objetivos/$id'));
    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(response.body, 'No se pudo eliminar el objetivo'),
      );
    }
  }

  String _extraerMensajeError(String body, String fallback) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    } catch (_) {
      return fallback;
    }
    return fallback;
  }
}
