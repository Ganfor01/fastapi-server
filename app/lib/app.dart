import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_gate_screen.dart';
import 'screens/organizador_page.dart';
import 'supabase_bootstrap.dart';
import 'theme/app_theme.dart';

class AppTareas extends StatefulWidget {
  const AppTareas({super.key});

  @override
  State<AppTareas> createState() => _AppTareasState();
}

class _AppTareasState extends State<AppTareas> {
  static const _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;
  Session? _session;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _cargarThemeMode();
    if (SupabaseBootstrap.isConfigured) {
      final auth = Supabase.instance.client.auth;
      _session = auth.currentSession;
      _authSubscription = auth.onAuthStateChange.listen((state) {
        if (!mounted) {
          return;
        }
        setState(() {
          _session = state.session;
        });
      });
    }
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

  Future<void> _cerrarSesion() async {
    if (!SupabaseBootstrap.isConfigured) {
      return;
    }
    await Supabase.instance.client.auth.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = !SupabaseBootstrap.isConfigured
        ? const _SupabaseConfigMissingScreen()
        : (_session == null
              ? const AuthGateScreen()
              : OrganizadorPage(
                  themeMode: _themeMode,
                  onThemeModeSelected: _setThemeMode,
                  onSignOut: _cerrarSesion,
                ));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weekai',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: home,
    );
  }
}

class _SupabaseConfigMissingScreen extends StatelessWidget {
  const _SupabaseConfigMissingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Falta configurar Supabase Auth',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Arranca la app con tus claves usando dart-define para SUPABASE_URL y SUPABASE_ANON_KEY.',
                        style: TextStyle(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
