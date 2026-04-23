import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static const _url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (!isConfigured) {
      return;
    }

    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }
}
