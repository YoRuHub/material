import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/database/models/api_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/node.dart';
import 'json_converter.dart';
import 'logger.dart';
import 'node_operations.dart';
import 'snackbar_helper.dart';

class ApiUtils {
  /// Geminiモデルの初期化
  static GenerativeModel _initializeGeminiClient(String apiKey,
      {String model = 'gemini-1.5'}) {
    return GenerativeModel(
      model: model,
      apiKey: apiKey,
    );
  }

  /// APIキーが有効かどうかをチェックする（Gemini向け）
  static Future<bool> verifyGeminiApiKey(String apiKey) async {
    // APIキーの基本的な形式チェック
    if (apiKey.isEmpty) {
      Logger.error("APIキーが空です。");
      return false;
    }

    // APIキーの基本的な形式検証（オプション：必要に応じてより詳細な検証を追加）
    if (apiKey.length < 39 || !apiKey.startsWith('AI')) {
      Logger.error("APIキーの形式が不正です。");
      return false;
    }

    final client = _initializeGeminiClient(apiKey);
    const prompt = 'test';

    try {
      // コンテンツの生成を試みる
      final content = [Content.text(prompt)];
      final response = await client.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        Logger.info("Gemini APIキーが正常に検証されました。");
        return true;
      } else {
        Logger.error("APIから空のレスポンスが返されました。");
        return false;
      }
    } on GenerativeAIException catch (e) {
      // Google Generative AIに特化した例外処理
      Logger.error("APIキー検証中にエラーが発生しました: ${e.message}");
      return false;
    } catch (e) {
      // 予期せぬ一般的な例外の処理
      Logger.error("予期せぬエラーが発生しました: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> postToGemini({
    required BuildContext context,
    required WidgetRef ref,
    required String model,
    required String modelVersion,
    required String inputText,
  }) async {
    final apiInfo = await ApiModel().fetchApi(model);
    final apiKey = apiInfo?['api_key'];
    final apiStatus = apiInfo?['status'];

    // APIキーの基本的な検証
    if (apiKey == null || apiKey.isEmpty) {
      Logger.error("APIキーが空です。");
      return null;
    }

    // APIの有効性を検証
    if (apiStatus == null || apiStatus.isEmpty) {
      Logger.error("APIが有効化されていません。");
      return null;
    }

    // クライアントの初期化
    final client = _initializeGeminiClient(apiKey, model: modelVersion);

    try {
      // 固定プロンプト
      final systemInstruction = Content.text(
          'Generate a structured JSON object containing a "nodes" array. '
          'Each node should contain a "id", "title", a "contents", and a "color" field, where "color" is a hex value in the format "#RRGGBB" or "#RRGGBBAA". '
          'The "nodes" array should be an ordered list of nodes. Each node should have a unique "id" field (e.g., "id": 1, "id": 2, etc.). '
          'For nodes with related content, establish logical connections between them using the "node_maps" and "node_link_maps" structures. '
          '"node_maps" should represent hierarchical or group-based relationships (e.g., which nodes belong together), while "node_link_maps" should represent direct relationships (e.g., which nodes are linked or related in one direction only, not cyclic). '
          'Ensure that the resulting JSON object has a proper structure like this: '
          '{"nodes": [{"id": 1, "title": "node title", "contents": "node content", "color": "#RRGGBB"}], "node_maps": {"1": [2]}, "node_link_maps": {"1": [3]}}. '
          'Please ensure that the node mappings and links are meaningful, logically connected based on the content of each node, and not cyclic. Do not simply follow an example format; instead, focus on logical relationships, ensuring that links and parent-child relationships are one-way and non-circular.');

      final response = await client.generateContent(
        [systemInstruction, Content.text(inputText)],
        generationConfig: GenerationConfig(
          temperature: 0.5,
          maxOutputTokens: 2048,
          responseMimeType: 'application/json',
        ),
      );

      final resultText = response.text;
      if (resultText == null || resultText.isEmpty) {
        Logger.error("Geminiからの応答が空です。");
        return null;
      }

      // JSONレスポンスのパース
      Map<String, dynamic>? parsedResult;
      try {
        parsedResult = _parseNodeMapResponse(resultText);
      } on FormatException catch (e, stackTrace) {
        Logger.error("JSONのフォーマットが不正です: $e");
        Logger.debug("スタックトレース: $stackTrace");
        return null;
      }

      if (parsedResult == null) {
        Logger.error("レスポンスのJSONパースに失敗しました: $resultText");
        return null;
      }

      // 構造の検証
      if (!_validateNodeMapStructure(parsedResult)) {
        Logger.error("ノードマップの構造が不正です: $parsedResult");
        return null;
      }

      // データのインポート
      if (context.mounted) {
        try {
          await importJsonFromApi(
            context: context,
            ref: ref,
            jsonContent: resultText,
          );
          Logger.info("JSONインポート処理が完了しました。");
        } catch (e, stackTrace) {
          Logger.error("JSONインポート中にエラーが発生しました: $e");
          Logger.debug("スタックトレース: $stackTrace");
          return null;
        }
      }

      Logger.info("Gemini APIリクエスト成功: ノードマップを生成しました。");
      return parsedResult;
    } on TimeoutException catch (e, stackTrace) {
      Logger.error("Gemini APIリクエストがタイムアウトしました: $e");
      Logger.debug("スタックトレース: $stackTrace");
    } on Exception catch (e, stackTrace) {
      Logger.error("Gemini APIリクエスト中に予期しないエラーが発生: $e");
      Logger.debug("スタックトレース: $stackTrace");
    }
    return null;
  }

  /// レスポンステキストからJSONをパースする内部メソッド
  static Map<String, dynamic>? _parseNodeMapResponse(String responseText) {
    try {
      // JSONコードブロックの抽出（```json ... ```）
      final jsonMatch =
          RegExp(r'```json\s*(.+?)```', dotAll: true).firstMatch(responseText);

      if (jsonMatch == null) {
        // JSONコードブロックが見つからない場合、生のテキストを試す
        return json.decode(responseText);
      }

      // 抽出されたJSONをパース
      return json.decode(jsonMatch.group(1)!.trim());
    } catch (e) {
      Logger.error("JSONパース中にエラーが発生: $e");
      return null;
    }
  }

  static bool _validateNodeColor(String color) {
    // 色のフォーマット: #から始まり、6桁の16進数が続く
    // 例: #ffe05252, #a1b2c3 などの形式
    final hexColorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
    return hexColorRegex.hasMatch(color);
  }

  /// ノードマップの構造を検証する内部メソッド
  static bool _validateNodeMapStructure(Map<String, dynamic> parsedResult) {
    // 基本的な構造検証
    if (!parsedResult.containsKey('nodes') ||
        !parsedResult.containsKey('node_maps') ||
        !parsedResult.containsKey('node_link_maps')) {
      return false;
    }

    // ノードの基本的な検証
    final nodes = parsedResult['nodes'];
    if (nodes is! List || nodes.isEmpty) {
      return false;
    }

    // 各ノードの詳細検証 - 色のフォーマットを含む
    for (var node in nodes) {
      if (node is! Map ||
          !node.containsKey('title') ||
          !node.containsKey('contents') ||
          !node.containsKey('color') ||
          !_validateNodeColor(node['color'])) {
        return false;
      }
    }

    return true;
  }

  static Future<void> importJsonFromApi({
    required BuildContext context,
    required WidgetRef ref,
    required String jsonContent,
  }) async {
    if (jsonContent.isEmpty) {
      SnackBarHelper.error(context, 'JSON content is empty.');
      return;
    }

    try {
      // Validate the JSON structure using existing validation method
      final parsedResult = _parseNodeMapResponse(jsonContent);
      if (parsedResult == null) {
        SnackBarHelper.error(context, 'Invalid JSON format.');
        return;
      }

      // Use the existing structure validation method
      if (!_validateNodeMapStructure(parsedResult)) {
        SnackBarHelper.error(context, 'Invalid node map structure.');
        return;
      }

      // Convert the JSON to a map using JsonConverter
      final importedData = JsonConverter.importJsonToMap(jsonContent);

      // Extract node information, mappings, and links
      final nodesList = importedData['nodes'] as List<Map<String, dynamic>>;
      final nodeMaps = importedData['node_maps'] as Map<int, List<int>>;
      final nodeLinkMaps =
          importedData['node_link_maps'] as Map<int, List<int>>;

      // Map to store old node IDs and their corresponding new Node objects
      final Map<int, Node> idMapping = {};

      // Add each node and register new Node objects
      for (var node in nodesList) {
        final oldNodeId = node['id'] as int;
        final title = node['title'] as String?;
        final contents = node['contents'] as String?;
        final color = Color(node['color']);

        // Create a new node
        Node newNode = await NodeOperations.addNode(
          context: context,
          ref: ref,
          nodeId: 0,
          title: title ?? '',
          contents: contents ?? '',
          color: color,
        );

        // Save the mapping between old and new node IDs
        idMapping[oldNodeId] = newNode;
      }

      // Rebuild node mappings
      for (var oldParentId in nodeMaps.keys) {
        final oldChildIds = nodeMaps[oldParentId]!;

        // Convert old IDs to new Node objects
        final parentNode = idMapping[oldParentId];
        if (parentNode == null) continue;

        for (var oldChildId in oldChildIds) {
          final childNode = idMapping[oldChildId];
          if (childNode == null) continue;

          // Add parent-child relationships with new Node objects
          await NodeOperations.linkChildNode(ref, parentNode.id, childNode);
        }
      }

      // Process node link mappings
      for (var sourceId in nodeLinkMaps.keys) {
        final targetIds = nodeLinkMaps[sourceId]!;

        // Create links between nodes
        final sourceNode = idMapping[sourceId];
        if (sourceNode == null) continue;

        for (var targetId in targetIds) {
          final targetNode = idMapping[targetId];
          if (targetNode == null) continue;

          // Add links between new Node objects
          NodeOperations.linkNode(
              ref: ref, activeNode: sourceNode, hoveredNode: targetNode);
        }
      }

      if (context.mounted) {
        SnackBarHelper.success(
          context,
          'JSON imported and processed successfully.',
        );
      }
    } catch (e) {
      // Log and show error
      Logger.error('Error importing JSON: $e');
      if (context.mounted) {
        SnackBarHelper.error(context, 'Failed to import JSON: $e');
      }
    }
  }

  static verifyOpenAiApiKey(String apiKey) {}
}
