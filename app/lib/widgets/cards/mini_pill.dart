import 'package:flutter/material.dart';

class MiniPill extends StatelessWidget {
  const MiniPill({
    super.key,
    required this.label,
    this.backgroundColor = const Color(0xFFF4F6FA),
    this.foregroundColor = const Color(0xFF5F6778),
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
