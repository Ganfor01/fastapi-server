import 'package:flutter/material.dart';

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
    final esTodoElDia = evento.esTodoElDia;
    final esEspecial = evento.esTodoElDia || evento.esVariosDias;
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundGradient = LinearGradient(
      colors: esEspecial
          ? (isDark
                ? const [Color(0xFF33281A), Color(0xFF241B12)]
                : const [Color(0xFFFFFCF6), Color(0xFFF7F1E3)])
          : (isDark
                ? const [Color(0xFF1B212B), Color(0xFF141922)]
                : [palette.cardGradientStart, palette.cardGradientEnd]),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final badgeBackground = esEspecial
        ? (isDark ? const Color(0xFFB38A4A) : const Color(0xFF8A6732))
        : (isDark ? const Color(0xFF8DB2FF) : const Color(0xFF10131A));
    final badgeForeground = esEspecial
        ? (isDark ? const Color(0xFF1A1209) : Colors.white)
        : (isDark ? const Color(0xFF0D1522) : Colors.white);
    final titleColor = esEspecial
        ? (isDark ? const Color(0xFFF6E7C8) : palette.titleColor)
        : palette.titleColor;
    final timeColor = esEspecial
        ? (isDark ? const Color(0xFFF1D8A6) : const Color(0xFF6E5528))
        : (isDark ? const Color(0xFFF3F6FB) : palette.titleColor);
    final bodyColor = esEspecial
        ? (isDark ? const Color(0xFFDCC8A1) : palette.subtitleColor)
        : palette.subtitleColor;
    final helperColor = esEspecial
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
                children: [
                  StatusBadge(
                    label: evento.esVariosDias
                        ? 'Viaje o rango'
                        : esTodoElDia
                        ? 'Evento especial'
                        : 'Evento',
                    backgroundColor: badgeBackground,
                    foregroundColor: badgeForeground,
                    icon: esEspecial
                        ? Icons.auto_awesome_rounded
                        : Icons.lock_clock_rounded,
                  ),
                  const Spacer(),
                  IconCircleButton(
                    tooltip: 'Editar evento',
                    onPressed: isBusy ? null : onEdit,
                    icon: Icons.edit_outlined,
                    backgroundColor: editBackground,
                    foregroundColor: editForeground,
                  ),
                  const SizedBox(width: 8),
                  IconCircleButton(
                    tooltip: 'Eliminar evento',
                    onPressed: isBusy ? null : onDelete,
                    icon: isBusy
                        ? Icons.hourglass_top_rounded
                        : Icons.delete_outline_rounded,
                    backgroundColor: deleteBackground,
                    foregroundColor: deleteForeground,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    evento.horarioLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: timeColor,
                    ),
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
              if (esEspecial) ...[
                const SizedBox(height: 12),
                Text(
                  evento.esVariosDias
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
                  if (esEspecial)
                    MiniPill(
                      label: evento.esVariosDias
                          ? 'Sin huecos en el rango'
                          : 'Sin huecos disponibles',
                    ),
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
