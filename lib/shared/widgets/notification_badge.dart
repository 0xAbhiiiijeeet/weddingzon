import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final bool showDotOnly;
  final Color? color;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.showDotOnly = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color ?? Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: showDotOnly
                ? const SizedBox(width: 4, height: 4)
                : Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ],
    );
  }
}