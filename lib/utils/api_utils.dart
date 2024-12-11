import 'dart:convert';
import 'package:http/http.dart' as http;
import 'logger.dart';

class ApiUtils {
  static const String geminiBaseUrl =
      "https://generativelanguage.googleapis.com/v1/models";

  /// APIキーが有効かどうかをチェックする（Gemini向け）
  static Future<bool> verifyGeminiApiKey(String apiKey) async {
    if (apiKey.isEmpty) {
      Logger.error("APIキーが空です。");
      return false;
    }

    final url =
        Uri.parse('$geminiBaseUrl/gemini-pro:generateContent?key=$apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "test"}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        Logger.info("Gemini APIキーが有効です。");
        return true;
      } else {
        Logger.error(
            "Gemini APIキーが無効です。ステータスコード: ${response.statusCode}, レスポンス: ${response.body}");
        return false;
      }
    } catch (e) {
      Logger.error("Gemini APIキーの検証中にエラーが発生しました: $e");
      return false;
    }
  }

  /// GeminiモデルへPOSTリクエストを送信する
  static Future<String?> postToGemini(String apiKey, String inputText) async {
    if (apiKey.isEmpty) {
      Logger.error("APIキーが空です。");
      return null;
    }

    final url =
        Uri.parse('$geminiBaseUrl/gemini-pro:generateContent?key=$apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": inputText}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final resultText =
            responseBody['candidates']?[0]['content']?['parts']?[0]['text'];
        Logger.info("Gemini APIリクエスト成功: $resultText");
        return resultText;
      } else {
        Logger.error(
            "Gemini APIリクエスト失敗。ステータスコード: ${response.statusCode}, レスポンス: ${response.body}");
        return null;
      }
    } catch (e) {
      Logger.error("Gemini APIリクエスト中にエラーが発生しました: $e");
      return null;
    }
  }

  static verifyOpenAiApiKey(String apiKey) {}
}
