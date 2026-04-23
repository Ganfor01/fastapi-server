import 'package:flutter/material.dart';

import '../models/evento_fijo.dart';

class MiniMonthCalendar extends StatefulWidget {
  const MiniMonthCalendar({
    super.key,
    required this.initialDate,
    required this.selectedDate,
    required this.eventos,
    required this.onSelectDate,
  });

  final DateTime initialDate;
  final DateTime selectedDate;
  final List<EventoFijo> eventos;
  final ValueChanged<DateTime> onSelectDate;

  @override
  State<MiniMonthCalendar> createState() => _MiniMonthCalendarState();
}

class _MiniMonthCalendarState extends State<MiniMonthCalendar> {
  late DateTime _visibleMonth;
  late final Set<String> _eventDates;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
    );
    _eventDates = _buildEventDates(widget.eventos);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = theme.colorScheme;
    final days = _buildCalendarDays(_visibleMonth);
    final selected = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10151D) : const Color(0xFFFFFCF7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A3140)
                      : const Color(0xFFD9D2C4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  _monthLabel(_visibleMonth),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                _MonthArrowButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () {
                    setState(() {
                      _visibleMonth = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month - 1,
                      );
                    });
                  },
                ),
                const SizedBox(width: 8),
                _MonthArrowButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () {
                    setState(() {
                      _visibleMonth = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Toca un día para saltar a su semana.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark
                    ? const Color(0xFF98A2B3)
                    : const Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: const [
                _WeekdayLabel('L'),
                _WeekdayLabel('M'),
                _WeekdayLabel('X'),
                _WeekdayLabel('J'),
                _WeekdayLabel('V'),
                _WeekdayLabel('S'),
                _WeekdayLabel('D'),
              ],
            ),
            const SizedBox(height: 10),
            ..._buildWeekRows(
              days: days,
              selected: selected,
              today: normalizedToday,
              palette: palette,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeekRows({
    required List<DateTime> days,
    required DateTime selected,
    required DateTime today,
    required ColorScheme palette,
    required bool isDark,
  }) {
    final rows = <Widget>[];
    for (var i = 0; i < days.length; i += 7) {
      final week = days.skip(i).take(7).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 7 < days.length ? 8 : 0),
          child: Row(
            children: week
                .map(
                  (day) => Expanded(
                    child: _CalendarDayCell(
                      date: day,
                      isCurrentMonth: day.month == _visibleMonth.month,
                      isSelected: _sameDay(day, selected),
                      isToday: _sameDay(day, today),
                      hasEvent: _eventDates.contains(_iso(day)),
                      isDark: isDark,
                      tint: palette.primary,
                      onTap: () => widget.onSelectDate(day),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }
    return rows;
  }

  List<DateTime> _buildCalendarDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final offset = first.weekday - 1;
    final start = first.subtract(Duration(days: offset));
    final last = DateTime(month.year, month.month + 1, 0);
    final trailing = 7 - last.weekday;
    final end = last.add(Duration(days: trailing == 7 ? 0 : trailing));

    final days = <DateTime>[];
    for (
      DateTime day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      days.add(day);
    }

    if (days.length == 35 || days.length == 42) {
      return days;
    }

    final missing = days.length < 35 ? 35 - days.length : 42 - days.length;
    for (var i = 0; i < missing; i++) {
      days.add(days.last.add(const Duration(days: 1)));
    }
    return days;
  }

  Set<String> _buildEventDates(List<EventoFijo> eventos) {
    final dates = <String>{};
    for (final evento in eventos) {
      final inicio = DateTime.tryParse(evento.fecha);
      final fin = DateTime.tryParse(evento.fechaFin);
      if (inicio == null || fin == null) {
        continue;
      }
      for (
        DateTime day = DateTime(inicio.year, inicio.month, inicio.day);
        !day.isAfter(DateTime(fin.year, fin.month, fin.day));
        day = day.add(const Duration(days: 1))
      ) {
        dates.add(_iso(day));
      }
    }
    return dates;
  }

  String _monthLabel(DateTime month) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  String _iso(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')
        .first;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF98A2B3)
                : const Color(0xFF667085),
          ),
        ),
      ),
    );
  }
}

class _MonthArrowButton extends StatelessWidget {
  const _MonthArrowButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171D27) : const Color(0xFFF3EEE3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3140) : const Color(0xFFE5DDCD),
          ),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.hasEvent,
    required this.isDark,
    required this.tint,
    required this.onTap,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final bool hasEvent;
  final bool isDark;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = isSelected
        ? tint.withValues(alpha: isDark ? 0.26 : 0.12)
        : Colors.transparent;
    final border = isSelected
        ? tint.withValues(alpha: isDark ? 0.42 : 0.22)
        : isToday
        ? (isDark ? const Color(0xFF39445A) : const Color(0xFFD9D1BF))
        : Colors.transparent;
    final textColor = !isCurrentMonth
        ? (isDark ? const Color(0xFF556070) : const Color(0xFFB8B2A5))
        : isSelected
        ? tint
        : (isDark ? const Color(0xFFE1E8F5) : const Color(0xFF273142));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: hasEvent
                      ? const Color(0xFF4E7CF4)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

