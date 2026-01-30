import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    debugPrint('[NAV] navigateTo: $routeName');
    return navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  Future<dynamic> navigateToReplacement(String routeName, {Object? arguments}) {
    debugPrint('[NAV] navigateToReplacement: $routeName');
    return navigatorKey.currentState!.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  void goBack() {
    debugPrint('[NAV] goBack');
    return navigatorKey.currentState!.pop();
  }

  Future<dynamic> pushNamedAndRemoveUntil(
    String routeName, {
    Object? arguments,
  }) {
    debugPrint('[NAV] pushNamedAndRemoveUntil: $routeName');
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}