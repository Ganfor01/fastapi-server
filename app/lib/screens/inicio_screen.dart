import 'package:flutter/material.dart';

import '../controllers/organizador_controller.dart';
import '../models/disponibilidad.dart';
import '../models/evento_fijo.dart';
import '../models/habito.dart';
import '../models/objetivo.dart';
import '../models/plan_semanal.dart';
import '../widgets/availability_pill.dart';
import '../widgets/empty_card.dart';
import '../widgets/hero_panel.dart';
import '../widgets/section_title.dart';
import '../widgets/visual_reminders_panel.dart';
import '../widgets/cards/evento_fijo_card.dart';
import '../widgets/cards/objetivo_card.dart';
import '../widgets/cards/stat_card.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({
    super.key,
    required this.plan,
    required this.controller,
    required this.themeMode,
    required this.onThemeModeSelected,
    required this.scrollController,
    required this.onAddHabit,
    required this.onAddEvent,
    required this.onAvailability,
    required this.onPlan,
    required this.onTrackHabit,
    required this.onCompleteObjetivo,
    required this.onDeleteObjetivo,
    required this.onCompleteEvento,
    required this.onEditEvento,
    required this.onDeleteEvento,
  });

  final PlanSemanal plan;
  final OrganizadorController controller;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeSelected;
  final ScrollController scrollController;
  final VoidCallback onAddHabit;
  final VoidCallback onAddEvent;
  final VoidCallback onAvailability;
  final VoidCallback onPlan;
  final ValueChanged<Habito> onTrackHabit;
  final ValueChanged<Objetivo> onCompleteObjetivo;
  final ValueChanged<Objetivo> onDeleteObjetivo;
  final ValueChanged<EventoFijo> onCompleteEvento;
  final ValueChanged<EventoFijo> onEditEvento;
  final ValueChanged<EventoFijo> onDeleteEvento;

  @override
  Widget build(BuildContext context) {
    final eventosOrdenados = [...plan.eventosFijos]
      ..sort((a, b) => _compararEventosPorCercania(a, b));

    return ListView(
      key: const PageStorageKey('organizador-scroll'),
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 120),
      children: [
        HeroPanel(
          themeMode: themeMode,
          onThemeModeSelected: onThemeModeSelected,
          onAddHabit: onAddHabit,
          onAddEvent: onAddEvent,
          onAvailability: onAvailability,
          onPlan: onPlan,
        ),
        const SizedBox(height: 18),
        StatCard(
          title: 'Hábitos activos',
          value: '${plan.habitos.length}',
          caption: plan.habitos.isEmpty
              ? 'Todavía no has añadido ninguno.'
              : plan.habitos.map((habito) => habito.titulo).join(' · '),
        ),
        const SizedBox(height: 24),
        const SectionTitle(
          title: 'Hoy y lo que viene',
          subtitle: '',
        ),
        const SizedBox(height: 12),
        VisualRemindersPanel(reminders: _buildVisualReminders(plan)),
        const SizedBox(height: 24),
        const SectionTitle(
          title: 'Hábitos',
          subtitle: 'Rutinas que quieres repetir varias veces a la semana.',
        ),
        const SizedBox(height: 12),
        if (plan.habitos.isEmpty)
          const EmptyCard(
            title: 'No hay hábitos todavía',
            subtitle: 'Añade algo como entrenar 3 días o leer 4 sesiones.',
          )
        else
          ...plan.habitos.map(_buildHabitoCard),
        const SizedBox(height: 24),
        const SectionTitle(
          title: 'Eventos',
          subtitle: 'Compromisos que reservas en una fecha concreta.',
        ),
        const SizedBox(height: 12),
        if (plan.eventosFijos.isEmpty)
          const EmptyCard(
            title: 'No hay eventos todavía',
            subtitle:
                'Añade cosas como exámenes, citas, bodas o reuniones para reservar ese hueco.',
          )
        else
          ...eventosOrdenados.map(_buildEventoFijoCard),
        const SizedBox(height: 24),
        const SectionTitle(
          title: 'Disponibilidad',
          subtitle:
              'Los huecos donde quieres que el sistema te coloque bloques.',
        ),
        const SizedBox(height: 12),
        if (plan.disponibilidad.isEmpty)
          const EmptyCard(
            title: 'Aún no hay disponibilidad',
            subtitle:
                'Define tus días y horas disponibles para que la semana se organice sola.',
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _buildDisponibilidadPills(plan.disponibilidad),
          ),
      ],
    );
  }

  List<Widget> _buildDisponibilidadPills(List<Disponibilidad> disponibilidad) {
    final grupos = <String, List<Disponibilidad>>{};
    for (final slot in disponibilidad) {
      final clave = '${slot.inicioHora}-${slot.finHora}';
      grupos.putIfAbsent(clave, () => <Disponibilidad>[]).add(slot);
    }

    final entries = grupos.entries.toList()
      ..sort(
        (a, b) => a.value.first.inicioMinutos.compareTo(
          b.value.first.inicioMinutos,
        ),
      );

    return entries.map((entry) {
      final slots = [...entry.value]
        ..sort((a, b) => a.diaSemana.compareTo(b.diaSemana));
      return AvailabilityPill(
        daysLabel: _daysSummary(slots),
        timeLabel: entry.key,
      );
    }).toList();
  }

  List<VisualReminder> _buildVisualReminders(PlanSemanal plan) {
    if (plan.dias.isEmpty) {
      return const [
        VisualReminder(
          title: 'Semana tranquila',
          subtitle:
              'Cuando tengas hábitos o eventos, aquí aparecerán avisos útiles.',
          icon: Icons.wb_sunny_outlined,
          tint: Color(0xFF6E7CFA),
        ),
      ];
    }

    final reminders = <VisualReminder>[];
    final now = DateTime.now();
    final hoyIso = _toIsoDate(now);
    final mananaIso = _toIsoDate(now.add(const Duration(days: 1)));
    final diaAncla = plan.dias.any((dia) => dia.fecha == hoyIso)
        ? plan.dias.firstWhere((dia) => dia.fecha == hoyIso)
        : plan.dias.first;
    final indiceAncla = plan.dias.indexOf(diaAncla);
    final diaSiguiente = indiceAncla + 1 < plan.dias.length
        ? plan.dias[indiceAncla + 1]
        : null;
    final etiquetaAncla = diaAncla.fecha == hoyIso
        ? 'Hoy'
        : _relativeDayLabel(diaAncla.fecha);
    final etiquetaSiguiente = diaSiguiente == null
        ? ''
        : diaSiguiente.fecha == mananaIso
        ? 'Mañana'
        : _relativeDayLabel(diaSiguiente.fecha);

    final notaAncla = diaAncla.notaLibre?.trim() ?? '';
    if (notaAncla.isNotEmpty) {
      reminders.add(
        VisualReminder(
          title: diaAncla.fecha == hoyIso
              ? 'Tienes una nota hoy'
              : '$etiquetaAncla recuerda tu nota',
          subtitle: notaAncla,
          icon: Icons.sticky_note_2_rounded,
          tint: const Color(0xFFE39C2E),
          onTap: () => _abrirDia(diaAncla.fecha),
        ),
      );
    }

    final habitosAncla = diaAncla.bloques
        .where(
          (bloque) =>
              bloque.tipoObjetivo == 'habito' && bloque.estado == 'pendiente',
        )
        .length;
    if (habitosAncla > 0) {
      reminders.add(
        VisualReminder(
          title:
              '$etiquetaAncla tienes ${_countLabel(habitosAncla, 'hábito', 'hábitos')}',
          subtitle: habitosAncla == 1
              ? 'Buen momento para tacharlo en cuanto tengas un hueco.'
              : 'Si los repartes con calma, hoy te quitas bastante de encima.',
          icon: Icons.fitness_center_rounded,
          tint: const Color(0xFF2FB36B),
          onTap: () => _abrirDia(diaAncla.fecha),
        ),
      );
    }

    final eventosAncla = plan.eventosFijos
        .where(
          (evento) =>
              !evento.completado && _eventoIncluyeFecha(evento, diaAncla.fecha),
        )
        .length;
    if (eventosAncla > 0) {
      reminders.add(
        VisualReminder(
          title:
              '$etiquetaAncla hay ${_countLabel(eventosAncla, 'evento', 'eventos')}',
          subtitle: eventosAncla == 1
              ? 'Tu agenda ya tiene un compromiso importante reservado.'
              : 'Pinta a día movido, así que viene bien tenerlo presente.',
          icon: Icons.event_note_rounded,
          tint: const Color(0xFF4E7CF4),
          onTap: () => _abrirDia(diaAncla.fecha),
        ),
      );
    }

    if (diaSiguiente != null) {
      final eventosEmpiezan = plan.eventosFijos
          .where(
            (evento) =>
                !evento.completado && evento.fecha == diaSiguiente.fecha,
          )
          .toList();
      if (eventosEmpiezan.isNotEmpty) {
        reminders.add(
          VisualReminder(
            title: eventosEmpiezan.length == 1
                ? '$etiquetaSiguiente empieza ${eventosEmpiezan.first.titulo}'
                : '$etiquetaSiguiente empiezan ${eventosEmpiezan.length} eventos',
            subtitle: eventosEmpiezan.length == 1
                ? 'Así te acuerdas con tiempo y no te pilla por sorpresa.'
                : 'Hay varios compromisos cerca, mejor tenerlos en el radar.',
            icon: Icons.upcoming_rounded,
            tint: const Color(0xFF8A63F6),
            onTap: () => _abrirDia(diaSiguiente.fecha),
          ),
        );
      }

      final notaSiguiente = diaSiguiente.notaLibre?.trim() ?? '';
      if (notaSiguiente.isNotEmpty && reminders.length < 3) {
        reminders.add(
          VisualReminder(
            title: diaSiguiente.fecha == mananaIso
                ? 'Recuerda mañana'
                : '$etiquetaSiguiente te dejaste una nota',
            subtitle: notaSiguiente,
            icon: Icons.sticky_note_2_rounded,
            tint: const Color(0xFFE39C2E),
            onTap: () => _abrirDia(diaSiguiente.fecha),
          ),
        );
      }
    }

    if (reminders.isEmpty) {
      reminders.add(
        const VisualReminder(
          title: 'No tienes ninguna nota estos días',
          subtitle:
              'Si escribes una nota rápida para hoy o mañana, aparecerá aquí.',
          icon: Icons.wb_sunny_outlined,
          tint: Color(0xFF6E7CFA),
        ),
      );
    }

    return reminders.take(3).toList();
  }

  String _daysSummary(List<Disponibilidad> slots) {
    const nombresCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final indices = slots.map((slot) => slot.diaSemana).toList()..sort();

    if (_sameDays(indices, const [0, 1, 2, 3, 4])) {
      return 'Lunes a viernes';
    }
    if (_sameDays(indices, const [5, 6])) {
      return 'Fin de semana';
    }

    return indices.map((dia) => nombresCortos[dia]).join(', ');
  }

  bool _sameDays(List<int> actual, List<int> expected) {
    if (actual.length != expected.length) {
      return false;
    }
    for (var i = 0; i < actual.length; i++) {
      if (actual[i] != expected[i]) {
        return false;
      }
    }
    return true;
  }

  String _toIsoDate(DateTime fecha) {
    final value = DateTime(fecha.year, fecha.month, fecha.day);
    return value.toIso8601String().split('T').first;
  }

  bool _eventoIncluyeFecha(EventoFijo evento, String fechaIso) {
    final fecha = DateTime.tryParse(fechaIso);
    final inicio = DateTime.tryParse(evento.fecha);
    final fin = DateTime.tryParse(evento.fechaFin);
    if (fecha == null || inicio == null || fin == null) {
      return false;
    }

    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final desde = DateTime(inicio.year, inicio.month, inicio.day);
    final hasta = DateTime(fin.year, fin.month, fin.day);
    return !dia.isBefore(desde) && !dia.isAfter(hasta);
  }

  int _compararEventosPorCercania(EventoFijo a, EventoFijo b) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaA = DateTime.tryParse(a.fecha);
    final fechaB = DateTime.tryParse(b.fecha);

    if (fechaA == null && fechaB == null) {
      return 0;
    }
    if (fechaA == null) {
      return 1;
    }
    if (fechaB == null) {
      return -1;
    }

    final diaA = DateTime(fechaA.year, fechaA.month, fechaA.day);
    final diaB = DateTime(fechaB.year, fechaB.month, fechaB.day);
    final distanciaA = diaA.difference(hoy).inDays.abs();
    final distanciaB = diaB.difference(hoy).inDays.abs();

    if (distanciaA != distanciaB) {
      return distanciaA.compareTo(distanciaB);
    }

    if (a.completado != b.completado) {
      return a.completado ? 1 : -1;
    }

    return diaA.compareTo(diaB);
  }

  String _countLabel(int count, String singular, String plural) {
    return count == 1 ? '1 $singular' : '$count $plural';
  }

  String _relativeDayLabel(String fechaIso) {
    final fecha = DateTime.tryParse(fechaIso);
    if (fecha == null) {
      return 'Ese día';
    }

    const nombres = [
      'El lunes',
      'El martes',
      'El miércoles',
      'El jueves',
      'El viernes',
      'El sábado',
      'El domingo',
    ];
    return nombres[fecha.weekday - 1];
  }

  void _abrirDia(String fechaIso) {
    final fecha = DateTime.tryParse(fechaIso);
    if (fecha == null) {
      return;
    }
    controller.irAFecha(fecha);
    controller.seleccionarPantalla(1);
  }

  Widget _buildHabitoCard(Habito habito) {
    final objetivo = controller.objetivoDesdeHabito(habito);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ObjetivoCard(
        objetivo: objetivo,
        tipoLabel: 'Hábito semanal',
        onComplete: () => onCompleteObjetivo(objetivo),
        onDelete: () => onDeleteObjetivo(objetivo),
        isBusy: false,
        progressCompleted: controller.sesionesCompletadasHabito(habito),
        progressTotal: habito.sesionesPorSemana,
        progressBusy: controller.habitosRegistrando.contains(habito.id),
        onProgress: () => onTrackHabit(habito),
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
          child: FadeTransition(opacity: fade, child: child),
        );
      },
      child: controller.eventosEliminando.contains(evento.id)
          ? SizedBox(key: ValueKey('evento-hidden-${evento.id}'))
          : Padding(
              key: ValueKey('evento-${evento.id}'),
              padding: const EdgeInsets.only(bottom: 12),
              child: EventoFijoCard(
                evento: evento,
                fechaLabel: controller.fechaRangoBonito(
                  evento.fecha,
                  evento.fechaFin,
                ),
                isCompletedOverride: controller.completadoEvento(evento),
                onComplete: () => onCompleteEvento(evento),
                onEdit: () => onEditEvento(evento),
                onDelete: () => onDeleteEvento(evento),
                isBusy: controller.eventosCompletando.contains(evento.id),
              ),
            ),
    );
  }
}
