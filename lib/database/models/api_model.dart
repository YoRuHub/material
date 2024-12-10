import 'package:flutter_app/utils/logger.dart';
import 'base_model.dart';

class ApiModel extends BaseModel {
  static const String table = 'api';
  static const String columnProduct = 'product';
  static const String columnApiKey = 'api_key';
  static const String columnCreatedAt = 'created_at';

  /// プロジェクトに属するノード全件取得
  Future<String?> fetchApi(String product) async {
    try {
      final result = await select(
        table,
        whereClause: '$columnProduct = ?',
        whereArgs: [product],
      );

      if (result.isNotEmpty) {
        Logger.debug('Successfully fetched api: ${result[0][columnProduct]}');
        return result[0][columnApiKey] as String?;
      } else {
        return null; // 結果が空の場合、nullを返す
      }
    } catch (e) {
      Logger.error('Error fetching API: $e');
      rethrow;
    }
  }

  Future<void> insertApi(String product, String apiKey) async {
    try {
      await insert(table, {columnProduct: product, columnApiKey: apiKey});
    } catch (e) {
      Logger.error('Error inserting api: $e');
      rethrow;
    }
  }

  Future<void> upsertApi(String product, String apiKey) async {
    try {
      final data = {columnProduct: product, columnApiKey: apiKey};
      await upsert(table, data, '$columnProduct = ?', [product]);
    } catch (e) {
      Logger.error('Error upserting api: $e');
      rethrow;
    }
  }

  Future<void> deleteApi(String product) async {
    try {
      await delete(table, '$columnProduct = ?', [product]);
      await resetAutoIncrement(table);
    } catch (e) {
      Logger.error('Error deleting api: $e');
      rethrow;
    }
  }
}
