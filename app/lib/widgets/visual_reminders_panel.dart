import 'package:flutter/material.dart';

class VisualReminder {
  const VisualReminder({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;
}

class VisualRemindersPanel extends StatelessWidget {
  const VisualRemindersPanel({
    super.key,
    required this.reminders,
  });

  final List<VisualReminder> reminders;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: reminders
          .map(
            (reminder) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReminderCard(
                reminder: reminder,
                isDark: isDark,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.isDark,
  });

  final VisualReminder reminder;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final baseTint = reminder.tint;
    final softBackground = Color.alphaBlend(
      baseTint.withValues(alpha: isDark ? 0.18 : 0.10),
      isDark ? const Color(0xFF151A22) : const Color(0xFFFFFCF7),
    );
    final outline = baseTint.withValues(alpha: isDark ? 0.32 : 0.22);
    final iconBackground = baseTint.withValues(alpha: isDark ? 0.20 : 0.14);
    final subtitleColor = isDark
        ? const Color(0xFF9AA4B2)
        : const Color(0xFF667085);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: reminder.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: softBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: outline),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  reminder.icon,
                  size: 20,
                  color: baseTint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reminder.subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
