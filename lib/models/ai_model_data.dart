// AIの種類
enum AiModel {
  gemini,
  openAi,
}

// Geminiのサブモデル
enum GeminiModel {
  gemini15,
  gemini15Flash,
}

class AiModelData {
  // サブモデル表示用のMap
  static final Map<AiModel, List<String>> subModels = {
    AiModel.gemini: ['Gemini 1.5', 'Gemini 1.5 Flash'],
  };

  // プロンプト例
  static final Map<String, String> examplePrompts = {
    'Gemini 1.5': 'Write a Python script to analyze stock market trends...',
    'Gemini 1.5 Flash': 'Analyze real-time data quickly for insights...',
    'OpenAI':
        'Generate a creative short story about artificial intelligence...',
  };

  // サブモデル選択の例
  static List<String> getSubModels(AiModel model) {
    return subModels[model] ?? [];
  }

  // プロンプト例取得
  static String getPrompt(AiModel model, GeminiModel? geminiModel) {
    if (model == AiModel.gemini && geminiModel != null) {
      return examplePrompts[subModels[model]![geminiModel.index]] ?? '';
    } else if (model == AiModel.openAi) {
      return examplePrompts['OpenAI'] ?? '';
    }
    return '';
  }
}
