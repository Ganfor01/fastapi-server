import 'package:flutter/foundation.dart';

import '../models/bloque_plan.dart';
import '../models/evento_fijo.dart';
import '../models/habito.dart';
import '../models/objetivo.dart';
import '../models/plan_semanal.dart';
import '../services/api_service.dart';
import '../widgets/dialogs/disponibilidad_dialog.dart';
import '../widgets/dialogs/evento_fijo_dialog.dart';
import '../widgets/dialogs/habito_dialog.dart';

class OrganizadorController extends ChangeNotifier {
  OrganizadorController({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  final Set<int> objetivosActualizando = <int>{};
  final Set<int> objetivosEliminando = <int>{};
  final Set<int> habitosRegistrando = <int>{};
  final Set<int> eventosCompletando = <int>{};
  final Set<int> eventosActualizando = <int>{};
  final Set<int> eventosEliminando = <int>{};
  final Set<String> notasGuardando = <String>{};
  final Map<int, int> _sesionesHabitoOptimistas = <int, int>{};
  final Map<int, bool> _eventosCompletadosOptimistas = <int, bool>{};

  PlanSemanal? ultimoPlan;
  late Future<PlanSemanal> planFuture;
  late int diaSeleccionado;
  int pantallaSeleccionada = 0;
  int weekOffset = 0;

  void inicializar() {
    diaSeleccionado = DateTime.now().weekday - 1;
    recargarPlan();
  }

  void recargarPlan() {
    planFuture = _apiService.obtenerPlanSemanal(weekOffset: weekOffset);
    notifyListeners();
  }

  void cachearPlan(PlanSemanal plan) {
    ultimoPlan = plan;
    weekOffset = plan.weekOffset;
    for (final habito in plan.habitos) {
      final optimista = _sesionesHabitoOptimistas[habito.id];
      if (optimista == null) {
        continue;
      }
      if (habito.sesionesCompletadasSemana >= optimista) {
        _sesionesHabitoOptimistas.remove(habito.id);
      }
    }
    for (final evento in plan.eventosFijos) {
      final optimista = _eventosCompletadosOptimistas[evento.id];
      if (optimista == null) {
        continue;
      }
      if (evento.completado == optimista) {
        _eventosCompletadosOptimistas.remove(evento.id);
      }
    }
  }

  void asegurarDiaSeleccionadoValido(PlanSemanal plan) {
    if (diaSeleccionado >= plan.dias.length) {
      diaSeleccionado = 0;
    }
  }

  void seleccionarPantalla(int index) {
    pantallaSeleccionada = index;
    notifyListeners();
  }

  void seleccionarDia(int dia) {
    diaSeleccionado = dia;
    notifyListeners();
  }

  void irASemanaActual() {
    if (weekOffset == 0) {
      return;
    }
    weekOffset = 0;
    diaSeleccionado = DateTime.now().weekday - 1;
    recargarPlan();
  }

  void cambiarSemana(int delta) {
    weekOffset += delta;
    diaSeleccionado = 0;
    recargarPlan();
  }

  void irAFecha(DateTime fecha) {
    final hoy = DateTime.now();
    final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);
    final destino = DateTime(fecha.year, fecha.month, fecha.day);
    final inicioSemanaActual = hoyNormalizado.subtract(
      Duration(days: hoyNormalizado.weekday - 1),
    );
    final inicioSemanaDestino = destino.subtract(
      Duration(days: destino.weekday - 1),
    );

    weekOffset =
        inicioSemanaDestino.difference(inicioSemanaActual).inDays ~/ 7;
    diaSeleccionado = destino.weekday - 1;
    recargarPlan();
  }

  Future<void> crearHabito(HabitoData datos) async {
    await _apiService.crearHabito(
      titulo: datos.titulo,
      detalle: datos.detalle,
      prioridad: datos.prioridad,
      duracionMinutos: datos.duracionMinutos,
      sesionesPorSemana: datos.sesionesPorSemana,
    );
    recargarPlan();
  }

  Future<String?> registrarSesionHabito(Habito habito) async {
    if (habitosRegistrando.contains(habito.id)) {
      return null;
    }

    final sesionesPrevias = sesionesCompletadasHabito(habito);
    habitosRegistrando.add(habito.id);
    _sesionesHabitoOptimistas[habito.id] = (
      sesionesPrevias + 1
    ).clamp(0, habito.sesionesPorSemana);
    notifyListeners();

    try {
      final mensaje = await _apiService.registrarSesionHabito(
        id: habito.id,
        weekOffset: weekOffset,
      );
      recargarPlan();
      return mensaje;
    } catch (_) {
      _sesionesHabitoOptimistas[habito.id] = sesionesPrevias;
      rethrow;
    } finally {
      habitosRegistrando.remove(habito.id);
      notifyListeners();
    }
  }

  int sesionesCompletadasHabito(Habito habito) {
    return _sesionesHabitoOptimistas[habito.id] ?? habito.sesionesCompletadasSemana;
  }

  Future<void> crearEventoFijo(EventoFijoData datos) async {
    await _apiService.crearEventoFijo(
      titulo: datos.titulo,
      detalle: datos.detalle,
      fecha: datos.fecha,
      fechaFin: datos.fechaFin,
      inicioMinutos: datos.inicioMinutos,
      finMinutos: datos.finMinutos,
      prioridad: datos.prioridad,
      notasPorDia: datos.notasPorDia,
    );
    recargarPlan();
  }

  Future<void> actualizarEventoFijo({
    required EventoFijo evento,
    required EventoFijoData datos,
  }) async {
    eventosActualizando.add(evento.id);
    notifyListeners();

    try {
      await _apiService.actualizarEventoFijo(
        id: evento.id,
        titulo: datos.titulo,
        detalle: datos.detalle,
        fecha: datos.fecha,
        fechaFin: datos.fechaFin,
        inicioMinutos: datos.inicioMinutos,
        finMinutos: datos.finMinutos,
        prioridad: datos.prioridad,
        notasPorDia: datos.notasPorDia,
      );
      recargarPlan();
    } finally {
      eventosActualizando.remove(evento.id);
      notifyListeners();
    }
  }

  Future<void> eliminarEventoFijo(EventoFijo evento) async {
    eventosEliminando.add(evento.id);
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await _apiService.eliminarEventoFijo(evento.id);
      recargarPlan();
    } catch (_) {
      eventosEliminando.remove(evento.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> completarEventoFijo(EventoFijo evento) async {
    if (eventosCompletando.contains(evento.id)) {
      return;
    }

    final estadoPrevio = completadoEvento(evento);
    eventosCompletando.add(evento.id);
    _eventosCompletadosOptimistas[evento.id] = !estadoPrevio;
    notifyListeners();

    try {
      await _apiService.completarEventoFijo(evento.id);
      recargarPlan();
    } catch (_) {
      _eventosCompletadosOptimistas[evento.id] = estadoPrevio;
      rethrow;
    } finally {
      eventosCompletando.remove(evento.id);
      notifyListeners();
    }
  }

  bool completadoEvento(EventoFijo evento) {
    return _eventosCompletadosOptimistas[evento.id] ?? evento.completado;
  }

  Future<void> guardarDisponibilidad(DisponibilidadData datos) async {
    await _apiService.guardarDisponibilidad(
      diasSeleccionados: datos.diasSeleccionados,
      inicioMinutos: datos.inicioMinutos,
      finMinutos: datos.finMinutos,
    );
    recargarPlan();
  }

  Future<String?> guardarNotaDia({
    required String fecha,
    required String nota,
  }) async {
    if (notasGuardando.contains(fecha)) {
      return null;
    }

    notasGuardando.add(fecha);
    notifyListeners();

    try {
      final mensaje = await _apiService.guardarNotaDia(
        fecha: fecha,
        nota: nota,
      );
      recargarPlan();
      return mensaje;
    } finally {
      notasGuardando.remove(fecha);
      notifyListeners();
    }
  }

  Future<void> planificarSemana() async {
    final plan = await _apiService.planificarSemana(weekOffset: weekOffset);
    ultimoPlan = plan;
    planFuture = Future.value(plan);
    weekOffset = plan.weekOffset;
    notifyListeners();
  }

  Future<void> marcarBloqueHecho(BloquePlan bloque) async {
    await _apiService.marcarBloqueHecho(bloque.id);
    recargarPlan();
  }

  Future<String?> replanificarBloque(BloquePlan bloque) async {
    final mensaje = await _apiService.replanificarBloque(bloque.id);
    recargarPlan();
    if (mensaje != 'Bloque replanificado') {
      return mensaje;
    }
    return null;
  }

  Future<void> completarObjetivo(Objetivo objetivo) async {
    if (objetivosActualizando.contains(objetivo.id)) {
      return;
    }

    objetivosActualizando.add(objetivo.id);
    notifyListeners();

    try {
      await _apiService.completarObjetivo(objetivo.id);
      recargarPlan();
    } finally {
      objetivosActualizando.remove(objetivo.id);
      notifyListeners();
    }
  }

  Future<void> eliminarObjetivo(Objetivo objetivo) async {
    objetivosEliminando.add(objetivo.id);
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await _apiService.eliminarObjetivo(objetivo.id);
      recargarPlan();
    } catch (_) {
      objetivosEliminando.remove(objetivo.id);
      notifyListeners();
      rethrow;
    }
  }

  String tipoLabel(String tipo) {
    switch (tipo) {
      case 'habito':
        return 'Hábito';
      case 'evento_fijo':
        return 'Evento';
      default:
        return 'Bloque';
    }
  }

  String fechaBonita(String fechaIso) {
    final fecha = DateTime.tryParse(fechaIso);
    if (fecha == null) {
      return fechaIso;
    }
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes';
  }

  String fechaConDiaBonita(String fechaIso) {
    final fecha = DateTime.tryParse(fechaIso);
    if (fecha == null) {
      return fechaIso;
    }
    const nombresDias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final nombreDia = nombresDias[fecha.weekday - 1];
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$nombreDia - $dia/$mes';
  }

  String fechaRangoBonito(String fechaInicioIso, String fechaFinIso) {
    if (fechaInicioIso == fechaFinIso) {
      return fechaConDiaBonita(fechaInicioIso);
    }
    return '${fechaBonita(fechaInicioIso)} - ${fechaBonita(fechaFinIso)}';
  }

  String rangoSemanaBonito(PlanSemanal plan) {
    if (plan.dias.isEmpty) {
      return '';
    }
    final inicio = plan.dias.first.fecha;
    final fin = plan.dias.last.fecha;
    return '${fechaBonita(inicio)} - ${fechaBonita(fin)}';
  }

  String mesSemanaBonito(PlanSemanal plan) {
    if (plan.dias.isEmpty) {
      return '';
    }
    final inicio = DateTime.tryParse(plan.dias.first.fecha);
    final fin = DateTime.tryParse(plan.dias.last.fecha);
    if (inicio == null || fin == null) {
      return '';
    }
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final mesInicio = meses[inicio.month - 1];
    final mesFin = meses[fin.month - 1];
    return mesInicio == mesFin
        ? mesInicio
        : '$mesInicio - $mesFin';
  }

  Objetivo objetivoDesdeHabito(Habito habito) {
    return Objetivo(
      id: habito.id,
      titulo: habito.titulo,
      detalle: habito.detalle,
      tipo: 'habito',
      prioridad: habito.prioridad,
      duracionMinutos: habito.duracionMinutos,
      sesionesPorSemana: habito.sesionesPorSemana,
      fechaLimite: null,
      completado: habito.completado,
    );
  }
}

