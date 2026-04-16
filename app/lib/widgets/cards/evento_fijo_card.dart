import 'package:flutter/material.dart';

import '../../models/evento_fijo.dart';
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const StatusBadge(
                  label: 'Evento fijo',
                  backgroundColor: Color(0xFF10131A),
                  foregroundColor: Colors.white,
                  icon: Icons.lock_clock_rounded,
                ),
                const Spacer(),
                IconCircleButton(
                  tooltip: 'Editar evento fijo',
                  onPressed: isBusy ? null : onEdit,
                  icon: Icons.edit_outlined,
                  backgroundColor: const Color(0xFFEFF3FF),
                  foregroundColor: const Color(0xFF4461D8),
                ),
                const SizedBox(width: 8),
                IconCircleButton(
                  tooltip: 'Eliminar evento fijo',
                  onPressed: isBusy ? null : onDelete,
                  icon: isBusy
                      ? Icons.hourglass_top_rounded
                      : Icons.delete_outline_rounded,
                  backgroundColor: const Color(0xFFFFECE9),
                  foregroundColor: const Color(0xFFD64545),
                ),
                const SizedBox(width: 10),
                Text(
                  '${evento.inicioHora} - ${evento.finHora}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171B24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              evento.titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171B24),
              ),
            ),
            if ((evento.detalle ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                evento.detalle!,
                style: const TextStyle(color: Color(0xFF5F6778), height: 1.4),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MiniPill(label: fechaLabel),
                MiniPill(label: '${evento.duracionMinutos} min'),
                MiniPill(label: 'Prioridad ${evento.prioridad}/5'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
