import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:med/common/widgets/appbar/appbar.dart';
import 'package:med/utils/constants/colors.dart';
import 'package:med/utils/constants/sizes.dart';
import 'package:med/utils/helpers/helper_functions.dart';
import 'ocr_utils.dart';
import 'medicine_form_page.dart';

class OCRScanPage extends StatefulWidget {
  const OCRScanPage({super.key});

  @override
  State<OCRScanPage> createState() => _OCRScanPageState();
}

class _OCRScanPageState extends State<OCRScanPage> {
  File? _image;
  bool isScanning = false;
  List<Map<String, dynamic>> medicines = [];

  final picker = ImagePicker();

  /// Pick Image
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        medicines.clear();
      });
    }
  }

  Future<void> scanPrescription() async {
    if (_image == null) return;

    setState(() => isScanning = true);

    try {
      print("=========== SENDING IMAGE TO GEMINI ===========");

      medicines = await OCRUtils.analyzePrescriptionWithGemini(_image!);

      if (!mounted) return;

      if (medicines.isNotEmpty) {
        // Encode the scanned prescription image once and pass it to the form
        // so it can be saved alongside each medicine in LocalDB.
        String? prescriptionBase64;
        try {
          final bytes = await _image!.readAsBytes();
          prescriptionBase64 = base64Encode(bytes);
        } catch (_) {}

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineFormPage(
              medicines: medicines,
              index: 0,
              prescriptionImageBase64: prescriptionBase64,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No medicines found in this image.")),
        );
      }
    } catch (e) {
      print("ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: MAppBar(
        showBackArrow: true,
        title: Text(
          'Scan Prescription',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MSizes.defaultSpace),
        child: Column(
          children: [
            // Image preview
            _image == null
                ? Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: dark ? MColors.darkerGrey : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: dark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.document_scanner_outlined,
                          size: 56,
                          color: dark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No image selected',
                          style: TextStyle(
                            color: dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Take a photo or pick from gallery',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _image!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

            const SizedBox(height: 24),

            // Camera / Gallery buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    dark: dark,
                    onTap: () => pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    dark: dark,
                    onTap: () => pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Scan button
            isScanning
                ? Column(
                    children: [
                      CircularProgressIndicator(color: MColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        'Extracting medicines... Please wait.',
                        style: TextStyle(
                          color: dark
                              ? Colors.grey.shade300
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _image != null ? scanPrescription : null,
                      icon: const Icon(
                        Icons.auto_fix_high,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Scan & Auto-Fill',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MColors.primary,
                        disabledBackgroundColor: dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

            const SizedBox(height: 24),

            // OR divider
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Manual add button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManualAddMedicinePage(),
                    ),
                  );
                },
                icon: Icon(Icons.edit_note, color: MColors.primary),
                label: Text(
                  'Add Medicine Manually',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: MColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: dark ? MColors.darkerGrey : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: MColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page that lets the user add medicines one by one manually.
/// After saving each medicine, they return here and can add another or finish.
class ManualAddMedicinePage extends StatefulWidget {
  const ManualAddMedicinePage({super.key});

  @override
  State<ManualAddMedicinePage> createState() => _ManualAddMedicinePageState();
}

class _ManualAddMedicinePageState extends State<ManualAddMedicinePage> {
  int addedCount = 0;

  Future<void> _addMedicine() async {
    final emptyMedicine = <String, dynamic>{
      'medicine_name': '',
      'frequency': '',
      'duration': '',
      'start_date': '',
      'chronic': false,
      'available_stock': null,
    };
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineFormPage(
          medicines: [emptyMedicine],
          index: 0,
          isManualMultiAdd: true,
        ),
      ),
    );
    if (result == true) {
      setState(() => addedCount++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = MHelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: MAppBar(
        showBackArrow: true,
        title: Text(
          'Add Medicines',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(MSizes.defaultSpace),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_rounded,
              size: 64,
              color: MColors.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            if (addedCount > 0) ...[
              Text(
                '$addedCount medicine${addedCount > 1 ? 's' : ''} added',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add another or tap Done to finish',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ] else ...[
              Text(
                'No medicines added yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap below to add your first medicine',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addMedicine,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  addedCount > 0 ? 'Add Another Medicine' : 'Add Medicine',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
            if (addedCount > 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: MColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
