import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/ocr_scan_page.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/local_db.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/medicine_form_page.dart';
import 'package:med/features/personalization/screens/mymedication/services/notification_service.dart';
import 'package:med/features/personalization/screens/mymedication/services/offline_queue_service.dart';
import 'package:med/features/personalization/screens/mymedication/services/sync_service.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';

class MMyMedicalHistoryScreen extends StatefulWidget {
  const MMyMedicalHistoryScreen({super.key});

  @override
  State<MMyMedicalHistoryScreen> createState() =>
      _MMyMedicalHistoryScreenState();
}

class _MMyMedicalHistoryScreenState extends State<MMyMedicalHistoryScreen> {
  bool isLoading = true;
  // Grouped: { diseaseName: [medicines] }
  Map<String, List<Map<String, dynamic>>> chronicDiseases = {};
  Map<String, List<Map<String, dynamic>>> nonChronicDiseases = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final meds = await LocalDB.getUserMedicines(uid);

    Map<String, List<Map<String, dynamic>>> chronic = {};
    Map<String, List<Map<String, dynamic>>> nonChronic = {};

    for (var med in meds) {
      final isChronic = med['chronic'] == 1;
      final disease = (med['disease_name'] ?? '').toString().trim();
      final key = disease.isEmpty ? 'General' : disease;

      if (isChronic) {
        chronic.putIfAbsent(key, () => []).add(med);
      } else {
        nonChronic.putIfAbsent(key, () => []).add(med);
      }
    }

    setState(() {
      chronicDiseases = chronic;
      nonChronicDiseases = nonChronic;
      isLoading = false;
    });
  }

  Future<void> _deleteMedicine(String medId) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Medicine?'),
            content: const Text(
              'This will remove the medicine and all its alarms.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
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

    final alarms = await LocalDB.getMedicineAlarms(medId);
    await LocalDB.deleteMedicineComplete(medId);
    await OfflineQueueService.queueOperation(
      type: 'DELETE',
      entity: 'MEDICINE',
      entityId: medId,
    );
    for (var a in alarms) {
      final aid = a['alarmId']?.toString() ?? '';
      if (aid.isNotEmpty) await NotificationService.cancelAlarm(aid.hashCode);
    }
    SyncService.trySyncNow();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);

    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(
          MSizes.defaultSpace,
          8,
          MSizes.defaultSpace,
          MSizes.defaultSpace,
        ),
        child: ElevatedButton.icon(
          onPressed: () async {
            await Get.to(() => const OCRScanPage());
            _loadData();
          },
          icon: const Icon(Iconsax.add, color: Colors.white),
          label: const Text(
            'Add Medication',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: MColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      appBar: MAppBar(
        title: Text(
          'Medical History',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        showBackArrow: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: MColors.primary))
          : (chronicDiseases.isEmpty && nonChronicDiseases.isEmpty)
          ? Center(
              child: Text(
                'No medicines added yet.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: MColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(MSizes.defaultSpace),
                children: [
                  if (chronicDiseases.isNotEmpty) ...[
                    _sectionHeader(
                      'Chronic Conditions',
                      Icons.favorite,
                      Colors.red.shade400,
                      dark,
                    ),
                    const SizedBox(height: 12),
                    ...chronicDiseases.entries.map(
                      (e) => _buildDiseaseGroup(e.key, e.value, true, dark),
                    ),
                    const SizedBox(height: MSizes.spaceBtwSections),
                  ],
                  if (nonChronicDiseases.isNotEmpty) ...[
                    _sectionHeader(
                      'Non-Chronic Conditions',
                      Icons.healing,
                      Colors.grey.shade500,
                      dark,
                    ),
                    const SizedBox(height: 12),
                    ...nonChronicDiseases.entries.map(
                      (e) => _buildDiseaseGroup(e.key, e.value, false, dark),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color, bool dark) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: dark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDiseaseGroup(
    String diseaseName,
    List<Map<String, dynamic>> medicines,
    bool isChronic,
    bool dark,
  ) {
    final cardColor = isChronic
        ? (dark ? const Color(0xFF1B3A1B) : const Color(0xFFE8F5E9))
        : (dark ? const Color(0xFF2A2A2A) : Colors.grey.shade100);
    final borderColor = isChronic
        ? (dark ? Colors.green.shade800 : Colors.green.shade200)
        : (dark ? Colors.grey.shade700 : Colors.grey.shade300);
    final accentColor = isChronic ? MColors.primary : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Disease header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.local_hospital, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    diseaseName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${medicines.length} med${medicines.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1),
          // Medicine list
          ...medicines.map((med) => _buildMedicineTile(med, accentColor, dark)),
        ],
      ),
    );
  }

  Widget _buildMedicineTile(
    Map<String, dynamic> med,
    Color accentColor,
    bool dark,
  ) {
    final bool isCompleted = _isCourseCompleted(med);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        med['medicine_name'] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: dark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${med['frequency'] ?? ''}  ${med['duration'] ?? ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                if (med['start_date'] != null &&
                    med['start_date'].toString().isNotEmpty)
                  Text(
                    'Started: ${_formatDate(med['start_date'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.grey.shade500 : Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: accentColor, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicineFormPage(
                    medicines: [Map<String, dynamic>.from(med)],
                    index: 0,
                  ),
                ),
              ).then((_) => _loadData());
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red.shade400,
              size: 20,
            ),
            onPressed: () => _deleteMedicine(med['medId']),
          ),
        ],
      ),
    );
  }

  bool _isCourseCompleted(Map<String, dynamic> med) {
    final duration = med['duration']?.toString() ?? '';
    final startDateStr = med['start_date']?.toString() ?? '';
    final chronic = med['chronic'];
    if (chronic == 1 || chronic == true) return false;
    if (duration.isEmpty || duration == 'Ongoing' || startDateStr.isEmpty)
      return false;
    final startDate = DateTime.tryParse(startDateStr);
    if (startDate == null) return false;
    final days = _parseDurationDays(duration);
    if (days == null) return false;
    final endDate = startDate.add(Duration(days: days - 1));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return todayDate.isAfter(endDate);
  }

  int? _parseDurationDays(String duration) {
    final parts = duration.trim().split(' ');
    if (parts.length < 2) return null;
    final value = int.tryParse(parts[0]);
    if (value == null) return null;
    final unit = parts[1].toLowerCase();
    if (unit.startsWith('day')) return value;
    if (unit.startsWith('week')) return value * 7;
    if (unit.startsWith('month')) return value * 30;
    return null;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    return '${d.day}/${d.month}/${d.year}';
  }
}
