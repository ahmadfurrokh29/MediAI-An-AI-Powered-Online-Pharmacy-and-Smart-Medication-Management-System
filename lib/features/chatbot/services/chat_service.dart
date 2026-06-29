import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Talks to the MediAI FastAPI backend.
///
/// Strategy (hybrid RAG):
///   1. Send the question to `/chat/rag` — a Retrieval-Augmented Generation
///      endpoint grounded in real DailyMed + OpenFDA drug labels. When the
///      knowledge base covers the question, the reply is fact-grounded and
///      carries source citations (e.g. "[DAILYMED | Ibuprofen | Side Effects]").
///   2. If the question falls outside the ingested knowledge base
///      (`rag_used == false`), fall back to the general `/chat` endpoint so the
///      user still gets a helpful pharmaceutical answer instead of a dead end.
class ChatService {
  /// Your machine's local IP on the Wi-Fi network.
  /// Change this if your computer's IP changes (run `ipconfig` to check).
  /// For Android emulator use: 'http://10.0.2.2:8800'
  static const String _baseUrl = 'http://192.168.137.116:8800';

  // Generous timeout: the first question about a drug not yet in the knowledge
  // base triggers live on-demand ingestion (fetch + chunk + embed), which can
  // take up to ~90s for drugs with large labels. Every later question about
  // that drug is served from cache in a few seconds.
  static const Duration _timeout = Duration(seconds: 120);

  /// Conversation/session id for multi-turn symptom triage. Generated once per
  /// app run and sent on every message so the backend can remember an in-progress
  /// symptom assessment across turns. Call [resetSession] to start a fresh chat.
  static String _sessionId = _newSessionId();

  static String _newSessionId() =>
      'app-${DateTime.now().microsecondsSinceEpoch}';

  /// Start a brand-new conversation (clears any in-progress triage on the server
  /// side by simply using a new session id).
  static void resetSession() {
    _sessionId = _newSessionId();
  }

  static Future<String> sendMessage(String message) async {
    try {
      // ── 1. Try the grounded RAG endpoint first ───────────────────────────
      final ragResponse = await http
          .post(
            Uri.parse('$_baseUrl/chat/rag'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message, 'session_id': _sessionId}),
          )
          .timeout(_timeout);

      if (ragResponse.statusCode == 200) {
        final data = jsonDecode(ragResponse.body) as Map<String, dynamic>;
        final ragUsed = data['rag_used'] as bool? ?? false;
        final triageActive = data['triage_active'] as bool? ?? false;
        final emergency = data['emergency'] as bool? ?? false;
        final reply = (data['reply'] as String?)?.trim() ?? '';

        // Return the reply directly when it's grounded OR part of a symptom
        // triage flow OR an emergency message. Triage questions have no RAG
        // context, so without this check the hybrid fallback below would
        // wrongly discard them and break the multi-turn assessment.
        if (reply.isNotEmpty && (ragUsed || triageActive || emergency)) {
          return reply;
        }
        // Otherwise fall through to the general endpoint below.
      }

      // ── 2. Fallback: general pharmaceutical chat ─────────────────────────
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reply'] as String;
      }
      return 'Error: Server returned ${response.statusCode}. Please try again.';
    } on SocketException catch (e) {
      // Phone can reach the IP but nothing is listening — backend is down,
      // or Windows Firewall is blocking inbound connections on port 8800.
      return 'Connection refused: $_baseUrl\n'
          'Make sure the backend is running and Windows Firewall allows port 8800.\n'
          'Detail: ${e.message}';
    } on http.ClientException catch (e) {
      return 'Network error: ${e.message}\n'
          'Check that your phone and PC are on the same Wi-Fi network.';
    } catch (e) {
      // Timeout or unexpected error — show the real exception type.
      return 'Could not reach backend at $_baseUrl\n'
          'Error: ${e.runtimeType}: $e';
    }
  }
}
