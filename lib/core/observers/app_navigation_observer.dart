import 'package:flutter/material.dart';
import '../services/logging_service.dart';

class AppNavigationObserver extends NavigatorObserver {
  final LoggingService _logger = LoggingService();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logger.logNavigation('Pushed route: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logger.logNavigation('Popped route: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logger.logNavigation(
      'Replaced route: ${oldRoute?.settings.name} with ${newRoute?.settings.name}',
    );
  }
}