/// DBテーブルスキーマクラス
class DatabaseSchemas {
  static const Map<String, String> tableSchemas = {
    /// ノード情報テーブル
    'node': '''
      CREATE TABLE IF NOT EXISTS node (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        contents TEXT,
        color_code TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        project_id INTEGER NOT NULL
      )
    ''',

    /// ノード情報MAPテーブル
    'node_map': '''
      CREATE TABLE IF NOT EXISTS node_map (
        parent_id INTEGER,
        child_id INTEGER
      )
    ''',

    /// プロジェクト情報テーブル
    'project': '''
      CREATE TABLE IF NOT EXISTS project (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''',
  };

  // ALTERテーブルスキーマ(Sample)
  static const Map<String, List<String>> alterTableSchemas = {
    // 'project': [
    //   "ALTER TABLE project ADD COLUMN description TEXT",
    // ],
    // 'node': [
    //   "ALTER TABLE node ADD COLUMN color_code TEXT",
    // ],
    // 'node_map': [
    //   "ALTER TABLE node_map ADD COLUMN priority INTEGER DEFAULT 0",
    // ],
  };
}
