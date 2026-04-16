import 'package:flutter/material.dart';

import '../controllers/organizador_controller.dart';
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
    required this.scrollController,
  });

  final PlanSemanal plan;
  final OrganizadorController controller;
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
          totalPendientes: plan.estadisticas.bloquesPendientes,
          diaLabel: dias[controller.diaSeleccionado].nombreDia,
          fechaLabel: controller.fechaBonita(
            dias[controller.diaSeleccionado].fecha,
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle(
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
          const EmptyCard(
            title: 'Este dia esta libre',
            subtitle:
                'Cuando planifiques la semana, aqui apareceran tus bloques.',
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
                    ? () => controller.replanificarBloque(bloque)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
