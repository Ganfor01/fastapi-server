import 'package:flutter/material.dart';

import 'cards/mini_pill.dart';

class WeekProfileHeader extends StatelessWidget {
  const WeekProfileHeader({
    super.key,
    required this.totalPendientes,
    required this.diaLabel,
    required this.fechaLabel,
  });

  final int totalPendientes;
  final String diaLabel;
  final String fechaLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF11151D), Color(0xFF1D2430)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFF2D3645),
                child: Icon(Icons.person_rounded, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi semana',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tu vista diaria para entrar, mirar y ejecutar.',
                      style: TextStyle(color: Color(0xFFB7C0CF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MiniPill(
                label: '$diaLabel - $fechaLabel',
                backgroundColor: const Color(0xFF2A3240),
                foregroundColor: Colors.white,
              ),
              MiniPill(
                label: '$totalPendientes bloques pendientes',
                backgroundColor: const Color(0xFF1F8A4C),
                foregroundColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
