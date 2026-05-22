import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../../../services/cloudinary_service.dart';
import '../controllers/banner_controller.dart';
import '../models/banner_model.dart';

class CreateBannerPage extends StatefulWidget {
  final VoidCallback onBack;

  const CreateBannerPage({super.key, required this.onBack});

  @override
  State<CreateBannerPage> createState() => _CreateBannerPageState();
}

class _CreateBannerPageState extends State<CreateBannerPage> {
  final _formKey = GlobalKey<FormState>();
  final bannerTitleController = TextEditingController();
  final descriptionController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _isSaving = false;

  bool isActive = true;
  bool isFeatured = false;

  @override
  void dispose() {
    bannerTitleController.dispose();
    descriptionController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  /// Pick a PNG/JPEG/JPG image file (upload happens only when Create is clicked).
  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/png,image/jpeg,image/jpg'
      ..multiple = false;

    html.document.body!.append(input);

    final changeCompleter = Completer<List<html.File>?>();
    input.onChange.listen((_) {
      final files = input.files;
      if (!changeCompleter.isCompleted) {
        changeCompleter.complete(
          (files != null && files.isNotEmpty) ? files : null,
        );
      }
    });

    input.click();

    final files = await changeCompleter.future;
    input.remove();

    if (files == null) return;

    final htmlFile = files.first;

    final readerCompleter = Completer<String>();
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      if (!readerCompleter.isCompleted) {
        readerCompleter.complete(reader.result as String);
      }
    });
    reader.onError.listen((_) {
      if (!readerCompleter.isCompleted) {
        readerCompleter.completeError('FileReader error');
      }
    });
    reader.readAsDataUrl(htmlFile);

    final dataUrl = await readerCompleter.future;
    final bytes = base64Decode(dataUrl.split(',').last);

    if (mounted) {
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = htmlFile.name;
      });
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            InkWell(
              onTap: widget.onBack,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: Color(0xFF4A5568)),
                  SizedBox(width: 8),
                  Text(
                    'Create Banner',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF2D3748),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Form Card
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Row(
                        children: [
                          Icon(Icons.flag, color: Color(0xFF4299E1), size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Create New Banner',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Image Upload Section
                      Row(
                        children: [
                          const Text(
                            'Banner Image',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(PNG, JPG or JPEG — recommended 1920×1080)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 16:9 aspect ratio preview container
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: GestureDetector(
                          onTap: _isSaving ? null : _pickImage,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _pickedImageBytes != null
                                      ? const Color(0xFF4299E1)
                                      : const Color(0xFFE2E8F0),
                                  width: 2,
                                ),
                              ),
                              child: _pickedImageBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.memory(
                                            _pickedImageBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                          // File name badge bottom-left
                                          if (_pickedImageName != null)
                                            Positioned(
                                              bottom: 8,
                                              left: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  _pickedImageName!,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          // Click-to-change overlay hint
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.edit,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Click to change',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 56,
                                          color: Color(0xFF4299E1),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Click to upload banner image',
                                          style: TextStyle(
                                            color: Color(0xFF4A5568),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'PNG, JPG or JPEG  •  1920 × 1080  (16:9)',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        OutlinedButton.icon(
                                          onPressed: _isSaving ? null : _pickImage,
                                          icon: const Icon(Icons.upload),
                                          label: const Text('Browse file'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF4299E1,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFF4299E1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Banner Title
                      const Text(
                        'Banner Title',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: bannerTitleController,
                        decoration: InputDecoration(
                          hintText: 'Banner Title',
                          hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter banner title';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Description',
                          hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Start Date and End Date Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: startDateController,
                                  readOnly: true,
                                  onTap: () =>
                                      _selectDate(context, startDateController),
                                  decoration: InputDecoration(
                                    hintText: 'Select Date',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFA0AEC0),
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF4299E1),
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please select start date';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'End Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: endDateController,
                                  readOnly: true,
                                  onTap: () =>
                                      _selectDate(context, endDateController),
                                  decoration: InputDecoration(
                                    hintText: 'Select Date',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFA0AEC0),
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF4299E1),
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Checkboxes
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              value: isActive,
                              onChanged: (val) {
                                setState(() {
                                  isActive = val ?? true;
                                });
                              },
                              title: const Text(
                                'Is Active',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              value: isFeatured,
                              onChanged: (val) {
                                setState(() {
                                  isFeatured = val ?? false;
                                });
                              },
                              title: const Text(
                                'isFeatured',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Create Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  setState(() => _isSaving = true);
                                  try {
                                    String imageUrl = '';
                                    String imagePublicId = '';
                                    if (_pickedImageBytes != null &&
                                        _pickedImageName != null) {
                                      final result =
                                          await CloudinaryService.uploadImage(
                                        bytes: _pickedImageBytes!,
                                        fileName: _pickedImageName!,
                                        folder: 'banners',
                                      );
                                      imageUrl = result.url;
                                      imagePublicId = result.publicId;
                                    }
                                    final banner = BannerModel(
                                      id: '',
                                      imageUrl: imageUrl,
                                      imagePublicId: imagePublicId,
                                      title: bannerTitleController.text.trim(),
                                      description:
                                          descriptionController.text.trim(),
                                      redirect: '',
                                      isActive: isActive,
                                      isFeatured: isFeatured,
                                      views: 0,
                                      clicks: 0,
                                      startDate: startDateController.text.trim(),
                                      endDate: endDateController.text.trim(),
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    );
                                    await BannerController.instance.createBanner(
                                      banner,
                                    );
                                    widget.onBack();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isSaving = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4299E1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Create',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
