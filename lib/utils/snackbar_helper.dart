import 'package:flutter/material.dart';

class SnackBarColors {
  static const Color error = Color(0xFFFFCDD2); // 淡い赤
  static const Color warning = Color(0xFFFFF3E0); // 淡いオレンジ
  static const Color success = Color(0xFFC8E6C9); // 淡い緑
  static const Color info = Color(0xFFBBDEFB); // 淡い青
}

class SnackBarHelper {
  static SnackBar error(String message) {
    return SnackBar(
      content: Row(
        children: [
          Icon(Icons.error, color: Colors.red[900]), // エラーアイコン
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold, // 文字を太字に設定
              ),
            ),
          ),
        ],
      ),
      backgroundColor: SnackBarColors.error,
      behavior: SnackBarBehavior.floating,
    );
  }

  static SnackBar warning(String message) {
    return SnackBar(
      content: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[900]), // 警告アイコン
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold, // 文字を太字に設定
              ),
            ),
          ),
        ],
      ),
      backgroundColor: SnackBarColors.warning,
      behavior: SnackBarBehavior.floating,
    );
  }

  static SnackBar success(String message) {
    return SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[900]), // 成功アイコン
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold, // 文字を太字に設定
              ),
            ),
          ),
        ],
      ),
      backgroundColor: SnackBarColors.success,
      behavior: SnackBarBehavior.floating,
    );
  }

  static SnackBar info(String message) {
    return SnackBar(
      content: Row(
        children: [
          Icon(Icons.info, color: Colors.blue[900]), // 情報アイコン
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold, // 文字を太字に設定
              ),
            ),
          ),
        ],
      ),
      backgroundColor: SnackBarColors.info,
      behavior: SnackBarBehavior.floating,
    );
  }
}
