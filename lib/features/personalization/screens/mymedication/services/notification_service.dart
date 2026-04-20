import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:med/utils/navigation_key.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/local_db.dart';
import 'package:med/features/personalization/screens/mymedication/alarm/alarm_trigger_screen.dart';
import 'package:med/features/personalization/screens/mymedication/my_medication.dart';

// ─── Background task name ───────────────────────────────────────
const String _stockCheckTaskName = 'com.mediai.stockCheck';

/// Top-level callback for WorkManager background execution.
/// Runs even when the app is killed.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == _stockCheckTaskName) {
      try {
        // Check connectivity first
        final connectivityResult = await Connectivity().checkConnectivity();
        final hasInternet = connectivityResult.any(
          (r) => r != ConnectivityResult.none,
        );
        if (!hasInternet) return Future.value(true); // retry next cycle

        // Initialize notifications plugin for background
        tz.initializeTimeZones();
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
        } catch (_) {}

        final plugin = FlutterLocalNotificationsPlugin();
        const androidSettings = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
        const initSettings = InitializationSettings(android: androidSettings);
        await plugin.initialize(settings: initSettings);

        // We can't use FirebaseAuth in background isolate easily,
        // so read uid from inputData passed during registration.
        final uid = inputData?['uid'] as String?;
        if (uid == null) return Future.value(true);

        final allMedicines = await LocalDB.getUserMedicines(uid);

        for (var med in allMedicines) {
          final medId = (med['medId'] ?? '').toString();
          if (medId.isEmpty) continue;

          int currentStock =
              int.tryParse(med['available_stock'].toString()) ?? 0;
          int alertDays =
              int.tryParse(med['alert_before_days'].toString()) ?? 0;
          bool isChronic = med['chronic'] == 1 || med['chronic'] == true;

          // alert_before_days == 0 means disabled
          if (alertDays <= 0) continue;
          // Out of stock is handled separately (always show)
          if (currentStock == 0) {
            // fall through to send out-of-stock alert
          } else {
            if (!isChronic) {
              int totalDoses =
                  int.tryParse(med['total_no_of_doses'].toString()) ?? 0;
              if (currentStock >= totalDoses) continue;
            }
            String freqStr = (med['frequency'] ?? '')
                .toString()
                .toLowerCase()
                .trim();
            int freq = 1;
            if (freqStr.contains('/')) {
              freq = int.tryParse(freqStr.split('/')[0].trim()) ?? 1;
            }
            int warningThreshold = freq * alertDays;
            if (currentStock > warningThreshold) continue;
          }

          final name = med['medicine_name'] ?? 'Medicine';
          final notifId = medId.hashCode + 90000;
          final bodyText = currentStock == 0
              ? '$name is out of stock! Please restock.'
              : '$name has only $currentStock units left. Restock soon!';

          await plugin.show(
            id: notifId,
            title: 'Low Stock Alert',
            body: bodyText,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'stock_alert_channel_v1',
                'Stock Alerts',
                channelDescription: 'Low stock alerts for medicines',
                importance: Importance.high,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
            ),
            payload: 'stock_alert',
          );

          // Save to Firestore
          try {
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(uid)
                .collection('Notifications')
                .doc('stock_$medId')
                .set({
                  'title': 'Low Stock Alert',
                  'body': bodyText,
                  'type': 'stock_alert',
                  'isRead': false,
                  'createdAt': FieldValue.serverTimestamp(),
                  'createdBy': 'System',
                });
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('Background stock check error: $e');
      }
    }
    return Future.value(true);
  });
}

/// Top-level handler for notification taps when app is killed/background.
/// Required by flutter_local_notifications for background tap handling.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Store the response; it will be processed when the app launches
  NotificationService._pendingResponse = response;
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static NotificationResponse? _pendingResponse;
  static const String _alarmChannelId = 'medicine_alarm_channel_v1';
  static const String _alarmChannelName = 'Medicine Alarms';
  static const String _alarmChannelDescription = 'Full-screen medicine alarms';
  static const String _stockChannelId = 'stock_alert_channel_v1';
  static const String _stockChannelName = 'Stock Alerts';

  /// Track which stock alerts have been sent this app session to avoid duplicates
  static final Set<String> _sentStockAlerts = {};

  static NotificationDetails _alarmNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _alarmChannelId,
        _alarmChannelName,
        channelDescription: _alarmChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        autoCancel: false,
        ongoing: true,
        timeoutAfter: 120000, // 2 minutes
      ),
    );
  }

  static DateTime? parseStartDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return _normalizeDate(raw);
    if (raw is Timestamp) return _normalizeDate(raw.toDate());
    if (raw is int) {
      return _normalizeDate(DateTime.fromMillisecondsSinceEpoch(raw));
    }

    final value = raw.toString().trim();
    if (value.isEmpty) return null;

    final iso = DateTime.tryParse(value);
    if (iso != null) return _normalizeDate(iso);

    final ymd = RegExp(
      r'^(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})$',
    ).firstMatch(value);
    if (ymd != null) {
      final year = int.parse(ymd.group(1)!);
      final month = int.parse(ymd.group(2)!);
      final day = int.parse(ymd.group(3)!);
      return _validateDate(year, month, day);
    }

    final dmy = RegExp(
      r'^(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})$',
    ).firstMatch(value);
    if (dmy != null) {
      final day = int.parse(dmy.group(1)!);
      final month = int.parse(dmy.group(2)!);
      final year = int.parse(dmy.group(3)!);
      return _validateDate(year, month, day);
    }

    return null;
  }

  static DateTime? _validateDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static Future<void> init() async {
    tz.initializeTimeZones();

    // Detect device timezone automatically via flutter_timezone
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      // FlutterTimezone may return a TimezoneInfo object or a String.
      // Extract the IANA timezone name (e.g., "Asia/Karachi").
      String timeZoneName = timeZoneInfo.toString();
      // If toString() gives something like "TimezoneInfo(Asia/Karachi, ...)"
      // extract the IANA name from it.
      final match = RegExp(r'TimezoneInfo\(([^,]+)').firstMatch(timeZoneName);
      if (match != null) {
        timeZoneName = match.group(1)!.trim();
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print("🌍 Timezone auto-detected: $timeZoneName");
    } catch (e) {
      // Fallback to Asia/Karachi
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
        print("🌍 Timezone fallback to: Asia/Karachi");
      } catch (_) {}
      print("Timezone detection error: $e");
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  static Future<void> cacheInitialNotification() async {
    final details = await _notificationsPlugin
        .getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final response = details?.notificationResponse;
      if (response != null) {
        _pendingResponse = response;
      }
    }
  }

  static Future<void> processPendingNotification() async {
    final response = _pendingResponse;
    if (response == null) return;
    _pendingResponse = null;
    await _handleNotificationTap(response);
  }

  // 2. ON CLICK LOGIC
  static void onNotificationTap(NotificationResponse response) {
    _handleNotificationTap(response);
  }

  static Future<void> _handleNotificationTap(
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    if (payload == null) return;

    print("🔔 Notification Clicked! Payload: $payload");

    final navState = navigatorKey.currentState;
    if (navState == null) {
      _pendingResponse = response;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        processPendingNotification();
      });
      return;
    }

    try {
      final firstSplit = payload.split('|');
      final isFirst = firstSplit.isNotEmpty && firstSplit.first == 'first';
      final rawPayload = isFirst ? payload.substring('first|'.length) : payload;

      // Handle stock alert tap → navigate to My Medication in-stock tab
      if (rawPayload == 'stock_alert') {
        navState.push(
          MaterialPageRoute(
            builder: (_) => const MMyMedicationScreen(initialTab: 1),
          ),
        );
        return;
      }

      // ── Extract target hour:minute from any payload format ──
      int? targetHour;
      int? targetMinute;

      if (rawPayload.startsWith('time|')) {
        // New grouped format: time|hour|minute
        final parts = rawPayload.split('|');
        if (parts.length >= 3) {
          targetHour = int.tryParse(parts[1]);
          targetMinute = int.tryParse(parts[2]);
        }
      } else if (rawPayload.startsWith('med|')) {
        // Legacy individual format: med|medId|alarmId|hour|minute
        final parts = rawPayload.split('|');
        if (parts.length >= 5) {
          targetHour = int.tryParse(parts[3]);
          targetMinute = int.tryParse(parts[4]);
        }
      } else if (rawPayload.contains(':')) {
        // Very old format: hour:minute
        final parts = rawPayload.split(':');
        if (parts.length == 2) {
          targetHour = int.tryParse(parts[0]);
          targetMinute = int.tryParse(parts[1]);
        }
      }

      if (targetHour == null || targetMinute == null) return;

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // ── Gather ALL medicines scheduled at this time ──
      final allMedicines = await LocalDB.getUserMedicines(uid);
      List<Map<String, dynamic>> medicinesToTakeNow = [];

      for (var med in allMedicines) {
        // Skip medicines whose start_date hasn't arrived yet
        final startDate = parseStartDate(med['start_date']);
        if (startDate != null) {
          final today = DateTime.now();
          final todayDateOnly = DateTime(today.year, today.month, today.day);
          if (startDate.isAfter(todayDateOnly)) continue;
        }

        final alarms = await LocalDB.getMedicineAlarms(med['medId']);
        for (var alarm in alarms) {
          if (alarm['time_hour'] == targetHour &&
              alarm['time_minute'] == targetMinute &&
              (alarm['isActive'] == 1 || alarm['isActive'] == true)) {
            medicinesToTakeNow.add({
              'medId': med['medId'],
              'medicine_name': med['medicine_name'],
              'specific_dose': alarm['specific_dose'],
              'chronic': med['chronic'],
              'alarmId': alarm['alarmId'],
              'time_hour': targetHour,
              'time_minute': targetMinute,
            });
            break;
          }
        }
      }

      if (medicinesToTakeNow.isEmpty) return;

      // ── If this was a future-date one-time alarm, convert to daily repeat ──
      if (isFirst) {
        final names = medicinesToTakeNow
            .map((m) => m['medicine_name'].toString())
            .toList();
        final title = names.length == 1
            ? "Time for ${names.first}"
            : "Time for your medicines";
        final body = names.length == 1
            ? "Please take your dose now."
            : "Take: ${names.join(', ')}";
        final notificationId = 'time_${targetHour}_$targetMinute'.hashCode;
        await _scheduleDailyRepeat(
          notificationId,
          title,
          body,
          targetHour,
          targetMinute,
          payload: 'time|$targetHour|$targetMinute',
        );
      }

      // ── Save grouped notification to Firestore ──
      await _saveAlarmNotificationToFirestore(
        uid,
        targetHour,
        targetMinute,
        medicinesToTakeNow,
      );

      navState.push(
        MaterialPageRoute(
          builder: (_) =>
              AlarmTriggerScreen(scheduledMedicines: medicinesToTakeNow),
        ),
      );
    } catch (e) {
      print("Error processing notification tap: $e");
    }
  }

  /// Save a grouped alarm notification to Firestore (unread).
  /// One entry per time slot per day.
  static Future<void> _saveAlarmNotificationToFirestore(
    String uid,
    int hour,
    int minute,
    List<Map<String, dynamic>> medicines,
  ) async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final hStr = hour.toString().padLeft(2, '0');
      final mStr = minute.toString().padLeft(2, '0');
      final docId = 'alarm_${hStr}_${mStr}_$dateStr';

      final names = medicines
          .map((m) => m['medicine_name'].toString())
          .toList();
      final doses = medicines
          .map((m) => '${m['medicine_name']} (${m['specific_dose'] ?? 1} dose)')
          .toList();

      final title = names.length == 1
          ? "Medicine Reminder: ${names.first}"
          : "Medicine Reminder ($hStr:$mStr)";
      final body = names.length == 1
          ? "${doses.first} — please take your dose."
          : doses.join(', ');

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('Notifications')
          .doc(docId)
          .set({
            'title': title,
            'body': body,
            'type': 'medicine_alarm',
            'isRead': false,
            'hour': hour,
            'minute': minute,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': 'System',
          });
    } catch (e) {
      debugPrint('Error saving alarm notification: $e');
    }
  }

  /// Mark the alarm notification for a given time slot as read (auto-read on mark-as-taken).
  static Future<void> markAlarmNotificationRead(int hour, int minute) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final hStr = hour.toString().padLeft(2, '0');
      final mStr = minute.toString().padLeft(2, '0');
      final docId = 'alarm_${hStr}_${mStr}_$dateStr';

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('Notifications')
          .doc(docId)
          .update({'isRead': true});
    } catch (_) {}
  }

  // 3. SCHEDULE ALARM FUNCTION
  //
  // Schedules alarms respecting duration. For chronic medicines, uses daily
  // repeat. For non-chronic, schedules individual one-time alarms for each
  // day within [startDate, endDate]. Grouped by time slot.

  /// Parse a duration string like "10 days", "2 weeks", "1 months", "Ongoing"
  /// into total number of days. Returns null for chronic/ongoing.
  static int? _parseDurationDays(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) return null;
    final lower = durationStr.toLowerCase().trim();
    if (lower == 'ongoing' || lower == 'chronic') return null;

    final parts = lower.split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;
    final value = int.tryParse(parts[0]);
    if (value == null) return null;

    if (parts.length < 2) return value; // assume days

    final unit = parts[1];
    if (unit.startsWith('week')) return value * 7;
    if (unit.startsWith('month')) return value * 30;
    return value; // days
  }

  /// Calculate end date from start_date + duration. Returns null if chronic.
  static DateTime? _calculateEndDate(DateTime? startDate, String? duration) {
    if (startDate == null) return null;
    final days = _parseDurationDays(duration);
    if (days == null) return null; // chronic
    return startDate.add(Duration(days: days - 1)); // inclusive end
  }

  /// Max days to schedule ahead to avoid hitting Android's pending alarm limit.
  static const int _maxScheduleAheadDays = 14;

  static Future<void> scheduleAlarm(
    int id,
    String title,
    String body,
    int hour,
    int minute, {
    DateTime? startDate,
    DateTime? endDate,
    bool isChronic = true,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);

    // Cancel any previously scheduled notifications for this slot
    await _notificationsPlugin.cancel(id: id);
    await _notificationsPlugin.cancel(id: id + 1);

    final startDateOnly = startDate != null
        ? DateTime(startDate.year, startDate.month, startDate.day)
        : today;

    print("🔔 Scheduling notification:");
    print("   ID: $id");
    print("   Start date: $startDateOnly");
    print("   End date: ${endDate ?? 'none (chronic)'}");
    print("   Chronic: $isChronic");
    print("   Current time: ${now.toString()}");

    if (isChronic || endDate == null) {
      // ── CHRONIC: daily repeat forever ──
      if (startDateOnly.isAfter(today)) {
        // Future start → one-time on start date, then daily repeat after tap
        var firstTrigger = tz.TZDateTime(
          tz.local,
          startDateOnly.year,
          startDateOnly.month,
          startDateOnly.day,
          hour,
          minute,
        );
        while (firstTrigger.isBefore(now) ||
            firstTrigger.isAtSameMomentAs(now)) {
          firstTrigger = firstTrigger.add(const Duration(days: 1));
        }
        print("   [CHRONIC-FUTURE] One-time trigger: $firstTrigger");
        await _notificationsPlugin.zonedSchedule(
          id: id + 1,
          title: title,
          body: body,
          scheduledDate: firstTrigger,
          notificationDetails: _alarmNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          payload: "first|${payload ?? '$hour:$minute'}",
        );
      } else {
        print("   [CHRONIC-DAILY] Scheduling daily repeat");
        await _scheduleDailyRepeat(
          id,
          title,
          body,
          hour,
          minute,
          payload: payload,
        );
      }
      return;
    }

    // ── NON-CHRONIC: schedule individual alarms for each day in range ──
    // End date already passed → no alarms needed
    if (endDate.isBefore(today)) {
      print("   [DURATION] End date passed, skipping");
      return;
    }

    // Effective range: max(startDate, today) to min(endDate, today + 14 days)
    final effectiveStart = startDateOnly.isAfter(today) ? startDateOnly : today;
    final maxAhead = today.add(Duration(days: _maxScheduleAheadDays));
    final effectiveEnd = endDate.isBefore(maxAhead) ? endDate : maxAhead;

    int scheduledCount = 0;
    DateTime current = effectiveStart;
    while (!current.isAfter(effectiveEnd)) {
      var triggerDate = tz.TZDateTime(
        tz.local,
        current.year,
        current.month,
        current.day,
        hour,
        minute,
      );

      // Skip if in the past
      if (triggerDate.isAfter(now)) {
        // Unique ID per day: base ID + day offset from start
        final dayOffset = current.difference(startDateOnly).inDays;
        final dayId =
            id + (dayOffset * 2) + 100; // offset to avoid ID collision

        await _notificationsPlugin.zonedSchedule(
          id: dayId,
          title: title,
          body: body,
          scheduledDate: triggerDate,
          notificationDetails: _alarmNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          payload: payload ?? '$hour:$minute',
        );
        scheduledCount++;
      }

      current = current.add(const Duration(days: 1));
    }

    print(
      "   [DURATION] Scheduled $scheduledCount alarms from $effectiveStart to $effectiveEnd",
    );
  }

  // 4. CANCEL ALARM — cancels both the recurring ID and its future-one-time twin
  static Future<void> cancelAlarm(int id) async {
    await _notificationsPlugin.cancel(id: id);
    await _notificationsPlugin.cancel(id: id + 1);
    print("🗑️ Cancelled notifications: ID $id and ID ${id + 1}");
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    print("🗑️ Cancelled all notifications");
  }

  /// Show an instant (non-scheduled) notification
  static Future<void> showInstantNotification(
    int id,
    String title,
    String body, {
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _stockChannelId,
          _stockChannelName,
          channelDescription: 'Low stock alerts for medicines',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Check stock levels and send ONE notification per low-stock medicine per session.
  /// Also saves each alert to Firestore Notifications collection.
  static Future<void> checkAndSendStockAlerts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final allMedicines = await LocalDB.getUserMedicines(uid);

      for (var med in allMedicines) {
        final medId = (med['medId'] ?? '').toString();
        if (medId.isEmpty) continue;

        // Skip if already sent this session
        if (_sentStockAlerts.contains(medId)) continue;

        int currentStock = int.tryParse(med['available_stock'].toString()) ?? 0;
        int alertDays = int.tryParse(med['alert_before_days'].toString()) ?? 0;
        bool isChronic = med['chronic'] == 1 || med['chronic'] == true;

        // alert_before_days == 0 means disabled
        if (alertDays <= 0) continue;

        bool isLowOrOut = false;
        if (currentStock == 0) {
          isLowOrOut = true;
        } else {
          if (!isChronic) {
            int totalDoses = int.tryParse(med['total_no_of_doses'].toString()) ?? 0;
            if (currentStock >= totalDoses) continue;
          }
          String freqStr = (med['frequency'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          int freq = 1;
          if (freqStr.contains('/')) {
            freq = int.tryParse(freqStr.split('/')[0].trim()) ?? 1;
          }
          int warningThreshold = freq * alertDays;
          isLowOrOut = currentStock <= warningThreshold;
        }
        if (!isLowOrOut) continue;

        final name = med['medicine_name'] ?? 'Medicine';
        final notifId = medId.hashCode + 90000;
        final bodyText = currentStock == 0
            ? '$name is out of stock! Please restock.'
            : '$name has only $currentStock units left. Restock soon!';

        // Send system notification
        await showInstantNotification(
          notifId,
          'Low Stock Alert',
          bodyText,
          payload: 'stock_alert',
        );

        // Save to Firestore Notifications
        try {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(uid)
              .collection('Notifications')
              .doc('stock_$medId')
              .set({
                'title': 'Low Stock Alert',
                'body': bodyText,
                'type': 'stock_alert',
                'isRead': false,
                'createdAt': FieldValue.serverTimestamp(),
                'createdBy': 'System',
              });
        } catch (_) {}

        _sentStockAlerts.add(medId);
      }
    } catch (e) {
      debugPrint('Stock alert error: $e');
    }
  }

  static Future<void> scheduleAllFromLocal() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    print("🔔 Re-scheduling all alarms from local DB (duration-aware)...");

    // Cancel all existing alarm notifications first
    await cancelAll();

    final medicines = await LocalDB.getUserMedicines(uid);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final maxDate = today.add(Duration(days: _maxScheduleAheadDays));

    // Build a list of {med, alarm, startDate, endDate, isChronic} entries
    List<Map<String, dynamic>> allEntries = [];

    for (final med in medicines) {
      final medId = med['medId']?.toString() ?? '';
      if (medId.isEmpty) continue;

      final isChronic = med['chronic'] == 1 || med['chronic'] == true;
      final startDate = parseStartDate(med['start_date']) ?? today;
      final duration = med['duration']?.toString();
      final endDate = isChronic ? null : _calculateEndDate(startDate, duration);

      // Skip and deactivate alarms for non-chronic medicines whose course has ended
      if (endDate != null && endDate.isBefore(today)) {
        print(
          "   ⏭️ ${med['medicine_name']} course ended on $endDate, deactivating alarms",
        );
        final alarms = await LocalDB.getMedicineAlarms(medId);
        for (final alarm in alarms) {
          final aid = alarm['alarmId']?.toString() ?? '';
          if (aid.isNotEmpty) {
            await LocalDB.deactivateAlarm(aid);
          }
        }
        continue;
      }

      final alarms = await LocalDB.getMedicineAlarms(medId);
      for (final alarm in alarms) {
        if (alarm['isActive'] != null &&
            alarm['isActive'] != 1 &&
            alarm['isActive'] != true) {
          continue;
        }
        final alarmId = alarm['alarmId']?.toString() ?? '';
        if (alarmId.isEmpty) continue;
        final hour = int.tryParse(alarm['time_hour']?.toString() ?? '') ?? 0;
        final minute =
            int.tryParse(alarm['time_minute']?.toString() ?? '') ?? 0;

        allEntries.add({
          'medId': medId,
          'medicine_name': med['medicine_name'],
          'alarmId': alarmId,
          'hour': hour,
          'minute': minute,
          'startDate': startDate,
          'endDate': endDate,
          'isChronic': isChronic,
        });
      }
    }

    // Separate chronic and non-chronic entries
    final chronicEntries = allEntries
        .where((e) => e['isChronic'] == true)
        .toList();
    final durationEntries = allEntries
        .where((e) => e['isChronic'] != true)
        .toList();

    // ── CHRONIC: Group by hour:minute → one daily-repeat alarm per time slot ──
    Map<String, List<Map<String, dynamic>>> chronicTimeGroups = {};
    for (final e in chronicEntries) {
      final key = '${e['hour']}_${e['minute']}';
      chronicTimeGroups.putIfAbsent(key, () => []);
      chronicTimeGroups[key]!.add(e);
    }

    for (final entry in chronicTimeGroups.entries) {
      final meds = entry.value;
      final hour = meds.first['hour'] as int;
      final minute = meds.first['minute'] as int;
      final names = meds.map((m) => m['medicine_name'].toString()).toList();

      final title = names.length == 1
          ? "Time for ${names.first}"
          : "Time for your medicines";
      final body = names.length == 1
          ? "Please take your dose now."
          : "Take: ${names.join(', ')}";

      final notificationId = 'time_${hour}_$minute'.hashCode;
      final payload = 'time|$hour|$minute';

      DateTime? earliestStart;
      for (final m in meds) {
        final sd = m['startDate'] as DateTime;
        if (earliestStart == null || sd.isBefore(earliestStart)) {
          earliestStart = sd;
        }
      }

      await scheduleAlarm(
        notificationId,
        title,
        body,
        hour,
        minute,
        startDate: earliestStart,
        isChronic: true,
        payload: payload,
      );

      print(
        "   [CHRONIC] Grouped ${meds.length} medicine(s) at $hour:$minute → $names",
      );
    }

    // ── NON-CHRONIC: Group by date+hour+minute → one alarm per day per time ──
    // For each day in range, find which medicines are active at each time slot
    Map<String, List<Map<String, dynamic>>> dayTimeGroups = {};

    for (final e in durationEntries) {
      final startDate = e['startDate'] as DateTime;
      final endDate = e['endDate'] as DateTime;
      final hour = e['hour'] as int;
      final minute = e['minute'] as int;

      // Effective range for scheduling
      final effectiveStart = startDate.isAfter(today) ? startDate : today;
      final effectiveEnd = endDate.isBefore(maxDate) ? endDate : maxDate;

      DateTime current = effectiveStart;
      while (!current.isAfter(effectiveEnd)) {
        final dayStr =
            '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
        final key = '${dayStr}_${hour}_$minute';
        dayTimeGroups.putIfAbsent(key, () => []);
        dayTimeGroups[key]!.add(e);
        current = current.add(const Duration(days: 1));
      }
    }

    // Also include chronic medicines in the day+time groups so the
    // notification body shows ALL medicines at that time (chronic + duration)
    for (final e in chronicEntries) {
      final hour = e['hour'] as int;
      final minute = e['minute'] as int;
      // Add chronic to each existing day group at the same time
      for (final key in dayTimeGroups.keys.toList()) {
        if (key.endsWith('_${hour}_$minute')) {
          // Check not already there
          if (!dayTimeGroups[key]!.any((m) => m['medId'] == e['medId'])) {
            dayTimeGroups[key]!.add(e);
          }
        }
      }
    }

    // Schedule individual one-time alarms for each day+time group
    int totalScheduled = 0;
    for (final entry in dayTimeGroups.entries) {
      final meds = entry.value;
      final parts = entry.key.split('_');
      // key format: YYYY-MM-DD_hour_minute
      final dateParts = parts[0].split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final hour = int.parse(parts[1]);
      final minute = int.parse(parts[2]);

      // Filter to only non-chronic meds for scheduling (chronic already has daily repeat)
      final nonChronicMeds = meds.where((m) => m['isChronic'] != true).toList();
      if (nonChronicMeds.isEmpty)
        continue; // all chronic, already scheduled above

      // Build title/body with ALL meds at this time (chronic + non-chronic)
      final allNames = meds
          .map((m) => m['medicine_name'].toString())
          .toSet()
          .toList();
      final title = allNames.length == 1
          ? "Time for ${allNames.first}"
          : "Time for your medicines";
      final body = allNames.length == 1
          ? "Please take your dose now."
          : "Take: ${allNames.join(', ')}";

      // Check if there's a chronic alarm at this exact time — if yes, skip
      // individual scheduling since the chronic daily repeat covers it and
      // _handleNotificationTap already gathers all meds at that time
      if (chronicTimeGroups.containsKey('${hour}_$minute')) continue;

      final triggerDate = tz.TZDateTime(
        tz.local,
        year,
        month,
        day,
        hour,
        minute,
      );
      final nowTz = tz.TZDateTime.now(tz.local);
      if (!triggerDate.isAfter(nowTz)) continue;

      // Unique notification ID for this date+time
      final notifId = 'dt_${year}_${month}_${day}_${hour}_$minute'.hashCode;
      final payload = 'time|$hour|$minute';

      await _notificationsPlugin.zonedSchedule(
        id: notifId,
        title: title,
        body: body,
        scheduledDate: triggerDate,
        notificationDetails: _alarmNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: payload,
      );
      totalScheduled++;
    }

    print(
      "🔔 Scheduling complete: ${chronicTimeGroups.length} chronic time slots, $totalScheduled duration-based alarms",
    );
  }

  static Future<void> _scheduleDailyRepeat(
    int id,
    String title,
    String body,
    int hour,
    int minute, {
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print("   [DAILY] Repeat scheduled for: $scheduledDate");
    print(
      "   Time until trigger: ${scheduledDate.difference(now).inHours}h "
      "${scheduledDate.difference(now).inMinutes % 60}m",
    );

    await _notificationsPlugin.cancel(id: id);
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _alarmNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload ?? "$hour:$minute",
    );
  }

  /// Register a periodic background task that checks stock levels
  /// even when the app is closed. Fires ~every 6 hours when device
  /// has network connectivity.
  static Future<void> registerBackgroundStockCheck() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      _stockCheckTaskName,
      _stockCheckTaskName,
      frequency: const Duration(hours: 6),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      inputData: {'uid': uid},
    );
    print('📦 Background stock check registered for uid=$uid');
  }
}
