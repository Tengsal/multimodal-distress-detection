import 'dart:convert';
import 'dart:io' show File, SocketException;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';

import '../models/session_model.dart';
import 'scoring_engine.dart';

class SessionService {

  static const String _baseUrl = "http://127.0.0.1:8000";
  static const String _endpoint = "/sessions";

  static const Duration _timeout = Duration(seconds: 30);

  static final _uuid = const Uuid();

  static Future<Map<String, dynamic>> submitSession({
    required ScoringEngine engine,
    required DateTime sessionStart,
    required String userText,
    required String faceImagePath,
    required String audioPath,
    String appVersion = "1.0.0",
  }) async {

    final session = _buildSession(
      engine: engine,
      sessionStart: sessionStart,
      userText: userText,
      appVersion: appVersion,
    );

    return _post(session, faceImagePath, audioPath);
  }

  static Future<Map<String, dynamic>> submitSessionBytes({
    required ScoringEngine engine,
    required DateTime sessionStart,
    required String userText,
    required Uint8List videoBytes,
    required Uint8List audioBytes,
    String appVersion = "1.0.0",
  }) async {
    final session = _buildSession(
      engine: engine,
      sessionStart: sessionStart,
      userText: userText,
      appVersion: appVersion,
    );

    return _postBytes(session, videoBytes, audioBytes);
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

  static Future<Map<String, dynamic>> _postBytes(
    SessionModel session,
    Uint8List videoBytes,
    Uint8List audioBytes,
  ) async {
    final uri = Uri.parse("$_baseUrl$_endpoint");
    final request = http.MultipartRequest("POST", uri);

    request.fields["session"] = jsonEncode(session.toJson());

    request.files.add(
      http.MultipartFile.fromBytes(
        "face_image",
        videoBytes,
        filename: "face.webm",
        contentType: MediaType("video", "webm"),
      ),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        "voice_audio",
        audioBytes,
        filename: "voice.wav",
        contentType: MediaType("audio", "wav"),
      ),
    );

    try {
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw SessionSubmitException("Server error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      if (e is SocketException || e.toString().contains("Connection refused")) {
        throw SessionSubmitException("Cannot connect to backend ($_baseUrl).");
      }
      throw SessionSubmitException("Network error: $e");
    }
  }

  static Future<Map<String, dynamic>> _post(
    SessionModel session,
    String faceImagePath,
    String audioPath,
  ) async {

    final uri = Uri.parse("$_baseUrl$_endpoint");

    final request = http.MultipartRequest("POST", uri);

    request.fields["session"] = jsonEncode(session.toJson());

    if (kIsWeb) {

      // WEB UPLOAD
      try {
        // In Web, paths are often blob: URLs or data: URLs
        final faceBytes = await http.readBytes(Uri.parse(faceImagePath));
        final audioBytes = await http.readBytes(Uri.parse(audioPath));

        request.files.add(
          http.MultipartFile.fromBytes(
            "face_image",
            faceBytes,
            filename: "face.webm",
            contentType: MediaType("video", "webm"),
          ),
        );

        request.files.add(
          http.MultipartFile.fromBytes(
            "voice_audio",
            audioBytes,
            filename: "voice.webm",
            contentType: MediaType("audio", "webm"),
          ),
        );
      } catch (e) {
        throw SessionSubmitException(
          "Web media loading failed ($e). "
          "Make sure file paths are valid URLs/Blobs."
        );
      }

    } else {

      // NATIVE VERSION
      final faceFile = File(faceImagePath);
      final audioFile = File(audioPath);

      if (!faceFile.existsSync()) {
        throw SessionSubmitException(
          "Face image not found: $faceImagePath",
        );
      }

      if (!audioFile.existsSync()) {
        throw SessionSubmitException(
          "Audio file not found: $audioPath",
        );
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          "face_image",
          faceImagePath,
          contentType: MediaType("image", "jpeg"),
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          "voice_audio",
          audioPath,
          contentType: MediaType("audio", "wav"),
        ),
      );
    }

    try {

      final streamedResponse =
          await request.send().timeout(_timeout);

      final response =
          await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        return jsonDecode(response.body)
            as Map<String, dynamic>;

      } else {

        throw SessionSubmitException(
          "Server error ${response.statusCode}: ${response.body}",
        );

      }

    } catch (e) {

      if (e is SocketException || e.toString().contains("Connection refused") || e.toString().contains("Failed to fetch")) {
        throw SessionSubmitException(
          "Cannot connect to backend ($_baseUrl). "
          "Check if server is running and CORS is allowed.",
        );
      }

      throw SessionSubmitException(
        "Network error: $e",
      );

    }
  }
}

class SessionSubmitException implements Exception {

  final String message;

  SessionSubmitException(this.message);

  @override
  String toString() {
    return "SessionSubmitException: $message";
  }
}