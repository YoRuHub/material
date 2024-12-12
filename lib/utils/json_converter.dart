import 'dart:convert';

import 'package:flutter/material.dart';

class JsonConverter {
  static String convertNodesToJson(
    List<Map<String, dynamic>> nodes,
    List<Map<String, dynamic>> nodeMaps,
    List<Map<String, dynamic>> nodeLinkMaps,
  ) {
    final nodeJson = {
      'nodes': nodes.asMap().map((index, node) {
        final nodeId = node['id'].toString();

        final contents = node['contents'];
        final formattedContents = contents != null && contents.contains('\n')
            ? '|\n${contents.split('\n').map((line) => '      $line').join('\n')}' // 改行を含むコンテンツ
            : contents != null && contents.isNotEmpty
                ? '"$contents"'
                : '""';

        // colorが整数型であれば、16進数のカラーコードに変換
        final color = node['color'];
        final formattedColor = (color != null && color is int)
            ? '#${color.toRadixString(16).padLeft(6, '0')}' // intをカラーコードに変換
            : (color != null && color is String) // すでにカラーコードが文字列であればそのまま使用
                ? color
                : '""'; // colorがnullの場合は""を設定

        return MapEntry(nodeId, {
          'title': node['title'] != null && node['title'].isNotEmpty
              ? '"${node['title']}"'
              : '""', // タイトルが空の場合は""を設定
          'contents': formattedContents,
          'color': formattedColor,
        });
      }),
    };

    // node_mapsの処理
    final groupedNodeMaps = <String, List<int>>{};
    for (var map in nodeMaps) {
      final parentId = map['parent_id'].toString();
      final childId = map['child_id'] as int;
      groupedNodeMaps.putIfAbsent(parentId, () => []).add(childId);
    }

    // node_link_mapの処理
    final groupedNodeLinkMaps = <String, List<int>>{};
    for (var link in nodeLinkMaps) {
      final sourceId = link['source_id'].toString();
      final targetId = link['target_id'] as int;
      groupedNodeLinkMaps.putIfAbsent(sourceId, () => []).add(targetId);
    }

    final jsonData = {
      ...nodeJson,
      'node_maps': groupedNodeMaps,
      'node_link_maps': groupedNodeLinkMaps, // node_link_mapの追加
    };

    return _convertMapToJson(jsonData);
  }

  static String _convertMapToJson(Map<String, dynamic> input) {
    return jsonEncode(input); // MapをJSON形式にエンコード
  }

  // JSONをパースしてデータをインポートする処理
  static Map<String, dynamic> importJsonToMap(String jsonString) {
    final decodedJson = jsonDecode(jsonString);

    // JSONの構造をそのまま変換
    final nodesList = (decodedJson['nodes'] as List).map((node) {
      final id = node['id'] as int? ?? 0;
      final title = node['title'] as String? ?? '';
      final contents = node['contents'] as String? ?? '';
      final color = node['color'] as String? ?? '#FFFFFF';

      return {
        'id': id,
        'title': title,
        'contents': contents,
        'color': _parseColor(color), // カラーコードを整数に変換
      };
    }).toList();

    // node_maps情報の変換
    final nodeMaps = (decodedJson['node_maps'] as Map).map((key, value) {
      final parentId = int.parse(key.toString());
      final childIds = List<int>.from(value);
      return MapEntry(parentId, childIds);
    });

    // node_link_maps情報の変換
    final nodeLinkMaps =
        (decodedJson['node_link_maps'] as Map).map((key, value) {
      final sourceId = int.parse(key.toString());
      final targetIds = List<int>.from(value);
      return MapEntry(sourceId, targetIds);
    });

    return {
      'nodes': nodesList, // ノードのリスト
      'node_maps': nodeMaps, // 親子関係のマッピング
      'node_link_maps': nodeLinkMaps, // リンクのマッピング
    };
  }

// カラーコードを整数に変換する関数
  static int _parseColor(String colorString) {
    if (colorString.startsWith('#')) {
      // #RRGGBB形式を整数に変換
      return int.parse('0xFF${colorString.substring(1)}');
    }
    throw FormatException('Invalid color format: $colorString');
  }
}
