import 'package:flutter/material.dart';

class AppSnackbar {
  static void showSuccess(BuildContext context, String mensaje) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: const Color(0xFF11151D),
      ),
    );
  }

  static void showError(BuildContext context, String mensaje) {
    final limpio = mensaje.replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(limpio)));
  }

  const AppSnackbar._();
}
