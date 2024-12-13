import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/database/models/api_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/ai_model_data.dart';
import '../models/node.dart';
import 'json_converter.dart';
import 'logger.dart';
import 'node_operations.dart';
import 'snackbar_helper.dart';

class ApiUtils {
  /// Geminiモデルの初期化
  static GenerativeModel _initializeGeminiClient(String apiKey,
      {String? model}) {
    // モデルがnullの場合、デフォルトのモデル名を使用
    model ??= AiModelData.getDefaultGeminiModel().name;

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

    // APIキーの基本的な形式検証
    if (apiKey.length < 39 || !apiKey.startsWith('AI')) {
      Logger.error("APIキーの形式が不正です。");
      return false;
    }

    final client = _initializeGeminiClient(apiKey);

    try {
      // 任意の内容でリクエストを送信（テキストが返ってくれば良い）
      final content = [Content.text('verify')];
      final response = await client.generateContent(content,
          generationConfig: GenerationConfig(
              maxOutputTokens: 10, // Extremely low token limit
              temperature: 0.0 // Minimal variability
              ));

      Logger.debug("API key verification response: ${response.text}");

      // テキストが返ってきたら成功とみなす
      return response.text != null && response.text!.isNotEmpty;
    } catch (e) {
      Logger.error("API key verification error: $e");
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
      final systemInstruction = Content.text(
          'You are a highly capable assistant. Provide accurate answers in Japanese based on the context and specific requests of the user\'s questions.\n'
          'Provide detailed answers relevant to the question and avoid general responses or unnecessary information.\n'
          'Please generate specific outputs following the instructions below:\n\n'
          '1. Focus on answering based on the relevant content from the question.\n'
          '2. Generate a structured JSON object that includes a "nodes" array.\n'
          '3. Each node should have "id", "title", "contents", and "color" fields, with "color" specified in the "#RRGGBB" format.\n'
          '4. The "nodes" array should list the nodes in order, and each node should have a unique "id" (e.g., "id": 1, "id": 2).\n'
          '5. For nodes with related content, use "node_maps" and "node_link_maps" structures to establish logical relationships:\n'
          '   - "node_maps" represents hierarchical or parent-child relationships (e.g., which nodes are included together).\n'
          '   - "node_link_maps" indicates one-way links or relationships (e.g., one node links to another).\n'
          '   - However, absolutely avoid circular links (bidirectional links). If a circular link exists, consider it invalid and exclude it.\n'
          '6. Ensure the output follows this structure:\n'
          '{"nodes": [{"id": 1, "title": "node title", "contents": "node content", "color": "#RRGGBB"}], "node_maps": {"1": [2]}, "node_link_maps": {"1": [3]}}.\n'
          '7. Parent-child relationships and links must always be one-way and not circular, creating meaningful relationships.\n'
          '8. Build logical relationships between links and parent-child connections based on the content of the nodes, rather than simply following the format.');

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
      Logger.error(
          'Error: Missing required fields: "nodes", "node_maps", or "node_link_maps".');
      return false;
    }

    // ノードの検証
    final nodes = parsedResult['nodes'];
    if (nodes is! List || nodes.isEmpty) {
      Logger.error('Error: "nodes" is not a valid list or is empty.');
      return false;
    }

    // 各ノードの詳細検証
    final seenIds = <int>{};
    for (var node in nodes) {
      if (node is! Map ||
          !node.containsKey('id') ||
          !node.containsKey('title') ||
          !node.containsKey('contents') ||
          !node.containsKey('color') ||
          !_validateNodeColor(node['color'])) {
        Logger.error(
            'Error: Invalid node structure or missing fields in node.');
        return false;
      }

      final id = node['id'];
      if (id is! int || !seenIds.add(id)) {
        Logger.error('Error: Duplicate or invalid "id" in nodes.');
        return false;
      }
    }

    // node_maps の検証
    if (parsedResult['node_maps'] is! Map<String, dynamic>) {
      Logger.error('Error: "node_maps" is not a valid Map.');
      return false;
    }

    // node_link_maps の検証
    if (parsedResult['node_link_maps'] is! Map<String, dynamic>) {
      Logger.error('Error: "node_link_maps" is not a valid Map.');
      return false;
    }

    // 全ての検証が通過した場合は true を返す
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
