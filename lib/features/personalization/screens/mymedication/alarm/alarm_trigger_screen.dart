import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/helpers/helper_functions.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/local_db.dart';
import '../services/notification_service.dart';
import '../services/offline_queue_service.dart';
import '../services/sync_service.dart';

class AlarmTriggerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> scheduledMedicines;

  const AlarmTriggerScreen({super.key, required this.scheduledMedicines});

  @override
  State<AlarmTriggerScreen> createState() => _AlarmTriggerScreenState();
}

class _AlarmTriggerScreenState extends State<AlarmTriggerScreen>
    with SingleTickerProviderStateMixin {
  Map<String, bool> selectedMedicines = {};
  bool isProcessing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    for (var med in widget.scheduledMedicines) {
      selectedMedicines[med['medId']] = true;
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int _parseFrequency(String freqStr) {
    freqStr = freqStr.toLowerCase().trim();
    int totalFreq = 0;
    if (freqStr.contains('+') ||
        freqStr.contains('-') ||
        freqStr.contains('/')) {
      String normalized = freqStr.replaceAll('-', '+').replaceAll('/', '+');
      List<String> parts = normalized.split('+');
      for (var p in parts) {
        int? val = int.tryParse(p.trim());
        if (val != null) totalFreq += val;
      }
    }
    if (totalFreq == 0) {
      if (freqStr.contains('twice') ||
          freqStr.contains('bd') ||
          freqStr.contains('2'))
        return 2;
      if (freqStr.contains('thrice') ||
          freqStr.contains('tds') ||
          freqStr.contains('3'))
        return 3;
      if (freqStr.contains('4x') ||
          freqStr.contains('qid') ||
          freqStr.contains('4'))
        return 4;
      return 1;
    }
    return totalFreq;
  }

  Widget _buildStockAlertCard(String text, bool isOut, bool dark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOut
            ? (dark
                  ? Colors.red.shade900.withValues(alpha: 0.3)
                  : Colors.red.shade50)
            : (dark
                  ? Colors.orange.shade900.withValues(alpha: 0.3)
                  : Colors.orange.shade50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOut
              ? (dark ? Colors.red.shade700 : Colors.red.shade200)
              : (dark ? Colors.orange.shade700 : Colors.orange.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOut ? Iconsax.warning_2 : Iconsax.info_circle,
            color: isOut ? Colors.red : Colors.orange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsTaken() async {
    setState(() => isProcessing = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    List<String> outOfStockMedicines = [];
    List<String> lowStockMedicines = [];

    try {
      for (var med in widget.scheduledMedicines) {
        String medId = med['medId'];
        if (selectedMedicines[medId] == true) {
          final dbMedicines = await LocalDB.getUserMedicines(uid);
          final currentMed = dbMedicines.firstWhere((m) => m['medId'] == medId);

          bool isChronic = currentMed['chronic'] == 1;
          int currentTotalDoses = currentMed['total_no_of_doses'] ?? 0;
          int currentStock = currentMed['available_stock'] ?? 0;
          int doseTaken = int.tryParse(med['specific_dose'].toString()) ?? 1;

          int freq = _parseFrequency(
            (currentMed['frequency'] ?? '').toString(),
          );
          int alertDays =
              int.tryParse(currentMed['alert_before_days'].toString()) ?? 0;

          int newStock = currentStock - doseTaken;
          if (newStock < 0) newStock = 0;

          int newTotalDoses = isChronic
              ? currentTotalDoses
              : (currentTotalDoses - doseTaken).clamp(0, 9999);

          if (newStock == 0) {
            if (isChronic || newTotalDoses > 0)
              outOfStockMedicines.add(med['medicine_name']);
          } else if (alertDays > 0) {
            // Only check low stock if alerts are enabled
            bool shouldAlert = true;
            if (!isChronic && newStock >= newTotalDoses) {
              shouldAlert = false; // stock covers remaining course
            }
            if (shouldAlert) {
              int warningThreshold = freq * alertDays;
              if (newStock <= warningThreshold) {
                int dailyConsumption = freq * doseTaken;
                String suggestion = isChronic
                    ? "Order ${dailyConsumption * 10} for 10-day refill."
                    : "Buy ${newTotalDoses - newStock} more to finish course.";
                lowStockMedicines.add(
                  "${med['medicine_name']} ($newStock left)\n💡 $suggestion",
                );
              }
            }
          }

          if (!isChronic && newTotalDoses == 0) {
            final alarms = await LocalDB.getMedicineAlarms(medId);
            await LocalDB.deleteMedicineComplete(medId);
            await OfflineQueueService.queueOperation(
              type: 'DELETE',
              entity: 'MEDICINE',
              entityId: medId,
            );
            for (var alarm in alarms) {
              final alarmId = alarm['alarmId']?.toString() ?? '';
              if (alarmId.isEmpty) continue;
              await NotificationService.cancelAlarm(alarmId.hashCode);
            }
          } else {
            await LocalDB.updateMedicineStats(medId, newTotalDoses, newStock);
            await OfflineQueueService.queueOperation(
              type: 'UPDATE',
              entity: 'MEDICINE',
              entityId: medId,
              data: {
                'total_no_of_doses': newTotalDoses,
                'available_stock': newStock,
              },
            );
          }
        }
      }

      SyncService.trySyncNow();

      // Auto-mark the alarm notification as read in Firestore
      if (widget.scheduledMedicines.isNotEmpty) {
        final firstMed = widget.scheduledMedicines.first;
        final h = firstMed['time_hour'];
        final m = firstMed['time_minute'];
        if (h != null && m != null) {
          final hour = h is int ? h : int.tryParse(h.toString());
          final minute = m is int ? m : int.tryParse(m.toString());
          if (hour != null && minute != null) {
            await NotificationService.markAlarmNotificationRead(hour, minute);
          }
        }
      }

      // Re-schedule grouped alarms (in case a medicine course completed)
      await NotificationService.scheduleAllFromLocal();

      final dark = MHelperFunctions.isDarkMode(context);
      if (mounted &&
          (outOfStockMedicines.isNotEmpty || lowStockMedicines.isNotEmpty)) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: dark ? MColors.darkerGrey : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Iconsax.warning_2, color: Colors.orange, size: 24),
                const SizedBox(width: 10),
                Text(
                  "Stock Alert",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...outOfStockMedicines.map(
                      (m) => _buildStockAlertCard(
                        '$m is out of stock!',
                        true,
                        dark,
                      ),
                    ),
                    ...lowStockMedicines.map(
                      (m) => _buildStockAlertCard(m, false, dark),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Got it",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);

    return Scaffold(
      backgroundColor: dark ? MColors.darkerGrey : Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Section ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MColors.primary,
                    MColors.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Pulsing alarm icon
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.clock,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Time for your medicine!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Medicine List ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select medicines taken',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.scheduledMedicines.length,
                itemBuilder: (context, index) {
                  final med = widget.scheduledMedicines[index];
                  final medId = med['medId'];
                  final isSelected = selectedMedicines[medId] == true;
                  final dose = med['specific_dose']?.toString() ?? '1';
                  final name = med['medicine_name'] ?? 'Medicine';
                  final disease = med['disease_name'] ?? '';

                  return GestureDetector(
                    onTap: () =>
                        setState(() => selectedMedicines[medId] = !isSelected),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (dark
                                  ? MColors.primary.withValues(alpha: 0.15)
                                  : MColors.primary.withValues(alpha: 0.08))
                            : (dark ? Colors.grey.shade900 : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? MColors.primary
                              : (dark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (!dark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Checkbox circle
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MColors.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? MColors.primary
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),

                          // Medicine pill icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: MColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Iconsax.health,
                              color: MColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Medicine info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: dark ? Colors.white : Colors.black87,
                                    decoration: isSelected ? null : null,
                                  ),
                                ),
                                if (disease.toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 2.0,
                                      bottom: 2.0,
                                    ),
                                    child: Text(
                                      disease,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blueGrey.shade400,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                Text(
                                  '$dose dose(s)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: dark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Bottom Buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // Mark as Taken button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: isProcessing
                        ? Center(
                            child: CircularProgressIndicator(
                              color: MColors.primary,
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _markAsTaken,
                            icon: const Icon(Iconsax.tick_circle, size: 22),
                            label: const Text(
                              'Mark as Taken',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  // Skip / Dismiss button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                        side: BorderSide(
                          color: dark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
