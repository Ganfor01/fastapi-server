import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/plan_semanal.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _productionBaseUrl = 'https://api.weekaiapp.es';

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) {
      return override;
    }
    if (kReleaseMode) {
      return _productionBaseUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final base = Uri.parse('$baseUrl$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return base;
    }
    return base.replace(queryParameters: queryParameters);
  }

  Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<PlanSemanal> obtenerPlanSemanal({int weekOffset = 0}) async {
    final response = await _client.get(
      _uri('/plan-semanal', {'week_offset': '$weekOffset'}),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el plan semanal');
    }
    return PlanSemanal.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
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
      headers: _headers(json: true),
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

  Future<String> registrarSesionHabito({
    required int id,
    required int weekOffset,
  }) async {
    final response = await _client.patch(
      _uri('/habitos/$id/registrar-sesion', {'week_offset': '$weekOffset'}),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(
          response.body,
          'No se pudo registrar la sesion del habito',
        ),
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final mensaje = data['mensaje'];
      if (mensaje is String && mensaje.isNotEmpty) {
        return mensaje;
      }
    } catch (_) {
      return 'Sesion de habito registrada';
    }

    return 'Sesion de habito registrada';
  }

  Future<void> crearEventoFijo({
    required String titulo,
    String? detalle,
    required String fecha,
    required String fechaFin,
    required int inicioMinutos,
    required int finMinutos,
    required int prioridad,
    Map<String, String> notasPorDia = const {},
  }) async {
    final response = await _client.post(
      _uri('/eventos-fijos'),
      headers: _headers(json: true),
      body: jsonEncode({
        'titulo': titulo,
        'detalle': detalle?.trim().isEmpty ?? true ? null : detalle!.trim(),
        'fecha': fecha,
        'fecha_fin': fechaFin,
        'inicio_minutos': inicioMinutos,
        'fin_minutos': finMinutos,
        'prioridad': prioridad,
        'notas_por_dia': notasPorDia,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(response.body, 'No se pudo crear el evento'),
      );
    }
  }

  Future<void> actualizarEventoFijo({
    required int id,
    required String titulo,
    String? detalle,
    required String fecha,
    required String fechaFin,
    required int inicioMinutos,
    required int finMinutos,
    required int prioridad,
    Map<String, String> notasPorDia = const {},
  }) async {
    final response = await _client.put(
      _uri('/eventos-fijos/$id'),
      headers: _headers(json: true),
      body: jsonEncode({
        'titulo': titulo,
        'detalle': detalle?.trim().isEmpty ?? true ? null : detalle!.trim(),
        'fecha': fecha,
        'fecha_fin': fechaFin,
        'inicio_minutos': inicioMinutos,
        'fin_minutos': finMinutos,
        'prioridad': prioridad,
        'notas_por_dia': notasPorDia,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(
          response.body,
          'No se pudo actualizar el evento',
        ),
      );
    }
  }

  Future<void> eliminarEventoFijo(int id) async {
    final response = await _client.delete(
      _uri('/eventos-fijos/$id'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(
          response.body,
          'No se pudo eliminar el evento',
        ),
      );
    }
  }

  Future<void> completarEventoFijo(int id) async {
    final response = await _client.patch(
      _uri('/eventos-fijos/$id/completar'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(
          response.body,
          'No se pudo marcar el evento como completado',
        ),
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
      headers: _headers(json: true),
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

  Future<String> guardarNotaDia({
    required String fecha,
    required String nota,
  }) async {
    final response = await _client.put(
      _uri('/notas-dia/$fecha'),
      headers: _headers(json: true),
      body: jsonEncode({'nota': nota}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(response.body, 'No se pudo guardar la nota del día'),
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final mensaje = data['mensaje'];
      if (mensaje is String && mensaje.isNotEmpty) {
        return mensaje;
      }
    } catch (_) {
      return 'Nota guardada';
    }

    return 'Nota guardada';
  }

  Future<PlanSemanal> planificarSemana({int weekOffset = 0}) async {
    final response = await _client.post(
      _uri('/planificar-semana', {'week_offset': '$weekOffset'}),
      headers: _headers(),
    );
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
    final response = await _client.patch(
      _uri('/bloques/$id/hecho'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudo marcar el bloque como hecho');
    }
  }

  Future<String> replanificarBloque(int id) async {
    final response = await _client.patch(
      _uri('/bloques/$id/fallado'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception(
        _extraerMensajeError(
          response.body,
          'No se pudo replanificar el bloque',
        ),
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final mensaje = data['mensaje'];
      if (mensaje is String && mensaje.isNotEmpty) {
        return mensaje;
      }
    } catch (_) {
      return 'Bloque replanificado';
    }

    return 'Bloque replanificado';
  }

  Future<void> completarObjetivo(int id) async {
    final response = await _client.patch(
      _uri('/objetivos/$id/completar'),
      headers: _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudo completar el objetivo');
    }
  }

  Future<void> eliminarObjetivo(int id) async {
    final response = await _client.delete(
      _uri('/objetivos/$id'),
      headers: _headers(),
    );
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
