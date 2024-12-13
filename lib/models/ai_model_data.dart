enum AiModel {
  gemini,
  openAi,
}

class GeminiModel {
  final String name;
  final String displayName;

  const GeminiModel._(this.name, this.displayName);

  // Pro models
  static const gemini15Pro = GeminiModel._('gemini-1.5-pro', 'Gemini 1.5 Pro');
  static const gemini15ProLatest =
      GeminiModel._('gemini-1.5-pro-latest', 'Gemini 1.5 Pro (Latest)');

  // Flash models
  static const gemini15Flash =
      GeminiModel._('gemini-1.5-flash', 'Gemini 1.5 Flash');
  static const gemini15FlashLatest =
      GeminiModel._('gemini-1.5-flash-latest', 'Gemini 1.5 Flash (Latest)');
  //Gemini 1.5 Flash-8B
  static const gemini15Flash8B =
      GeminiModel._('gemini-1.5-flash-8b', 'Gemini 1.5 Flash-8B');

  // Get all model values
  static List<GeminiModel> get values => [
        gemini15Pro,
        gemini15ProLatest,
        gemini15Flash,
        gemini15FlashLatest,
        gemini15Flash8B
      ];
}

class AiModelData {
  // Updated subModels to include all Gemini models
  static const Map<AiModel, List<GeminiModel>> subModels = {
    AiModel.gemini: [
      GeminiModel.gemini15Pro,
      GeminiModel.gemini15ProLatest,
      GeminiModel.gemini15Flash,
      GeminiModel.gemini15FlashLatest,
      GeminiModel.gemini15Flash8B
    ],
    AiModel.openAi: [], // OpenAI has no sub-models
  };

  // Updated example prompts to match new models
  static const Map<String, String> examplePrompts = {
    'gemini-1.5-pro':
        'Perform advanced, complex analysis with high-quality reasoning...',
    'gemini-1.5-pro-latest':
        'Utilize the most recent improvements in the Pro model...',
    'gemini-1.5-flash': 'Process tasks quickly with lightweight, fast model...',
    'gemini-1.5-flash-latest':
        'Get the most up-to-date fast processing capabilities...',
    'gemini-1.5-flash-8b':
        'Process tasks quickly with lightweight, fast model...',
    'OpenAI':
        'Generate a creative short story about artificial intelligence...',
  };

  // Existing methods remain the same
  static List<GeminiModel> getSubModels(AiModel model) {
    return subModels[model] ?? [];
  }

  static String getPrompt(AiModel model, GeminiModel geminiModel) {
    return examplePrompts[geminiModel.name] ?? '';
  }

  static GeminiModel getDefaultGeminiModel() {
    return GeminiModel.gemini15Flash8B;
  }
}
