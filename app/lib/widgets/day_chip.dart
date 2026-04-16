import 'package:flutter/material.dart';

import '../models/plan_semanal.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10131A) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFF10131A) : const Color(0xFFE7EBF3),
          ),
        ),
        child: Column(
          children: [
            Text(
              dia.nombreDia.substring(0, 3),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF171B24),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fechaBonita,
              style: TextStyle(
                color: selected ? Colors.white70 : const Color(0xFF6A7285),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
