/// DBテーブルスキーマクラス
class DatabaseSchemas {
  static const Map<String, String> tableSchemas = {
    /// ノード情報テーブル
    'node': '''
      CREATE TABLE IF NOT EXISTS node (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        contents TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''',

    /// ノード情報MAPテーブル
    'node_map': '''
      CREATE TABLE IF NOT EXISTS node_map (
        parent_id INTEGER,
        child_id INTEGER
      )
    '''
  };
}
