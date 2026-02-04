import 'dart:convert';
import 'package:http/http.dart' as http;

class MHttpHelper {
  static const String _baseUrl =
      'https://your-api-base-url.com'; // Replace with your API base URL

  // Helper method to make a GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(Uri.parse('$_baseUrl/$endpoint'));
    return _handleResponse(response);
  }

  // Helper method to make a POST request
  static Future<Map<String, dynamic>> post(
    String endpoint,
    dynamic data,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  // Helper method to make a DELETE request
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(Uri.parse('$_baseUrl/$endpoint'));
    return _handleResponse(response);
  }

  // Handle the HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final body = response.body;
      // Print raw body for debugging so we can inspect malformed/non-JSON responses
      print('[HTTP] 200 OK raw response body:\n$body');
      if (body.trim().isEmpty) {
        // Return empty map instead of trying to decode empty body
        print('[HTTP] Empty response body for 200 OK; returning empty map');
        return <String, dynamic>{};
      }
      try {
        return json.decode(body) as Map<String, dynamic>;
      } catch (e) {
        print('[HTTP] JSON decode error: $e');
        print('[HTTP] Raw body that failed to decode:\n$body');
        throw Exception('Invalid JSON response from server');
      }
    } else {
      // Print raw body for non-200 responses as well to aid debugging
      print(
        '[HTTP] Non-200 response: ${response.statusCode} raw body:\n${response.body}',
      );
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }
}
