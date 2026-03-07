// lib/services/session_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/session_model.dart';
import 'scoring_engine.dart';

// ================================================================
//  SESSION SERVICE
//
//  Responsibilities:
//    1. Build a SessionModel from the ScoringEngine state
//    2. POST the session JSON to the FastAPI backend
//    3. Handle errors gracefully (offline fallback ready)
//
//  Dependencies (add to pubspec.yaml):
//    http: ^1.2.0
//    uuid: ^4.3.3
// ================================================================

class SessionService {

  // ── Config ────────────────────────────────────────────────────

  // Change this to your FastAPI server address.
  // For local dev: http://localhost:8000
  // For device on same network: http://192.168.x.x:8000
  static const String _baseUrl = "http://192.168.1.5:8000";
  static const String _endpoint = "/sessions";
  static const Duration _timeout = Duration(seconds: 10);

  static final _uuid = Uuid();

  // ── Build + Submit ────────────────────────────────────────────

  /// Call this when the FSM reaches "end".
  /// Returns the server's response body on success, throws on failure.
  static Future<Map<String, dynamic>> submitSession({
    required ScoringEngine engine,
    required DateTime sessionStart,
    String appVersion = "1.0.0",
  }) async {
    final session = _buildSession(
      engine: engine,
      sessionStart: sessionStart,
      appVersion: appVersion,
    );

    return await _post(session);
  }

  // ── Internal ──────────────────────────────────────────────────

  static SessionModel _buildSession({
    required ScoringEngine engine,
    required DateTime sessionStart,
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
      appVersion: appVersion,
    );
  }

  static Future<Map<String, dynamic>> _post(SessionModel session) async {
    final uri = Uri.parse("$_baseUrl$_endpoint");
    final body = jsonEncode(session.toJson());

    try {
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw SessionSubmitException(
          "Server error ${response.statusCode}: ${response.body}",
        );
      }
    } on SessionSubmitException {
      rethrow;
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