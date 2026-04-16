import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/organizador_controller.dart';
import '../models/bloque_plan.dart';
import '../models/evento_fijo.dart';
import '../models/objetivo.dart';
import '../models/plan_semanal.dart';
import '../utils/app_snackbar.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/disponibilidad_dialog.dart';
import '../widgets/dialogs/evento_fijo_dialog.dart';
import '../widgets/dialogs/habito_dialog.dart';
import '../widgets/error_state.dart';
import 'inicio_screen.dart';
import 'mi_semana_screen.dart';

class OrganizadorPage extends StatefulWidget {
  const OrganizadorPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeSelected,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeSelected;

  @override
  State<OrganizadorPage> createState() => _OrganizadorPageState();
}

class _OrganizadorPageState extends State<OrganizadorPage> {
  final OrganizadorController _controller = OrganizadorController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _agendaScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.inicializar();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _agendaScrollController.dispose();
    super.dispose();
  }

  Future<void> _crearHabito() async {
    final datos = await showDialog<HabitoData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const HabitoDialog(),
    );

    if (datos == null) {
      return;
    }

    try {
      await _controller.crearHabito(datos);
      _mostrarExito('Hábito creado');
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _crearEventoFijo() async {
    final datos = await showDialog<EventoFijoData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const EventoFijoDialog(),
    );

    if (datos == null) {
      return;
    }

    try {
      await _controller.crearEventoFijo(datos);
      _mostrarExito('Evento creado');
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _editarEventoFijo(EventoFijo evento) async {
    if (_controller.eventosActualizando.contains(evento.id)) {
      return;
    }

    final datos = await showDialog<EventoFijoData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EventoFijoDialog(eventoInicial: evento),
    );

    if (datos == null) {
      return;
    }

    try {
      await _controller.actualizarEventoFijo(evento: evento, datos: datos);
      _mostrarExito('Evento actualizado');
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _eliminarEventoFijo(EventoFijo evento) async {
    final confirmar = await ConfirmDialog.show(
      context,
      title: 'Eliminar evento',
      message:
          'Se borrará "${evento.titulo}" y dejará libre ese hueco en la agenda.',
    );

    if (!confirmar) {
      return;
    }

    HapticFeedback.mediumImpact();
    try {
      await _controller.eliminarEventoFijo(evento);
      _mostrarExito('Evento eliminado');
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _configurarDisponibilidad() async {
    final datos = await showDialog<DisponibilidadData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DisponibilidadDialog(),
    );

    if (datos == null) {
      return;
    }

    try {
      await _controller.guardarDisponibilidad(datos);
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _planificarSemana() async {
    try {
      await _controller.planificarSemana();
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _replanificarBloque(BloquePlan bloque) async {
    try {
      final mensaje = await _controller.replanificarBloque(bloque);
      if (mensaje != null) {
        _mostrarError(mensaje);
      }
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _completarObjetivo(Objetivo objetivo) async {
    HapticFeedback.selectionClick();
    try {
      await _controller.completarObjetivo(objetivo);
      HapticFeedback.mediumImpact();
      _mostrarExito('Objetivo completado');
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _eliminarObjetivo(Objetivo objetivo) async {
    final confirmar = await ConfirmDialog.show(
      context,
      title: 'Eliminar objetivo',
      message:
          'Se borrará "${objetivo.titulo}" de forma definitiva. Esta acción no se puede deshacer.',
    );

    if (!confirmar) {
      return;
    }

    HapticFeedback.mediumImpact();
    try {
      await _controller.eliminarObjetivo(objetivo);
      HapticFeedback.heavyImpact();
      _mostrarExito('Objetivo eliminado');
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) {
      return;
    }
    AppSnackbar.showSuccess(context, mensaje);
  }

  void _mostrarError(String mensaje) {
    if (!mounted) {
      return;
    }
    AppSnackbar.showError(context, mensaje);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: FutureBuilder<PlanSemanal>(
              future: _controller.planFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _controller.cachearPlan(snapshot.data!);
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null &&
                    _controller.ultimoPlan == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError && _controller.ultimoPlan == null) {
                  return ErrorState(onRetry: _controller.recargarPlan);
                }

                final plan = snapshot.data ?? _controller.ultimoPlan!;
                _controller.asegurarDiaSeleccionadoValido(plan);

                return _controller.pantallaSeleccionada == 0
                    ? RefreshIndicator(
                        onRefresh: () async => _controller.recargarPlan(),
                        child: InicioScreen(
                          plan: plan,
                          controller: _controller,
                          themeMode: widget.themeMode,
                          onThemeModeSelected: widget.onThemeModeSelected,
                          scrollController: _scrollController,
                          onAddHabit: _crearHabito,
                          onAddEvent: _crearEventoFijo,
                          onAvailability: _configurarDisponibilidad,
                          onPlan: _planificarSemana,
                          onCompleteObjetivo: _completarObjetivo,
                          onDeleteObjetivo: _eliminarObjetivo,
                          onEditEvento: _editarEventoFijo,
                          onDeleteEvento: _eliminarEventoFijo,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _controller.recargarPlan(),
                        child: MiSemanaScreen(
                          plan: plan,
                          controller: _controller,
                          themeMode: widget.themeMode,
                          onThemeModeSelected: widget.onThemeModeSelected,
                          onRescheduleBloque: _replanificarBloque,
                          scrollController: _agendaScrollController,
                        ),
                      );
              },
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _controller.pantallaSeleccionada,
            onDestinationSelected: _controller.seleccionarPantalla,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Mi semana',
              ),
            ],
          ),
        );
      },
    );
  }
}
