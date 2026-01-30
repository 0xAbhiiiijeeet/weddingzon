import 'dart:developer' as developer;

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();

  factory LoggingService() {
    return _instance;
  }

  LoggingService._internal();

  void info(String message, {String name = 'INFO'}) {
    developer.log(message, name: name, level: 800);
  }

  void warning(String message, {String name = 'WARNING'}) {
    developer.log(message, name: name, level: 900);
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'ERROR',
  }) {
    developer.log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  void debug(String message, {String name = 'DEBUG'}) {
    developer.log(message, name: name, level: 500);
  }

  void logNavigation(String message) {
    info(message, name: 'NAVIGATION');
  }

  void logInteraction(String message) {
    info(message, name: 'INTERACTION');
  }

  void logNetwork(String message) {
    info(message, name: 'NETWORK');
  }
}