import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/local_db.dart';
import 'package:med/features/personalization/screens/mymedication/services/notification_service.dart';
import 'package:med/features/personalization/screens/mymedication/services/sync_service.dart';
import 'package:med/features/personalization/screens/mymedication/services/offline_queue_service.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/helpers/helper_functions.dart';
import 'package:med/utils/constants/sizes.dart';

class MedicineFormPage extends StatefulWidget {
  final List<Map<String, dynamic>> medicines;
  final int index;
  final bool isManualMultiAdd;
  const MedicineFormPage({
    super.key,
    required this.medicines,
    required this.index,
    this.isManualMultiAdd = false,
  });
  @override
  State<MedicineFormPage> createState() => _MedicineFormPageState();
}

class _MedicineFormPageState extends State<MedicineFormPage> {
  late TextEditingController nameController;
  late TextEditingController diseaseNameController;
  late TextEditingController durationController;
  late TextEditingController stockController;
  late TextEditingController alertDaysController;

  // Morning / Noon / Night dose controllers
  late TextEditingController morningDoseController;
  late TextEditingController noonDoseController;
  late TextEditingController nightDoseController;

  String durationUnit = 'days';
  bool isChronic = false;
  DateTime startDate = DateTime.now();

  /// Whether the alert-before-days field should be shown/enabled
  bool get _isAlertDaysEnabled {
    final stock = int.tryParse(stockController.text) ?? 0;
    if (isChronic) return true; // always enabled for chronic
    // Non-chronic: disabled if stock == 0 or stock >= required doses
    if (stock == 0) return false;
    final requiredDoses = _calculateTotalDoses();
    if (stock >= requiredDoses) return false;
    return true;
  }

  // Alarm times: 0=Morning, 1=Noon, 2=Night
  List<Map<String, dynamic>> alarmSlots = [];

  Map<String, dynamic> get med => widget.medicines[widget.index];
  int get totalMedicines => widget.medicines.length;
  int get currentIndex => widget.index;

  /// True when we're editing an existing medicine (has a medId from DB)
  bool get isEditing =>
      med['medId'] != null && med['medId'].toString().isNotEmpty;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: med['medicine_name'] ?? '');
    diseaseNameController = TextEditingController(
      text: med['disease_name'] ?? '',
    );
    stockController = TextEditingController(
      text: (med['available_stock'] ?? 0).toString(),
    );
    alertDaysController = TextEditingController(
      text: (med['alert_before_days'] ?? 3).toString(),
    );

    // Parse frequency to Morning/Noon/Night
    _parseFrequencyToSlots();

    // If editing existing medicine, load alarms from DB
    if (isEditing) {
      _loadAlarmsFromDB();
    }

    // Parse duration
    final dur = med['duration'] ?? '7 days';
    final durStr = dur.toString();
    if (durStr.toLowerCase() == 'ongoing' ||
        durStr.toLowerCase() == 'continuous') {
      isChronic = true;
      durationController = TextEditingController(text: '');
    } else {
      final durParts = durStr.split(' ');
      durationController = TextEditingController(
        text: durParts.isNotEmpty ? durParts[0] : '7',
      );
      if (durParts.length > 1) durationUnit = durParts[1];
    }
    if (med['chronic'] == true || med['chronic'] == 1) isChronic = true;

    if (med['start_date'] != null && med['start_date'].toString().isNotEmpty) {
      startDate =
          DateTime.tryParse(med['start_date'].toString()) ?? DateTime.now();
    }
  }

  void _parseFrequencyToSlots() {
    // Default: all 3 slots with 0 dose
    String morningDose = '0';
    String noonDose = '0';
    String nightDose = '0';

    int morningHour = 8, morningMin = 0;
    int noonHour = 14, noonMin = 0;
    int nightHour = 20, nightMin = 0;

    // Try to parse from existing alarms
    if (med['alarms'] != null && med['alarms'] is List) {
      final alarms = med['alarms'] as List;
      for (var a in alarms) {
        int h = a['time_hour'] ?? 8;
        int m = a['time_minute'] ?? 0;
        String dose = (a['specific_dose'] ?? '1').toString();
        if (h < 12) {
          morningDose = dose;
          morningHour = h;
          morningMin = m;
        } else if (h < 17) {
          noonDose = dose;
          noonHour = h;
          noonMin = m;
        } else {
          nightDose = dose;
          nightHour = h;
          nightMin = m;
        }
      }
    } else {
      // Parse from frequency string like "1/day" or "3/day"
      final freq = med['frequency'] ?? '1/day';
      final freqParts = freq.toString().split('/');
      int count = 1;
      if (freqParts.length == 2) count = int.tryParse(freqParts[0]) ?? 1;
      String baseDose = med['specific_dose'] ?? '1';
      if (count >= 1) morningDose = baseDose;
      if (count >= 2) noonDose = baseDose;
      if (count >= 3) nightDose = baseDose;
    }

    morningDoseController = TextEditingController(text: morningDose);
    noonDoseController = TextEditingController(text: noonDose);
    nightDoseController = TextEditingController(text: nightDose);

    alarmSlots = [
      {
        'label': 'Morning',
        'icon': Icons.wb_sunny,
        'hour': morningHour,
        'minute': morningMin,
        'controller': morningDoseController,
      },
      {
        'label': 'Noon',
        'icon': Icons.wb_cloudy,
        'hour': noonHour,
        'minute': noonMin,
        'controller': noonDoseController,
      },
      {
        'label': 'Night',
        'icon': Icons.nightlight_round,
        'hour': nightHour,
        'minute': nightMin,
        'controller': nightDoseController,
      },
    ];
  }

  /// Load existing alarms from DB and populate the slots
  Future<void> _loadAlarmsFromDB() async {
    final medId = med['medId']?.toString() ?? '';
    if (medId.isEmpty) return;
    final alarms = await LocalDB.getMedicineAlarms(medId);
    if (alarms.isEmpty) return;

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
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    nameController.dispose();
    diseaseNameController.dispose();
    durationController.dispose();
    stockController.dispose();
    alertDaysController.dispose();
    morningDoseController.dispose();
    noonDoseController.dispose();
    nightDoseController.dispose();
    super.dispose();
  }

  int get _activeSlotCount {
    int count = 0;
    for (var slot in alarmSlots) {
      final dose =
          int.tryParse((slot['controller'] as TextEditingController).text) ?? 0;
      if (dose > 0) count++;
    }
    return count;
  }

  String get _frequencyString {
    final count = _activeSlotCount;
    return '$count/day';
  }

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Edit Medicine'
              : 'Medicine ${currentIndex + 1} of $totalMedicines',
          style: theme.textTheme.headlineSmall,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (totalMedicines > 1) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (currentIndex + 1) / totalMedicines,
                  backgroundColor: dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  color: MColors.primary,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: MSizes.spaceBtwItems),
            ],

            _buildLabel('Medicine Name', theme),
            const SizedBox(height: 6),
            _buildTextField(
              nameController,
              'e.g. Paracetamol',
              Icons.medication,
              dark,
            ),
            const SizedBox(height: MSizes.spaceBtwItems),

            _buildLabel('Disease / Condition', theme),
            const SizedBox(height: 6),
            _buildTextField(
              diseaseNameController,
              'e.g. Fever, Diabetes',
              Icons.local_hospital,
              dark,
            ),
            const SizedBox(height: MSizes.spaceBtwItems),

            _buildLabel('Type', theme),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildTypeChip(
                  'Non-Chronic',
                  !isChronic,
                  dark,
                  () => setState(() => isChronic = false),
                ),
                const SizedBox(width: 12),
                _buildTypeChip(
                  'Chronic',
                  isChronic,
                  dark,
                  () => setState(() => isChronic = true),
                ),
              ],
            ),
            const SizedBox(height: MSizes.spaceBtwItems),

            // ---- FREQUENCY: Morning / Noon / Night boxes ----
            _buildLabel('Dosage Schedule', theme),
            const SizedBox(height: 8),
            Row(
              children: alarmSlots.map((slot) {
                final ctrl = slot['controller'] as TextEditingController;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: dark ? MColors.darkerGrey : Colors.grey.shade50,
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

            if (!isChronic) ...[
              _buildLabel('Duration', theme),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('e.g. 7', null, dark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildDropdown(dark, durationUnit, [
                    'days',
                    'weeks',
                    'months',
                  ], (v) => setState(() => durationUnit = v!)),
                ],
              ),
              const SizedBox(height: MSizes.spaceBtwItems),
            ],

            _buildLabel('Start Date', theme),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => startDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: dark ? MColors.darkerGrey : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: MColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${startDate.day}/${startDate.month}/${startDate.year}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MSizes.spaceBtwItems),

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
                isChronic ? 'e.g. 1' : 'e.g. 2',
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
                    Icon(Icons.notifications_off, color: Colors.grey, size: 20),
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
            const SizedBox(height: MSizes.spaceBtwItems),

            // ---- ALARM TIMES (editable) ----
            _buildLabel('Alarm Times', theme),
            const SizedBox(height: 8),
            ...alarmSlots
                .where((slot) {
                  final dose =
                      int.tryParse(
                        (slot['controller'] as TextEditingController).text,
                      ) ??
                      0;
                  return dose > 0;
                })
                .map((slot) {
                  final time = TimeOfDay(
                    hour: slot['hour'] as int,
                    minute: slot['minute'] as int,
                  );
                  final dose =
                      (slot['controller'] as TextEditingController).text;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: time,
                        );
                        if (picked != null) {
                          setState(() {
                            slot['hour'] = picked.hour;
                            slot['minute'] = picked.minute;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: MColors.primary.withOpacity(
                            dark ? 0.15 : 0.06,
                          ),
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

            if (_activeSlotCount == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Enter dose amount above to set alarms',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: MSizes.spaceBtwSections),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveMedicine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing
                      ? 'Update Medicine'
                      : (currentIndex < totalMedicines - 1
                            ? 'Save & Next'
                            : 'Save Medicine'),
                  style: const TextStyle(
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

  int _calculateTotalDoses() {
    if (isChronic) return 999999;
    final durVal = int.tryParse(durationController.text) ?? 7;
    int totalDays = durVal;
    if (durationUnit == 'weeks') totalDays = durVal * 7;
    if (durationUnit == 'months') totalDays = durVal * 30;
    return totalDays * _activeSlotCount;
  }

  Future<void> _saveMedicine() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter medicine name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_activeSlotCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set at least one dose'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate alert_before_days: must be >= 1 when enabled
    int alertDays = int.tryParse(alertDaysController.text) ?? 0;
    if (_isAlertDaysEnabled) {
      if (alertDays < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert before days must be at least 1'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      alertDays = 0; // disabled → store 0
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final durationStr = isChronic
        ? 'Ongoing'
        : '${durationController.text} $durationUnit';
    final totalDoses = _calculateTotalDoses();
    final medName = nameController.text.trim();
    final diseaseName = diseaseNameController.text.trim();

    // Reuse existing medId when editing; for new medicines, derive from name+disease
    // so that saving the same medicine+disease again updates instead of duplicating.
    final medId = isEditing
        ? med['medId'].toString()
        : '${medName}_${diseaseName}'
              .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
              .toLowerCase();

    try {
      // Always cancel old alarms and delete old alarm rows for this medId
      // (handles both editing and re-adding a medicine with same name+disease)
      final oldAlarms = await LocalDB.getMedicineAlarms(medId);
      for (var a in oldAlarms) {
        final aid = a['alarmId']?.toString() ?? '';
        if (aid.isNotEmpty) {
          await NotificationService.cancelAlarm(aid.hashCode);
          await OfflineQueueService.queueOperation(
            type: 'DELETE',
            entity: 'ALARM',
            entityId: aid,
          );
        }
      }
      await LocalDB.deleteMedicineAlarms(medId);

      final medicineData = {
        'medId': medId,
        'medicine_name': medName,
        'disease_name': diseaseName,
        'frequency': _frequencyString,
        'duration': durationStr,
        'start_date': startDate.toIso8601String(),
        'chronic': isChronic ? 1 : 0,
        'total_no_of_doses': totalDoses,
        'available_stock': int.tryParse(stockController.text) ?? 0,
        'alert_before_days': alertDays,
      };

      // insertMedicine uses ConflictAlgorithm.replace so it will update if medId exists
      await LocalDB.insertMedicine(uid, medicineData);

      await OfflineQueueService.queueOperation(
        type: isEditing ? 'UPDATE' : 'INSERT',
        entity: 'MEDICINE',
        entityId: medId,
        data: medicineData,
      );

      // Insert alarms for active slots only
      for (var slot in alarmSlots) {
        final dose =
            int.tryParse((slot['controller'] as TextEditingController).text) ??
            0;
        if (dose <= 0) continue;

        final hour = slot['hour'] as int;
        final minute = slot['minute'] as int;
        final alarmId = '${medId}_${slot['label']}';
        final alarmData = {
          'alarmId': alarmId,
          'specific_dose': dose.toString(),
          'time_hour': hour,
          'time_minute': minute,
          'duration': durationStr,
          'isActive': 1,
        };
        await LocalDB.insertAlarm(uid, medId, alarmData);

        // Queue alarm sync to Firebase
        await OfflineQueueService.queueOperation(
          type: isEditing ? 'UPDATE' : 'INSERT',
          entity: 'ALARM',
          entityId: alarmId,
          data: {...alarmData, 'medId': medId, 'uid': uid},
        );
      }

      // Re-schedule all alarms grouped by time slot
      await NotificationService.scheduleAllFromLocal();

      SyncService.trySyncNow();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$medName ${isEditing ? 'updated' : 'saved'} successfully!',
          ),
          backgroundColor: MColors.primary,
        ),
      );

      if (widget.isManualMultiAdd) {
        // In manual multi-add mode, pop back so the user can add more or finish
        Navigator.pop(context, true);
      } else if (isEditing) {
        // When editing, just go back to the previous screen
        Navigator.pop(context, true);
      } else if (currentIndex < totalMedicines - 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineFormPage(
              medicines: widget.medicines,
              index: currentIndex + 1,
            ),
          ),
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
