import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/database/models/api_model.dart';
import 'package:flutter_app/utils/snackbar_helper.dart';
import '../../providers/api_provider.dart';

class ApiKeyInputWidget extends ConsumerStatefulWidget {
  final String apiType; // Gemini、OpenAIなどのAPIタイプを指定
  const ApiKeyInputWidget({super.key, required this.apiType});

  @override
  ApiKeyInputWidgetState createState() => ApiKeyInputWidgetState();
}

class ApiKeyInputWidgetState extends ConsumerState<ApiKeyInputWidget>
    with TickerProviderStateMixin {
  final TextEditingController _apiKeyController = TextEditingController();
  late final ApiModel _apiModel;
  bool _isObscured = true; // APIキーの表示/非表示
  bool _isVerifying = false; // 検証中フラグ
  bool _isApiKeyEmpty = true; // APIキーが空かどうかを管理
  bool _isKeyChanged = false; // 入力があった場合のフラグ
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _apiModel = ApiModel();
    _loadApiKey();

    // AnimationController の初期化
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _rotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  Future<void> _loadApiKey() async {
    final apiKey = await _apiModel.fetchApi(widget.apiType);
    if (apiKey != null) {
      setState(() {
        _apiKeyController.text = apiKey['api_key'];
        _isApiKeyEmpty = apiKey.isEmpty;
      });
    }
  }

  // Save処理：APIキーを保存し、有効性を検証する
  Future<void> _saveApiKey() async {
    String newApiKey = _apiKeyController.text.trim();

    // APIキーが空の場合は削除処理
    if (newApiKey.isEmpty) {
      await _apiModel.upsertApi(widget.apiType, '', status: '');
      setState(() {
        _isApiKeyEmpty = true;
        _isKeyChanged = false;
      });
      ref
          .read(apiStatusProvider.notifier)
          .verifyApiKey(widget.apiType, ''); // 空のキーを検証
      return;
    }

    setState(() {
      _isVerifying = true;
      _isApiKeyEmpty = false;
      _isKeyChanged = false; // 保存処理中は変更状態をリセット
    });
    _controller.repeat(); // アニメーション開始

    // APIの有効性を検証
    await ref
        .read(apiStatusProvider.notifier)
        .verifyApiKey(widget.apiType, newApiKey);

    setState(() {
      _isVerifying = false;
    });
    _controller.stop(); // アニメーション停止

    // 結果に応じて保存
    final apiStatus = ref.read(apiStatusProvider)[widget.apiType] ??
        ApiStatus.none; // nullチェック追加
    String status = apiStatus == ApiStatus.valid ? 'valid' : 'invalid';
    await _apiModel.upsertApi(widget.apiType, newApiKey, status: status);

    if (apiStatus == ApiStatus.valid) {
      if (mounted) {
        SnackBarHelper.success(context, '${widget.apiType} が有効になりました。');
      }
    }
  }

  void _toggleObscure() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  String _getFormattedApiType() {
    switch (widget.apiType.toLowerCase()) {
      case 'gemini':
        return 'Gemini';
      case 'openAi':
        return 'OpenAI';
      default:
        return widget.apiType; // 他のAPIタイプがあればそのまま返す
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiStatus = ref.watch(apiStatusProvider); // APIの有効性状態を監視

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
                '${_getFormattedApiType()} API Key',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                obscureText: _isObscured,
                decoration: InputDecoration(
                  hintText: 'Enter your API key',
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: _toggleObscure,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _isApiKeyEmpty = value.trim().isEmpty;
                    _isKeyChanged = true; // 入力がある場合に変更状態とみなす
                  });
                },
                onSubmitted: (_) => _saveApiKey(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isVerifying
                        ? AnimatedBuilder(
                            key: const ValueKey('refreshIcon'),
                            animation: _rotation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotation.value * 6.3,
                                child: const Icon(Icons.refresh,
                                    color: Colors.grey),
                              );
                            },
                          )
                        : (!_isKeyChanged &&
                                !_isApiKeyEmpty &&
                                apiStatus[widget.apiType] !=
                                    ApiStatus.none // none の場合に非表示にする
                            ? (apiStatus[widget.apiType] == ApiStatus.valid
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green,
                                    key: ValueKey('checkIcon'))
                                : const Icon(Icons.error,
                                    color: Colors.red,
                                    key: ValueKey('errorIcon')))
                            : const SizedBox.shrink()), // 空の場合や入力中は非表示
                  ),
                  ElevatedButton(
                    onPressed: _saveApiKey,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
