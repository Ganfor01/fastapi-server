import 'package:flutter/material.dart';

import '../models/disponibilidad.dart';

class AvailabilityPill extends StatelessWidget {
  const AvailabilityPill({super.key, required this.slot});

  final Disponibilidad slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBF3)),
      ),
      child: Text(
        '${slot.nombreDia}  ${slot.inicioHora}-${slot.finHora}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
