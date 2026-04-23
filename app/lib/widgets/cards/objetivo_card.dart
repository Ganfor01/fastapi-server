import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/objetivo.dart';
import '../../theme/app_theme.dart';
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
    this.progressCompleted,
    this.progressTotal,
    this.onProgress,
    this.progressBusy = false,
  });

  final Objetivo objetivo;
  final String tipoLabel;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final bool isBusy;
  final int? progressCompleted;
  final int? progressTotal;
  final VoidCallback? onProgress;
  final bool progressBusy;

  @override
  Widget build(BuildContext context) {
    final estaCompletado = objetivo.completado;
    final usaProgresoSemanal =
        progressCompleted != null && progressTotal != null && onProgress != null;
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = _visualObjetivo(objetivo.tipo, isDark);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: estaCompletado
              ? LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF132019), Color(0xFF0F1814)]
                      : const [Color(0xFFF8FCF9), Color(0xFFF1FAF4)],
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
                                ? (isDark
                                      ? const Color(0xFF1B3726)
                                      : const Color(0xFFE7F7EC))
                                : visual.iconBackground,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            estaCompletado ? Icons.check_rounded : visual.icon,
                            color: estaCompletado
                                ? (isDark
                                      ? const Color(0xFF7ED89F)
                                      : const Color(0xFF228B57))
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
                                  ? (isDark
                                        ? const Color(0xFF1B3726)
                                        : const Color(0xFFE7F7EC))
                                  : visual.badgeBackground,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tipoLabel,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: estaCompletado
                                    ? (isDark
                                          ? const Color(0xFF7ED89F)
                                          : const Color(0xFF228B57))
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
                          : usaProgresoSemanal
                          ? Align(
                              key: const ValueKey('weekly-progress-action'),
                              alignment: Alignment.centerRight,
                              child: _WeeklyProgressButton(
                                completed: progressCompleted!,
                                total: progressTotal!,
                                isBusy: progressBusy,
                                onPressed: onProgress!,
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
                      ? palette.subtitleColor
                      : palette.titleColor,
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
                    color: palette.subtitleColor,
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
                    MiniPill(label: 'Límite ${objetivo.fechaLimite}'),
                ],
              ),
              if (usaProgresoSemanal) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Dejar este hábito'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(0xFFFFB6AE)
                          : const Color(0xFFD64545),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

_ObjetivoVisual _visualObjetivo(String tipo, bool isDark) {
  switch (tipo) {
    case 'habito':
    default:
      return _ObjetivoVisual(
        icon: Icons.repeat_rounded,
        iconBackground: isDark
            ? const Color(0xFF1A3426)
            : const Color(0xFFE9F7EE),
        iconColor: isDark
            ? const Color(0xFF7ED89F)
            : const Color(0xFF1F8A4C),
        badgeBackground: isDark
            ? const Color(0xFF203626)
            : const Color(0xFFEAF8EF),
        badgeForeground: isDark
            ? const Color(0xFF92E4B0)
            : const Color(0xFF1F8A4C),
        helperLabel: 'Rutina semanal',
        helperBackground: isDark
            ? const Color(0xFF203626)
            : const Color(0xFFEAF8EF),
        helperForeground: isDark
            ? const Color(0xFF92E4B0)
            : const Color(0xFF1F8A4C),
        backgroundColors: isDark
            ? const [Color(0xFF161F1A), Color(0xFF101813)]
            : const [Color(0xFFFFFFFF), Color(0xFFF7FCF8)],
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

class _WeeklyProgressButton extends StatefulWidget {
  const _WeeklyProgressButton({
    required this.completed,
    required this.total,
    required this.isBusy,
    required this.onPressed,
  });

  final int completed;
  final int total;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  State<_WeeklyProgressButton> createState() => _WeeklyProgressButtonState();
}

class _WeeklyProgressButtonState extends State<_WeeklyProgressButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebrationController;
  late final Animation<double> _sparkleFade;
  late final Animation<double> _sparkleScale;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _sparkleFade = CurvedAnimation(
      parent: _celebrationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _sparkleScale = Tween<double>(begin: 0.7, end: 1.15).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: Curves.easeOutBack,
      ),
    );
    _celebrationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _celebrationController.reset();
      }
    });

    if (_isComplete(widget.completed, widget.total)) {
      _celebrationController.value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant _WeeklyProgressButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasComplete = _isComplete(oldWidget.completed, oldWidget.total);
    final isComplete = _isComplete(widget.completed, widget.total);
    if (!wasComplete && isComplete) {
      HapticFeedback.lightImpact();
      _celebrationController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  bool _isComplete(int completed, int total) => total > 0 && completed >= total;

  @override
  Widget build(BuildContext context) {
    final completed = widget.completed;
    final total = widget.total;
    final isBusy = widget.isBusy;
    final ratio = total <= 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final isComplete = _isComplete(completed, total);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: isComplete
          ? 'Hábito completado esta semana'
          : 'Marcar una sesión semanal',
      child: InkWell(
        onTap: isBusy || isComplete ? null : widget.onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FadeTransition(
                  opacity: _sparkleFade,
                  child: ScaleTransition(
                    scale: _sparkleScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _SparkDot(
                          alignment: const Alignment(0, -1),
                          color: isDark
                              ? const Color(0xFF92E4B0)
                              : const Color(0xFF2FB36B),
                          size: 8,
                        ),
                        _SparkDot(
                          alignment: const Alignment(0.92, -0.38),
                          color: isDark
                              ? const Color(0xFFB9CCFF)
                              : const Color(0xFF4C7BF4),
                          size: 6,
                        ),
                        _SparkDot(
                          alignment: const Alignment(-0.92, -0.2),
                          color: isDark
                              ? const Color(0xFFE6BD74)
                              : const Color(0xFFF0B44C),
                          size: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: ratio),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedRatio, _) {
                    return SizedBox(
                      width: 62,
                      height: 62,
                      child: CircularProgressIndicator(
                        value: animatedRatio,
                        strokeWidth: 5,
                        backgroundColor: isDark
                            ? const Color(0xFF243128)
                            : const Color(0xFFE7EDF5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? const Color(0xFF92E4B0)
                              : const Color(0xFF2FB36B),
                        ),
                      ),
                    );
                  },
                ),
                AnimatedScale(
                  scale: isComplete ? 1.06 : 1,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFE3EBE5)
                          : const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFC8D5CC)
                            : const Color(0xFFD9DFEA),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? const Color(0x22000000)
                              : const Color(0x120F172A),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: isComplete
                            ? Icon(
                                key: const ValueKey('weekly-check'),
                                Icons.check_rounded,
                                size: 20,
                                color: isDark
                                    ? const Color(0xFF1F8A4C)
                                    : const Color(0xFF2FB36B),
                              )
                            : Column(
                                key: ValueKey('weekly-counter-$completed-$total'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$completed/$total',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                if (isBusy)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A211C)
                            : const Color(0xFFFFFFFF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? const Color(0x22000000)
                                : const Color(0x120F172A),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SparkDot extends StatelessWidget {
  const _SparkDot({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
