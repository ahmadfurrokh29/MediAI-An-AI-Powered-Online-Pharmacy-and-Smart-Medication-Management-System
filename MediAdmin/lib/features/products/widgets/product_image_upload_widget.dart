import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Holds the state of one product image slot (picked bytes + uploaded URL).
class ProductImageEntry {
  Uint8List? bytes;   // null when loaded from an existing network URL
  String name;
  String? url;        // Cloudinary URL after upload (or pre-existing URL)
  String? publicId;   // Cloudinary public_id for deletion
  bool uploading;

  ProductImageEntry({
    this.bytes,
    required this.name,
    this.url,
    this.publicId,
    this.uploading = false,
  });
}

/// 110×110 thumbnail shown in the product image upload grid.
class ProductImageThumbnail extends StatelessWidget {
  const ProductImageThumbnail({
    super.key,
    required this.image,
    required this.onRemove,
    this.isPrimary = false,
  });

  final ProductImageEntry image;
  final VoidCallback onRemove;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image preview
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 110,
            height: 110,
            color: Colors.grey.shade100,
            child: image.bytes != null
                // Newly picked file — show raw bytes
                ? Image.memory(image.bytes!, fit: BoxFit.cover)
                // Pre-existing URL — show network image
                : image.url != null
                    ? Image.network(
                        image.url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
          ),
        ),

        // Uploading spinner overlay
        if (image.uploading)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black45,
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Uploaded checkmark badge
        if (!image.uploading && image.url != null)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 12),
                  SizedBox(width: 3),
                  Text(
                    'Uploaded',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

        // "Main" badge on first image
        if (isPrimary)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Main',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Remove button (only when not uploading)
        if (!image.uploading)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}
