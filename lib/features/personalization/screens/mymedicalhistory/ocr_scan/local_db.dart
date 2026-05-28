import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'medicines.db');
    return await openDatabase(
      path,
      version: 9,
      onCreate: (db, version) async {
        // Medicines Table (Added total_no_of_doses & available_stock & alert_before_days & sync metadata)
        await db.execute('''
          CREATE TABLE medicines(
            uid TEXT,
            medId TEXT PRIMARY KEY,
            medicine_name TEXT,
            disease_name TEXT DEFAULT '',
            frequency TEXT,
            duration TEXT,
            start_date TEXT,
            chronic INTEGER,
            total_no_of_doses INTEGER,
            available_stock INTEGER,
            alert_before_days INTEGER DEFAULT 3,
            synced INTEGER DEFAULT 0,
            local_updated_at INTEGER
          )
        ''');
        // Alarms Table (Added sync metadata)
        await db.execute('''
          CREATE TABLE alarms(
            alarmId TEXT PRIMARY KEY,
            uid TEXT,
            medId TEXT,
            specific_dose TEXT,
            time_hour INTEGER,
            time_minute INTEGER,
            duration TEXT,
            isActive INTEGER,
            synced INTEGER DEFAULT 0,
            local_updated_at INTEGER
          )
        ''');
        // Pending Changes Table for Offline Queue
        await db.execute('''
          CREATE TABLE pending_changes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation_type TEXT NOT NULL,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            entity_data TEXT,
            timestamp INTEGER NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE alarms(
              alarmId TEXT PRIMARY KEY,
              uid TEXT,
              medId TEXT,
              specific_dose TEXT,
              time_hour INTEGER,
              time_minute INTEGER,
              duration TEXT,
              isActive INTEGER
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE medicines ADD COLUMN total_no_of_doses INTEGER DEFAULT 0',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE medicines ADD COLUMN available_stock INTEGER DEFAULT 0',
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE medicines ADD COLUMN alert_before_days INTEGER DEFAULT 3',
          );
        }
        if (oldVersion < 7) {
          //Add sync metadata columns to medicines
          await db.execute(
            'ALTER TABLE medicines ADD COLUMN synced INTEGER DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE medicines ADD COLUMN local_updated_at INTEGER',
          );
          // Add sync metadata columns to alarms
          await db.execute(
            'ALTER TABLE alarms ADD COLUMN synced INTEGER DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE alarms ADD COLUMN local_updated_at INTEGER',
          );
          // Create pending_changes table
          await db.execute('''
            CREATE TABLE pending_changes(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              operation_type TEXT NOT NULL,
              entity_type TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              entity_data TEXT,
              timestamp INTEGER NOT NULL,
              synced INTEGER DEFAULT 0
            )
          ''');
        }
        if (oldVersion < 8) {
          await db.execute(
            "ALTER TABLE medicines ADD COLUMN disease_name TEXT DEFAULT ''",
          );
        }
        if (oldVersion < 9) {
          await db.execute(
            'ALTER TABLE medicines ADD COLUMN prescription_image TEXT',
          );
        }
      },
    );
  }

  static Future<void> insertMedicine(
    String uid,
    Map<String, dynamic> medicine, {
    bool synced = false,
  }) async {
    final db = await database;
    int isChronic = (medicine['chronic'] == true || medicine['chronic'] == 1)
        ? 1
        : 0;

    await db.insert('medicines', {
      'uid': uid,
      'medId': medicine['medId'],
      'medicine_name': medicine['medicine_name'],
      'disease_name': medicine['disease_name'] ?? '',
      'frequency': medicine['frequency'],
      'duration': medicine['duration'],
      'start_date': medicine['start_date'],
      'chronic': isChronic,
      'total_no_of_doses': medicine['total_no_of_doses'] ?? 0,
      'available_stock': medicine['available_stock'] ?? 0,
      'alert_before_days': medicine['alert_before_days'] ?? 3,
      'synced': synced ? 1 : 0,
      'local_updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> insertAlarm(
    String uid,
    String medId,
    Map<String, dynamic> alarm, {
    bool synced = false,
  }) async {
    final db = await database;
    int isAlarmActive = (alarm['isActive'] == true || alarm['isActive'] == 1)
        ? 1
        : 0;

    await db.insert('alarms', {
      'alarmId': alarm['alarmId'],
      'uid': uid,
      'medId': medId,
      'specific_dose': alarm['specific_dose'],
      'time_hour': alarm['time_hour'],
      'time_minute': alarm['time_minute'],
      'duration': alarm['duration'],
      'isActive': isAlarmActive,
      'synced': synced ? 1 : 0,
      'local_updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<bool> checkUserHasData(String uid) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'medicines',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> getUserMedicines(String uid) async {
    final db = await database;
    return await db.query('medicines', where: 'uid = ?', whereArgs: [uid]);
  }

  static Future<List<Map<String, dynamic>>> getMedicineAlarms(
    String medId,
  ) async {
    final db = await database;
    return await db.query(
      'alarms',
      where: 'medId = ?',
      whereArgs: [medId],
      orderBy: 'time_hour ASC, time_minute ASC',
    );
  }

  static Future<Map<String, dynamic>?> getMedicineById(String medId) async {
    final db = await database;
    final result = await db.query(
      'medicines',
      where: 'medId = ?',
      whereArgs: [medId],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }

  static Future<Map<String, dynamic>?> getAlarmById(String alarmId) async {
    final db = await database;
    final result = await db.query(
      'alarms',
      where: 'alarmId = ?',
      whereArgs: [alarmId],
      limit: 1,
    );
    return result.isEmpty ? null : result.first;
  }

  static Future<void> clearLocalData() async {
    final db = await database;
    await db.delete('medicines');
    await db.delete('alarms');
  }

  static Future<void> deactivateAlarm(String alarmId) async {
    final db = await database;
    await db.update(
      'alarms',
      {
        'isActive': 0,
        'synced': 0,
        'local_updated_at': DateTime.now().toIso8601String(),
      },
      where: 'alarmId = ?',
      whereArgs: [alarmId],
    );
  }

  static Future<void> deleteMedicineAlarms(String medId) async {
    final db = await database;
    await db.delete('alarms', where: 'medId = ?', whereArgs: [medId]);
  }

  static Future<void> deleteMedicineComplete(String medId) async {
    final db = await database;
    await db.delete('medicines', where: 'medId = ?', whereArgs: [medId]);
    await db.delete('alarms', where: 'medId = ?', whereArgs: [medId]);
  }

  static Future<void> updateMedicineStats(
    String medId,
    int newDoses,
    int newStock,
  ) async {
    final db = await database;
    await db.update(
      'medicines',
      {
        'total_no_of_doses': newDoses,
        'available_stock': newStock,
        'synced': 0,
        'local_updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'medId = ?',
      whereArgs: [medId],
    );
  }

  // ============= OFFLINE SYNC METHODS =============

  /// Queue a pending operation for later sync
  static Future<void> queuePendingChange({
    required String operationType,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? entityData,
  }) async {
    final db = await database;
    // Remove any existing pending changes for this entity to avoid conflicting
    // operations (e.g., DELETE followed by UPDATE) being processed later.
    await db.delete(
      'pending_changes',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
    );

    await db.insert('pending_changes', {
      'operation_type': operationType,
      'entity_type': entityType,
      'entity_id': entityId,
      'entity_data': entityData != null
          ? entityData.entries.map((e) => '${e.key}:${e.value}').join('|')
          : null,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'synced': 0,
    });
  }

  /// Get all pending changes that need to be synced
  static Future<List<Map<String, dynamic>>> getPendingChanges() async {
    final db = await database;
    return await db.query(
      'pending_changes',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }

  /// Mark a pending change as synced
  static Future<void> markPendingChangeSynced(int id) async {
    final db = await database;
    await db.update(
      'pending_changes',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all synced pending changes
  static Future<void> clearSyncedChanges() async {
    final db = await database;
    await db.delete('pending_changes', where: 'synced = ?', whereArgs: [1]);
  }

  /// Mark a medicine as synced
  static Future<void> markMedicineSynced(String medId) async {
    final db = await database;
    await db.update(
      'medicines',
      {'synced': 1},
      where: 'medId = ?',
      whereArgs: [medId],
    );
  }

  /// Mark an alarm as synced
  static Future<void> markAlarmSynced(String alarmId) async {
    final db = await database;
    await db.update(
      'alarms',
      {'synced': 1},
      where: 'alarmId = ?',
      whereArgs: [alarmId],
    );
  }

  /// Get unsynced medicines for a user
  static Future<List<Map<String, dynamic>>> getUnsyncedMedicines(
    String uid,
  ) async {
    final db = await database;
    return await db.query(
      'medicines',
      where: 'uid = ? AND synced = ?',
      whereArgs: [uid, 0],
    );
  }

  /// Get unsynced alarms for a user
  static Future<List<Map<String, dynamic>>> getUnsyncedAlarms(
    String uid,
  ) async {
    final db = await database;
    return await db.query(
      'alarms',
      where: 'uid = ? AND synced = ?',
      whereArgs: [uid, 0],
    );
  }

  /// Fetch distinct non-null prescription images for medicines whose names
  /// fuzzy-match any of the given [names] (case-insensitive contains check).
  /// Reads from the dedicated [prescription_images] table which is created
  /// lazily — so it works on any DB version without a migration.
  static Future<List<String>> getPrescriptionImagesForNames(
    String uid,
    List<String> names,
  ) async {
    if (names.isEmpty) return [];
    await _ensurePrescriptionTable();
    final db = await database;
    final rows = await db.query(
      'prescription_images',
      columns: ['medicine_name', 'image_base64'],
      where: 'uid = ?',
      whereArgs: [uid],
    );
    final seen = <String>{};
    final result = <String>[];
    for (final row in rows) {
      final img = row['image_base64'] as String?;
      if (img == null || img.isEmpty) continue;
      final medName = (row['medicine_name'] as String? ?? '').toLowerCase();
      final matched = names.any((n) {
        final q = n.toLowerCase();
        return medName.contains(q) || q.contains(medName);
      });
      if (matched && !seen.contains(img)) {
        seen.add(img);
        result.add(img);
      }
    }
    return result;
  }

  /// Ensures the [prescription_images] table exists. Uses
  /// CREATE TABLE IF NOT EXISTS so it is safe to call on any DB version
  /// without needing a schema migration.
  static Future<void> _ensurePrescriptionTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS prescription_images (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        uid         TEXT    NOT NULL,
        medicine_name TEXT  NOT NULL,
        image_base64  TEXT  NOT NULL,
        created_at  INTEGER NOT NULL
      )
    ''');
  }

  /// Saves (or updates) a prescription image for the given medicine name.
  /// Creates the [prescription_images] table if it doesn't exist yet.
  static Future<void> savePrescriptionImage(
    String uid,
    String medicineName,
    String imageBase64,
  ) async {
    await _ensurePrescriptionTable();
    final db = await database;
    final key = medicineName.toLowerCase().trim();
    final existing = await db.query(
      'prescription_images',
      columns: ['id'],
      where: 'uid = ? AND medicine_name = ?',
      whereArgs: [uid, key],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('prescription_images', {
        'uid': uid,
        'medicine_name': key,
        'image_base64': imageBase64,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await db.update(
        'prescription_images',
        {
          'image_base64': imageBase64,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'uid = ? AND medicine_name = ?',
        whereArgs: [uid, key],
      );
    }
  }

  // ── Stock refill tracking ─────────────────────────────────────────────────

  static Future<void> _ensureRefilledOrdersTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS refilled_orders (
        order_id    TEXT    PRIMARY KEY,
        refilled_at INTEGER NOT NULL
      )
    ''');
  }

  /// Returns true if stock has already been refilled for this order.
  static Future<bool> isOrderStockRefilled(String orderId) async {
    await _ensureRefilledOrdersTable();
    final db = await database;
    final result = await db.query(
      'refilled_orders',
      where: 'order_id = ?',
      whereArgs: [orderId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Marks an order as having its stock refilled so it is not processed twice.
  static Future<void> markOrderStockRefilled(String orderId) async {
    await _ensureRefilledOrdersTable();
    final db = await database;
    await db.insert(
      'refilled_orders',
      {
        'order_id': orderId,
        'refilled_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Get pending changes count
  static Future<int> getPendingChangesCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pending_changes WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
