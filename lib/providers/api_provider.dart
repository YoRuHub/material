import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/api_utils.dart';

/// APIの有効性状態を表す列挙型
enum ApiStatus { valid, invalid, none }

/// APIの有効性を管理する StateNotifier
class ApiStatusNotifier extends StateNotifier<Map<String, ApiStatus>> {
  ApiStatusNotifier() : super({});

  /// APIの有効性を検証して状態を更新する
  Future<void> verifyApiKey(String apiType, String apiKey) async {
    if (apiKey.isEmpty) {
      // APIキーが空なら状態を"none"にリセット
      state = {...state, apiType: ApiStatus.none};
      return;
    }

    // 初期状態は"none"とする
    state = {...state, apiType: ApiStatus.none};

    bool isValid = false;

    // APIごとに検証処理を実行
    switch (apiType) {
      case 'Gemini':
        isValid = await ApiUtils.verifyGeminiApiKey(apiKey);
        break;
      case 'OpenAI':
        isValid = await ApiUtils.verifyOpenAiApiKey(apiKey);
        break;
      // 他のAPIタイプがあれば追加
      default:
        isValid = false;
        break;
    }

    // 検証結果を反映
    state = {
      ...state,
      apiType: isValid ? ApiStatus.valid : ApiStatus.invalid,
    };
  }

  /// 指定されたAPIの有効性状態を取得
  ApiStatus getStatus(String apiType) {
    return state[apiType] ?? ApiStatus.none;
  }

  /// API設定をプロバイダーにセットする
  void updateStatus(String apiType, ApiStatus status) {
    // 空の場合は状態をnoneに設定
    if (apiType.isEmpty) {
      state = {
        ...state,
        apiType: ApiStatus.none,
      };
    } else {
      state = {
        ...state,
        apiType: status,
      };
    }
  }
}

/// Riverpodプロバイダ
final apiStatusProvider =
    StateNotifierProvider<ApiStatusNotifier, Map<String, ApiStatus>>(
  (ref) => ApiStatusNotifier(),
);
