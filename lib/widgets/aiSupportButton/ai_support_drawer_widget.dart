// lib/screens/ai_support_drawer_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai_model_data.dart';
import '../../utils/snackbar_helper.dart';
import 'model_selector_widget.dart';

class AiSupportDrawerWidget extends ConsumerStatefulWidget {
  const AiSupportDrawerWidget({super.key});

  @override
  AiSupportDrawerWidgetState createState() => AiSupportDrawerWidgetState();
}

class AiSupportDrawerWidgetState extends ConsumerState<AiSupportDrawerWidget> {
  final TextEditingController _textController = TextEditingController();

  // メインAIモデルの選択状態
  AiModel _selectedMainModel = AiModel.gemini;

  // Geminiのサブモデル選択状態
  GeminiModel _selectedGeminiModel = GeminiModel.gemini15;

  @override
  void initState() {
    super.initState();
    _updatePrompt();
  }

  // プロンプト更新
  void _updatePrompt() {
    _textController.text =
        AiModelData.getPrompt(_selectedMainModel, _selectedGeminiModel);
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
                    hintText: 'Enter your prompt...',
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
                      onPressed: () {
                        String targetModel =
                            _selectedMainModel == AiModel.gemini
                                ? AiModelData.subModels[AiModel.gemini]![
                                    _selectedGeminiModel.index]
                                : 'OpenAI';
                        SnackBarHelper.success(
                            context, 'Sent prompt to $targetModel.');
                      },
                      icon: const Icon(Icons.send),
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
