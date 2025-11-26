import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging utility for the Heart Rate Dashboard application.
///
/// Provides consistent logging across the entire application with appropriate
/// log levels based on build mode (debug vs release).
///
/// Usage:
/// ```dart
/// import 'package:heart_rate_dashboard/utils/app_logger.dart';
///
/// final logger = AppLogger.getLogger('MyClassName');
/// logger.d('Debug message');
/// logger.i('Info message');
/// logger.w('Warning message');
/// logger.e('Error message', error: e, stackTrace: stackTrace);
/// ```
class AppLogger {
  /// Cache of loggers by name to avoid creating multiple instances
  static final Map<String, Logger> _loggers = {};

  /// Get a logger instance for a specific class or module.
  ///
  /// [name] The name of the class or module (typically the class name).
  /// Returns a configured Logger instance.
  static Logger getLogger(String name) {
    if (_loggers.containsKey(name)) {
      return _loggers[name]!;
    }

    final logger = Logger(
      printer: _CustomLogPrinter(name),
      level: kDebugMode ? Level.debug : Level.warning,
      filter: ProductionFilter(),
    );

    _loggers[name] = logger;
    return logger;
  }

  /// Get a simple logger without class name prefix (for general use).
  static Logger get general => getLogger('App');
}

/// Custom log printer that includes the class/module name in the output.
class _CustomLogPrinter extends LogPrinter {
  final String className;
  final PrettyPrinter _prettyPrinter;

  _CustomLogPrinter(this.className)
    : _prettyPrinter = PrettyPrinter(
        methodCount: 0, // Don't include stack trace for normal logs
        errorMethodCount: 8, // Include stack trace for errors
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      );

  @override
  List<String> log(LogEvent event) {
    final emoji = PrettyPrinter.defaultLevelEmojis[event.level];
    final lines = _prettyPrinter.log(event);

    // Add class name to the first line
    if (lines.isNotEmpty) {
      lines[0] = '$emoji [$className] ${lines[0]}';
    }

    return lines;
  }
}
