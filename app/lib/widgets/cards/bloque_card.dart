import 'package:flutter/material.dart';

import '../../models/bloque_plan.dart';
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

    return Card(
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
                    color: esFijo
                        ? const Color(0xFF10131A)
                        : esHecho
                        ? const Color(0xFFE7F7EC)
                        : esFallado
                        ? const Color(0xFFFFF1E8)
                        : const Color(0xFFEFF3FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    esFijo
                        ? 'Evento fijo'
                        : esHecho
                        ? 'Hecho'
                        : esFallado
                        ? 'Fallado'
                        : tipoLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: esFijo
                          ? Colors.white
                          : esHecho
                          ? const Color(0xFF228B57)
                          : esFallado
                          ? const Color(0xFFB55D1D)
                          : const Color(0xFF4461D8),
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
                  '${bloque.inicioHora} - ${bloque.finHora}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171B24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              bloque.tituloObjetivo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171B24),
              ),
            ),
            if ((bloque.detalleObjetivo ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                bloque.detalleObjetivo!,
                style: const TextStyle(color: Color(0xFF5F6778)),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MiniPill(label: '${bloque.duracionMinutos} min'),
                if (esFijo) const MiniPill(label: 'Hora cerrada'),
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
    );
  }
}
