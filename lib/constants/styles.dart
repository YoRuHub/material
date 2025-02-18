// lib/constants/styles.dart
import 'package:flutter/material.dart';

class DialogButtonStyles {
  static final ButtonStyle cancel = ElevatedButton.styleFrom(
    backgroundColor: Colors.grey[300],
    foregroundColor: Colors.black87,
  );

  static final ButtonStyle confirm = ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  );

  static final ButtonStyle destructive = ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
  );
}
