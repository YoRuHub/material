//lib\utils\snackbar_helper.dart
import 'package:flutter/material.dart';
import '../widgets/snackbar/snackbar_position.dart';
import '../widgets/snackbar/snackbar_widget.dart';
import '../widgets/snackbar/snackbar_type.dart';

class SnackBarHelper {
  static final List<OverlayEntry> _snackBars = [];

  /// Show a custom snackbar with stacking and auto-removal
  static void showCustomSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Icon icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);

    // Declare overlayEntry first
    late final OverlayEntry overlayEntry;

    // Assign overlayEntry after declaration
    overlayEntry = OverlayEntry(
      builder: (context) {
        final index = _snackBars.indexOf(overlayEntry);
        final bottomOffset = SnackBarPosition.calculateBottomOffset(
          context,
          _snackBars,
          index,
        );

        return Positioned(
          bottom: bottomOffset, // Dynamic bottom based on screen and index
          right: 8,
          child: SnackBarWidget(
            message: message,
            backgroundColor: backgroundColor,
            icon: icon,
          ),
        );
      },
    );

    // Add the new snackbar to the list and overlay
    _snackBars.add(overlayEntry);
    overlay.insert(overlayEntry);

    // Update positions of all snackbars
    _updateSnackBarPositions();

    // Automatically remove the snackbar after the specified duration
    Future.delayed(duration, () {
      _removeSnackBar(overlayEntry);
    });
  }

  /// Remove a specific snackbar and reposition others
  static void _removeSnackBar(OverlayEntry entry) {
    if (!_snackBars.contains(entry)) return;

    _snackBars.remove(entry);
    entry.remove();

    // Update positions of remaining snackbars
    _updateSnackBarPositions();
  }

  /// Update positions of all active snackbars
  static void _updateSnackBarPositions() {
    for (int i = 0; i < _snackBars.length; i++) {
      _snackBars[i].markNeedsBuild();
    }
  }

  /// Show a success snackbar
  static void success(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    showCustomSnackBar(
      context,
      message: message,
      backgroundColor: SnackBarType.successColor,
      icon: SnackBarType.successIcon,
      duration: duration,
    );
  }

  /// Show an error snackbar
  static void error(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    showCustomSnackBar(
      context,
      message: message,
      backgroundColor: SnackBarType.errorColor,
      icon: SnackBarType.errorIcon,
      duration: duration,
    );
  }

  /// Show a warning snackbar
  static void warning(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    showCustomSnackBar(
      context,
      message: message,
      backgroundColor: SnackBarType.warningColor,
      icon: SnackBarType.warningIcon,
      duration: duration,
    );
  }

  /// Show an info snackbar
  static void info(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    showCustomSnackBar(
      context,
      message: message,
      backgroundColor: SnackBarType.infoColor,
      icon: SnackBarType.infoIcon,
      duration: duration,
    );
  }
}
