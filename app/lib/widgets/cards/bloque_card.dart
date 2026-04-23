import 'package:flutter/material.dart';

import '../../models/bloque_plan.dart';
import '../../theme/app_theme.dart';
import 'mini_pill.dart';
import 'tick_button.dart';

class BloqueCard extends StatelessWidget {
  const BloqueCard({
    super.key,
    required this.bloque,
    required this.tipoLabel,
    required this.onDone,
    required this.onReschedule,
  });

  final BloquePlan bloque;
  final String tipoLabel;
  final VoidCallback? onDone;
  final VoidCallback? onReschedule;

  @override
  Widget build(BuildContext context) {
    final esHecho = bloque.estado == 'hecho';
    final esFallado = bloque.estado == 'fallado';
    final esFijo = bloque.esFijo;
    final esEventoTodoElDia =
        bloque.esFijo && bloque.inicioMinutos == 0 && bloque.finMinutos == 1440;
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundGradient = esEventoTodoElDia
        ? LinearGradient(
            colors: isDark
                ? const [Color(0xFF33281A), Color(0xFF241B12)]
                : const [Color(0xFFFFFCF6), Color(0xFFF7F1E3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: isDark
                ? const [Color(0xFF1A1F28), Color(0xFF141922)]
                : [palette.cardGradientStart, palette.cardGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final chipBackground = esFijo
        ? esEventoTodoElDia
            ? (isDark ? const Color(0xFFB38A4A) : const Color(0xFF8A6732))
            : (isDark ? const Color(0xFF8DB2FF) : const Color(0xFF10131A))
        : esHecho
        ? const Color(0xFFE7F7EC)
        : esFallado
        ? const Color(0xFFFFF1E8)
        : const Color(0xFFEFF3FF);

    final chipForeground = esFijo
        ? esEventoTodoElDia
            ? (isDark ? const Color(0xFF1A1209) : Colors.white)
            : (isDark ? const Color(0xFF0D1522) : Colors.white)
        : esHecho
        ? const Color(0xFF228B57)
        : esFallado
        ? const Color(0xFFB55D1D)
        : const Color(0xFF4461D8);

    final titleColor = esEventoTodoElDia
        ? (isDark ? const Color(0xFFF6E7C8) : palette.titleColor)
        : palette.titleColor;
    final bodyColor = esEventoTodoElDia
        ? (isDark ? const Color(0xFFDCC8A1) : palette.subtitleColor)
        : palette.subtitleColor;
    final timeColor = esEventoTodoElDia
        ? (isDark ? const Color(0xFFF1D8A6) : const Color(0xFF6E5528))
        : palette.titleColor;
    final helperColor = esEventoTodoElDia
        ? (isDark ? const Color(0xFFE0CFAB) : const Color(0xFF7A6336))
        : palette.subtitleColor;

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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: chipBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      esFijo
                          ? esEventoTodoElDia
                              ? 'Evento especial'
                              : 'Evento'
                          : esHecho
                          ? 'Hecho'
                          : esFallado
                          ? 'Fallado'
                          : tipoLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: chipForeground,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!esHecho && !esFijo && onDone != null) ...[
                    TickButton(
                      tooltip: 'Marcar bloque como hecho',
                      onPressed: onDone!,
                      compact: true,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    esEventoTodoElDia
                        ? 'Todo el dia'
                        : '${bloque.inicioHora} - ${bloque.finHora}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: timeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                bloque.tituloObjetivo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              if ((bloque.detalleObjetivo ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  bloque.detalleObjetivo!,
                  style: TextStyle(color: bodyColor),
                ),
              ],
              if ((bloque.notaDia ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0x221F8A4C)
                        : const Color(0xFFEAF7EF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF275E3C)
                          : const Color(0xFFC8E7D3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF8FD4A7)
                            : const Color(0xFF2A7C4B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bloque.notaDia!,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFE1F2E6)
                                : const Color(0xFF245B39),
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (esEventoTodoElDia) ...[
                const SizedBox(height: 12),
                Text(
                  'El dia queda reservado por completo.',
                  style: TextStyle(
                    color: helperColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MiniPill(
                    label: esEventoTodoElDia
                        ? 'Dia completo'
                        : '${bloque.duracionMinutos} min',
                  ),
                  if (esFijo)
                    MiniPill(
                      label: esEventoTodoElDia
                          ? 'Reserva total'
                          : 'Hora cerrada',
                    ),
                  if (esEventoTodoElDia)
                    const MiniPill(label: 'Sin huecos disponibles'),
                  if ((bloque.notaDia ?? '').trim().isNotEmpty)
                    const MiniPill(label: 'Nota del día'),
                  if (bloque.replanificado)
                    const MiniPill(label: 'Replanificado'),
                ],
              ),
              if (!esHecho && !esFijo) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: onReschedule,
                      child: const Text('No pude, recolocar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
