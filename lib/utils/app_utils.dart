import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_helper.dart';
import '../providers/node_provider.dart';
import '../providers/node_state_provider.dart';
import '../providers/screen_provider.dart';

class AppUtils {
  static Future<bool> reset(WidgetRef ref) async {
    final nodeStateNotifier = ref.read(nodeStateProvider.notifier);
    final nodesNotifirer = ref.read(nodesProvider.notifier);
    final screenNotifier = ref.read(screenProvider.notifier);
    final dbHelper = DatabaseHelper();

    try {
      // データベースをリセット
      await dbHelper.database;
      dbHelper.resetTables();
      dbHelper.initDatabaseTables();
      // providerをリセット
      nodeStateNotifier.resetState();
      nodesNotifirer.clearNodes();
      screenNotifier.resetScreen();

      return true;
    } catch (e) {
      return false;
    }
  }
}
