import 'package:flutter/material.dart';

class TickButton extends StatelessWidget {
  const TickButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.isBusy = false,
    this.compact = false,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final bool isBusy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 38.0;
    final iconSize = compact ? 16.0 : 18.0;
    final circleBorder = CircleBorder(
      side: const BorderSide(color: Color(0xFFD9DFEA)),
    );

    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          shape: circleBorder,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isBusy ? null : onPressed,
            customBorder: circleBorder,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isBusy
                    ? SizedBox(
                        key: const ValueKey('tick-loading'),
                        width: iconSize,
                        height: iconSize,
                        child: const CircularProgressIndicator.adaptive(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF8A92A3),
                          ),
                        ),
                      )
                    : Icon(
                        key: const ValueKey('tick-idle'),
                        Icons.check_rounded,
                        size: iconSize,
                        color: const Color(0xFF8A92A3),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
