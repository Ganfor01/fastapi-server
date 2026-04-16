import 'package:flutter/material.dart';

import 'screens/organizador_page.dart';
import 'theme/app_theme.dart';

class AppTareas extends StatelessWidget {
  const AppTareas({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Liflow',
      theme: AppTheme.theme,
      home: const OrganizadorPage(),
    );
  }
}
