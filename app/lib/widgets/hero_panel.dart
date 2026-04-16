import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.themeMode,
    required this.onThemeModeSelected,
    required this.onAddHabit,
    required this.onAddEvent,
    required this.onAvailability,
    required this.onPlan,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeSelected;
  final VoidCallback onAddHabit;
  final VoidCallback onAddEvent;
  final VoidCallback onAvailability;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [palette.heroStart, palette.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: palette.heroBorder),
        boxShadow: [
          BoxShadow(
            color: palette.subtleShadow,
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: palette.heroChipBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Organizador automático de vida',
                  style: TextStyle(
                    color: palette.heroChipForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              _ThemeModeButton(
                themeMode: themeMode,
                onSelected: onThemeModeSelected,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Tu semana, ordenada sola.',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.08,
              color: palette.titleColor,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Añade hábitos y eventos. Luego marca tus huecos y deja que la app organice la semana.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: palette.subtitleColor,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onAddHabit,
                icon: const Icon(Icons.repeat_rounded),
                label: const Text('Hábito'),
              ),
              OutlinedButton.icon(
                onPressed: onAddEvent,
                icon: const Icon(Icons.event),
                label: const Text('Evento'),
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.onSurface,
                  backgroundColor: palette.secondarySurface.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.themeMode,
    required this.onSelected,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Apariencia',
      initialValue: themeMode,
      onSelected: onSelected,
      color: Theme.of(context).colorScheme.surface,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (context) => const [
        PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
        PopupMenuItem(value: ThemeMode.dark, child: Text('Oscuro')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: palette.secondarySurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.heroBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_themeIcon(themeMode), size: 18, color: palette.titleColor),
            const SizedBox(width: 8),
            Text(
              'Modo',
              style: TextStyle(
                color: palette.titleColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.system => Icons.light_mode_rounded,
    };
  }
}
