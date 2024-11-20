import 'package:flutter/material.dart';

class SnackBarHelper {
  /// Show a success snackbar
  static void success(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: duration,
    );
  }

  /// Show an error snackbar
  static void error(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.red,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: duration,
    );
  }

  /// Show a warning snackbar
  static void warning(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange,
      icon: const Icon(Icons.warning, color: Colors.white),
      duration: duration,
    );
  }

  /// Show an info snackbar
  static void info(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.blue,
      icon: const Icon(Icons.info, color: Colors.white),
      duration: duration,
    );
  }

  /// Private method to show a snackbar
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Icon icon,
    required Duration duration,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
