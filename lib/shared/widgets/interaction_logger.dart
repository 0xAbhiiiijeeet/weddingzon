import 'package:flutter/material.dart';
import '../../core/services/logging_service.dart';

class InteractionLogger extends StatelessWidget {
  final Widget child;

  const InteractionLogger({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final logger = LoggingService();

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        logger.logInteraction(
          'User tapped at (${event.position.dx.toStringAsFixed(2)}, ${event.position.dy.toStringAsFixed(2)})',
        );
      },
      child: child,
    );
  }
}