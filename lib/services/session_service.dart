import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/session_model.dart';
import 'scoring_engine.dart';

class SessionService {
  static const String _baseUrl = 'http://localhost:8000';
  static const String _endpoint = '/sessions';
  static const Duration _timeout = Duration(seconds: 4);

  static final Uuid _uuid = const Uuid();

  static Future<Map<String, dynamic>> submitSession({
    required ScoringEngine engine,
    required DateTime sessionStart,
    required String userText,
    String appVersion = '1.0.0',
  }) async {
    final session = _buildSession(
      engine: engine,
      sessionStart: sessionStart,
      userText: userText,
      appVersion: appVersion,
    );

    return _post(session);
  }

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
      userText: userText,
      appVersion: appVersion,
    );
  }

  static Future<Map<String, dynamic>> _post(SessionModel session) async {
    final uri = Uri.parse('$_baseUrl$_endpoint');
    final body = jsonEncode(session.toJson());

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw SessionSubmitException(
        'Server error ${response.statusCode}: ${response.body}',
      );
    } on TimeoutException {
      throw SessionSubmitException(
        'Request timed out after ${_timeout.inSeconds}s.',
      );
    } catch (e) {
      throw SessionSubmitException('Network error: $e');
    }
  }
}

class SessionSubmitException implements Exception {
  final String message;

  SessionSubmitException(this.message);

  @override
  String toString() => 'SessionSubmitException: $message';
}
