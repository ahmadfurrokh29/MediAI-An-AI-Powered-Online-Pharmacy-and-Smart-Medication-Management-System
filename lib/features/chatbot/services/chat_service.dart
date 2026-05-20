import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  /// Your machine's local IP on the Wi-Fi network.
  /// Change this if your computer's IP changes (run `ipconfig` to check).
  /// For Android emulator use: 'http://10.0.2.2:8000'
  static const String _baseUrl = 'http://192.168.18.109:8000';

  static Future<String> sendMessage(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reply'] as String;
      } else {
        return 'Error: Unable to get a response (${response.statusCode}). Please try again.';
      }
    } catch (_) {
      return 'Could not connect to the server. Make sure the backend is running and you are on the same network.';
    }
  }
}
