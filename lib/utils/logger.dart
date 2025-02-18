import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum LogLevel { debug, info, error, warning }

class Logger {
  static LogLevel currentLevel = LogLevel.info; // デフォルトは INFO

  static Future<void> initialize(bool isDebug) async {
    if (isDebug) {
      currentLevel = LogLevel.debug;
    } else {
      currentLevel = LogLevel.info;
    }
  }

  static void debug(String message) {
    _log(LogLevel.debug, message);
  }

  static void info(String message) {
    _log(LogLevel.info, message);
  }

  static void error(String message) {
    _log(LogLevel.error, message);
  }

  static void _log(LogLevel level, String message) {
    if (_shouldLog(level)) {
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
      final formattedDate = formatter.format(now);
      final levelString = _getLevelString(level);

      // ログレベルとメッセージの間に適切なスペースを挿入
      final formattedLog =
          '$formattedDate [$levelString]'.padRight(30) + message;

      debugPrint(formattedLog);
    }
  }

  static bool _shouldLog(LogLevel level) {
    return level.index >= currentLevel.index;
  }

  static String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.error:
        return 'ERROR';
      default:
        return 'UNKNOWN';
    }
  }
}
