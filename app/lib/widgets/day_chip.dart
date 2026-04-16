import 'package:flutter/material.dart';

import '../models/plan_semanal.dart';
import '../theme/app_theme.dart';

class DayChip extends StatelessWidget {
  const DayChip({
    super.key,
    required this.dia,
    required this.selected,
    required this.onTap,
    required this.fechaBonita,
  });

  final DiaPlan dia;
  final bool selected;
  final VoidCallback onTap;
  final String fechaBonita;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final nombreDiaCorto = switch (dia.nombreDia) {
      'Miercoles' || 'Miércoles' => 'Mie',
      'Sabado' || 'Sábado' => 'Sab',
      _ => dia.nombreDia.substring(0, 3),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? palette.selectionBackground : palette.secondarySurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? palette.selectionBackground : palette.cardBorder,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: palette.subtleShadow,
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              nombreDiaCorto,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? palette.selectionForeground : palette.titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fechaBonita,
              style: TextStyle(
                color: selected ? palette.selectionMuted : palette.subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
