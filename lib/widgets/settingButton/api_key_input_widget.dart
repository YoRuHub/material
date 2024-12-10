// lib/widgets/api_key_input_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/database/models/api_model.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_app/utils/snackbar_helper.dart';

class ApiKeyInputWidget extends StatefulWidget {
  final String apiType; // Gemini、OpenAIなどのAPIタイプを指定
  const ApiKeyInputWidget({super.key, required this.apiType});

  @override
  ApiKeyInputWidgetState createState() => ApiKeyInputWidgetState();
}

class ApiKeyInputWidgetState extends State<ApiKeyInputWidget> {
  final TextEditingController _apiKeyController = TextEditingController();
  late final ApiModel _apiModel;
  bool _isObscured = true; // APIキーが非表示かどうかを管理

  @override
  void initState() {
    super.initState();
    _apiModel = ApiModel();
    _loadApiKey();
  }

  // APIキーを読み込む
  Future<void> _loadApiKey() async {
    Logger.debug(widget.apiType);
    String? apiKey = await _apiModel.fetchApi(widget.apiType);

    if (apiKey != null) {
      Logger.debug(apiKey);
      setState(() {
        _apiKeyController.text = apiKey;
      });
    }
  }

  // APIキーを保存
  Future<void> _saveApiKey() async {
    String newApiKey = _apiKeyController.text.trim();
    if (newApiKey.isNotEmpty) {
      await _apiModel.upsertApi(widget.apiType, newApiKey);
      if (mounted) {
        SnackBarHelper.success(context, '${widget.apiType} APIキーを保存しました。');
      }
    } else {
      SnackBarHelper.error(context, 'APIキーを入力してください。');
    }
  }

  // APIキーのダミー検証
  Future<void> _dummyVerifyApiKey() async {
    String apiKey = _apiKeyController.text.trim();
    if (apiKey.isNotEmpty) {
      SnackBarHelper.success(context, '${widget.apiType} APIキーが有効です（ダミー検証）。');
      await _apiModel.upsertApi(widget.apiType, apiKey);
    } else {
      SnackBarHelper.error(context, 'APIキーが入力されていません。');
    }
  }

  // 表示・非表示の切り替え
  void _toggleObscure() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.apiType} API Key',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                obscureText: _isObscured, // テキストを隠す
                decoration: InputDecoration(
                  hintText: 'Enter your ${widget.apiType} API Key',
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: _toggleObscure, // 目のアイコンで表示・非表示を切り替える
                  ),
                ),
                onSubmitted: (_) => _saveApiKey(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _dummyVerifyApiKey,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Verify'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
