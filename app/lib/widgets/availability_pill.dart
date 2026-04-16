import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AvailabilityPill extends StatelessWidget {
  const AvailabilityPill({
    super.key,
    required this.daysLabel,
    required this.timeLabel,
  });

  final String daysLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      constraints: const BoxConstraints(minWidth: 164),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.cardGradientStart, palette.cardGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.subtleShadow,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.tertiarySurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  daysLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: palette.subtitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
