import 'package:flutter/material.dart';

import '../controllers/organizador_controller.dart';
import '../models/evento_fijo.dart';
import '../models/habito.dart';
import '../models/objetivo.dart';
import '../models/plan_semanal.dart';
import '../models/tarea_flexible.dart';
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
    required this.scrollController,
    required this.onAddTask,
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
  final ScrollController scrollController;
  final VoidCallback onAddTask;
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
          onAddTask: onAddTask,
          onAddHabit: onAddHabit,
          onAddEvent: onAddEvent,
          onAvailability: onAvailability,
          onPlan: onPlan,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Objetivos activos',
                value: '${plan.estadisticas.objetivosActivos}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Bloques pendientes',
                value: '${plan.estadisticas.bloquesPendientes}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionTitle(
          title: 'Tareas flexibles',
          subtitle:
              'Cosas que quieres hacer antes de una fecha, pero sin hora fija.',
        ),
        const SizedBox(height: 12),
        if (plan.tareasFlexibles.isEmpty)
          const EmptyCard(
            title: 'No hay tareas flexibles todavia',
            subtitle: 'Prueba con algo como estudiar 5 horas antes del jueves.',
          )
        else
          ...plan.tareasFlexibles.map(_buildTareaFlexibleCard),
        const SizedBox(height: 24),
        const SectionTitle(
          title: 'Habitos',
          subtitle: 'Rutinas que quieres repetir varias veces a la semana.',
        ),
        const SizedBox(height: 12),
        if (plan.habitos.isEmpty)
          const EmptyCard(
            title: 'No hay habitos todavia',
            subtitle: 'Anade algo como entrenar 3 dias o leer 4 sesiones.',
          )
        else
          ...plan.habitos.map(_buildHabitoCard),
        const SizedBox(height: 24),
        const SectionTitle(
          title: 'Eventos fijos',
          subtitle: 'Compromisos con hora cerrada que la app nunca movera.',
        ),
        const SizedBox(height: 12),
        if (plan.eventosFijos.isEmpty)
          const EmptyCard(
            title: 'No hay eventos fijos todavia',
            subtitle:
                'Anade cosas como examenes, citas o reuniones para reservar ese hueco.',
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
            title: 'Aun no hay disponibilidad',
            subtitle:
                'Define tus dias y horas disponibles para que la semana se organice sola.',
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: plan.disponibilidad
                .map((slot) => AvailabilityPill(slot: slot))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildTareaFlexibleCard(TareaFlexible tarea) {
    final objetivo = controller.objetivoDesdeTareaFlexible(tarea);

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
      child: controller.objetivosEliminando.contains(tarea.id)
          ? SizedBox(key: ValueKey('objetivo-hidden-${tarea.id}'))
          : Padding(
              key: ValueKey('objetivo-${tarea.id}'),
              padding: const EdgeInsets.only(bottom: 12),
              child: ObjetivoCard(
                objetivo: objetivo,
                tipoLabel: 'Tarea flexible',
                onComplete: () => onCompleteObjetivo(objetivo),
                onDelete: () => onDeleteObjetivo(objetivo),
                isBusy: controller.objetivosActualizando.contains(tarea.id),
              ),
            ),
    );
  }

  Widget _buildHabitoCard(Habito habito) {
    final objetivo = controller.objetivoDesdeHabito(habito);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ObjetivoCard(
        objetivo: objetivo,
        tipoLabel: 'Habito semanal',
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
                fechaLabel: controller.fechaConDiaBonita(evento.fecha),
                onEdit: () => onEditEvento(evento),
                onDelete: () => onDeleteEvento(evento),
                isBusy: controller.eventosActualizando.contains(evento.id),
              ),
            ),
    );
  }
}
