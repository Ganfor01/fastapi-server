import 'package:flutter/foundation.dart';

import '../models/bloque_plan.dart';
import '../models/evento_fijo.dart';
import '../models/habito.dart';
import '../models/objetivo.dart';
import '../models/plan_semanal.dart';
import '../models/tarea_flexible.dart';
import '../services/api_service.dart';
import '../widgets/dialogs/disponibilidad_dialog.dart';
import '../widgets/dialogs/evento_fijo_dialog.dart';
import '../widgets/dialogs/habito_dialog.dart';
import '../widgets/dialogs/tarea_flexible_dialog.dart';

class OrganizadorController extends ChangeNotifier {
  OrganizadorController({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  final Set<int> objetivosActualizando = <int>{};
  final Set<int> objetivosEliminando = <int>{};
  final Set<int> eventosActualizando = <int>{};
  final Set<int> eventosEliminando = <int>{};

  PlanSemanal? ultimoPlan;
  late Future<PlanSemanal> planFuture;
  late int diaSeleccionado;
  int pantallaSeleccionada = 0;

  void inicializar() {
    diaSeleccionado = DateTime.now().weekday - 1;
    recargarPlan();
  }

  void recargarPlan() {
    planFuture = _apiService.obtenerPlanSemanal();
    notifyListeners();
  }

  void cachearPlan(PlanSemanal plan) {
    ultimoPlan = plan;
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

  Future<void> crearTareaFlexible(TareaFlexibleData datos) async {
    await _apiService.crearTareaFlexible(
      titulo: datos.titulo,
      detalle: datos.detalle,
      fechaLimite: datos.fechaLimite,
      prioridad: datos.prioridad,
      duracionMinutos: datos.duracionMinutos,
      sesionesPorSemana: datos.sesionesPorSemana,
    );
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

  Future<void> crearEventoFijo(EventoFijoData datos) async {
    await _apiService.crearEventoFijo(
      titulo: datos.titulo,
      detalle: datos.detalle,
      fecha: datos.fecha,
      inicioMinutos: datos.inicioMinutos,
      finMinutos: datos.finMinutos,
      prioridad: datos.prioridad,
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
        inicioMinutos: datos.inicioMinutos,
        finMinutos: datos.finMinutos,
        prioridad: datos.prioridad,
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

  Future<void> guardarDisponibilidad(DisponibilidadData datos) async {
    await _apiService.guardarDisponibilidad(
      diasSeleccionados: datos.diasSeleccionados,
      inicioMinutos: datos.inicioMinutos,
      finMinutos: datos.finMinutos,
    );
    recargarPlan();
  }

  Future<void> planificarSemana() async {
    final plan = await _apiService.planificarSemana();
    ultimoPlan = plan;
    planFuture = Future.value(plan);
    notifyListeners();
  }

  Future<void> marcarBloqueHecho(BloquePlan bloque) async {
    await _apiService.marcarBloqueHecho(bloque.id);
    recargarPlan();
  }

  Future<void> replanificarBloque(BloquePlan bloque) async {
    await _apiService.replanificarBloque(bloque.id);
    recargarPlan();
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
      case 'fecha_limite':
        return 'Fecha limite';
      case 'habito':
        return 'Habito';
      case 'evento_fijo':
        return 'Evento fijo';
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
      'Miercoles',
      'Jueves',
      'Viernes',
      'Sabado',
      'Domingo',
    ];
    final nombreDia = nombresDias[fecha.weekday - 1];
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$nombreDia - $dia/$mes';
  }

  Objetivo objetivoDesdeTareaFlexible(TareaFlexible tarea) {
    return Objetivo(
      id: tarea.id,
      titulo: tarea.titulo,
      detalle: tarea.detalle,
      tipo: 'fecha_limite',
      prioridad: tarea.prioridad,
      duracionMinutos: tarea.duracionMinutos,
      sesionesPorSemana: tarea.sesionesPorSemana,
      fechaLimite: tarea.fechaLimite,
      completado: tarea.completado,
    );
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
