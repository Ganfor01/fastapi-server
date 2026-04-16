import 'package:flutter/material.dart';

import '../controllers/organizador_controller.dart';
import '../models/bloque_plan.dart';
import '../models/plan_semanal.dart';
import '../widgets/day_chip.dart';
import '../widgets/empty_card.dart';
import '../widgets/section_title.dart';
import '../widgets/week_profile_header.dart';
import '../widgets/cards/bloque_card.dart';

class MiSemanaScreen extends StatelessWidget {
  const MiSemanaScreen({
    super.key,
    required this.plan,
    required this.controller,
    required this.themeMode,
    required this.onThemeModeSelected,
    required this.onRescheduleBloque,
    required this.scrollController,
  });

  final PlanSemanal plan;
  final OrganizadorController controller;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeSelected;
  final ValueChanged<BloquePlan> onRescheduleBloque;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final dias = plan.dias;
    final diaActivo = dias[controller.diaSeleccionado];

    return ListView(
      key: const PageStorageKey('agenda-scroll'),
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 120),
      children: [
        WeekProfileHeader(
          themeMode: themeMode,
          onThemeModeSelected: onThemeModeSelected,
          tituloSemana: controller.weekOffset == 0
              ? 'Mi semana'
              : 'Semana de ${controller.mesSemanaBonito(plan)}',
          rangoLabel: controller.rangoSemanaBonito(plan),
          diaLabel: dias[controller.diaSeleccionado].nombreDia,
          fechaLabel: controller.fechaBonita(
            dias[controller.diaSeleccionado].fecha,
          ),
          isCurrentWeek: controller.weekOffset == 0,
          onPreviousWeek: () => controller.cambiarSemana(-1),
          onNextWeek: () => controller.cambiarSemana(1),
          onToday: controller.irASemanaActual,
        ),
        const SizedBox(height: 24),
        SectionTitle(
          title: controller.weekOffset == 0
              ? 'Agenda de la semana'
              : 'Agenda de esa semana',
          subtitle: controller.weekOffset == 0
              ? 'Tu plan diario en una vista limpia y directa.'
              : 'Ideal para revisar viajes, eventos y lo que se acerca.',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: dias
                .map(
                  (dia) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: DayChip(
                      dia: dia,
                      selected: dia.diaSemana == controller.diaSeleccionado,
                      onTap: () => controller.seleccionarDia(dia.diaSemana),
                      fechaBonita: controller.fechaBonita(dia.fecha),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (diaActivo.bloques.isEmpty)
          EmptyCard(
            title: controller.weekOffset == 0
                ? 'Este día está libre'
                : 'No hay nada en este día',
            subtitle: controller.weekOffset == 0
                ? 'Cuando planifiques la semana, aquí aparecerán tus bloques.'
                : 'Puedes seguir avanzando semanas para ver eventos futuros.',
          )
        else
          ...diaActivo.bloques.map(
            (bloque) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BloqueCard(
                bloque: bloque,
                tipoLabel: controller.tipoLabel(bloque.tipoObjetivo),
                onDone: bloque.estado == 'pendiente' && !bloque.esFijo
                    ? () => controller.marcarBloqueHecho(bloque)
                    : null,
                onReschedule: bloque.estado == 'pendiente' && !bloque.esFijo
                    ? () => onRescheduleBloque(bloque)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
