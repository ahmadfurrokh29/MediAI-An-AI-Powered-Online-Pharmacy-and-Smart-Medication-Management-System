import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/local_db.dart';
import 'offline_queue_service.dart';
import 'connectivity_service.dart';

class SyncService {
  static bool _isSyncing = false;

  /// Try to sync now (non-blocking, fails silently if offline or already syncing)
  static void trySyncNow() {
    if (_isSyncing) {
      print('⏳ Sync already in progress, will retry in 3s...');
      Future.delayed(const Duration(seconds: 3), () {
        if (!_isSyncing && ConnectivityService.isOnline) {
          unawaited(syncAll());
        }
      });
      return;
    }

    if (!ConnectivityService.isOnline) {
      print('📡 Offline - sync will happen when connection is restored');
      return;
    }

    // Run sync in background without awaiting
    unawaited(syncAll());
  }

  /// Main sync orchestrator - bidirectional sync
  static Future<void> syncAll() async {
    if (_isSyncing) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ Cannot sync: No user logged in');
      return;
    }

    _isSyncing = true;
    print('🔄 Starting bidirectional sync...');

    try {
      // Step 1: Push local changes to Firebase
      await _pushLocalChangesToFirebase(user.uid);

      // Step 2: Pull Firebase changes to local (for multi-device support)
      await _pullFirebaseChangesToLocal(user.uid);

      // Step 3: Clean up processed queue
      await OfflineQueueService.clearProcessed();

      print('✅ Sync completed successfully!');
    } catch (e) {
      print('❌ Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Push all pending local changes to Firebase
  static Future<void> _pushLocalChangesToFirebase(String uid) async {
    final pendingChanges = await OfflineQueueService.getPendingChanges();

    if (pendingChanges.isEmpty) {
      print('✓ No pending changes to sync');
      return;
    }

    print('📤 Pushing ${pendingChanges.length} pending changes to Firebase...');

    for (var change in pendingChanges) {
      try {
        final operationType = change['operation_type'] as String;
        final entityType = change['entity_type'] as String;
        final entityId = change['entity_id'] as String;
        final entityDataStr = change['entity_data'] as String?;

        if (operationType == 'INSERT') {
          await _handleInsert(uid, entityType, entityId, entityDataStr);
        } else if (operationType == 'UPDATE') {
          await _handleUpdate(uid, entityType, entityId, entityDataStr);
        } else if (operationType == 'DELETE') {
          await _handleDelete(uid, entityType, entityId);
        }

        // Mark as processed in queue
        await OfflineQueueService.markProcessed(change['id'] as int);

        // Mark entity as synced in local DB
        if (entityType == 'MEDICINE') {
          await LocalDB.markMedicineSynced(entityId);
        } else if (entityType == 'ALARM') {
          await LocalDB.markAlarmSynced(entityId);
        }

        print('✓ Synced $operationType $entityType: $entityId');
      } catch (e) {
        print(
          '✗ Failed to sync ${change['operation_type']} ${change['entity_type']}: $e',
        );
      }
    }
  }

  /// Handle INSERT operation to Firebase
  static Future<void> _handleInsert(
    String uid,
    String entityType,
    String entityId,
    String? entityDataStr,
  ) async {
    if (entityDataStr == null) {
      print(
        '⚠️ _handleInsert: entityDataStr is null for $entityType $entityId',
      );
      return;
    }

    final data = OfflineQueueService.parseEntityData(entityDataStr);
    if (data == null) {
      print(
        '⚠️ _handleInsert: parseEntityData returned null for: $entityDataStr',
      );
      return;
    }

    print(
      '📝 _handleInsert: $entityType $entityId → data keys: ${data.keys.toList()}',
    );

    if (entityType == 'MEDICINE') {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('medicines')
          .doc(entityId)
          .set({...data, 'updatedAt': FieldValue.serverTimestamp()});
    } else if (entityType == 'ALARM') {
      final medId = data['medId'];
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('medicines')
          .doc(medId)
          .collection('alarms')
          .doc(entityId)
          .set({...data, 'updatedAt': FieldValue.serverTimestamp()});
    }
  }

  /// Handle UPDATE operation to Firebase
  static Future<void> _handleUpdate(
    String uid,
    String entityType,
    String entityId,
    String? entityDataStr,
  ) async {
    if (entityDataStr == null) return;

    final data = OfflineQueueService.parseEntityData(entityDataStr);
    if (data == null) return;

    if (entityType == 'MEDICINE') {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('medicines')
          .doc(entityId)
          .set({
            ...data,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } else if (entityType == 'ALARM') {
      final medId = data['medId'];
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('medicines')
          .doc(medId)
          .collection('alarms')
          .doc(entityId)
          .set({
            ...data,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
  }

  /// Handle DELETE operation to Firebase
  static Future<void> _handleDelete(
    String uid,
    String entityType,
    String entityId,
  ) async {
    if (entityType == 'MEDICINE') {
      // Delete all alarms first
      final alarmsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('medicines')
          .doc(entityId)
          .collection('alarms')
          .get();

      for (var alarmDoc in alarmsSnapshot.docs) {
        await alarmDoc.reference.delete();
      }

      // Then delete the medicine
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('medicines')
          .doc(entityId)
          .delete();
    } else if (entityType == 'ALARM') {
      // For alarm deletion, we need to find which medicine it belongs to
      final medicines = await LocalDB.getUserMedicines(uid);
      for (var med in medicines) {
        final medId = med['medId'];
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('medicines')
            .doc(medId)
            .collection('alarms')
            .doc(entityId)
            .delete()
            .catchError((_) {
              // Ignore if alarm doesn't exist
            });
      }
    }
  }

  /// Pull Firebase changes to local (for multi-device sync)
  static Future<void> _pullFirebaseChangesToLocal(String uid) async {
    try {
      print('📥 Pulling Firebase changes to local...');

      // Collect pending DELETE IDs so we don't re-insert items the user just deleted locally
      final pendingChanges = await OfflineQueueService.getPendingChanges();
      final pendingMedicineDeleteIds = pendingChanges
          .where(
            (c) =>
                c['operation_type'] == 'DELETE' &&
                c['entity_type'] == 'MEDICINE',
          )
          .map((c) => c['entity_id'] as String)
          .toSet();
      final pendingAlarmDeleteIds = pendingChanges
          .where(
            (c) =>
                c['operation_type'] == 'DELETE' && c['entity_type'] == 'ALARM',
          )
          .map((c) => c['entity_id'] as String)
          .toSet();

      final medicinesSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('medicines')
          .get();

      for (var medDoc in medicinesSnapshot.docs) {
        // Skip medicines that have a pending local DELETE
        if (pendingMedicineDeleteIds.contains(medDoc.id)) {
          print(
            '⏭️ Skipping pull for medicine ${medDoc.id} (pending local delete)',
          );
          continue;
        }

        final medData = medDoc.data();

        // Insert or update medicine in local DB (mark as synced)
        await LocalDB.insertMedicine(uid, medData, synced: true);

        // Sync alarms for this medicine
        final alarmsSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('medicines')
            .doc(medDoc.id)
            .collection('alarms')
            .get();

        for (var alarmDoc in alarmsSnapshot.docs) {
          // Skip alarms that have a pending local DELETE
          if (pendingAlarmDeleteIds.contains(alarmDoc.id)) continue;

          final alarmData = alarmDoc.data();
          await LocalDB.insertAlarm(uid, medDoc.id, alarmData, synced: true);
        }
      }

      print('✓ Firebase data pulled to local');
    } catch (e) {
      print('✗ Error pulling Firebase data: $e');
    }
  }

  /// Original method - kept for backward compatibility (now calls new sync)
  static Future<void> syncFirebaseToLocal() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("⚠️ Sync failed: No user logged in.");
        return;
      }

      final uid = user.uid;

      bool hasLocalData = await LocalDB.checkUserHasData(uid);

      if (hasLocalData) {
        print(
          "ℹ️ Data already exists in Local DB for this user. Use syncAll() for updates.",
        );
        return;
      }

      print("🔄 Local DB is empty. Fetching data from Firebase for: $uid");

      await _pullFirebaseChangesToLocal(uid);

      print("✅ Initial sync complete!");
    } catch (e) {
      print("❌ SYNC ERROR: $e");
    }
  }
}
