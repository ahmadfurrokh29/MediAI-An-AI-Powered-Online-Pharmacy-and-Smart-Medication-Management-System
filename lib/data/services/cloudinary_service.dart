import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryResult {
  final String url;
  final String publicId;
  const CloudinaryResult({required this.url, required this.publicId});
}

class CloudinaryService {
  static const String _cloudName = 'dufcpc8fa';
  static const String _uploadPreset = 'MediAI';
  static const String _apiKey = '733156383219276';
  static const String _apiSecret = 'oM3dZhrS-gTt0uWNx8jsnc4hP2k';

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

  /// Delete an image from Cloudinary by its [publicId].
  /// Silently ignores errors so a failed Cloudinary delete never blocks other operations.
  static Future<void> deleteImage(String publicId) async {
    if (publicId.isEmpty) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final toSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(toSign)).toString();

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
      // Best-effort — swallow errors
    }
  }
}
