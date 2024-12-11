class Prompts {
  // `final` を使用して定義された変数
  static const String nodeGenerationPrompt = '''
  {
    "contents": [
      {
        "parts": [
          {
            "text": "ここはユーザーが入力したテキストです。"
          }
        ],
        "role": "user"
      }
    ],
    "systemInstruction": {
      "parts": [
        {
          "text": "Create a node map based on the given task and output the title, content, and color of each node. Additionally, show the relationships (links) between the nodes.",
        }
      ],
      "role": "model"
    },
    "generationConfig": {
      "responseMimeType": "application/json",
      "responseSchema": {
        "type": "object",
        "properties": {
          "nodes": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "title": { "type": "string" },
                "contents": { "type": "string" },
                "color": { "type": "string", "pattern": "^#([0-9A-Fa-f]{6})([0-9A-Fa-f]{2})\$" }
              },
              "required": ["title", "contents", "color"]
            }
          },
          "node_maps": {
            "type": "object",
            "additionalProperties": {
              "type": "array",
              "items": { "type": "integer" }
            }
          },
          "node_link_maps": {
            "type": "object",
            "additionalProperties": {
              "type": "array",
              "items": { "type": "integer" }
            }
          }
        }
      }
    }
  }
  ''';

  // プロンプトを取得するメソッド（オプション）
  static String getNodeGenerationPrompt() {
    return nodeGenerationPrompt;
  }
}
