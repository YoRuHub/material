/// DBテーブルスキーマクラス
class DatabaseSchemas {
  static const Map<String, String> tableSchemas = {
    /// ノード情報テーブル
    'node': '''
      CREATE TABLE IF NOT EXISTS node (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        contents TEXT,
        color INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        project_id INTEGER NOT NULL
      )
    ''',

    /// ノード情報MAPテーブル
    'node_map': '''
      CREATE TABLE IF NOT EXISTS node_map (
        parent_id INTEGER,
        child_id INTEGER,
        project_id INTEGER NOT NULL
      )
    ''',

    /// サブノード情報MAPテーブル
    'node_link_map': '''
      CREATE TABLE IF NOT EXISTS node_link_map (
        source_id INTEGER,
        target_id INTEGER,
        project_id INTEGER NOT NULL
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

    /// 設定情報テーブル（ノード間の理想的な距離を管理）
    'settings': '''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ideal_node_distance REAL DEFAULT 100.0
        )
    ''',
  };
  // defaultDataSchemas
  static const Map<String, String> insertSchemas = {
    'settings': '''
     INSERT OR IGNORE INTO settings (id, ideal_node_distance) VALUES
       (1, 100.0);
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
