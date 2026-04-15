
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/bloque_plan.dart';
import 'models/disponibilidad.dart';
import 'models/evento_fijo.dart';
import 'models/habito.dart';
import 'models/objetivo.dart';
import 'models/plan_semanal.dart';
import 'models/tarea_flexible.dart';
import 'services/api_service.dart';

void main() {
  runApp(const AppTareas());
}

class AppTareas extends StatelessWidget {
  const AppTareas({super.key});

  @override
  Widget build(BuildContext context) {
    const colorPrincipal = Color(0xFF5B7CFA);
    const colorFondo = Color(0xFFF5F7FB);
    const colorSuperficie = Color(0xFFFFFFFF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Liflow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorPrincipal,
          primary: colorPrincipal,
          surface: colorSuperficie,
        ),
        scaffoldBackgroundColor: colorFondo,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: colorSuperficie,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: Color(0xFFE7EBF3)),
          ),
        ),
      ),
      home: const OrganizadorPage(),
    );
  }
}

class OrganizadorPage extends StatefulWidget {
  const OrganizadorPage({super.key});

  @override
  State<OrganizadorPage> createState() => _OrganizadorPageState();
}

class _OrganizadorPageState extends State<OrganizadorPage> {
  final ApiService _apiService = ApiService();
  final Set<int> _objetivosActualizando = <int>{};
  final Set<int> _objetivosEliminando = <int>{};
  final Set<int> _eventosActualizando = <int>{};
  final Set<int> _eventosEliminando = <int>{};
  final ScrollController _scrollController = ScrollController();
  final ScrollController _agendaScrollController = ScrollController();
  PlanSemanal? _ultimoPlan;
  late Future<PlanSemanal> _planFuture;
  late int _diaSeleccionado;
  int _pantallaSeleccionada = 0;

  @override
  void initState() {
    super.initState();
    _diaSeleccionado = DateTime.now().weekday - 1;
    _recargarPlan();
  }

  void _recargarPlan() {
    setState(() {
      _planFuture = _apiService.obtenerPlanSemanal();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _agendaScrollController.dispose();
    super.dispose();
  }

  Future<void> _crearTareaFlexible() async {
    final datos = await showDialog<_TareaFlexibleData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _TareaFlexibleDialog(),
    );

    if (datos == null) {
      return;
    }

    try {
      await _apiService.crearTareaFlexible(
        titulo: datos.titulo,
        detalle: datos.detalle,
        fechaLimite: datos.fechaLimite,
        prioridad: datos.prioridad,
        duracionMinutos: datos.duracionMinutos,
        sesionesPorSemana: datos.sesionesPorSemana,
      );
      _recargarPlan();
      _mostrarExito('Tarea flexible creada');
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _crearHabito() async {
    final datos = await showDialog<_HabitoData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _HabitoDialog(),
    );

    if (datos == null) {
      return;
    }

    try {
      await _apiService.crearHabito(
        titulo: datos.titulo,
        detalle: datos.detalle,
        prioridad: datos.prioridad,
        duracionMinutos: datos.duracionMinutos,
        sesionesPorSemana: datos.sesionesPorSemana,
      );
      _recargarPlan();
      _mostrarExito('Habito creado');
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _crearEventoFijo() async {
    final datos = await showDialog<_EventoFijoData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _EventoFijoDialog(),
    );

    if (datos == null) {
      return;
    }

    try {
      await _apiService.crearEventoFijo(
        titulo: datos.titulo,
        detalle: datos.detalle,
        fecha: datos.fecha,
        inicioMinutos: datos.inicioMinutos,
        finMinutos: datos.finMinutos,
        prioridad: datos.prioridad,
      );
      _recargarPlan();
      _mostrarExito('Evento fijo creado');
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _editarEventoFijo(EventoFijo evento) async {
    if (_eventosActualizando.contains(evento.id)) {
      return;
    }

    final datos = await showDialog<_EventoFijoData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EventoFijoDialog(eventoInicial: evento),
    );

    if (datos == null) {
      return;
    }

    setState(() {
      _eventosActualizando.add(evento.id);
    });

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
      _recargarPlan();
      _mostrarExito('Evento fijo actualizado');
    } catch (error) {
      _mostrarError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _eventosActualizando.remove(evento.id);
        });
      }
    }
  }

  Future<void> _eliminarEventoFijo(EventoFijo evento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar evento fijo'),
          content: Text(
            'Se borrara "${evento.titulo}" y dejara libre ese hueco en la agenda.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD64545),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _eventosEliminando.add(evento.id);
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await _apiService.eliminarEventoFijo(evento.id);
      _recargarPlan();
      _mostrarExito('Evento fijo eliminado');
    } catch (error) {
      if (mounted) {
        setState(() {
          _eventosEliminando.remove(evento.id);
        });
      }
      _mostrarError(error.toString());
    }
  }

  Future<void> _configurarDisponibilidad() async {
    final datos = await showDialog<_DisponibilidadData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DisponibilidadDialog(),
    );

    if (datos == null) {
      return;
    }

    try {
      await _apiService.guardarDisponibilidad(
        diasSeleccionados: datos.diasSeleccionados,
        inicioMinutos: datos.inicioMinutos,
        finMinutos: datos.finMinutos,
      );
      _recargarPlan();
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _planificarSemana() async {
    try {
      final plan = await _apiService.planificarSemana();
      if (!mounted) {
        return;
      }
      setState(() {
        _ultimoPlan = plan;
        _planFuture = Future.value(plan);
      });
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _marcarBloqueHecho(BloquePlan bloque) async {
    try {
      await _apiService.marcarBloqueHecho(bloque.id);
      _recargarPlan();
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _replanificarBloque(BloquePlan bloque) async {
    try {
      await _apiService.replanificarBloque(bloque.id);
      _recargarPlan();
    } catch (error) {
      _mostrarError(error.toString());
    }
  }

  Future<void> _completarObjetivo(Objetivo objetivo) async {
    if (_objetivosActualizando.contains(objetivo.id)) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _objetivosActualizando.add(objetivo.id);
    });

    try {
      await _apiService.completarObjetivo(objetivo.id);
      HapticFeedback.mediumImpact();
      _recargarPlan();
      _mostrarExito('Objetivo completado');
    } catch (error) {
      _mostrarError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _objetivosActualizando.remove(objetivo.id);
        });
      }
    }
  }

  Future<void> _eliminarObjetivo(Objetivo objetivo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar objetivo'),
          content: Text(
            'Se borrara "${objetivo.titulo}" de forma definitiva. Esta accion no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD64545),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _objetivosEliminando.add(objetivo.id);
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await _apiService.eliminarObjetivo(objetivo.id);
      HapticFeedback.heavyImpact();
      _recargarPlan();
      _mostrarExito('Objetivo eliminado');
    } catch (error) {
      if (mounted) {
        setState(() {
          _objetivosEliminando.remove(objetivo.id);
        });
      }
      _mostrarError(error.toString());
    }
  }

  void _mostrarExito(String mensaje) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: const Color(0xFF11151D),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) {
      return;
    }
    final limpio = mensaje.replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(limpio)));
  }

  String _tipoLabel(String tipo) {
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

  String _fechaBonita(String fechaIso) {
    final fecha = DateTime.tryParse(fechaIso);
    if (fecha == null) {
      return fechaIso;
    }
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes';
  }

  String _fechaConDiaBonita(String fechaIso) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<PlanSemanal>(
        future: _planFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _ultimoPlan = snapshot.data;
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null &&
              _ultimoPlan == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && _ultimoPlan == null) {
            return _ErrorState(onRetry: _recargarPlan);
          }

          final plan = snapshot.data ?? _ultimoPlan!;
          final dias = plan.dias;
          if (_diaSeleccionado >= dias.length) {
            _diaSeleccionado = 0;
          }
          return _pantallaSeleccionada == 0
              ? RefreshIndicator(
                  onRefresh: () async => _recargarPlan(),
                  child: _buildInicio(plan),
                )
              : RefreshIndicator(
                  onRefresh: () async => _recargarPlan(),
                  child: _buildMiSemana(plan),
                );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pantallaSeleccionada,
        onDestinationSelected: (index) {
          setState(() {
            _pantallaSeleccionada = index;
          });
        },
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
  }

  Widget _buildInicio(PlanSemanal plan) {
    return ListView(
      key: const PageStorageKey('organizador-scroll'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 120),
      children: [
        _HeroPanel(
          onAddTask: _crearTareaFlexible,
          onAddHabit: _crearHabito,
          onAddEvent: _crearEventoFijo,
          onAvailability: _configurarDisponibilidad,
          onPlan: _planificarSemana,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Objetivos activos',
                value: '${plan.estadisticas.objetivosActivos}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Bloques pendientes',
                value: '${plan.estadisticas.bloquesPendientes}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle(
          title: 'Tareas flexibles',
          subtitle: 'Cosas que quieres hacer antes de una fecha, pero sin hora fija.',
        ),
        const SizedBox(height: 12),
        if (plan.tareasFlexibles.isEmpty)
          const _EmptyCard(
            title: 'No hay tareas flexibles todavia',
            subtitle: 'Prueba con algo como estudiar 5 horas antes del jueves.',
          )
        else
          ...plan.tareasFlexibles.map(_buildTareaFlexibleCard),
        const SizedBox(height: 24),
        const _SectionTitle(
          title: 'Habitos',
          subtitle: 'Rutinas que quieres repetir varias veces a la semana.',
        ),
        const SizedBox(height: 12),
        if (plan.habitos.isEmpty)
          const _EmptyCard(
            title: 'No hay habitos todavia',
            subtitle: 'Anade algo como entrenar 3 dias o leer 4 sesiones.',
          )
        else
          ...plan.habitos.map(_buildHabitoCard),
        const SizedBox(height: 24),
        const _SectionTitle(
          title: 'Eventos fijos',
          subtitle: 'Compromisos con hora cerrada que la app nunca movera.',
        ),
        const SizedBox(height: 12),
        if (plan.eventosFijos.isEmpty)
          const _EmptyCard(
            title: 'No hay eventos fijos todavia',
            subtitle: 'Anade cosas como examenes, citas o reuniones para reservar ese hueco.',
          )
        else
          ...plan.eventosFijos.map(_buildEventoFijoCard),
        const SizedBox(height: 24),
        const _SectionTitle(
          title: 'Disponibilidad',
          subtitle: 'Los huecos donde quieres que el sistema te coloque bloques.',
        ),
        const SizedBox(height: 12),
        if (plan.disponibilidad.isEmpty)
          const _EmptyCard(
            title: 'Aun no hay disponibilidad',
            subtitle: 'Define tus dias y horas disponibles para que la semana se organice sola.',
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: plan.disponibilidad
                .map((slot) => _AvailabilityPill(slot: slot))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildMiSemana(PlanSemanal plan) {
    final dias = plan.dias;
    final diaActivo = dias[_diaSeleccionado];

    return ListView(
      key: const PageStorageKey('agenda-scroll'),
      controller: _agendaScrollController,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 120),
      children: [
        _WeekProfileHeader(
          totalPendientes: plan.estadisticas.bloquesPendientes,
          diaLabel: dias[_diaSeleccionado].nombreDia,
          fechaLabel: _fechaBonita(dias[_diaSeleccionado].fecha),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(
          title: 'Agenda de la semana',
          subtitle: 'Tu plan diario en una vista limpia y directa.',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: dias
                .map(
                  (dia) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _DayChip(
                      dia: dia,
                      selected: dia.diaSemana == _diaSeleccionado,
                      onTap: () {
                        setState(() {
                          _diaSeleccionado = dia.diaSemana;
                        });
                      },
                      fechaBonita: _fechaBonita(dia.fecha),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (diaActivo.bloques.isEmpty)
          const _EmptyCard(
            title: 'Este dia esta libre',
            subtitle: 'Cuando planifiques la semana, aqui apareceran tus bloques.',
          )
        else
          ...diaActivo.bloques.map(
            (bloque) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BloqueCard(
                bloque: bloque,
                tipoLabel: _tipoLabel(bloque.tipoObjetivo),
                onDone: bloque.estado == 'pendiente' && !bloque.esFijo
                    ? () => _marcarBloqueHecho(bloque)
                    : null,
                onReschedule: bloque.estado == 'pendiente' && !bloque.esFijo
                    ? () => _replanificarBloque(bloque)
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTareaFlexibleCard(TareaFlexible tarea) {
    final objetivo = Objetivo(
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SizeTransition(
          sizeFactor: fade,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: fade,
            child: child,
          ),
        );
      },
      child: _objetivosEliminando.contains(tarea.id)
          ? SizedBox(
              key: ValueKey('objetivo-hidden-${tarea.id}'),
            )
          : Padding(
              key: ValueKey('objetivo-${tarea.id}'),
              padding: const EdgeInsets.only(bottom: 12),
              child: _ObjetivoCard(
                objetivo: objetivo,
                tipoLabel: 'Tarea flexible',
                onComplete: () => _completarObjetivo(objetivo),
                onDelete: () => _eliminarObjetivo(objetivo),
                isBusy: _objetivosActualizando.contains(tarea.id),
              ),
            ),
    );
  }

  Widget _buildHabitoCard(Habito habito) {
    final objetivo = Objetivo(
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _ObjetivoCard(
        objetivo: objetivo,
        tipoLabel: 'Habito semanal',
        onComplete: () => _completarObjetivo(objetivo),
        onDelete: () => _eliminarObjetivo(objetivo),
        isBusy: _objetivosActualizando.contains(habito.id),
      ),
    );
  }

  Widget _buildEventoFijoCard(EventoFijo evento) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SizeTransition(
          sizeFactor: fade,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: fade,
            child: child,
          ),
        );
      },
      child: _eventosEliminando.contains(evento.id)
          ? SizedBox(
              key: ValueKey('evento-hidden-${evento.id}'),
            )
          : Padding(
              key: ValueKey('evento-${evento.id}'),
              padding: const EdgeInsets.only(bottom: 12),
              child: _EventoFijoCard(
                evento: evento,
                fechaLabel: _fechaConDiaBonita(evento.fecha),
                onEdit: () => _editarEventoFijo(evento),
                onDelete: () => _eliminarEventoFijo(evento),
                isBusy: _eventosActualizando.contains(evento.id),
              ),
            ),
    );
  }
}

class _TareaFlexibleData {
  const _TareaFlexibleData({
    required this.titulo,
    required this.detalle,
    required this.prioridad,
    required this.duracionMinutos,
    required this.sesionesPorSemana,
    required this.fechaLimite,
  });

  final String titulo;
  final String detalle;
  final int prioridad;
  final int duracionMinutos;
  final int sesionesPorSemana;
  final String fechaLimite;
}

class _HabitoData {
  const _HabitoData({
    required this.titulo,
    required this.detalle,
    required this.prioridad,
    required this.duracionMinutos,
    required this.sesionesPorSemana,
  });

  final String titulo;
  final String detalle;
  final int prioridad;
  final int duracionMinutos;
  final int sesionesPorSemana;
}

class _DisponibilidadData {
  const _DisponibilidadData({
    required this.diasSeleccionados,
    required this.inicioMinutos,
    required this.finMinutos,
  });

  final List<int> diasSeleccionados;
  final int inicioMinutos;
  final int finMinutos;
}

class _EventoFijoData {
  const _EventoFijoData({
    required this.titulo,
    required this.detalle,
    required this.fecha,
    required this.inicioMinutos,
    required this.finMinutos,
    required this.prioridad,
  });

  final String titulo;
  final String detalle;
  final String fecha;
  final int inicioMinutos;
  final int finMinutos;
  final int prioridad;
}

class _TareaFlexibleDialog extends StatefulWidget {
  const _TareaFlexibleDialog();

  @override
  State<_TareaFlexibleDialog> createState() => _TareaFlexibleDialogState();
}

class _TareaFlexibleDialogState extends State<_TareaFlexibleDialog> {
  final _tituloController = TextEditingController();
  final _detalleController = TextEditingController();
  String? _error;
  int _prioridad = 3;
  int _duracion = 60;
  int _sesiones = 3;
  DateTime? _fechaLimite;

  @override
  void dispose() {
    _tituloController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  void _guardar() {
    final titulo = _tituloController.text.trim();
    if (titulo.length < 3) {
      setState(() {
        _error = 'El titulo debe tener al menos 3 caracteres';
      });
      return;
    }
    if (_fechaLimite == null) {
      setState(() {
        _error = 'Elige una fecha limite';
      });
      return;
    }

    Navigator.of(context).pop(
      _TareaFlexibleData(
        titulo: titulo,
        detalle: _detalleController.text.trim(),
        prioridad: _prioridad,
        duracionMinutos: _duracion,
        sesionesPorSemana: _sesiones,
        fechaLimite: _fechaLimite!.toIso8601String().split('T').first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva tarea flexible'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tituloController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Titulo',
                hintText: 'Ej: Estudiar mates',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() {
                    _error = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detalleController,
              decoration: const InputDecoration(
                labelText: 'Detalle',
                hintText: 'Ej: temas 1 al 4',
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _prioridad,
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                    items: const [1, 2, 3, 4, 5]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text('$item/5'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _prioridad = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _duracion,
                    decoration: const InputDecoration(labelText: 'Min por sesion'),
                    items: const [30, 45, 60, 90, 120]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text('$item min'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _duracion = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _sesiones,
              decoration: const InputDecoration(labelText: 'Sesiones a planificar'),
              items: const [1, 2, 3, 4, 5, 6, 7]
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text('$item'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sesiones = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final ahora = DateTime.now();
                final elegida = await showDatePicker(
                  context: context,
                  firstDate: ahora,
                  lastDate: ahora.add(const Duration(days: 365)),
                  initialDate: _fechaLimite ?? ahora.add(const Duration(days: 3)),
                );
                if (elegida != null) {
                  setState(() {
                    _fechaLimite = elegida;
                    _error = null;
                  });
                }
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                _fechaLimite == null
                    ? 'Elegir fecha limite'
                    : 'Fecha limite: ${_fechaLimite!.day}/${_fechaLimite!.month}/${_fechaLimite!.year}',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _HabitoDialog extends StatefulWidget {
  const _HabitoDialog();

  @override
  State<_HabitoDialog> createState() => _HabitoDialogState();
}

class _HabitoDialogState extends State<_HabitoDialog> {
  final _tituloController = TextEditingController();
  final _detalleController = TextEditingController();
  String? _error;
  int _prioridad = 3;
  int _duracion = 60;
  int _sesiones = 3;

  @override
  void dispose() {
    _tituloController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  void _guardar() {
    final titulo = _tituloController.text.trim();
    if (titulo.length < 3) {
      setState(() {
        _error = 'El titulo debe tener al menos 3 caracteres';
      });
      return;
    }

    Navigator.of(context).pop(
      _HabitoData(
        titulo: titulo,
        detalle: _detalleController.text.trim(),
        prioridad: _prioridad,
        duracionMinutos: _duracion,
        sesionesPorSemana: _sesiones,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo habito'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tituloController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Titulo',
                hintText: 'Ej: Entrenar',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() {
                    _error = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detalleController,
              decoration: const InputDecoration(
                labelText: 'Detalle',
                hintText: 'Ej: fuerza o correr',
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _prioridad,
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                    items: const [1, 2, 3, 4, 5]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text('$item/5'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _prioridad = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _duracion,
                    decoration: const InputDecoration(labelText: 'Duracion'),
                    items: const [30, 45, 60, 90, 120]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text('$item min'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _duracion = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _sesiones,
              decoration: const InputDecoration(labelText: 'Dias por semana'),
              items: const [1, 2, 3, 4, 5, 6, 7]
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text('$item'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sesiones = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _EventoFijoDialog extends StatefulWidget {
  const _EventoFijoDialog({this.eventoInicial});

  final EventoFijo? eventoInicial;

  @override
  State<_EventoFijoDialog> createState() => _EventoFijoDialogState();
}

class _EventoFijoDialogState extends State<_EventoFijoDialog> {
  final _tituloController = TextEditingController();
  final _detalleController = TextEditingController();
  String? _error;
  DateTime? _fecha;
  int _inicio = 10 * 60;
  int _fin = 12 * 60;
  int _prioridad = 4;

  @override
  void initState() {
    super.initState();
    final evento = widget.eventoInicial;
    if (evento != null) {
      _tituloController.text = evento.titulo;
      _detalleController.text = evento.detalle ?? '';
      _fecha = DateTime.tryParse(evento.fecha);
      _inicio = evento.inicioMinutos;
      _fin = evento.finMinutos;
      _prioridad = evento.prioridad;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  String _hora(int minutos) {
    final hora = (minutos ~/ 60).toString().padLeft(2, '0');
    final min = (minutos % 60).toString().padLeft(2, '0');
    return '$hora:$min';
  }

  List<int> _horasDisponibles() {
    return List<int>.generate(32, (index) => (6 * 60) + (index * 30));
  }

  List<int> _horasFinDisponibles() {
    return _horasDisponibles().where((item) => item > _inicio).toList();
  }

  void _guardar() {
    FocusScope.of(context).unfocus();

    final titulo = _tituloController.text.trim();
    if (titulo.length < 3) {
      setState(() {
        _error = 'El titulo debe tener al menos 3 caracteres';
      });
      return;
    }

    if (_fecha == null) {
      setState(() {
        _error = 'Elige una fecha para el evento';
      });
      return;
    }

    Navigator.of(context).pop(
      _EventoFijoData(
        titulo: titulo,
        detalle: _detalleController.text.trim(),
        fecha: _fecha!.toIso8601String().split('T').first,
        inicioMinutos: _inicio,
        finMinutos: _fin,
        prioridad: _prioridad,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horasInicio = _horasDisponibles();
    final horasFin = _horasFinDisponibles();
    final inicioActual = horasInicio.contains(_inicio) ? _inicio : horasInicio.first;
    final finActual = horasFin.contains(_fin) ? _fin : horasFin.first;

    return AlertDialog(
      title: Text(
        widget.eventoInicial == null ? 'Nuevo evento fijo' : 'Editar evento fijo',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tituloController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Titulo',
                hintText: 'Ej: Examen de mates',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() {
                    _error = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detalleController,
              decoration: const InputDecoration(
                labelText: 'Detalle',
                hintText: 'Ej: Aula 2, reunion con el equipo...',
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final ahora = DateTime.now();
                final elegida = await showDatePicker(
                  context: context,
                  firstDate: ahora,
                  lastDate: ahora.add(const Duration(days: 365)),
                  initialDate: _fecha ?? ahora.add(const Duration(days: 1)),
                );
                if (elegida != null) {
                  setState(() {
                    _fecha = elegida;
                    _error = null;
                  });
                }
              },
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _fecha == null
                    ? 'Elegir fecha'
                    : 'Fecha: ${_fecha!.day}/${_fecha!.month}/${_fecha!.year}',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('evento-inicio-$inicioActual'),
                    initialValue: inicioActual,
                    decoration: const InputDecoration(labelText: 'Desde'),
                    items: horasInicio
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_hora(item)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _inicio = value;
                          if (_fin <= _inicio) {
                            _fin = _horasFinDisponibles().first;
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('evento-fin-$inicioActual-$finActual'),
                    initialValue: finActual,
                    decoration: const InputDecoration(labelText: 'Hasta'),
                    items: horasFin
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_hora(item)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _fin = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _prioridad,
              decoration: const InputDecoration(labelText: 'Prioridad'),
              items: const [1, 2, 3, 4, 5]
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text('$item/5'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _prioridad = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _DisponibilidadDialog extends StatefulWidget {
  const _DisponibilidadDialog();

  @override
  State<_DisponibilidadDialog> createState() => _DisponibilidadDialogState();
}

class _DisponibilidadDialogState extends State<_DisponibilidadDialog> {
  final Set<int> _dias = {0, 1, 2, 3, 4};
  int _inicio = 18 * 60;
  int _fin = 21 * 60;
  String? _error;

  static const _diasTexto = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  String _hora(int minutos) {
    final hora = (minutos ~/ 60).toString().padLeft(2, '0');
    final min = (minutos % 60).toString().padLeft(2, '0');
    return '$hora:$min';
  }

  List<int> _horasDisponibles() {
    return List<int>.generate(28, (index) => (6 * 60) + (index * 30));
  }

  List<int> _horasFinDisponibles() {
    return _horasDisponibles().where((item) => item > _inicio).toList();
  }

  @override
  Widget build(BuildContext context) {
    final horasInicio = _horasDisponibles();
    final horasFin = _horasFinDisponibles();
    final inicioActual = horasInicio.contains(_inicio) ? _inicio : horasInicio.first;
    final finActual = horasFin.contains(_fin) ? _fin : horasFin.first;

    return AlertDialog(
      title: const Text('Disponibilidad'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona los dias que quieres usar para planificar.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                7,
                (index) => FilterChip(
                  label: Text(_diasTexto[index]),
                  selected: _dias.contains(index),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _dias.add(index);
                      } else {
                        _dias.remove(index);
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('inicio-$inicioActual'),
                    initialValue: inicioActual,
                    decoration: const InputDecoration(labelText: 'Desde'),
                    items: horasInicio
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_hora(item)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _inicio = value;
                          if (_fin <= _inicio) {
                            _fin = _horasFinDisponibles().first;
                          }
                          _error = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('fin-$inicioActual-$finActual'),
                    initialValue: finActual,
                    decoration: const InputDecoration(labelText: 'Hasta'),
                    items: horasFin
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_hora(item)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _fin = value;
                          _error = null;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_dias.isEmpty) {
              setState(() {
                _error = 'Selecciona al menos un dia';
              });
              return;
            }
            if (_fin <= _inicio) {
              setState(() {
                _error = 'La hora de fin debe ser posterior';
              });
              return;
            }
            Navigator.of(context).pop(
              _DisponibilidadData(
                diasSeleccionados: _dias.toList()..sort(),
                inicioMinutos: _inicio,
                finMinutos: _fin,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.onAddTask,
    required this.onAddHabit,
    required this.onAddEvent,
    required this.onAvailability,
    required this.onPlan,
  });

  final VoidCallback onAddTask;
  final VoidCallback onAddHabit;
  final VoidCallback onAddEvent;
  final VoidCallback onAvailability;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFEFF), Color(0xFFEFF3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFDDE4F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Organizador automatico de vida',
              style: TextStyle(
                color: Color(0xFF4461D8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tu semana, ordenada sola.',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: Color(0xFF171B24),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Anade tareas flexibles, habitos y eventos con hora fija. Luego marca tus huecos y deja que la app organice la semana.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF5F6778),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onAddTask,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tarea flexible'),
              ),
              OutlinedButton.icon(
                onPressed: onAddHabit,
                icon: const Icon(Icons.repeat_rounded),
                label: const Text('Habito'),
              ),
              OutlinedButton.icon(
                onPressed: onAddEvent,
                icon: const Icon(Icons.event),
                label: const Text('Evento fijo'),
              ),
              OutlinedButton.icon(
                onPressed: onAvailability,
                icon: const Icon(Icons.schedule),
                label: const Text('Disponibilidad'),
              ),
              OutlinedButton.icon(
                onPressed: onPlan,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Planificar semana'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF171B24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF687083)),
        ),
      ],
    );
  }
}

class _WeekProfileHeader extends StatelessWidget {
  const _WeekProfileHeader({
    required this.totalPendientes,
    required this.diaLabel,
    required this.fechaLabel,
  });

  final int totalPendientes;
  final String diaLabel;
  final String fechaLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF11151D), Color(0xFF1D2430)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFF2D3645),
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi semana',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tu vista diaria para entrar, mirar y ejecutar.',
                      style: TextStyle(color: Color(0xFFB7C0CF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniPill(
                label: '$diaLabel - $fechaLabel',
                backgroundColor: const Color(0xFF2A3240),
                foregroundColor: Colors.white,
              ),
              _MiniPill(
                label: '$totalPendientes bloques pendientes',
                backgroundColor: const Color(0xFF1F8A4C),
                foregroundColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventoFijoCard extends StatelessWidget {
  const _EventoFijoCard({
    required this.evento,
    required this.fechaLabel,
    required this.onEdit,
    required this.onDelete,
    required this.isBusy,
  });

  final EventoFijo evento;
  final String fechaLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _StatusBadge(
                  label: 'Evento fijo',
                  backgroundColor: Color(0xFF10131A),
                  foregroundColor: Colors.white,
                  icon: Icons.lock_clock_rounded,
                ),
                const Spacer(),
                _IconCircleButton(
                  tooltip: 'Editar evento fijo',
                  onPressed: isBusy ? null : onEdit,
                  icon: Icons.edit_outlined,
                  backgroundColor: const Color(0xFFEFF3FF),
                  foregroundColor: const Color(0xFF4461D8),
                ),
                const SizedBox(width: 8),
                _IconCircleButton(
                  tooltip: 'Eliminar evento fijo',
                  onPressed: isBusy ? null : onDelete,
                  icon: isBusy ? Icons.hourglass_top_rounded : Icons.delete_outline_rounded,
                  backgroundColor: const Color(0xFFFFECE9),
                  foregroundColor: const Color(0xFFD64545),
                ),
                const SizedBox(width: 10),
                Text(
                  '${evento.inicioHora} - ${evento.finHora}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171B24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              evento.titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171B24),
              ),
            ),
            if ((evento.detalle ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                evento.detalle!,
                style: const TextStyle(
                  color: Color(0xFF5F6778),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniPill(label: fechaLabel),
                _MiniPill(label: '${evento.duracionMinutos} min'),
                _MiniPill(label: 'Prioridad ${evento.prioridad}/5'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171B24),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Color(0xFF687083)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObjetivoCard extends StatelessWidget {
  const _ObjetivoCard({
    required this.objetivo,
    required this.tipoLabel,
    required this.onComplete,
    required this.onDelete,
    required this.isBusy,
  });

  final Objetivo objetivo;
  final String tipoLabel;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final estaCompletado = objetivo.completado;
    final visual = _visualObjetivo(objetivo.tipo);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: estaCompletado
              ? const LinearGradient(
                  colors: [Color(0xFFF8FCF9), Color(0xFFF1FAF4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: visual.backgroundColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: estaCompletado
                          ? const Color(0xFFE7F7EC)
                          : visual.iconBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      estaCompletado ? Icons.check_rounded : visual.icon,
                      color: estaCompletado
                          ? const Color(0xFF228B57)
                          : visual.iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: estaCompletado
                          ? const Color(0xFFE7F7EC)
                          : visual.badgeBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tipoLabel,
                      style: TextStyle(
                        color: estaCompletado
                            ? const Color(0xFF228B57)
                            : visual.badgeForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: estaCompletado
                        ? Row(
                            key: const ValueKey('completed-actions'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _StatusBadge(
                                label: 'Completado',
                                backgroundColor: Color(0xFF22A861),
                                foregroundColor: Colors.white,
                                icon: Icons.check_rounded,
                              ),
                              const SizedBox(width: 8),
                              _IconCircleButton(
                                tooltip: 'Eliminar objetivo',
                                onPressed: onDelete,
                                icon: Icons.delete_outline_rounded,
                                backgroundColor: const Color(0xFFFFECE9),
                                foregroundColor: const Color(0xFFD64545),
                              ),
                            ],
                          )
                        : _TickButton(
                            key: const ValueKey('complete-action'),
                            tooltip: 'Completar objetivo',
                            onPressed: onComplete,
                            isBusy: isBusy,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: estaCompletado
                      ? const Color(0xFF7D8596)
                      : const Color(0xFF171B24),
                  decoration: estaCompletado
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
                child: Text(objetivo.titulo),
              ),
              if ((objetivo.detalle ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: estaCompletado
                        ? const Color(0xFF8A92A3)
                        : const Color(0xFF5F6778),
                    height: 1.4,
                  ),
                  child: Text(objetivo.detalle!),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniPill(
                    label: visual.helperLabel,
                    backgroundColor: visual.helperBackground,
                    foregroundColor: visual.helperForeground,
                  ),
                  _MiniPill(label: 'Prioridad ${objetivo.prioridad}/5'),
                  _MiniPill(label: '${objetivo.duracionMinutos} min'),
                  _MiniPill(label: '${objetivo.sesionesPorSemana} sesiones'),
                  if (objetivo.fechaLimite != null)
                    _MiniPill(label: 'Limite ${objetivo.fechaLimite}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

_ObjetivoVisual _visualObjetivo(String tipo) {
  switch (tipo) {
    case 'habito':
      return const _ObjetivoVisual(
        icon: Icons.repeat_rounded,
        iconBackground: Color(0xFFE9F7EE),
        iconColor: Color(0xFF1F8A4C),
        badgeBackground: Color(0xFFEAF8EF),
        badgeForeground: Color(0xFF1F8A4C),
        helperLabel: 'Rutina semanal',
        helperBackground: Color(0xFFEAF8EF),
        helperForeground: Color(0xFF1F8A4C),
        backgroundColors: [Color(0xFFFFFFFF), Color(0xFFF7FCF8)],
      );
    case 'fecha_limite':
    default:
      return const _ObjetivoVisual(
        icon: Icons.flag_rounded,
        iconBackground: Color(0xFFFFF1E7),
        iconColor: Color(0xFFB85B1E),
        badgeBackground: Color(0xFFFFF3EA),
        badgeForeground: Color(0xFFB85B1E),
        helperLabel: 'Antes de una fecha',
        helperBackground: Color(0xFFFFF3EA),
        helperForeground: Color(0xFFB85B1E),
        backgroundColors: [Color(0xFFFFFFFF), Color(0xFFFFFBF7)],
      );
  }
}

class _ObjetivoVisual {
  const _ObjetivoVisual({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.helperLabel,
    required this.helperBackground,
    required this.helperForeground,
    required this.backgroundColors,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final Color badgeBackground;
  final Color badgeForeground;
  final String helperLabel;
  final Color helperBackground;
  final Color helperForeground;
  final List<Color> backgroundColors;
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.slot});

  final Disponibilidad slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBF3)),
      ),
      child: Text(
        '${slot.nombreDia}  ${slot.inicioHora}-${slot.finHora}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.dia,
    required this.selected,
    required this.onTap,
    required this.fechaBonita,
  });

  final DiaPlan dia;
  final bool selected;
  final VoidCallback onTap;
  final String fechaBonita;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10131A) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFF10131A) : const Color(0xFFE7EBF3),
          ),
        ),
        child: Column(
          children: [
            Text(
              dia.nombreDia.substring(0, 3),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF171B24),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fechaBonita,
              style: TextStyle(
                color: selected ? Colors.white70 : const Color(0xFF6A7285),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BloqueCard extends StatelessWidget {
  const _BloqueCard({
    required this.bloque,
    required this.tipoLabel,
    required this.onDone,
    required this.onReschedule,
  });

  final BloquePlan bloque;
  final String tipoLabel;
  final VoidCallback? onDone;
  final VoidCallback? onReschedule;

  @override
  Widget build(BuildContext context) {
    final esHecho = bloque.estado == 'hecho';
    final esFallado = bloque.estado == 'fallado';
    final esFijo = bloque.esFijo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: esFijo
                        ? const Color(0xFF10131A)
                        : esHecho
                        ? const Color(0xFFE7F7EC)
                        : esFallado
                            ? const Color(0xFFFFF1E8)
                            : const Color(0xFFEFF3FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    esFijo
                        ? 'Evento fijo'
                        : esHecho
                        ? 'Hecho'
                        : esFallado
                            ? 'Fallado'
                            : tipoLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: esFijo
                          ? Colors.white
                          : esHecho
                          ? const Color(0xFF228B57)
                          : esFallado
                              ? const Color(0xFFB55D1D)
                              : const Color(0xFF4461D8),
                    ),
                  ),
                ),
                const Spacer(),
                if (!esHecho && !esFijo && onDone != null) ...[
                  _TickButton(
                    tooltip: 'Marcar bloque como hecho',
                    onPressed: onDone!,
                    compact: true,
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  '${bloque.inicioHora} - ${bloque.finHora}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171B24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              bloque.tituloObjetivo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171B24),
              ),
            ),
            if ((bloque.detalleObjetivo ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                bloque.detalleObjetivo!,
                style: const TextStyle(color: Color(0xFF5F6778)),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniPill(label: '${bloque.duracionMinutos} min'),
                if (esFijo) const _MiniPill(label: 'Hora cerrada'),
                if (bloque.replanificado) const _MiniPill(label: 'Replanificado'),
              ],
            ),
            if (!esHecho && !esFijo) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton(
                    onPressed: onReschedule,
                    child: const Text('No pude, recolocar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TickButton extends StatelessWidget {
  const _TickButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.isBusy = false,
    this.compact = false,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final bool isBusy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 38.0;
    final iconSize = compact ? 16.0 : 18.0;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD9DFEA)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isBusy
                  ? SizedBox(
                      key: const ValueKey('tick-loading'),
                      width: iconSize,
                      height: iconSize,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF8A92A3),
                        ),
                      ),
                    )
                  : Icon(
                      key: const ValueKey('tick-idle'),
                      Icons.check_rounded,
                      size: iconSize,
                      color: const Color(0xFF8A92A3),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    this.backgroundColor = const Color(0xFFF4F6FA),
    this.foregroundColor = const Color(0xFF5F6778),
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Color(0xFF687083))),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 50),
                const SizedBox(height: 12),
                const Text(
                  'No se pudo conectar con la API',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Comprueba que FastAPI este corriendo en ${ApiService.baseUrl}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
