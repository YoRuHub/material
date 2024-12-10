import 'dart:convert';

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

    // ノード情報を変換
    final nodes = (decodedJson['nodes'] as Map).map((key, value) {
      final node = value as Map;
      final title = node['title'] ?? '';
      final contents = node['contents'] ?? '';
      final color = node['color'] ?? '';

      return MapEntry(key, {
        'id': int.parse(key.toString()), // nodeIdを整数に変換
        'title': title is String && title != '""' ? title : null,
        'contents': contents is String && contents != '""' ? contents : null,
        'color': _parseColor(color), // カラーコードを元の整数に戻す
      });
    });

    // node_maps情報を変換
    final nodeMaps = (decodedJson['node_maps'] as Map).map((key, value) {
      final parentId = int.parse(key.toString());
      final childIds = List<int>.from(value);
      return MapEntry(parentId, childIds);
    });

    // node_link_maps情報を変換
    final nodeLinkMaps =
        (decodedJson['node_link_maps'] as Map).map((key, value) {
      final sourceId = int.parse(key.toString());
      final targetIds = List<int>.from(value);
      return MapEntry(sourceId, targetIds);
    });

    return {
      'nodes': nodes.values.toList(),
      'node_maps': nodeMaps,
      'node_link_maps': nodeLinkMaps, // node_link_mapのインポート処理を追加
    };
  }

  // カラーコードを元の整数に戻す処理
  static int _parseColor(String color) {
    if (color.startsWith('#')) {
      final colorWithoutHash = color.substring(1);
      return int.parse(colorWithoutHash, radix: 16);
    }
    return 0; // 無効なカラーコードの場合は0を返す
  }
}
