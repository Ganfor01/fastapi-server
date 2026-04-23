import 'package:flutter/material.dart';

import 'app.dart';
import 'supabase_bootstrap.dart';
export 'app.dart';

Future<void> main() async {
  await SupabaseBootstrap.initialize();
  runApp(const AppTareas());
}
