import 'package:flutter_app/utils/logger.dart';
import 'base_model.dart';

class ApiModel extends BaseModel {
  static const String table = 'api';
  static const String columnProduct = 'product';
  static const String columnApiKey = 'api_key';
  static const String columnStatus = 'status';
  static const String columnCreatedAt = 'created_at';

  /// プロジェクトに属するノード全件取得
  Future<Map<String, dynamic>?> fetchApi(String product) async {
    try {
      final result = await select(
        table,
        whereClause: '$columnProduct = ?',
        whereArgs: [product],
      );
      Logger.debug('Successfully fetched api: ${result.length} rows');

      if (result.isNotEmpty) {
        Logger.debug('Successfully fetched api: ${result[0][columnProduct]}');
        return {
          'product': result[0][columnProduct],
          'api_key': result[0][columnApiKey],
          'status': result[0][columnStatus],
        };
      } else {
        return null; // 結果が空の場合、nullを返す
      }
    } catch (e) {
      Logger.error('Error fetching API: $e');
      rethrow;
    }
  }

  Future<void> upsertApi(String product, String apiKey,
      {String? status}) async {
    try {
      final data = {
        columnProduct: product,
        columnApiKey: apiKey,
        columnStatus: status
      };
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
