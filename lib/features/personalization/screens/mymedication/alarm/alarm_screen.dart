import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:med/navigation_menu.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/local_db.dart';
import '../services/notification_service.dart';
import '../services/offline_queue_service.dart';
import '../services/sync_service.dart';

class AlarmScreen extends StatefulWidget {
  final List<Map<String, dynamic>> medicines;

  const AlarmScreen({super.key, required this.medicines});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<Map<String, dynamic>> scheduledAlarms = [];
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingOrDefault();
  }

  Future<void> _loadExistingOrDefault() async {
    final List<Map<String, dynamic>> tempAlarms = [];

    for (var med in widget.medicines) {
      final medId = med['medId'];
      List<Map<String, dynamic>> alarms = [];
      try {
        alarms = await LocalDB.getMedicineAlarms(medId);
      } catch (_) {}

      final activeAlarms = alarms.where((a) {
        final value = a['isActive'];
        return value == null || value == 1 || value == true;
      }).toList();

      if (activeAlarms.isNotEmpty) {
        for (var alarm in activeAlarms) {
          final hour = int.tryParse(alarm['time_hour']?.toString() ?? '') ?? 8;
          final minute =
              int.tryParse(alarm['time_minute']?.toString() ?? '') ?? 0;
          tempAlarms.add({
            'alarmId': alarm['alarmId'] ?? '${medId}_alarm_$hour',
            'medId': medId,
            'medicine_name': med['medicine_name'],
            'specific_dose': alarm['specific_dose']?.toString() ?? '1',
            'time': TimeOfDay(hour: hour, minute: minute),
            'duration': alarm['duration'] ?? med['duration'] ?? '1 month',
            'start_date': med['start_date'] ?? '',
            'isActive': true,
          });
        }
      } else {
        tempAlarms.addAll(_buildDefaultAlarmsForMed(med));
      }
    }

    if (!mounted) return;
    setState(() {
      scheduledAlarms = tempAlarms;
    });
  }

  List<Map<String, dynamic>> _buildDefaultAlarmsForMed(
    Map<String, dynamic> med,
  ) {
    String freqStr =
        med['frequency']?.toString().toLowerCase().replaceAll(' ', '') ?? '';
    List<Map<String, dynamic>> timeAndDose = [];

    if (freqStr.contains('+') ||
        freqStr.contains('-') ||
        freqStr.contains('/')) {
      String normalized = freqStr.replaceAll('-', '+').replaceAll('/', '+');
      List<String> parts = normalized.split('+');
      if (parts.length >= 3) {
        int morningDose = int.tryParse(parts[0]) ?? 0;
        int noonDose = int.tryParse(parts[1]) ?? 0;
        int nightDose = int.tryParse(parts[2]) ?? 0;
        if (morningDose > 0) {
          timeAndDose.add({'hour': 8, 'dose': morningDose.toString()});
        }
        if (noonDose > 0) {
          timeAndDose.add({'hour': 14, 'dose': noonDose.toString()});
        }
        if (nightDose > 0) {
          timeAndDose.add({'hour': 20, 'dose': nightDose.toString()});
        }
      }
    }

    if (timeAndDose.isEmpty) {
      int freq = 1;
      if (freqStr.contains('twice') ||
          freqStr.contains('2x') ||
          freqStr.contains('bd') ||
          freqStr == '2') {
        freq = 2;
      } else if (freqStr.contains('thrice') ||
          freqStr.contains('3x') ||
          freqStr.contains('tds') ||
          freqStr == '3')
        freq = 3;
      else if (freqStr.contains('4x') ||
          freqStr.contains('qid') ||
          freqStr == '4')
        freq = 4;

      String defaultDose = '1';

      if (freq == 1) {
        timeAndDose.add({'hour': 8, 'dose': defaultDose});
      } else if (freq == 2) {
        timeAndDose.add({'hour': 8, 'dose': defaultDose});
        timeAndDose.add({'hour': 20, 'dose': defaultDose});
      } else if (freq == 3) {
        timeAndDose.add({'hour': 8, 'dose': defaultDose});
        timeAndDose.add({'hour': 14, 'dose': defaultDose});
        timeAndDose.add({'hour': 20, 'dose': defaultDose});
      } else if (freq == 4) {
        timeAndDose.add({'hour': 8, 'dose': defaultDose});
        timeAndDose.add({'hour': 12, 'dose': defaultDose});
        timeAndDose.add({'hour': 16, 'dose': defaultDose});
        timeAndDose.add({'hour': 20, 'dose': defaultDose});
      } else
        timeAndDose.add({'hour': 8, 'dose': defaultDose});
    }

    final List<Map<String, dynamic>> defaults = [];
    for (var td in timeAndDose) {
      defaults.add({
        'alarmId': '${med['medId']}_alarm_${td['hour']}',
        'medId': med['medId'],
        'medicine_name': med['medicine_name'],
        'specific_dose': td['dose'],
        'time': TimeOfDay(hour: td['hour'], minute: 0),
        'duration': med['duration'] ?? '1 month',
        'start_date': med['start_date'] ?? '',
        'isActive': true,
      });
    }
    return defaults;
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: scheduledAlarms[index]['time'],
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: MColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => scheduledAlarms[index]['time'] = picked);
  }

  // 🔥 Helper Widget for Cart Buttons inside Dialog
  Widget _buildMedicineAlertCard(String text, bool isOut) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOut ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOut ? Colors.red.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // TODO: Filhaal koi action nahi
                  print("Ignored");
                },
                child: Text(
                  "Ignore",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () =>
                    print("Added to cart"), // TODO: Implement Cart Logic Later
                child: const Row(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Add to Cart",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndScheduleAlarms() async {
    setState(() => isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final uid = user.uid;

      // 1. Save alarms to DB/Firebase

      // CRITICAL: First, cancel ALL old notifications for these medicines.
      // We cancel by TIME-SLOT ID (same ID used during scheduling) so that
      // stale slot-based notifications are properly removed.
      Set<String> cancelledSlots = {};
      for (var alarm in scheduledAlarms) {
        final h = alarm['time'].hour as int;
        final m = alarm['time'].minute as int;
        final slotKey = '${h}_$m';
        if (!cancelledSlots.contains(slotKey)) {
          int notificationId = slotKey.hashCode;
          await NotificationService.cancelAlarm(notificationId);
          print(
            "🗑️ Cancelled old slot notification: $slotKey (ID: $notificationId)",
          );
          cancelledSlots.add(slotKey);
        }
      }

      // Clear existing alarms + notifications for these medicines before re-inserting.
      // Use widget.medicines (not scheduledAlarms) so we cover medicines whose
      // alarms were ALL removed via the red-cross button.
      final allMedIds = widget.medicines
          .map((m) => m['medId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      // Build set of alarm IDs that will be kept (still in scheduledAlarms)
      final keptAlarmIds = scheduledAlarms
          .map((a) => a['alarmId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      for (final medId in allMedIds) {
        final existingAlarms = await LocalDB.getMedicineAlarms(medId);
        for (final oldAlarm in existingAlarms) {
          final oldAlarmId = oldAlarm['alarmId']?.toString() ?? '';
          if (oldAlarmId.isEmpty) continue;
          await NotificationService.cancelAlarm(oldAlarmId.hashCode);

          // Queue a DELETE for alarms that were removed (not in the kept set)
          if (!keptAlarmIds.contains(oldAlarmId)) {
            await OfflineQueueService.queueOperation(
              type: 'DELETE',
              entity: 'ALARM',
              entityId: oldAlarmId,
            );
          }
        }
        await LocalDB.deleteMedicineAlarms(medId);
      }

      for (var alarm in scheduledAlarms) {
        final medId = alarm['medId'];
        final alarmId = alarm['alarmId'];

        final alarmData = {
          'alarmId': alarmId,
          'medId': medId,
          'specific_dose': alarm['specific_dose'],
          'time_hour': alarm['time'].hour,
          'time_minute': alarm['time'].minute,
          'duration': alarm['duration'],
          'isActive': alarm['isActive'],
        };

        // NEW OFFLINE-FIRST APPROACH:
        // 1. Save to Local DB first (always succeeds)
        await LocalDB.insertAlarm(uid, medId, alarmData, synced: false);

        // 2. Queue for later sync (backup for offline)
        await OfflineQueueService.queueOperation(
          type: 'INSERT',
          entity: 'ALARM',
          entityId: alarmId,
          data: alarmData,
        );

        // 3. Direct Firestore write (immediate, reliable)
        try {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(uid)
              .collection('medicines')
              .doc(medId)
              .collection('alarms')
              .doc(alarmId)
              .set({...alarmData, 'updatedAt': FieldValue.serverTimestamp()});
          await LocalDB.markAlarmSynced(alarmId);
          print('✅ Alarm $alarmId synced directly to Firestore');
        } catch (e) {
          print(
            '⚠️ Direct sync failed for alarm $alarmId: $e (will retry via queue)',
          );
        }
      }

      // 2. Schedule ONE notification per alarm (even if same time)
      for (var alarm in scheduledAlarms) {
        final hour = alarm['time'].hour as int;
        final minute = alarm['time'].minute as int;
        final medId = alarm['medId']?.toString() ?? '';
        final alarmId = alarm['alarmId']?.toString() ?? '';
        if (medId.isEmpty || alarmId.isEmpty) continue;

        final startDate = NotificationService.parseStartDate(
          alarm['start_date'],
        );
        final notificationId = alarmId.hashCode;
        final title = "Time for ${alarm['medicine_name']}";
        const body = "Please take your dose now.";
        final payload = 'med|$medId|$alarmId|$hour|$minute';

        print(
          "📅 Scheduling alarm $medId/$alarmId at $hour:$minute with start date: ${startDate?.toString() ?? 'null'}",
        );

        await NotificationService.scheduleAlarm(
          notificationId,
          title,
          body,
          hour,
          minute,
          startDate: startDate,
          payload: payload,
        );
      }

      // 3. Try immediate sync (non-blocking, fails silently if offline)
      SyncService.trySyncNow();

      // ==========================================================
      // 🔥 2. POST-SAVE IMMEDIATE STOCK CHECK LOGIC
      // ==========================================================
      List<String> outOfStockMedicines = [];
      List<String> lowStockMedicines = [];

      for (var med in widget.medicines) {
        bool isChronic =
            med['chronic'] == 1 ||
            med['chronic'] == true ||
            med['chronic'] == 'true';
        int currentStock = int.tryParse(med['available_stock'].toString()) ?? 0;
        int currentTotalDoses =
            int.tryParse(med['total_no_of_doses'].toString()) ?? 0;
        int freq = 1;
        String freqStr = (med['frequency'] ?? '').toString().toLowerCase();
        if (freqStr.contains('twice') ||
            freqStr.contains('bd') ||
            freqStr.contains('2')) {
          freq = 2;
        } else if (freqStr.contains('thrice') ||
            freqStr.contains('tds') ||
            freqStr.contains('3'))
          freq = 3;
        else if (freqStr.contains('4x') ||
            freqStr.contains('qid') ||
            freqStr.contains('4'))
          freq = 4;

        int dailyConsumption = freq;
        int alertDays = int.tryParse(med['alert_before_days'].toString()) ?? 3;
        int calculatedThreshold = dailyConsumption * alertDays;
        int warningThreshold = calculatedThreshold > 5
            ? calculatedThreshold
            : 5;

        if (currentStock == 0) {
          outOfStockMedicines.add(med['medicine_name']);
        } else if (currentStock <= warningThreshold) {
          bool needsAlert = false;
          String suggestionText = "";

          if (isChronic) {
            needsAlert = true;
            suggestionText =
                "Tip: Order ${dailyConsumption * 10} tablets for a 10-day refill.";
          } else {
            if (currentStock < currentTotalDoses) {
              needsAlert = true;
              suggestionText =
                  "Tip: Buy ${currentTotalDoses - currentStock} more to finish your course.";
            }
          }

          if (needsAlert) {
            lowStockMedicines.add(
              "${med['medicine_name']} (Only $currentStock left)\n💡 $suggestionText",
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alarms Scheduled Successfully! ⏰✅")),
        );

        // Agar kisi dawai ka stock form save hote hi kam hai tou Alert dikhao
        if (outOfStockMedicines.isNotEmpty || lowStockMedicines.isNotEmpty) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 30,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Stock Alert!",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "You just added medicines that are running low on stock.",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      if (outOfStockMedicines.isNotEmpty) ...[
                        const Text(
                          "🔴 Out of Stock:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...outOfStockMedicines.map(
                          (m) => _buildMedicineAlertCard(m, true),
                        ),
                      ],
                      if (lowStockMedicines.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          "🟠 Running Low (Buy Soon):",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...lowStockMedicines.map(
                          (m) => _buildMedicineAlertCard(m, false),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "Proceed to Home",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Navigate back to main app after saving alarms
        if (mounted) {
          Get.offAll(() => const NavigationMenu());
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MAppBar(
        showBackArrow: true,
        title: Text(
          'Set Alarms',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: scheduledAlarms.length,
              itemBuilder: (context, index) {
                final alarm = scheduledAlarms[index];
                final timeString = alarm['time'].format(context);
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: name + cancel
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alarm['medicine_name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Remove Alarm',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  scheduledAlarms.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Take: ${alarm['specific_dose']} dose(s)",
                          style: TextStyle(
                            color: MColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Duration: ${alarm['duration']}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Time chip
                        Align(
                          alignment: Alignment.centerRight,
                          child: ActionChip(
                            label: Text(
                              timeString,
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: MColors.primary,
                            onPressed: () => _selectTime(context, index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.primary,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: scheduledAlarms.isEmpty || isSaving
                  ? null
                  : _saveAndScheduleAlarms,
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Confirm & Save Alarms",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
