import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/cloudinary_service.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';

class UpdateCategoryPage extends StatefulWidget {
  final VoidCallback onBack;
  final Map<String, dynamic> category;

  const UpdateCategoryPage({
    super.key,
    required this.onBack,
    required this.category,
  });

  @override
  State<UpdateCategoryPage> createState() => _UpdateCategoryPageState();
}

class _UpdateCategoryPageState extends State<UpdateCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final controller = Get.find<CategoryController>();
  late bool featured;
  late bool active;

  // ── Icon image state ───────────────────────────────────────────────────────
  Uint8List? _iconBytes;
  String? _iconUrl;
  String? _iconPublicId;
  bool _isUploadingIcon = false;

  // ── Banner image state ─────────────────────────────────────────────────────
  Uint8List? _bannerBytes;
  String? _bannerUrl;
  String? _bannerPublicId;
  bool _isUploadingBanner = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category['name']);
    featured = widget.category['isFeatured'] ?? false;
    active = widget.category['isActive'] ?? true;
    // Pre-fill existing image URLs and publicIds
    _iconUrl = (widget.category['image'] as String?) ?? '';
    _bannerUrl = (widget.category['bannerImage'] as String?) ?? '';
    _iconPublicId = (widget.category['imagePublicId'] as String?) ?? '';
    _bannerPublicId = (widget.category['bannerImagePublicId'] as String?) ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Generic file picker + Cloudinary upload ────────────────────────────────
  Future<void> _pickAndUpload({
    required String folder,
    required void Function(Uint8List bytes) onPicked,
    required void Function(String url, String publicId) onUploaded,
    required void Function() onUploadStart,
    required void Function() onUploadEnd,
  }) async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/png,image/jpeg,image/jpg,image/webp'
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
      onPicked(bytes);
      onUploadStart();
    }

    try {
      final result = await CloudinaryService.uploadImage(
        bytes: bytes,
        fileName: htmlFile.name,
        folder: folder,
      );
      if (mounted) onUploaded(result.url, result.publicId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) onUploadEnd();
    }
  }

  Future<void> _pickIcon() => _pickAndUpload(
        folder: 'categories/icons',
        onPicked: (bytes) => setState(() {
          _iconBytes = bytes;
          _iconUrl = null;
          _iconPublicId = null;
        }),
        onUploadStart: () => setState(() => _isUploadingIcon = true),
        onUploaded: (url, pid) => setState(() {
          _iconUrl = url;
          _iconPublicId = pid;
        }),
        onUploadEnd: () => setState(() => _isUploadingIcon = false),
      );

  Future<void> _pickBanner() => _pickAndUpload(
        folder: 'categories/banners',
        onPicked: (bytes) => setState(() {
          _bannerBytes = bytes;
          _bannerUrl = null;
          _bannerPublicId = null;
        }),
        onUploadStart: () => setState(() => _isUploadingBanner = true),
        onUploaded: (url, pid) => setState(() {
          _bannerUrl = url;
          _bannerPublicId = pid;
        }),
        onUploadEnd: () => setState(() => _isUploadingBanner = false),
      );

  // ── Update ─────────────────────────────────────────────────────────────────
  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingIcon || _isUploadingBanner) {
      Get.snackbar('Please wait', 'Images are still uploading…');
      return;
    }

    final existing = widget.category;
    final updated = CategoryModel(
      id: existing['id'],
      name: _nameController.text.trim(),
      image: _iconUrl ?? (existing['image'] as String? ?? ''),
      bannerImage:
          _bannerUrl ?? (existing['bannerImage'] as String? ?? ''),
      imagePublicId:
          _iconPublicId ?? (existing['imagePublicId'] as String? ?? ''),
      bannerImagePublicId:
          _bannerPublicId ?? (existing['bannerImagePublicId'] as String? ?? ''),
      isFeatured: featured,
      isActive: active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await controller.updateCategory(updated);
    await controller.fetchCategories();
    widget.onBack();
  }

  // ── Image upload box widget ────────────────────────────────────────────────
  Widget _imageUploadBox({
    required String label,
    required String hint,
    required Uint8List? bytes,
    required String? uploadedUrl,
    required bool uploading,
    required VoidCallback onTap,
    required double aspectRatio,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        Text(hint,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: aspectRatio,
          child: GestureDetector(
            onTap: uploading ? null : onTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: bytes != null
                        ? (uploadedUrl != null
                            ? const Color(0xFF48BB78)
                            : const Color(0xFF4299E1))
                        : (uploadedUrl != null && uploadedUrl.isNotEmpty)
                            ? const Color(0xFF48BB78)
                            : const Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                child: uploading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Uploading…'),
                          ],
                        ),
                      )
                    : bytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(bytes, fit: BoxFit.cover),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: uploadedUrl != null
                                          ? Colors.green
                                          : Colors.orange,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          uploadedUrl != null
                                              ? Icons.check
                                              : Icons.hourglass_top,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          uploadedUrl != null
                                              ? 'Uploaded'
                                              : 'Processing…',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit,
                                            color: Colors.white, size: 11),
                                        SizedBox(width: 3),
                                        Text(
                                          'Click to change',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : (uploadedUrl != null && uploadedUrl.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(uploadedUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                              child: Icon(Icons.broken_image,
                                                  size: 40),
                                            )),
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.edit,
                                                color: Colors.white,
                                                size: 11),
                                            SizedBox(width: 3),
                                            Text(
                                              'Click to change',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 40,
                                    color: Color(0xFF4299E1),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click to upload',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back row
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
            const SizedBox(width: 10),
            const Text(
              'Update Category',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 30),

        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                width: 700,
                padding: const EdgeInsets.all(30),
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Category Name ────────────────────────────────
                      const Text('Category Name',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter category name'
                            : null,
                        decoration: InputDecoration(
                          hintText: 'Enter category name',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Image uploads ────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Icon (1:1)
                          Expanded(
                            child: _imageUploadBox(
                              label: 'Category Icon',
                              hint:
                                  'Square image shown on Home categories list',
                              bytes: _iconBytes,
                              uploadedUrl: _iconUrl,
                              uploading: _isUploadingIcon,
                              onTap: _pickIcon,
                              aspectRatio: 1,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Category Banner (16:9)
                          Expanded(
                            flex: 2,
                            child: _imageUploadBox(
                              label: 'Category Banner',
                              hint:
                                  'Wide banner shown when category is opened (16:9)',
                              bytes: _bannerBytes,
                              uploadedUrl: _bannerUrl,
                              uploading: _isUploadingBanner,
                              onTap: _pickBanner,
                              aspectRatio: 16 / 9,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Featured toggle ──────────────────────────────
                      Row(
                        children: [
                          const Text('Featured',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 20),
                          Switch(
                            value: featured,
                            activeThumbColor: Colors.green,
                            onChanged: (val) =>
                                setState(() => featured = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Status toggle ────────────────────────────────
                      Row(
                        children: [
                          const Text('Status',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 20),
                          Switch(
                            value: active,
                            activeThumbColor: Colors.green,
                            onChanged: (val) => setState(() => active = val),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            active ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color:
                                  active ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // ── Update button ────────────────────────────────
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4299E1),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: controller.isLoading.value
                                ? null
                                : _handleUpdate,
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Update',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
