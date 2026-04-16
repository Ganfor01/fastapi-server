import 'package:flutter/material.dart';

class AppTheme {
  static const Color _lightPrimary = Color(0xFF4C7BF4);
  static const Color _darkPrimary = Color(0xFF8DB2FF);

  static ThemeData get lightTheme => _buildTheme(
    scheme: ColorScheme.fromSeed(
      seedColor: _lightPrimary,
      brightness: Brightness.light,
    ).copyWith(
      primary: _lightPrimary,
      onPrimary: Colors.white,
      secondary: const Color(0xFF6C8EEA),
      onSecondary: Colors.white,
      error: const Color(0xFFD64545),
      onError: Colors.white,
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF111827),
    ),
    palette: const AppPalette(
      heroStart: Color(0xFFF9FBFF),
      heroEnd: Color(0xFFF1F5FD),
      heroBorder: Color(0xFFD9E2F0),
      heroChipBackground: Color(0xFFE8F0FF),
      heroChipForeground: Color(0xFF4167C9),
      weekHeaderStart: Color(0xFFEEF3FB),
      weekHeaderEnd: Color(0xFFE2EAF6),
      weekHeaderForeground: Color(0xFF162033),
      weekHeaderMuted: Color(0xFF657186),
      weekHeaderAccent: Color(0xFFFFFFFF),
      cardGradientStart: Color(0xFFFFFFFF),
      cardGradientEnd: Color(0xFFF7F9FC),
      cardBorder: Color(0xFFE2E8F0),
      secondarySurface: Color(0xFFF4F7FB),
      tertiarySurface: Color(0xFFEFF4FB),
      pillForeground: Color(0xFF5D6778),
      titleColor: Color(0xFF111827),
      subtitleColor: Color(0xFF667085),
      subtleShadow: Color(0x1022304A),
      selectionBackground: Color(0xFF111827),
      selectionForeground: Colors.white,
      selectionMuted: Color(0xFFD4D9E3),
    ),
  );

  static ThemeData get darkTheme => _buildTheme(
    scheme: ColorScheme.fromSeed(
      seedColor: _darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _darkPrimary,
      onPrimary: const Color(0xFF09111F),
      secondary: const Color(0xFF6E8FE4),
      onSecondary: const Color(0xFF09111F),
      error: const Color(0xFFFF8A7A),
      onError: const Color(0xFF21100D),
      surface: const Color(0xFF111318),
      onSurface: const Color(0xFFF3F6FB),
    ),
    palette: const AppPalette(
      heroStart: Color(0xFF151922),
      heroEnd: Color(0xFF0E1219),
      heroBorder: Color(0xFF283140),
      heroChipBackground: Color(0xFF1C2740),
      heroChipForeground: Color(0xFF9EBBFF),
      weekHeaderStart: Color(0xFF191E28),
      weekHeaderEnd: Color(0xFF11151D),
      weekHeaderForeground: Color(0xFFF4F7FC),
      weekHeaderMuted: Color(0xFF98A6BC),
      weekHeaderAccent: Color(0xFF202836),
      cardGradientStart: Color(0xFF171B23),
      cardGradientEnd: Color(0xFF12161D),
      cardBorder: Color(0xFF27303B),
      secondarySurface: Color(0xFF1A1F28),
      tertiarySurface: Color(0xFF202734),
      pillForeground: Color(0xFFC1CAD8),
      titleColor: Color(0xFFF4F7FC),
      subtitleColor: Color(0xFF98A2B3),
      subtleShadow: Color(0x30000000),
      selectionBackground: Color(0xFFF4F7FC),
      selectionForeground: Color(0xFF111827),
      selectionMuted: Color(0xFF95A2B6),
    ),
  );

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required AppPalette palette,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          scheme.brightness == Brightness.light
              ? const Color(0xFFF3F5F8)
              : const Color(0xFF0B0E13),
      extensions: [palette],
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: palette.cardBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            scheme.brightness == Brightness.light
                ? const Color(0xEFFFFFFF)
                : const Color(0xEE12161D),
        elevation: 0,
        indicatorColor:
            scheme.brightness == Brightness.light
                ? const Color(0xFFDFE9FF)
                : const Color(0xFF24324A),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? scheme.onSurface : palette.subtitleColor,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: scheme.onSurface,
          backgroundColor:
              scheme.brightness == Brightness.light
                  ? const Color(0xCCFFFFFF)
                  : const Color(0x661A1F28),
          side: BorderSide(color: palette.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: palette.titleColor,
        displayColor: palette.titleColor,
      ),
    );
  }

  const AppTheme._();
}

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.heroStart,
    required this.heroEnd,
    required this.heroBorder,
    required this.heroChipBackground,
    required this.heroChipForeground,
    required this.weekHeaderStart,
    required this.weekHeaderEnd,
    required this.weekHeaderForeground,
    required this.weekHeaderMuted,
    required this.weekHeaderAccent,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.cardBorder,
    required this.secondarySurface,
    required this.tertiarySurface,
    required this.pillForeground,
    required this.titleColor,
    required this.subtitleColor,
    required this.subtleShadow,
    required this.selectionBackground,
    required this.selectionForeground,
    required this.selectionMuted,
  });

  final Color heroStart;
  final Color heroEnd;
  final Color heroBorder;
  final Color heroChipBackground;
  final Color heroChipForeground;
  final Color weekHeaderStart;
  final Color weekHeaderEnd;
  final Color weekHeaderForeground;
  final Color weekHeaderMuted;
  final Color weekHeaderAccent;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final Color cardBorder;
  final Color secondarySurface;
  final Color tertiarySurface;
  final Color pillForeground;
  final Color titleColor;
  final Color subtitleColor;
  final Color subtleShadow;
  final Color selectionBackground;
  final Color selectionForeground;
  final Color selectionMuted;

  @override
  AppPalette copyWith({
    Color? heroStart,
    Color? heroEnd,
    Color? heroBorder,
    Color? heroChipBackground,
    Color? heroChipForeground,
    Color? weekHeaderStart,
    Color? weekHeaderEnd,
    Color? weekHeaderForeground,
    Color? weekHeaderMuted,
    Color? weekHeaderAccent,
    Color? cardGradientStart,
    Color? cardGradientEnd,
    Color? cardBorder,
    Color? secondarySurface,
    Color? tertiarySurface,
    Color? pillForeground,
    Color? titleColor,
    Color? subtitleColor,
    Color? subtleShadow,
    Color? selectionBackground,
    Color? selectionForeground,
    Color? selectionMuted,
  }) {
    return AppPalette(
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      heroBorder: heroBorder ?? this.heroBorder,
      heroChipBackground: heroChipBackground ?? this.heroChipBackground,
      heroChipForeground: heroChipForeground ?? this.heroChipForeground,
      weekHeaderStart: weekHeaderStart ?? this.weekHeaderStart,
      weekHeaderEnd: weekHeaderEnd ?? this.weekHeaderEnd,
      weekHeaderForeground: weekHeaderForeground ?? this.weekHeaderForeground,
      weekHeaderMuted: weekHeaderMuted ?? this.weekHeaderMuted,
      weekHeaderAccent: weekHeaderAccent ?? this.weekHeaderAccent,
      cardGradientStart: cardGradientStart ?? this.cardGradientStart,
      cardGradientEnd: cardGradientEnd ?? this.cardGradientEnd,
      cardBorder: cardBorder ?? this.cardBorder,
      secondarySurface: secondarySurface ?? this.secondarySurface,
      tertiarySurface: tertiarySurface ?? this.tertiarySurface,
      pillForeground: pillForeground ?? this.pillForeground,
      titleColor: titleColor ?? this.titleColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      subtleShadow: subtleShadow ?? this.subtleShadow,
      selectionBackground: selectionBackground ?? this.selectionBackground,
      selectionForeground: selectionForeground ?? this.selectionForeground,
      selectionMuted: selectionMuted ?? this.selectionMuted,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      heroBorder: Color.lerp(heroBorder, other.heroBorder, t)!,
      heroChipBackground:
          Color.lerp(heroChipBackground, other.heroChipBackground, t)!,
      heroChipForeground:
          Color.lerp(heroChipForeground, other.heroChipForeground, t)!,
      weekHeaderStart: Color.lerp(weekHeaderStart, other.weekHeaderStart, t)!,
      weekHeaderEnd: Color.lerp(weekHeaderEnd, other.weekHeaderEnd, t)!,
      weekHeaderForeground:
          Color.lerp(weekHeaderForeground, other.weekHeaderForeground, t)!,
      weekHeaderMuted:
          Color.lerp(weekHeaderMuted, other.weekHeaderMuted, t)!,
      weekHeaderAccent:
          Color.lerp(weekHeaderAccent, other.weekHeaderAccent, t)!,
      cardGradientStart:
          Color.lerp(cardGradientStart, other.cardGradientStart, t)!,
      cardGradientEnd: Color.lerp(cardGradientEnd, other.cardGradientEnd, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      secondarySurface:
          Color.lerp(secondarySurface, other.secondarySurface, t)!,
      tertiarySurface:
          Color.lerp(tertiarySurface, other.tertiarySurface, t)!,
      pillForeground: Color.lerp(pillForeground, other.pillForeground, t)!,
      titleColor: Color.lerp(titleColor, other.titleColor, t)!,
      subtitleColor: Color.lerp(subtitleColor, other.subtitleColor, t)!,
      subtleShadow: Color.lerp(subtleShadow, other.subtleShadow, t)!,
      selectionBackground:
          Color.lerp(selectionBackground, other.selectionBackground, t)!,
      selectionForeground:
          Color.lerp(selectionForeground, other.selectionForeground, t)!,
      selectionMuted: Color.lerp(selectionMuted, other.selectionMuted, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
