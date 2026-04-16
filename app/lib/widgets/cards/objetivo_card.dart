import 'package:flutter/material.dart';

import '../../models/objetivo.dart';
import 'icon_circle_button.dart';
import 'mini_pill.dart';
import 'status_badge.dart';
import 'tick_button.dart';

class ObjetivoCard extends StatelessWidget {
  const ObjetivoCard({
    super.key,
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
                  Expanded(
                    child: Row(
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
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: estaCompletado
                                  ? const Color(0xFFE7F7EC)
                                  : visual.badgeBackground,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tipoLabel,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: estaCompletado
                                    ? const Color(0xFF228B57)
                                    : visual.badgeForeground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: AnimatedSwitcher(
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
                          ? Align(
                              key: const ValueKey('completed-actions'),
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  const StatusBadge(
                                    label: 'Completado',
                                    backgroundColor: Color(0xFF22A861),
                                    foregroundColor: Colors.white,
                                    icon: Icons.check_rounded,
                                  ),
                                  IconCircleButton(
                                    tooltip: 'Eliminar objetivo',
                                    onPressed: onDelete,
                                    icon: Icons.delete_outline_rounded,
                                    backgroundColor: const Color(0xFFFFECE9),
                                    foregroundColor: const Color(0xFFD64545),
                                  ),
                                ],
                              ),
                            )
                          : Align(
                              key: const ValueKey('complete-action'),
                              alignment: Alignment.centerRight,
                              child: TickButton(
                                tooltip: 'Completar objetivo',
                                onPressed: onComplete,
                                isBusy: isBusy,
                              ),
                            ),
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
                  MiniPill(
                    label: visual.helperLabel,
                    backgroundColor: visual.helperBackground,
                    foregroundColor: visual.helperForeground,
                  ),
                  MiniPill(label: 'Prioridad ${objetivo.prioridad}/5'),
                  MiniPill(label: '${objetivo.duracionMinutos} min'),
                  MiniPill(label: '${objetivo.sesionesPorSemana} sesiones'),
                  if (objetivo.fechaLimite != null)
                    MiniPill(label: 'Limite ${objetivo.fechaLimite}'),
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
