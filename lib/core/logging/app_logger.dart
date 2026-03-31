import 'dart:developer' as developer;

class AppLogger {
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'VibeTrack', error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'VibeTrack',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'VibeTrack',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
