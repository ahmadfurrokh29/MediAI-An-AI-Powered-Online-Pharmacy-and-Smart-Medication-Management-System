import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OCRUtils {
  static const String geminiApiKey = "YOUR_GEMINI_API_KEY_HERE";

  static const String _primaryEndpoint =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

  static const String _fallbackEndpoint =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent";

  static Future<List<Map<String, dynamic>>> analyzePrescriptionWithGemini(
    File imageFile,
  ) async {
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final promptText = """
    You are an expert medical assistant. Read this handwritten prescription image.
    Extract the prescribed medicines and return a JSON list of objects.
    Each object must exactly have these keys:
    - "medicine_name" (String)
    - "disease_name" (String, the disease or condition being treated. If not mentioned, leave as "")
    - "frequency" (String, e.g., "0+1+2")
    - "duration" (String, in days, e.g., "7 days")
    - "start_date" (String, use today's date or date on prescription. Format: YYYY-MM-DD)
    - "chronic" (boolean, false by default)
    If you cannot read or find a field, leave it as an empty string "".
    """;

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": promptText},
            {
              "inlineData": {"mimeType": "image/jpeg", "data": base64Image},
            },
          ],
        },
      ],
      "generationConfig": {
        "temperature": 0.2,
        "responseMimeType": "application/json",
      },
    });

    // Try primary model first, fallback to lite on server errors
    try {
      return await _callGemini(_primaryEndpoint, body);
    } catch (e) {
      if (_isServerBusyError(e)) {
        print("⚠️ Gemini 2.5 Flash busy, falling back to Flash Lite...");
        return await _callGemini(_fallbackEndpoint, body);
      }
      rethrow;
    }
  }

  static bool _isServerBusyError(Object e) {
    final msg = e.toString();
    return msg.contains('503') ||
        msg.contains('429') ||
        msg.contains('500') ||
        msg.contains('overloaded') ||
        msg.contains('RESOURCE_EXHAUSTED');
  }

  static Future<List<Map<String, dynamic>>> _callGemini(
    String endpoint,
    String body,
  ) async {
    final url = Uri.parse("$endpoint?key=$geminiApiKey");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      try {
        final textResponse =
            data['candidates'][0]['content']['parts'][0]['text'];

        final parsedJson = jsonDecode(textResponse);

        if (parsedJson is List) {
          return List<Map<String, dynamic>>.from(parsedJson);
        } else if (parsedJson is Map && parsedJson.containsKey('medicines')) {
          return List<Map<String, dynamic>>.from(parsedJson['medicines']);
        } else if (parsedJson is Map) {
          return [Map<String, dynamic>.from(parsedJson)];
        }
        return [];
      } catch (e) {
        throw Exception("Failed to parse Gemini JSON: $e");
      }
    } else {
      throw Exception(
        "Gemini API Error ${response.statusCode}: ${response.body}",
      );
    }
  }
}
