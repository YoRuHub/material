// lib/models/ai_model_data.dart

enum AiModel {
  gemini,
  openAi,
}

class GeminiModel {
  final String name;
  final String displayName;

  const GeminiModel._(this.name, this.displayName);

  static const gemini15Flash =
      GeminiModel._('gemini-1.5-flash', 'Gemini 1.5 Flash');

  static List<GeminiModel> get values => [gemini15Flash];
}

class AiModelData {
  // AiModelごとのサブモデルリスト
  static const Map<AiModel, List<GeminiModel>> subModels = {
    AiModel.gemini: [GeminiModel.gemini15Flash],
    AiModel.openAi: [], // OpenAIにはサブモデルがない例
  };

  // プロンプト例
  static const Map<String, String> examplePrompts = {
    'gemini-1.5': 'Write a Python script to analyze stock market trends...',
    'gemini-1.5-flash':
        'Handle high-speed data processing for instant results...',
    'OpenAI':
        'Generate a creative short story about artificial intelligence...',
  };

  // サブモデルリストを取得
  static List<GeminiModel> getSubModels(AiModel model) {
    return subModels[model] ?? [];
  }

  // プロンプト例を取得
  static String getPrompt(AiModel model, GeminiModel geminiModel) {
    return examplePrompts[geminiModel.name] ?? '';
  }
}
