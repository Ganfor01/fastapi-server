import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import '../../models/evento_fijo.dart';
import '../../theme/app_theme.dart';
import 'icon_circle_button.dart';
import 'mini_pill.dart';
import 'status_badge.dart';

class EventoFijoCard extends StatelessWidget {
  const EventoFijoCard({
    super.key,
    required this.evento,
    required this.fechaLabel,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
    required this.isBusy,
    this.isCompletedOverride,
  });

  final EventoFijo evento;
  final String fechaLabel;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isBusy;
  final bool? isCompletedOverride;

  @override
  Widget build(BuildContext context) {
    final esTodoElDia = evento.esTodoElDia;
    final esMultiple = evento.esVariosDias;
    final esEspecial = esTodoElDia && !esMultiple;
    final estaCompletado = isCompletedOverride ?? evento.completado;
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundGradient = LinearGradient(
      colors: estaCompletado
          ? (isDark
                ? const [Color(0xFF1A1D22), Color(0xFF121419)]
                : const [Color(0xFFF4F5F7), Color(0xFFEDEFF2)])
          : esMultiple
          ? (isDark
                ? const [Color(0xFF1E2434), Color(0xFF151B28)]
                : const [Color(0xFFF8FAFF), Color(0xFFEAEFFD)])
          : esEspecial
          ? (isDark
                ? const [Color(0xFF33281A), Color(0xFF241B12)]
                : const [Color(0xFFFFFCF6), Color(0xFFF7F1E3)])
          : (isDark
                ? const [Color(0xFF1B212B), Color(0xFF141922)]
                : [palette.cardGradientStart, palette.cardGradientEnd]),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final badgeBackground = estaCompletado
        ? (isDark ? const Color(0xFF2A2F38) : const Color(0xFFE5E8ED))
        : esMultiple
        ? (isDark ? const Color(0xFF9FB4FF) : const Color(0xFF5267C9))
        : esEspecial
        ? (isDark ? const Color(0xFFB38A4A) : const Color(0xFF8A6732))
        : (isDark ? const Color(0xFF8DB2FF) : const Color(0xFF10131A));
    final badgeForeground = estaCompletado
        ? (isDark ? const Color(0xFFD8DEE8) : const Color(0xFF5F6B7C))
        : esMultiple
        ? (isDark ? const Color(0xFF111726) : Colors.white)
        : esEspecial
        ? (isDark ? const Color(0xFF1A1209) : Colors.white)
        : (isDark ? const Color(0xFF0D1522) : Colors.white);
    final titleColor = estaCompletado
        ? (isDark ? const Color(0xFFE4E8EF) : const Color(0xFF394150))
        : esMultiple
        ? (isDark ? const Color(0xFFE6ECFF) : const Color(0xFF24355C))
        : esEspecial
        ? (isDark ? const Color(0xFFF6E7C8) : palette.titleColor)
        : palette.titleColor;
    final timeColor = estaCompletado
        ? (isDark ? const Color(0xFFB7C0CC) : const Color(0xFF687386))
        : esMultiple
        ? (isDark ? const Color(0xFFC8D6FF) : const Color(0xFF5267C9))
        : esEspecial
        ? (isDark ? const Color(0xFFF1D8A6) : const Color(0xFF6E5528))
        : (isDark ? const Color(0xFFF3F6FB) : palette.titleColor);
    final bodyColor = estaCompletado
        ? (isDark ? const Color(0xFFA7B0BC) : const Color(0xFF727C8C))
        : esMultiple
        ? (isDark ? const Color(0xFFBECBF0) : const Color(0xFF506082))
        : esEspecial
        ? (isDark ? const Color(0xFFDCC8A1) : palette.subtitleColor)
        : palette.subtitleColor;
    final helperColor = estaCompletado
        ? (isDark ? const Color(0xFFB8C1CC) : const Color(0xFF6B7584))
        : esMultiple
        ? (isDark ? const Color(0xFFD5E0FF) : const Color(0xFF5A6FAF))
        : esEspecial
        ? (isDark ? const Color(0xFFE0CFAB) : const Color(0xFF7A6336))
        : palette.subtitleColor;
    final editBackground = isDark
        ? const Color(0xFF25324A)
        : const Color(0xFFEFF3FF);
    final editForeground = isDark
        ? const Color(0xFFB4CAFF)
        : const Color(0xFF4461D8);
    final deleteBackground = isDark
        ? const Color(0xFF3A2224)
        : const Color(0xFFFFECE9);
    final deleteForeground = isDark
        ? const Color(0xFFFFB6AE)
        : const Color(0xFFD64545);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(
                          label: estaCompletado
                              ? 'Completado'
                              : esMultiple
                              ? 'Múltiple'
                              : esTodoElDia
                              ? 'Evento especial'
                              : 'Evento',
                          backgroundColor: badgeBackground,
                          foregroundColor: badgeForeground,
                          icon: estaCompletado
                              ? Icons.check_rounded
                              : esMultiple
                              ? Icons.calendar_view_week_rounded
                              : esEspecial
                              ? Icons.auto_awesome_rounded
                              : Icons.lock_clock_rounded,
                        ),
                        Text(
                          evento.horarioLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: timeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _EventDoneButton(
                        isCompleted: estaCompletado,
                        isBusy: isBusy,
                        onPressed: onComplete,
                      ),
                      IconCircleButton(
                        tooltip: 'Editar evento',
                        onPressed: isBusy ? null : onEdit,
                        icon: Icons.edit_outlined,
                        backgroundColor: editBackground,
                        foregroundColor: editForeground,
                      ),
                      IconCircleButton(
                        tooltip: 'Eliminar evento',
                        onPressed: isBusy ? null : onDelete,
                        icon: isBusy
                            ? Icons.hourglass_top_rounded
                            : Icons.delete_outline_rounded,
                        backgroundColor: deleteBackground,
                        foregroundColor: deleteForeground,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                evento.titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              if ((evento.detalle ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  evento.detalle!,
                  style: TextStyle(color: bodyColor, height: 1.4),
                ),
              ],
              if (estaCompletado || esMultiple || esEspecial) ...[
                const SizedBox(height: 12),
                Text(
                  estaCompletado
                      ? 'Ya está marcado como hecho y seguirá aquí hasta que tú lo borres.'
                      : esMultiple
                      ? 'Reserva completa durante todo el rango.'
                      : 'Reserva completa para ese día.',
                  style: TextStyle(
                    color: helperColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MiniPill(label: fechaLabel),
                  MiniPill(
                    label: evento.esVariosDias
                        ? 'Varios días'
                        : esTodoElDia
                        ? 'Día completo'
                        : '${evento.duracionMinutos} min',
                  ),
                  if (esMultiple || esEspecial)
                    MiniPill(
                      label: esMultiple
                          ? 'Sin huecos en el rango'
                          : 'Sin huecos disponibles',
                    ),
                  if (evento.totalNotas > 0)
                    MiniPill(
                      label: evento.totalNotas == 1
                          ? '1 nota diaria'
                          : '${evento.totalNotas} notas diarias',
                    ),
                  if (estaCompletado) const MiniPill(label: 'Ya hecho'),
                  MiniPill(label: 'Prioridad ${evento.prioridad}/5'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDoneButton extends StatefulWidget {
  const _EventDoneButton({
    required this.isCompleted,
    required this.isBusy,
    required this.onPressed,
  });

  final bool isCompleted;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  State<_EventDoneButton> createState() => _EventDoneButtonState();
}

class _EventDoneButtonState extends State<_EventDoneButton>
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
  }

  @override
  void didUpdateWidget(covariant _EventDoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isCompleted && widget.isCompleted) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: widget.isCompleted
          ? 'Marcar como no completado'
          : 'Marcar evento como hecho',
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FadeTransition(
              opacity: _sparkleFade,
              child: ScaleTransition(
                scale: _sparkleScale,
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    _EventSparkDot(
                      alignment: Alignment(0, -1),
                      color: Color(0xFF2FB36B),
                      size: 7,
                    ),
                    _EventSparkDot(
                      alignment: Alignment(0.9, -0.25),
                      color: Color(0xFF4C7BF4),
                      size: 5,
                    ),
                    _EventSparkDot(
                      alignment: Alignment(-0.9, -0.2),
                      color: Color(0xFFF0B44C),
                      size: 5,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedScale(
              scale: widget.isCompleted ? 1.05 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Material(
                color: widget.isCompleted
                    ? (isDark ? const Color(0xFF2A2F38) : const Color(0xFFF1F3F6))
                    : Colors.white,
                shape: CircleBorder(
                  side: BorderSide(
                    color: widget.isCompleted
                        ? (isDark
                              ? const Color(0xFF97A2B2)
                              : const Color(0xFFB7C0CC))
                        : const Color(0xFFD9DFEA),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.isBusy ? null : widget.onPressed,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(scale: animation, child: child),
                        );
                      },
                      child: widget.isBusy
                          ? const SizedBox(
                              key: ValueKey('event-loading'),
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2.4,
                              ),
                            )
                          : Icon(
                              key: ValueKey(widget.isCompleted),
                              Icons.check_rounded,
                              size: 18,
                              color: widget.isCompleted
                                  ? (isDark
                                        ? const Color(0xFFD8DEE8)
                                        : const Color(0xFF707A89))
                                  : const Color(0xFF8A92A3),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventSparkDot extends StatelessWidget {
  const _EventSparkDot({
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
