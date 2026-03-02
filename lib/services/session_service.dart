import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/session_model.dart';
import 'scoring_engine.dart';

class SessionService {
  // ── Backend Config ─────────────────────────────────────────────

  static const String _baseUrl = "http://localhost:8000";
  static const String _endpoint = "/sessions";
  static const Duration _timeout = Duration(seconds: 10);

  static final _uuid = Uuid();

  // ── Public API ─────────────────────────────────────────────────

  /// Call this when session is finished.
  static Future<Map<String, dynamic>> submitSession({
    required ScoringEngine engine,
    required DateTime sessionStart,
    required String userText, // 🔥 REQUIRED NOW
    String appVersion = "1.0.0",
  }) async {
    final session = _buildSession(
      engine: engine,
      sessionStart: sessionStart,
      userText: userText,
      appVersion: appVersion,
    );

    return await _post(session);
  }

  // ── Internal Builder ───────────────────────────────────────────

  static SessionModel _buildSession({
    required ScoringEngine engine,
    required DateTime sessionStart,
    required String userText,
    required String appVersion,
  }) {
    return SessionModel(
      sessionId: _uuid.v4(),
      startedAt: sessionStart,
      completedAt: DateTime.now(),
      responses: engine.responses,
      moduleScores: engine.computeModuleScores(),
      safetyFlags: engine.safetyFlags,
      isHighRisk: engine.isHighRisk,
      totalQuestionsAnswered: engine.responses.length,
      userText: userText, // 🔥 TEXT CONNECTED HERE
      appVersion: appVersion,
    );
  }

  // ── POST to Backend ────────────────────────────────────────────

  static Future<Map<String, dynamic>> _post(SessionModel session) async {
    final uri = Uri.parse("$_baseUrl$_endpoint");
    final body = jsonEncode(session.toJson());

    try {
      final response = await http
          .post(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw SessionSubmitException(
          "Server error ${response.statusCode}: ${response.body}",
        );
      }
    } catch (e) {
      throw SessionSubmitException("Network error: $e");
    }
  }
}

class SessionSubmitException implements Exception {
  final String message;

  SessionSubmitException(this.message);

  @override
  String toString() => "SessionSubmitException: $message";
}