import 'package:flutter/material.dart';

class SnackBarPosition {
  /// Calculate the dynamic bottom offset based on the index of the snackbar.
  static double calculateBottomOffset(
      BuildContext context, List<OverlayEntry> snackBars, int index) {
    final screenHeight = MediaQuery.of(context).size.height;
    const snackBarHeight = 56.0; // Approximate height of each snackbar

    // Calculate dynamic bottom offset based on the number of snackbars and screen height
    final bottomOffset = 8.0 + (index * snackBarHeight);

    // Ensure the snackbars don't go off-screen
    final maxBottomOffset = screenHeight - snackBarHeight * (snackBars.length);
    return bottomOffset > maxBottomOffset ? maxBottomOffset : bottomOffset;
  }
}
