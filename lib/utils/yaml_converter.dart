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

        return MapEntry(nodeId, {
          'title': node['title'] != null && node['title'].isNotEmpty
              ? '"${node['title']}"'
              : '""', // タイトルが空の場合は""を設定
          'contents': formattedContents,
          'color': node['color'] != null
              ? '"${node['color']}"'
              : '""', // colorも空の場合は""を設定
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
}
