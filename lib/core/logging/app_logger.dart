import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogEntry {
  const AppLogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  final String level;
  final String message;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;
}

class AppLogger {
  static final ValueNotifier<List<AppLogEntry>> entries =
      ValueNotifier<List<AppLogEntry>>(<AppLogEntry>[]);

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log('INFO', 800, message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log('WARN', 900, message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log('ERROR', 1000, message, error: error, stackTrace: stackTrace);
  }

  static void clear() {
    entries.value = <AppLogEntry>[];
  }

  static void _log(
    String level,
    int developerLevel,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now();
    final consoleLine = _formatConsoleLine(
      level: level,
      message: message,
      timestamp: timestamp,
      error: error,
    );

    developer.log(
      message,
      name: 'VibeTrack',
      level: developerLevel,
      error: error,
      stackTrace: stackTrace,
      time: timestamp,
    );

    if (kDebugMode) {
      debugPrint(consoleLine);
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace, label: '[$level] $message');
      }
    }

    final next = List<AppLogEntry>.from(entries.value)
      ..insert(
        0,
        AppLogEntry(
          level: level,
          message: message,
          timestamp: timestamp,
          error: error,
          stackTrace: stackTrace,
        ),
      );

    if (next.length > 200) {
      next.removeRange(200, next.length);
    }
    entries.value = next;
  }

  static String _formatConsoleLine({
    required String level,
    required String message,
    required DateTime timestamp,
    Object? error,
  }) {
    final time = timestamp.toIso8601String();
    final errorSuffix = error == null ? '' : ' | error=$error';
    // return '[$time][$level][VibeTrack] $message$errorSuffix';
    return '[$level] $message$errorSuffix';
  }
}
