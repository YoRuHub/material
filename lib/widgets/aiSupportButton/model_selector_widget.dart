// lib/widgets/model_selector_widget.dart

import 'package:flutter/material.dart';
import '../../models/ai_model_data.dart';

class ModelSelectorWidget extends StatelessWidget {
  final AiModel selectedMainModel;
  final GeminiModel selectedGeminiModel;
  final ValueChanged<AiModel?> onMainModelChanged;
  final ValueChanged<GeminiModel?> onGeminiModelChanged;

  const ModelSelectorWidget({
    super.key,
    required this.selectedMainModel,
    required this.selectedGeminiModel,
    required this.onMainModelChanged,
    required this.onGeminiModelChanged,
  });

  @override
  Widget build(BuildContext context) {
    // AiModelDataからサブモデルを取得
    final subModels = AiModelData.getSubModels(selectedMainModel);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 左側：メインAIモデル選択 (幅1)
        Flexible(
          flex: 1, // 幅の比率 1
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI Model'),
              DropdownButton<AiModel>(
                value: selectedMainModel,
                isExpanded: true,
                onChanged: onMainModelChanged,
                items: AiModel.values.map((AiModel model) {
                  return DropdownMenuItem<AiModel>(
                    value: model,
                    child: Text(model == AiModel.gemini ? 'Gemini' : 'OpenAI'),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16.0), // 余白

        // 右側：Geminiサブモデル選択 (幅2)
        if (selectedMainModel == AiModel.gemini)
          Flexible(
            flex: 2, // 幅の比率 2
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gemini Version',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<GeminiModel>(
                  value: selectedGeminiModel,
                  isExpanded: true,
                  onChanged: onGeminiModelChanged,
                  items: GeminiModel.values.map((GeminiModel model) {
                    return DropdownMenuItem<GeminiModel>(
                      value: model,
                      child: Text(subModels[model.index]),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
