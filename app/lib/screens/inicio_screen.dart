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
    required this.onCompleteObjetivo,
    required this.onDeleteObjetivo,
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
  final ValueChanged<Objetivo> onCompleteObjetivo;
  final ValueChanged<Objetivo> onDeleteObjetivo;
  final ValueChanged<EventoFijo> onEditEvento;
  final ValueChanged<EventoFijo> onDeleteEvento;

  @override
  Widget build(BuildContext context) {
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
          ...plan.eventosFijos.map(_buildEventoFijoCard),
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

  Widget _buildHabitoCard(Habito habito) {
    final objetivo = controller.objetivoDesdeHabito(habito);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ObjetivoCard(
        objetivo: objetivo,
        tipoLabel: 'Hábito semanal',
        onComplete: () => onCompleteObjetivo(objetivo),
        onDelete: () => onDeleteObjetivo(objetivo),
        isBusy: controller.objetivosActualizando.contains(habito.id),
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
                onEdit: () => onEditEvento(evento),
                onDelete: () => onDeleteEvento(evento),
                isBusy: controller.eventosActualizando.contains(evento.id),
              ),
            ),
    );
  }
}
