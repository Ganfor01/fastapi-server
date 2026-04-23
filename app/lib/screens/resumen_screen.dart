import 'package:flutter/material.dart';

import '../models/habito.dart';
import '../models/plan_semanal.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_card.dart';
import '../widgets/section_title.dart';
import '../widgets/cards/mini_pill.dart';
import '../widgets/cards/stat_card.dart';

class ResumenScreen extends StatelessWidget {
  const ResumenScreen({
    super.key,
    required this.plan,
    required this.scrollController,
  });

  final PlanSemanal plan;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final habitos = plan.habitos;
    final totalSesiones = habitos.fold<int>(
      0,
      (total, habito) => total + habito.sesionesPorSemana,
    );
    final sesionesCompletadas = habitos.fold<int>(
      0,
      (total, habito) =>
          total +
          habito.sesionesCompletadasSemana.clamp(0, habito.sesionesPorSemana),
    );
    final habitosCompletados = habitos.where(_habitoCompletado).length;
    final eventosSemana = _eventosEnSemana(plan);
    final porcentaje = totalSesiones == 0
        ? 0
        : ((sesionesCompletadas / totalSesiones) * 100).round();

    return ListView(
      key: const PageStorageKey('resumen-scroll'),
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: [palette.weekHeaderStart, palette.weekHeaderEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: palette.cardBorder),
            boxShadow: [
              BoxShadow(
                color: palette.subtleShadow,
                blurRadius: 20,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: palette.weekHeaderAccent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      color: palette.weekHeaderForeground,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu resumen',
                          style: TextStyle(
                            color: palette.weekHeaderForeground,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Una vista clara de cómo va tu semana.',
                          style: TextStyle(color: palette.weekHeaderMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  MiniPill(
                    label: _rangoSemana(plan),
                    backgroundColor: palette.weekHeaderAccent,
                    foregroundColor: palette.weekHeaderForeground,
                  ),
                  MiniPill(
                    label: '$porcentaje% completado',
                    backgroundColor: palette.secondarySurface,
                    foregroundColor: palette.weekHeaderForeground,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final apilado = constraints.maxWidth < 760;
            final cards = [
              StatCard(
                title: 'Sesiones hechas',
                value: '$sesionesCompletadas/$totalSesiones',
                caption: totalSesiones == 0
                    ? 'Aún no tienes hábitos activos.'
                    : 'Ya llevas $porcentaje% de lo previsto esta semana.',
                captionMaxLines: apilado ? null : 3,
              ),
              StatCard(
                title: 'Hábitos al día',
                value: '$habitosCompletados/${habitos.length}',
                caption: habitos.isEmpty
                    ? 'Cuando añadas hábitos, verás aquí tu ritmo.'
                    : habitosCompletados == habitos.length
                    ? 'Semana muy redonda: los llevas todos al día.'
                    : 'Todavía te quedan ${habitos.length - habitosCompletados}.',
                captionMaxLines: apilado ? null : 3,
              ),
              StatCard(
                title: 'Eventos esta semana',
                value: '$eventosSemana',
                caption: eventosSemana == 0
                    ? 'Semana despejada por ahora.'
                    : eventosSemana == 1
                    ? 'Tienes un compromiso reservado.'
                    : 'Tienes varios compromisos ya colocados.',
                captionMaxLines: apilado ? null : 3,
              ),
            ];

            if (apilado) {
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i != cards.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: cards[2]),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        const SectionTitle(
          title: 'Progreso de hábitos',
          subtitle: 'Lo que ya llevas cumplido y lo que aún queda esta semana.',
        ),
        const SizedBox(height: 12),
        if (habitos.isEmpty)
          const EmptyCard(
            title: 'Todavía no hay hábitos',
            subtitle: 'Cuando empieces a añadirlos, aquí verás tu avance semanal.',
          )
        else
          ...habitos.map(
            (habito) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HabitSummaryCard(habito: habito),
            ),
          ),
        const SizedBox(height: 26),
        const SectionTitle(
          title: 'Ritmo de la semana',
          subtitle: 'Un vistazo rápido a qué días están más ligeros o más llenos.',
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: plan.dias
                  .map((dia) => _DayLoadRow(dia: dia))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  static bool _habitoCompletado(Habito habito) =>
      habito.sesionesCompletadasSemana >= habito.sesionesPorSemana;

  static int _eventosEnSemana(PlanSemanal plan) {
    final ids = <int>{};
    for (final dia in plan.dias) {
      for (final bloque in dia.bloques) {
        if (bloque.esFijo) {
          ids.add(bloque.id);
        }
      }
    }
    return ids.length;
  }

  static String _rangoSemana(PlanSemanal plan) {
    if (plan.dias.isEmpty) {
      return 'Sin semana';
    }
    final inicio = DateTime.tryParse(plan.dias.first.fecha);
    final fin = DateTime.tryParse(plan.dias.last.fecha);
    if (inicio == null || fin == null) {
      return 'Semana actual';
    }
    final diaInicio = inicio.day.toString().padLeft(2, '0');
    final diaFin = fin.day.toString().padLeft(2, '0');
    final mesInicio = inicio.month.toString().padLeft(2, '0');
    final mesFin = fin.month.toString().padLeft(2, '0');
    return '$diaInicio/$mesInicio - $diaFin/$mesFin';
  }
}

class _HabitSummaryCard extends StatelessWidget {
  const _HabitSummaryCard({required this.habito});

  final Habito habito;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final completadas = habito.sesionesCompletadasSemana.clamp(
      0,
      habito.sesionesPorSemana,
    );
    final ratio = habito.sesionesPorSemana == 0
        ? 0.0
        : completadas / habito.sesionesPorSemana;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    habito.titulo,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: palette.titleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ratio >= 1
                        ? (isDark
                              ? const Color(0xFF1E3A2A)
                              : const Color(0xFFE7F7EC))
                        : palette.secondarySurface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$completadas/${habito.sesionesPorSemana}',
                    style: TextStyle(
                      color: ratio >= 1
                          ? (isDark
                                ? const Color(0xFF96E2B4)
                                : const Color(0xFF228B57))
                          : palette.titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if ((habito.detalle ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                habito.detalle!,
                style: TextStyle(
                  color: palette.subtitleColor,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: isDark
                    ? const Color(0xFF242C38)
                    : const Color(0xFFE7EDF5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  ratio >= 1
                      ? const Color(0xFF2FB36B)
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              ratio >= 1
                  ? 'Objetivo semanal cumplido.'
                  : 'Te faltan ${habito.sesionesPorSemana - completadas} sesiones para cerrarlo.',
              style: TextStyle(
                color: palette.subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayLoadRow extends StatelessWidget {
  const _DayLoadRow({required this.dia});

  final DiaPlan dia;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cantidad = dia.bloques.length;
    final intensidad = (cantidad / 5).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              dia.nombreDia,
              style: TextStyle(
                color: palette.titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: intensidad,
                minHeight: 10,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF242C38)
                    : const Color(0xFFE7EDF5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  cantidad == 0
                      ? palette.selectionMuted
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            cantidad == 1 ? '1 bloque' : '$cantidad bloques',
            style: TextStyle(
              color: palette.subtitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
