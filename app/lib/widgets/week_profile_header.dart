import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'cards/mini_pill.dart';

class WeekProfileHeader extends StatelessWidget {
  const WeekProfileHeader({
    super.key,
    required this.themeMode,
    required this.onThemeModeSelected,
    required this.tituloSemana,
    required this.rangoLabel,
    required this.diaLabel,
    required this.fechaLabel,
    required this.isCurrentWeek,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onToday,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeSelected;
  final String tituloSemana;
  final String rangoLabel;
  final String diaLabel;
  final String fechaLabel;
  final bool isCurrentWeek;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [palette.weekHeaderStart, palette.weekHeaderEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.subtleShadow,
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.weekHeaderAccent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: palette.weekHeaderForeground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tituloSemana,
                      style: TextStyle(
                        color: palette.weekHeaderForeground,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Muévete por tus semanas y revisa lo que viene.',
                      style: TextStyle(color: palette.weekHeaderMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _HeaderThemeButton(
                themeMode: themeMode,
                onSelected: onThemeModeSelected,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MiniPill(
                label: rangoLabel,
                backgroundColor: palette.weekHeaderAccent,
                foregroundColor: palette.weekHeaderForeground,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPreviousWeek,
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Anterior'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onNextWeek,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Siguiente'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: isCurrentWeek ? null : onToday,
                child: const Text('Hoy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderThemeButton extends StatelessWidget {
  const _HeaderThemeButton({
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: palette.secondarySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Icon(
          switch (themeMode) {
            ThemeMode.light => Icons.light_mode_rounded,
            ThemeMode.dark => Icons.dark_mode_rounded,
            ThemeMode.system => Icons.light_mode_rounded,
          },
          color: palette.weekHeaderForeground,
          size: 20,
        ),
      ),
    );
  }
}
