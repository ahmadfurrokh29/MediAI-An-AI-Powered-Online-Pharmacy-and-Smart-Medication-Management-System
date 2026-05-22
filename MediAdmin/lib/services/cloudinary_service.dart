import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Result returned by [CloudinaryService.uploadImage].
class CloudinaryResult {
  final String url;
  final String publicId;
  const CloudinaryResult({required this.url, required this.publicId});
}

/// Handles image uploads and deletions on Cloudinary.
///
/// Upload uses an *unsigned* preset (no secret needed).
/// Delete uses a *signed* request (requires API key + secret).
///
/// ⚠️  Replace [_apiKey] with your Cloudinary API Key from
///     https://console.cloudinary.com → Settings → API Keys.
class CloudinaryService {
  static const String _cloudName = 'dufcpc8fa';
  static const String _uploadPreset = 'MediAI';

  // Find your API Key in the Cloudinary Console → Settings → API Keys.
  static const String _apiKey = '733156383219276';
  static const String _apiSecret = 'oM3dZhrS-gTt0uWNx8jsnc4hP2k';

  // ── Upload ─────────────────────────────────────────────────────────────────

  /// Upload [bytes] to Cloudinary inside [folder].
  /// Returns a [CloudinaryResult] containing the secure URL and public_id.
  static Future<CloudinaryResult> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw 'Cloudinary upload failed (${streamed.statusCode}): $body';
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    final publicId = json['public_id'] as String?;
    if (url == null || url.isEmpty) {
      throw 'Cloudinary returned no URL: $body';
    }
    return CloudinaryResult(url: url, publicId: publicId ?? '');
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Delete an image from Cloudinary by its [publicId].
  /// Silently ignores errors so a failed Cloudinary delete never blocks
  /// the Firestore delete.
  static Future<void> deleteImage(String publicId) async {
    if (publicId.isEmpty) return;
    if (_apiKey == 'YOUR_CLOUDINARY_API_KEY') return; // not configured yet

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Signature = SHA1("public_id={id}&timestamp={ts}{apiSecret}")
      final toSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1
          .convert(utf8.encode(toSign))
          .toString();

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy',
      );
      await http.post(
        uri,
        body: {
          'public_id': publicId,
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      );
    } catch (_) {
      // Swallow errors – Cloudinary cleanup is best-effort
    }
  }
}
