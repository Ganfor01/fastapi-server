import 'package:flutter/material.dart';

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.onAddTask,
    required this.onAddHabit,
    required this.onAddEvent,
    required this.onAvailability,
    required this.onPlan,
  });

  final VoidCallback onAddTask;
  final VoidCallback onAddHabit;
  final VoidCallback onAddEvent;
  final VoidCallback onAvailability;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFFFDFEFF), Color(0xFFEFF3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFDDE4F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Organizador automatico de vida',
              style: TextStyle(
                color: Color(0xFF4461D8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tu semana, ordenada sola.',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: Color(0xFF171B24),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Anade tareas flexibles, habitos y eventos con hora fija. Luego marca tus huecos y deja que la app organice la semana.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF5F6778),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onAddTask,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tarea flexible'),
              ),
              OutlinedButton.icon(
                onPressed: onAddHabit,
                icon: const Icon(Icons.repeat_rounded),
                label: const Text('Habito'),
              ),
              OutlinedButton.icon(
                onPressed: onAddEvent,
                icon: const Icon(Icons.event),
                label: const Text('Evento fijo'),
              ),
              OutlinedButton.icon(
                onPressed: onAvailability,
                icon: const Icon(Icons.schedule),
                label: const Text('Disponibilidad'),
              ),
              OutlinedButton.icon(
                onPressed: onPlan,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Planificar semana'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
