import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/local_db.dart';

/// Service to manage pending offline operations queue
class OfflineQueueService {
  /// Queue an operation for later sync
  static Future<void> queueOperation({
    required String type,
    required String entity,
    required String entityId,
    Map<String, dynamic>? data,
  }) async {
    await LocalDB.queuePendingChange(
      operationType: type,
      entityType: entity,
      entityId: entityId,
      entityData: data,
    );
    print('📝 Queued $type operation for $entity: $entityId');
  }

  /// Get all pending changes that need to be synced
  static Future<List<Map<String, dynamic>>> getPendingChanges() async {
    return await LocalDB.getPendingChanges();
  }

  /// Mark a pending change as processed
  static Future<void> markProcessed(int id) async {
    await LocalDB.markPendingChangeSynced(id);
  }

  /// Clear all processed changes from the queue
  static Future<void> clearProcessed() async {
    await LocalDB.clearSyncedChanges();
  }

  /// Get count of pending changes
  static Future<int> getPendingCount() async {
    return await LocalDB.getPendingChangesCount();
  }

  /// Parse entity data from string format back to Map
  static Map<String, dynamic>? parseEntityData(String? dataString) {
    if (dataString == null || dataString.isEmpty) return null;

    final Map<String, dynamic> data = {};
    final List<String> pairs = dataString.split('|');

    for (final pair in pairs) {
      final colonIndex = pair.indexOf(':');
      if (colonIndex < 1) continue; // skip if no colon or starts with colon
      final key = pair.substring(0, colonIndex);
      final value = pair.substring(colonIndex + 1);

      // Try to parse as number if possible
      if (int.tryParse(value) != null) {
        data[key] = int.parse(value);
      } else if (value == 'true') {
        data[key] = true;
      } else if (value == 'false') {
        data[key] = false;
      } else {
        data[key] = value;
      }
    }

    return data;
  }
}
