import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Eliminar',
    this.cancelLabel = 'Cancelar',
    this.confirmBackgroundColor = const Color(0xFFD64545),
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmBackgroundColor;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Eliminar',
    String cancelLabel = 'Cancelar',
    Color confirmBackgroundColor = const Color(0xFFD64545),
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return ConfirmDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          confirmBackgroundColor: confirmBackgroundColor,
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: confirmBackgroundColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
