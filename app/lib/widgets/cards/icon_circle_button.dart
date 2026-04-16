import 'package:flutter/material.dart';

class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}
