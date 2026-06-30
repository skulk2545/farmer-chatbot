import 'package:flutter/foundation.dart';

class LoggingService {
  /// Centralized logging service that only logs messages in debug builds.
  
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      print('[DEBUG]${tag != null ? ' [$tag]' : ''}: $message');
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      print('[INFO]${tag != null ? ' [$tag]' : ''}: $message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      print('[WARNING]${tag != null ? ' [$tag]' : ''}: $message');
    }
  }

  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[ERROR]${tag != null ? ' [$tag]' : ''}: $message');
      if (error != null) {
        print('Details: $error');
      }
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }
}
