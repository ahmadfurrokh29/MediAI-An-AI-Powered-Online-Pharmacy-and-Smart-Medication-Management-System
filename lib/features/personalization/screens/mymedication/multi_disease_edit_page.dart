import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/local_db.dart';
import 'package:med/features/personalization/screens/mymedication/services/notification_service.dart';
import 'package:med/features/personalization/screens/mymedication/services/sync_service.dart';
import 'package:med/features/personalization/screens/mymedication/services/offline_queue_service.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/helpers/helper_functions.dart';
import 'package:med/utils/constants/sizes.dart';

/// Edit page for a merged medicine card that has the same medicine name
/// across multiple diseases. Shows one shared medicine name and separate
/// disease/frequency/alarm sections per disease entry.
class MultiDiseaseEditPage extends StatefulWidget {
  /// The list of raw DB rows (each has its own medId, disease_name, etc.)
  final List<Map<String, dynamic>> diseaseEntries;

  const MultiDiseaseEditPage({super.key, required this.diseaseEntries});

  @override
  State<MultiDiseaseEditPage> createState() => _MultiDiseaseEditPageState();
}

class _MultiDiseaseEditPageState extends State<MultiDiseaseEditPage> {
  late TextEditingController nameController;
  late TextEditingController stockController;
  late TextEditingController alertDaysController;

  /// Per-disease state
  late List<_DiseaseSection> diseaseSections;

  bool get _isAlertDaysEnabled {
    final stock = int.tryParse(stockController.text) ?? 0;
    if (stock == 0) return false;
    // If any entry is chronic, always enable
    for (var s in diseaseSections) {
      if (s.isChronic) return true;
    }
    // Non-chronic: disabled if stock >= total required doses across all entries
    int totalRequired = 0;
    for (var s in diseaseSections) {
      totalRequired += s.calculateTotalDoses();
    }
    if (totalRequired > 0 && stock >= totalRequired) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    final first = widget.diseaseEntries.first;
    nameController = TextEditingController(text: first['medicine_name'] ?? '');

    // Sum stock across all entries
    int totalStock = 0;
    for (var e in widget.diseaseEntries) {
      totalStock += int.tryParse(e['available_stock'].toString()) ?? 0;
    }
    stockController = TextEditingController(text: totalStock.toString());
    alertDaysController = TextEditingController(
      text: (first['alert_before_days'] ?? 3).toString(),
    );

    diseaseSections = widget.diseaseEntries.map((entry) {
      return _DiseaseSection.fromMedicine(entry);
    }).toList();

    // Load alarms from DB for each entry
    _loadAllAlarms();
  }

  Future<void> _loadAllAlarms() async {
    for (var section in diseaseSections) {
      final alarms = await LocalDB.getMedicineAlarms(section.medId);
      section.loadAlarmsFromDB(alarms);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    nameController.dispose();
    stockController.dispose();
    alertDaysController.dispose();
    for (var s in diseaseSections) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    final medName = nameController.text.trim();
    if (medName.isEmpty) {
      _showError('Please enter medicine name');
      return;
    }
    // Validate each section has at least one dose
    for (int i = 0; i < diseaseSections.length; i++) {
      if (diseaseSections[i].activeSlotCount == 0) {
        _showError(
          'Set at least one dose for ${diseaseSections[i].diseaseController.text.isNotEmpty ? diseaseSections[i].diseaseController.text : "entry ${i + 1}"}',
        );
        return;
      }
    }

    int alertDays = int.tryParse(alertDaysController.text) ?? 0;
    if (_isAlertDaysEnabled && alertDays < 1) {
      _showError('Alert before days must be at least 1');
      return;
    }
    if (!_isAlertDaysEnabled) alertDays = 0;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final totalStock = int.tryParse(stockController.text) ?? 0;
    // Distribute stock evenly
    int stockPerEntry = totalStock ~/ diseaseSections.length;
    int stockRemainder = totalStock % diseaseSections.length;

    try {
      for (int i = 0; i < diseaseSections.length; i++) {
        final section = diseaseSections[i];
        final medId = section.medId;
        final diseaseName = section.diseaseController.text.trim();
        final durationStr = section.isChronic
            ? 'Ongoing'
            : '${section.durationController.text} ${section.durationUnit}';
        final freq = section.frequencyString;
        final totalDoses = section.calculateTotalDoses();
        int entryStock = stockPerEntry + (i < stockRemainder ? 1 : 0);

        // Determine which alarmIds will be created for this entry (new state)
        final Set<String> newAlarmIds = {};
        for (var slot in section.alarmSlots) {
          final dose =
              int.tryParse(
                (slot['controller'] as TextEditingController).text,
              ) ??
              0;
          if (dose <= 0) continue;
          final alarmId = '${medId}_${slot['label']}';
          newAlarmIds.add(alarmId);
        }

        // Cancel old alarms. Only queue DELETE for alarms that are NOT present in newAlarmIds.
        final oldAlarms = await LocalDB.getMedicineAlarms(medId);
        for (var a in oldAlarms) {
          final aid = a['alarmId']?.toString() ?? '';
          if (aid.isEmpty) continue;
          debugPrint(
            'CANCEL ALARM (edit): alarmId=$aid, hashCode=${aid.hashCode}',
          );
          // Always cancel notification locally to avoid duplicate triggers. But only queue a
          // DELETE operation if the alarm will not be re-created by this edit.
          await NotificationService.cancelAlarm(aid.hashCode);
          if (!newAlarmIds.contains(aid)) {
            await OfflineQueueService.queueOperation(
              type: 'DELETE',
              entity: 'ALARM',
              entityId: aid,
            );
          } else {
            debugPrint(
              'Skipping queue DELETE for $aid because it will be re-created (treated as update)',
            );
          }
        }

        // Remove existing alarms from local DB. We'll re-insert the ones that remain active.
        await LocalDB.deleteMedicineAlarms(medId);

        final medicineData = {
          'medId': medId,
          'medicine_name': medName,
          'disease_name': diseaseName,
          'frequency': freq,
          'duration': durationStr,
          'start_date': section.startDate.toIso8601String(),
          'chronic': section.isChronic ? 1 : 0,
          'total_no_of_doses': totalDoses,
          'available_stock': entryStock,
          'alert_before_days': alertDays,
        };

        await LocalDB.insertMedicine(uid, medicineData);
        await OfflineQueueService.queueOperation(
          type: 'UPDATE',
          entity: 'MEDICINE',
          entityId: medId,
          data: {...medicineData, 'uid': uid},
        );

        // Insert new alarms for active slots only
        for (var slot in section.alarmSlots) {
          final dose =
              int.tryParse(
                (slot['controller'] as TextEditingController).text,
              ) ??
              0;
          if (dose <= 0) continue;
          final hour = slot['hour'] as int;
          final minute = slot['minute'] as int;
          final alarmId = '${medId}_${slot['label']}';
          debugPrint(
            'SCHEDULE ALARM (edit): alarmId=$alarmId, hashCode=${alarmId.hashCode}, hour=$hour, minute=$minute',
          );
          final alarmData = {
            'alarmId': alarmId,
            'specific_dose': dose.toString(),
            'time_hour': hour,
            'time_minute': minute,
            'duration': durationStr,
            'isActive': 1,
          };
          await LocalDB.insertAlarm(uid, medId, alarmData);
          await OfflineQueueService.queueOperation(
            type: 'UPDATE',
            entity: 'ALARM',
            entityId: alarmId,
            data: {...alarmData, 'medId': medId, 'uid': uid},
          );
        }
      }

      // Re-schedule all notifications from DB so alarm cards reflect new data
      await NotificationService.scheduleAllFromLocal();
      SyncService.trySyncNow();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$medName updated successfully!'),
          backgroundColor: MColors.primary,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Medicine', style: theme.textTheme.headlineSmall),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Shared: Medicine Name ──
            _buildLabel('Medicine Name', theme),
            const SizedBox(height: 6),
            _buildTextField(
              nameController,
              'e.g. Paracetamol',
              Icons.medication,
              dark,
            ),
            const SizedBox(height: MSizes.spaceBtwSections),

            // ── Per-disease sections ──
            ...diseaseSections.asMap().entries.map((entry) {
              final idx = entry.key;
              final section = entry.value;
              return _buildDiseaseSection(idx, section, dark, theme);
            }),

            // ── Shared: Stock & Alert ──
            _buildLabel('Available Stock (tablets/units)', theme),
            const SizedBox(height: 6),
            _buildTextField(
              stockController,
              'e.g. 30',
              Icons.inventory,
              dark,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: MSizes.spaceBtwItems),

            _buildLabel(
              _isAlertDaysEnabled
                  ? 'Alert Before (days)'
                  : 'Alert Before (days) — disabled',
              theme,
            ),
            const SizedBox(height: 6),
            if (_isAlertDaysEnabled)
              _buildTextField(
                alertDaysController,
                'e.g. 3',
                Icons.notifications_active,
                dark,
                keyboardType: TextInputType.number,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: dark ? MColors.darkerGrey : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_off,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (int.tryParse(stockController.text) ?? 0) == 0
                            ? 'No stock — alert not needed'
                            : 'Stock covers full course — no alert needed',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: MSizes.spaceBtwSections),

            // ── Save Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Update All',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: MSizes.defaultSpace),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseSection(
    int index,
    _DiseaseSection section,
    bool dark,
    ThemeData theme,
  ) {
    final accentColor = section.isChronic
        ? Colors.red.shade400
        : MColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(Icons.local_hospital, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Condition ${index + 1}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Disease name
          _buildLabel('Disease / Condition', theme),
          const SizedBox(height: 6),
          _buildTextField(
            section.diseaseController,
            'e.g. Fever',
            Icons.local_hospital,
            dark,
          ),
          const SizedBox(height: MSizes.spaceBtwItems),

          // Type
          _buildLabel('Type', theme),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildTypeChip(
                'Non-Chronic',
                !section.isChronic,
                dark,
                () => setState(() => section.isChronic = false),
              ),
              const SizedBox(width: 12),
              _buildTypeChip(
                'Chronic',
                section.isChronic,
                dark,
                () => setState(() => section.isChronic = true),
              ),
            ],
          ),
          const SizedBox(height: MSizes.spaceBtwItems),

          // Dosage schedule
          _buildLabel('Dosage Schedule', theme),
          const SizedBox(height: 8),
          Row(
            children: section.alarmSlots.map((slot) {
              final ctrl = slot['controller'] as TextEditingController;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: dark ? MColors.darkerGrey : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (int.tryParse(ctrl.text) ?? 0) > 0
                          ? MColors.primary
                          : (dark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        slot['icon'] as IconData,
                        color: MColors.primary,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        slot['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 50,
                        height: 36,
                        child: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: MColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: MSizes.spaceBtwItems),

          // Duration (non-chronic only)
          if (!section.isChronic) ...[
            _buildLabel('Duration', theme),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: section.durationController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('e.g. 7', null, dark),
                  ),
                ),
                const SizedBox(width: 8),
                _buildDropdown(
                  dark,
                  section.durationUnit,
                  ['days', 'weeks', 'months'],
                  (v) => setState(() => section.durationUnit = v!),
                ),
              ],
            ),
            const SizedBox(height: MSizes.spaceBtwItems),
          ],

          // Start date
          _buildLabel('Start Date', theme),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: section.startDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => section.startDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: dark ? MColors.darkerGrey : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: MColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${section.startDate.day}/${section.startDate.month}/${section.startDate.year}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MSizes.spaceBtwItems),

          // Alarm times
          _buildLabel('Alarm Times', theme),
          const SizedBox(height: 8),
          ...section.alarmSlots
              .where(
                (slot) =>
                    (int.tryParse(
                          (slot['controller'] as TextEditingController).text,
                        ) ??
                        0) >
                    0,
              )
              .map((slot) {
                final time = TimeOfDay(
                  hour: slot['hour'] as int,
                  minute: slot['minute'] as int,
                );
                final dose = (slot['controller'] as TextEditingController).text;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (picked != null)
                        setState(() {
                          slot['hour'] = picked.hour;
                          slot['minute'] = picked.minute;
                        });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: MColors.primary.withOpacity(dark ? 0.15 : 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: MColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            slot['icon'] as IconData,
                            color: MColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            slot['label'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: dark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            time.format(context),
                            style: TextStyle(
                              color: MColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '($dose dose)',
                            style: TextStyle(
                              color: dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit, color: MColors.primary, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          if (section.activeSlotCount == 0)
            Text(
              'Enter dose amount above to set alarms',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  // ── Shared helper widgets ──

  Widget _buildLabel(String text, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon, bool dark) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null
          ? Icon(icon, color: MColors.primary, size: 20)
          : null,
      filled: true,
      fillColor: dark ? MColors.darkerGrey : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: MColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData? icon,
    bool dark, {
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: _inputDecoration(hint, icon, dark),
    );
  }

  Widget _buildTypeChip(
    String label,
    bool selected,
    bool dark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? MColors.primary
              : (dark ? MColors.darkerGrey : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? MColors.primary
                : (dark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (dark ? Colors.white70 : Colors.black87),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    bool dark,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: dark ? MColors.darkerGrey : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Holds per-disease form state
class _DiseaseSection {
  final String medId;
  final TextEditingController diseaseController;
  final TextEditingController durationController;
  final TextEditingController morningDoseController;
  final TextEditingController noonDoseController;
  final TextEditingController nightDoseController;
  String durationUnit;
  bool isChronic;
  DateTime startDate;
  late List<Map<String, dynamic>> alarmSlots;

  _DiseaseSection({
    required this.medId,
    required this.diseaseController,
    required this.durationController,
    required this.morningDoseController,
    required this.noonDoseController,
    required this.nightDoseController,
    required this.durationUnit,
    required this.isChronic,
    required this.startDate,
  }) {
    alarmSlots = [
      {
        'label': 'Morning',
        'icon': Icons.wb_sunny,
        'hour': 8,
        'minute': 0,
        'controller': morningDoseController,
      },
      {
        'label': 'Noon',
        'icon': Icons.wb_cloudy,
        'hour': 14,
        'minute': 0,
        'controller': noonDoseController,
      },
      {
        'label': 'Night',
        'icon': Icons.nightlight_round,
        'hour': 20,
        'minute': 0,
        'controller': nightDoseController,
      },
    ];
  }

  factory _DiseaseSection.fromMedicine(Map<String, dynamic> med) {
    final dur = (med['duration'] ?? '7 days').toString();
    bool chronic = med['chronic'] == 1 || med['chronic'] == true;
    String durText = '7';
    String durUnit = 'days';
    if (dur.toLowerCase() == 'ongoing' || dur.toLowerCase() == 'continuous') {
      chronic = true;
      durText = '';
    } else {
      final parts = dur.split(' ');
      if (parts.isNotEmpty) durText = parts[0];
      if (parts.length > 1) {
        final unit = parts[1].toLowerCase();
        if (unit == 'days' || unit == 'weeks' || unit == 'months') {
          durUnit = unit;
        }
      }
    }

    // Parse frequency to initial dose slots (will be overridden by loadAlarmsFromDB)
    String morningDose = '0', noonDose = '0', nightDose = '0';
    final freq = med['frequency'] ?? '1/day';
    final freqParts = freq.toString().split('/');
    int count = 1;
    if (freqParts.length == 2) count = int.tryParse(freqParts[0]) ?? 1;
    if (count >= 1) morningDose = '1';
    if (count >= 2) noonDose = '1';
    if (count >= 3) nightDose = '1';

    DateTime sd = DateTime.now();
    if (med['start_date'] != null && med['start_date'].toString().isNotEmpty) {
      sd = DateTime.tryParse(med['start_date'].toString()) ?? DateTime.now();
    }

    return _DiseaseSection(
      medId: med['medId']?.toString() ?? '',
      diseaseController: TextEditingController(text: med['disease_name'] ?? ''),
      durationController: TextEditingController(text: durText),
      morningDoseController: TextEditingController(text: morningDose),
      noonDoseController: TextEditingController(text: noonDose),
      nightDoseController: TextEditingController(text: nightDose),
      durationUnit: durUnit,
      isChronic: chronic,
      startDate: sd,
    );
  }

  void loadAlarmsFromDB(List<Map<String, dynamic>> alarms) {
    for (var a in alarms) {
      int h = a['time_hour'] ?? 8;
      int m = a['time_minute'] ?? 0;
      String dose = (a['specific_dose'] ?? '1').toString();
      if (h < 12) {
        morningDoseController.text = dose;
        alarmSlots[0]['hour'] = h;
        alarmSlots[0]['minute'] = m;
      } else if (h < 17) {
        noonDoseController.text = dose;
        alarmSlots[1]['hour'] = h;
        alarmSlots[1]['minute'] = m;
      } else {
        nightDoseController.text = dose;
        alarmSlots[2]['hour'] = h;
        alarmSlots[2]['minute'] = m;
      }
    }
  }

  int get activeSlotCount {
    int count = 0;
    for (var slot in alarmSlots) {
      if ((int.tryParse((slot['controller'] as TextEditingController).text) ??
              0) >
          0)
        count++;
    }
    return count;
  }

  String get frequencyString => '${activeSlotCount}/day';

  int calculateTotalDoses() {
    if (isChronic) return 999999;
    final durVal = int.tryParse(durationController.text) ?? 7;
    int totalDays = durVal;
    if (durationUnit == 'weeks') totalDays = durVal * 7;
    if (durationUnit == 'months') totalDays = durVal * 30;
    return totalDays * activeSlotCount;
  }

  void dispose() {
    diseaseController.dispose();
    durationController.dispose();
    morningDoseController.dispose();
    noonDoseController.dispose();
    nightDoseController.dispose();
  }
}
