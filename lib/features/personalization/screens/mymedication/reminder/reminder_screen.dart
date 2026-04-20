import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/local_db.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/medicine_form_page.dart';
import 'package:med/features/personalization/screens/mymedication/multi_disease_edit_page.dart';
import '../services/notification_service.dart';
import '../services/offline_queue_service.dart';
import '../services/sync_service.dart';

class RemindersScreen extends StatefulWidget {
  final bool showAppBar;
  const RemindersScreen({super.key, this.showAppBar = true});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> medicinesList = [];
  Map<String, List<Map<String, dynamic>>> alarmsMap = {};

  @override
  void initState() {
    super.initState();
    _loadRemindersData();
  }

  Future<void> _loadRemindersData() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final fetchedMedicines = await LocalDB.getUserMedicines(uid);
    Map<String, List<Map<String, dynamic>>> tempAlarmsMap = {};

    // Merge medicines by name: combine alarms, disease names
    Map<String, Map<String, dynamic>> merged = {};
    Map<String, List<Map<String, dynamic>>> mergedAlarms = {};
    Map<String, List<String>> mergedMedIds = {};

    for (var med in fetchedMedicines) {
      final medId = med['medId'];
      final alarms = await LocalDB.getMedicineAlarms(medId);
      tempAlarmsMap[medId] = alarms;

      final name = (med['medicine_name'] ?? '').toString().trim().toLowerCase();
      if (merged.containsKey(name)) {
        // Append disease name if different
        final existing = (merged[name]!['disease_name'] ?? '').toString();
        final newDisease = (med['disease_name'] ?? '').toString().trim();
        if (newDisease.isNotEmpty && !existing.contains(newDisease)) {
          merged[name]!['disease_name'] = existing.isEmpty
              ? newDisease
              : '$existing, $newDisease';
        }
        if (med['chronic'] == 1 || med['chronic'] == true)
          merged[name]!['chronic'] = 1;
        // Combine alarms (avoid duplicate times)
        for (var alarm in alarms) {
          final existingAlarms = mergedAlarms[name]!;
          bool duplicate = existingAlarms.any(
            (a) =>
                a['time_hour'] == alarm['time_hour'] &&
                a['time_minute'] == alarm['time_minute'],
          );
          if (!duplicate) mergedAlarms[name]!.add(alarm);
        }
        mergedMedIds[name]!.add(medId);
      } else {
        merged[name] = Map<String, dynamic>.from(med);
        mergedAlarms[name] = List<Map<String, dynamic>>.from(alarms);
        mergedMedIds[name] = [medId];
      }
    }

    // Build final list from merged
    List<Map<String, dynamic>> mergedList = [];
    Map<String, List<Map<String, dynamic>>> mergedAlarmsMap = {};
    for (var entry in merged.entries) {
      final med = entry.value;
      med['_allMedIds'] = mergedMedIds[entry.key];
      mergedList.add(med);
      mergedAlarmsMap[med['medId']] = mergedAlarms[entry.key] ?? [];
    }

    setState(() {
      medicinesList = mergedList;
      alarmsMap = mergedAlarmsMap;
      isLoading = false;
    });
  }

  Future<void> _deleteMedicine(String medId, {List<String>? allMedIds}) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Medicine?'),
            content: const Text(
              'Are you sure you want to delete this medicine and all its alarms?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;
    setState(() => isLoading = true);

    try {
      final idsToDelete = allMedIds ?? [medId];
      for (var id in idsToDelete) {
        final alarmsToCancel = await LocalDB.getMedicineAlarms(id);
        await LocalDB.deleteMedicineComplete(id);
        await OfflineQueueService.queueOperation(
          type: 'DELETE',
          entity: 'MEDICINE',
          entityId: id,
        );
        for (var alarm in alarmsToCancel) {
          final alarmId = alarm['alarmId']?.toString() ?? '';
          if (alarmId.isEmpty) continue;
          await NotificationService.cancelAlarm(alarmId.hashCode);
        }
      }
      SyncService.trySyncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine deleted successfully!')),
      );
      await _loadRemindersData();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String formatTime(int hour, int minute) {
    final time = TimeOfDay(hour: hour, minute: minute);
    return time.format(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    // Debug log for alarms being displayed
    for (final medicine in medicinesList) {
      final medId = medicine['medId'];
      final alarms = alarmsMap[medId] ?? [];
      for (final alarm in alarms) {
        final aid = alarm['alarmId']?.toString() ?? '';
        debugPrint(
          'DISPLAY ALARM (UI): alarmId=$aid, hashCode=${aid.hashCode}, hour=${alarm['time_hour']}, minute=${alarm['time_minute']}',
        );
      }
    }

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text('My Reminders', style: theme.textTheme.headlineSmall),
            )
          : null,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: MColors.primary))
          : medicinesList.isEmpty
          ? Center(
              child: Text(
                'No reminders set yet.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRemindersData,
              color: MColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(MSizes.defaultSpace),
                itemCount: medicinesList.length,
                itemBuilder: (context, index) {
                  final medicine = medicinesList[index];
                  final medId = medicine['medId'];
                  final alarms = alarmsMap[medId] ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: dark ? MColors.darkerGrey : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                      boxShadow: dark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: MColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.medication,
                                  color: MColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      medicine['medicine_name'] ?? '',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if ((medicine['disease_name'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text(
                                        medicine['disease_name'],
                                        style: TextStyle(
                                          color: MColors.primary,
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: MColors.primary,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final allIds = List<String>.from(
                                    medicine['_allMedIds'] ?? [medId],
                                  );
                                  if (allIds.length > 1) {
                                    // Multi-disease: load all underlying entries and open multi-disease editor
                                    final entries = <Map<String, dynamic>>[];
                                    for (final id in allIds) {
                                      final row = await LocalDB.getMedicineById(
                                        id,
                                      );
                                      if (row != null) entries.add(row);
                                    }
                                    if (entries.isEmpty) return;
                                    if (!context.mounted) return;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MultiDiseaseEditPage(
                                          diseaseEntries: entries,
                                        ),
                                      ),
                                    );
                                  } else {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MedicineFormPage(
                                          medicines: [
                                            Map<String, dynamic>.from(medicine),
                                          ],
                                          index: 0,
                                        ),
                                      ),
                                    );
                                  }
                                  await _loadRemindersData();
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.shade400,
                                  size: 20,
                                ),
                                onPressed: () => _deleteMedicine(
                                  medId,
                                  allMedIds: List<String>.from(
                                    medicine['_allMedIds'] ?? [medId],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Info chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _infoChip(
                                Icons.repeat,
                                medicine['frequency'] ?? '',
                                dark,
                              ),
                              _infoChip(
                                Icons.timer_outlined,
                                medicine['duration'] ?? '',
                                dark,
                              ),
                              if (medicine['chronic'] == 1)
                                _infoChip(
                                  Icons.favorite,
                                  'Chronic',
                                  dark,
                                  color: Colors.red.shade400,
                                ),
                            ],
                          ),
                          if (alarms.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Divider(
                              color: dark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade200,
                              height: 1,
                            ),
                            const SizedBox(height: 12),
                            // Group alarms by time (hour+minute) and count diseases
                            // Show unique alarm times only, no disease count
                            Builder(
                              builder: (context) {
                                final Set<String> shownTimes = {};
                                return Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: alarms
                                      .where((alarm) {
                                        final key =
                                            '${alarm['time_hour']}:${alarm['time_minute']}';
                                        if (shownTimes.contains(key))
                                          return false;
                                        shownTimes.add(key);
                                        return true;
                                      })
                                      .map((alarm) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: MColors.primary.withOpacity(
                                              dark ? 0.2 : 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: MColors.primary
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.alarm,
                                                color: MColors.primary,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                formatTime(
                                                  alarm['time_hour'],
                                                  alarm['time_minute'],
                                                ),
                                                style: TextStyle(
                                                  color: MColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if ((alarm['specific_dose'] ?? '')
                                                  .toString()
                                                  .isNotEmpty) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  ' ${alarm['specific_dose']}',
                                                  style: TextStyle(
                                                    color: dark
                                                        ? Colors.grey.shade400
                                                        : Colors.grey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      })
                                      .toList(),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _infoChip(IconData icon, String label, bool dark, {Color? color}) {
    final c = color ?? (dark ? Colors.grey.shade400 : Colors.grey.shade600);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(dark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
