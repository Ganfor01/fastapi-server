import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/organizador_page.dart';
import 'theme/app_theme.dart';

class AppTareas extends StatefulWidget {
  const AppTareas({super.key});

  @override
  State<AppTareas> createState() => _AppTareasState();
}

class _AppTareasState extends State<AppTareas> {
  static const _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _cargarThemeMode();
  }

  Future<void> _cargarThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modoGuardado = prefs.getString(_themeModeKey);
    var themeMode = ThemeMode.light;
    if (modoGuardado == 'dark') {
      themeMode = ThemeMode.dark;
    }

    if (!mounted) {
      return;
    }

    setState(() => _themeMode = themeMode);
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    _guardarThemeMode(mode);
  }

  Future<void> _guardarThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeModeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Liflow',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: OrganizadorPage(
        themeMode: _themeMode,
        onThemeModeSelected: _setThemeMode,
      ),
    );
  }
}
