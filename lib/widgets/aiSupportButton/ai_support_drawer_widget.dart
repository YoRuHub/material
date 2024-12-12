import 'package:flutter/material.dart';
import 'package:flutter_app/utils/api_utils.dart';
import 'package:flutter_app/utils/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai_model_data.dart';
import 'model_selector_widget.dart';

class AiSupportDrawerWidget extends ConsumerStatefulWidget {
  const AiSupportDrawerWidget({super.key});

  @override
  AiSupportDrawerWidgetState createState() => AiSupportDrawerWidgetState();
}

class AiSupportDrawerWidgetState extends ConsumerState<AiSupportDrawerWidget>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();

  // メインAIモデルの選択状態
  AiModel _selectedMainModel = AiModel.gemini;

  // Geminiのサブモデル選択状態
  GeminiModel _selectedGeminiModel = GeminiModel.gemini15Flash;

  // プロンプトのヒントテキスト
  String _hintText = 'Enter your prompt...';

  // ローディング状態
  bool _isLoading = false;

  // アニメーションコントローラ
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _updatePrompt();

    // アニメーションコントローラの初期化
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _rotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  // プロンプト更新
  void _updatePrompt() {
    setState(() {
      _hintText =
          AiModelData.getPrompt(_selectedMainModel, _selectedGeminiModel);
    });
  }

  // 非同期でAPIにリクエストを送信
  Future<void> _sendPrompt() async {
    setState(() {
      _isLoading = true; // ローディング開始
    });

    _controller.repeat(); // アニメーション開始

    // APIリクエストの非同期処理
    final response = await ApiUtils.postToGemini(
      context: context,
      ref: ref,
      model: _selectedMainModel.name,
      modelVersion: _selectedGeminiModel.name,
      inputText: _textController.text,
    );

    Logger.debug('Response: $response');

    setState(() {
      _isLoading = false; // ローディング終了
    });
    _controller.stop(); // アニメーション停止
  }

  @override
  void dispose() {
    _controller.dispose(); // AnimationControllerの破棄
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'AI Assistant',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),

            // モデル選択（左）とサブモデル選択（右）
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ModelSelectorWidget(
                selectedMainModel: _selectedMainModel,
                selectedGeminiModel: _selectedGeminiModel,
                onMainModelChanged: (AiModel? newValue) {
                  setState(() {
                    _selectedMainModel = newValue!;
                    _selectedGeminiModel =
                        AiModelData.getSubModels(_selectedMainModel)
                            .first; // 最初のサブモデルに設定
                    _updatePrompt();
                  });
                },
                onGeminiModelChanged: (GeminiModel? newValue) {
                  setState(() {
                    _selectedGeminiModel = newValue!;
                    _updatePrompt();
                  });
                },
              ),
            ),

            // テキスト入力フィールド
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: _hintText, // ヒントテキストを設定
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    filled: true,
                  ),
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),

            // アクションボタン
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendPrompt, // ローディング中は無効化
                      icon: _isLoading
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
                          : const Icon(Icons.send),
                      label: const Text('Send Prompt'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
