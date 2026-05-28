import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:med/features/personalization/controllers/user_controller.dart';
import 'package:med/features/personalization/screens/mymedicalhistory/ocr_scan/local_db.dart';
import 'package:med/utils/constants/colors.dart';

/// Shown when a medicine is not found in the store.
/// Lets the user send the prescription to the admin for manual fulfilment.
class PrescriptionRequestScreen extends StatefulWidget {
  /// Name of the medicine that was not found.
  final String medicineName;

  /// Pre-loaded prescription base64 from LocalDB, if available.
  final String? prescriptionBase64;

  const PrescriptionRequestScreen({
    super.key,
    required this.medicineName,
    this.prescriptionBase64,
  });

  @override
  State<PrescriptionRequestScreen> createState() =>
      _PrescriptionRequestScreenState();
}

class _PrescriptionRequestScreenState
    extends State<PrescriptionRequestScreen> {
  String? _prescriptionBase64;
  bool _isSending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _prescriptionBase64 = widget.prescriptionBase64;
    // If not pre-loaded, try fetching from LocalDB
    if (_prescriptionBase64 == null || _prescriptionBase64!.isEmpty) {
      _loadPrescriptionFromDB();
    }
  }

  Future<void> _loadPrescriptionFromDB() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;
      final images = await LocalDB.getPrescriptionImagesForNames(
        uid,
        [widget.medicineName],
      );
      if (images.isNotEmpty && mounted) {
        setState(() => _prescriptionBase64 = images.first);
      }
    } catch (_) {}
  }

  /// Resize image bytes to at most 600×800 using dart:ui and return PNG bytes.
  /// Produces small output for prescription documents (text on white), typically
  /// 30–200 KB — well within Firestore's 1 MB document limit.
  Future<Uint8List?> _compressImageBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 600,
        targetHeight: 800,
      );
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickPrescription() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 1200,
        imageQuality: 60,
      );
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      if (mounted) setState(() => _prescriptionBase64 = base64Encode(bytes));
    } catch (e) {
      _showSnack('Could not pick image: $e', Colors.red);
    }
  }

  /// Compress + base64-encode the current prescription as a PNG data-URI.
  /// Used when Cloudinary upload fails. Prescriptions (text on white) compress
  /// to ~30–200 KB at 600×800, well within Firestore's 1 MB limit.
  Future<String> _base64Fallback() async {
    if (_prescriptionBase64 == null || _prescriptionBase64!.isEmpty) return '';
    final rawBytes = base64Decode(_prescriptionBase64!);
    final compressed = await _compressImageBytes(rawBytes);
    final fallbackBytes = compressed ?? rawBytes;
    final b64 = base64Encode(fallbackBytes);
    if (b64.length <= 900000) return 'data:image/png;base64,$b64';
    return ''; // too large even after compression
  }

  Future<void> _sendRequest() async {
    setState(() => _isSending = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final user = UserController.instance.user.value;

      // Upload prescription image to Cloudinary (unsigned upload)
      // Falls back to compressed base64 data-URI if Cloudinary is unreachable.
      String prescriptionUrl = '';
      if (_prescriptionBase64 != null && _prescriptionBase64!.isNotEmpty) {
        try {
          final bytes = base64Decode(_prescriptionBase64!);
          final uri = Uri.parse(
              'https://api.cloudinary.com/v1_1/dufcpc8fa/image/upload');
          final req = http.MultipartRequest('POST', uri)
            ..fields['upload_preset'] = 'MediAI'
            ..files.add(http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
            ));
          final streamed = await req.send();
          final body = await streamed.stream.bytesToString();
          if (streamed.statusCode == 200) {
            final data = jsonDecode(body) as Map<String, dynamic>;
            prescriptionUrl = (data['secure_url'] as String?) ?? '';
          } else {
            debugPrint('Cloudinary upload failed: ${streamed.statusCode} $body');
            prescriptionUrl = await _base64Fallback();
          }
        } catch (e) {
          debugPrint('Cloudinary upload error: $e');
          prescriptionUrl = await _base64Fallback();
        }
      }

      await FirebaseFirestore.instance
          .collection('PrescriptionRequests')
          .add({
        'customerId': uid,
        'customerName': user.fullName,
        'customerEmail': user.email,
        'medicineName': widget.medicineName,
        'prescriptionUrl': prescriptionUrl,
        'status': 'Pending',
        'adminResponse': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) setState(() => _sent = true);
    } catch (e) {
      _showSnack('Failed to send: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Prescription'),
        centerTitle: true,
        backgroundColor: MColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _sent ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Prescription Sent!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Our team will review your prescription for "${widget.medicineName}" and get back to you shortly.',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back to Stock Management'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final hasPrescription =
        _prescriptionBase64 != null && _prescriptionBase64!.isNotEmpty;
    Uint8List? imgBytes;
    if (hasPrescription) {
      try {
        imgBytes = base64Decode(_prescriptionBase64!);
      } catch (_) {}
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '"${widget.medicineName}" was not found in our store.\nSend your prescription so our team can check for you.',
                    style:
                        TextStyle(color: Colors.orange.shade800, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Medicine name
          const Text(
            'Medicine',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              widget.medicineName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),

          // Prescription image
          const Text(
            'Prescription',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 10),

          if (imgBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                imgBytes,
                width: double.infinity,
                fit: BoxFit.contain,
                height: 260,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _pickPrescription,
                icon: const Icon(Icons.refresh),
                label: const Text('Change Prescription'),
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: _pickPrescription,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: MColors.primary.withOpacity(0.4),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file,
                        size: 40, color: MColors.primary.withOpacity(0.6)),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to upload prescription (optional)',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Send button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendRequest,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSending ? 'Sending...' : 'Send Prescription to Store',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Our team will contact you within 24 hours.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
