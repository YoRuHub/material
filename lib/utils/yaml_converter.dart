import 'package:yaml/yaml.dart';

class YamlConverter {
  static String convertNodesToYaml(
    List<Map<String, dynamic>> nodes,
    List<Map<String, dynamic>> nodeMaps,
  ) {
    final nodeYaml = {
      'nodes': nodes.asMap().map((index, node) {
        final nodeId = node['id'].toString();

        final contents = node['contents'];
        final formattedContents = contents != null && contents.contains('\n')
            ? '|\n${contents.split('\n').map((line) => '      $line').join('\n')}' // 実際のコンテンツを使用し、各行に3スペースのインデント
            : contents != null && contents.isNotEmpty
                ? '"$contents"'
                : '""'; // 空の場合は""を設定

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

    // node_mapsの処理は以前と同じ
    final groupedNodeMaps = <String, List<int>>{};
    for (var map in nodeMaps) {
      final parentId = map['parent_id'].toString();
      final childId = map['child_id'] as int;
      groupedNodeMaps.putIfAbsent(parentId, () => []).add(childId);
    }

    final yamlData = {
      ...nodeYaml,
      'node_maps': groupedNodeMaps,
    };

    return _convertMapToYaml(yamlData);
  }

  static String _convertMapToYaml(Map<String, dynamic> input) {
    final StringBuffer yamlBuffer = StringBuffer();

    void writeYaml(Map<String, dynamic> map, [int indent = 0]) {
      map.forEach((key, value) {
        yamlBuffer.write('  ' * indent);
        yamlBuffer.write('$key: ');

        if (value is Map) {
          yamlBuffer.writeln();
          writeYaml(value as Map<String, dynamic>, indent + 1);
        } else if (value is List) {
          yamlBuffer.writeln();
          for (var item in value) {
            yamlBuffer.write('  ' * (indent + 1));
            yamlBuffer.writeln('- $item');
          }
        } else if (value is String && value.startsWith('|')) {
          // 改行を含むコンテンツの特別な処理
          yamlBuffer.writeln(value);
        } else if (value is String && value.startsWith('#')) {
          // カラーコードなどの特定の文字列を明示的に囲む
          yamlBuffer.writeln('"$value"');
        } else {
          yamlBuffer.writeln(value);
        }
      });
    }

    writeYaml(input);
    return yamlBuffer.toString();
  }

  // YAMLをパースしてデータをインポートする処理
  static Map<String, dynamic> importYamlToMap(String yamlString) {
    final dynamic decodedYaml = loadYaml(yamlString);

    // ノード情報を変換
    final nodes = (decodedYaml['nodes'] as YamlMap).map((key, value) {
      final node = value as YamlMap;
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
    final nodeMaps = (decodedYaml['node_maps'] as YamlMap).map((key, value) {
      final parentId = int.parse(key.toString());
      final childIds = List<int>.from(value);
      return MapEntry(parentId, childIds);
    });

    return {
      'nodes': nodes.values.toList(),
      'node_maps': nodeMaps,
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
