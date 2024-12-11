import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ai_model_data.dart';
import '../../providers/api_provider.dart';

class ModelSelectorWidget extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // AiModelDataからサブモデルを取得
    final subModels = AiModelData.getSubModels(selectedMainModel);

    // APIの有効性状態を監視
    final apiStatus = ref.watch(apiStatusProvider);

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
                onChanged: (model) {
                  // メインモデルが有効な場合のみ選択可能
                  if (apiStatus[model?.name] == ApiStatus.valid) {
                    onMainModelChanged(model);
                  }
                },
                items: AiModel.values.map((AiModel model) {
                  final isValid = apiStatus[model.name] == ApiStatus.valid;
                  return DropdownMenuItem<AiModel>(
                    value: model,
                    enabled: isValid, // 無効なモデルは選択できない
                    child: Text(
                      model == AiModel.gemini ? 'Gemini' : 'OpenAI',
                      style: TextStyle(
                        color: isValid ? null : Colors.grey, // 無効な場合は色を変更
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16.0), // 余白

        // 右側：Geminiサブモデル選択 (幅2) → OpenAI選択時は表示しない
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
