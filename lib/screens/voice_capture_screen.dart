import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../services/session_service.dart';
import '../services/scoring_engine.dart';

class VoiceCaptureScreen extends StatefulWidget {
  final String userText;
  final String faceImagePath;

  const VoiceCaptureScreen({
    super.key,
    required this.userText,
    required this.faceImagePath,
  });

  @override
  State<VoiceCaptureScreen> createState() => _VoiceCaptureScreenState();
}

class _VoiceCaptureScreenState extends State<VoiceCaptureScreen> {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isSubmitting = false;

  String? _audioPath;

  int _secondsRemaining = 15;
  Timer? _timer;

  // ----------------------------------------------------
  // Start recording
  // ----------------------------------------------------

  Future<void> _startRecording() async {

    final permission = await Permission.microphone.request();

    if (!permission.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission denied")),
      );
      return;
    }

    String path;

    if (kIsWeb) {
      // Web cannot access filesystem like mobile
      path = "voice_recording.wav";
    } else {
      final dir = await getTemporaryDirectory();
      path =
          "${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav";
    }

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
      ),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _secondsRemaining = 15;
      _audioPath = path;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_secondsRemaining <= 1) {
          _stopRecording();
        } else {
          setState(() {
            _secondsRemaining--;
          });
        }
      },
    );
  }

  // ----------------------------------------------------
  // Stop recording
  // ----------------------------------------------------

  Future<void> _stopRecording() async {

    final path = await _recorder.stop();

    _timer?.cancel();

    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _audioPath = path;
    });
  }

  // ----------------------------------------------------
  // Submit session
  // ----------------------------------------------------

  Future<void> _submitSession() async {

    if (_audioPath == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {

      await SessionService.submitSession(
        engine: ScoringEngine(),
        sessionStart: DateTime.now(),
        userText: widget.userText,
        faceImagePath: widget.faceImagePath,
        audioPath: _audioPath!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session submitted successfully"),
        ),
      );

      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission error: $e")),
      );

    } finally {

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }

    }
  }

  // ----------------------------------------------------
  // Dispose
  // ----------------------------------------------------

  @override
  void dispose() {
    _recorder.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ----------------------------------------------------
  // UI
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice Recording"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "Please speak about how you are feeling.",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 40),

            if (_isRecording)
              Text(
                "Recording... $_secondsRemaining s",
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isRecording
                  ? _stopRecording
                  : _startRecording,
              child: Text(
                _isRecording
                    ? "Stop Recording"
                    : "Start Recording",
              ),
            ),

            const SizedBox(height: 20),

            if (_audioPath != null && !_isRecording)
              const Text("Recording complete"),

            const Spacer(),

            _isSubmitting
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed:
                        (_audioPath == null || _isRecording)
                            ? null
                            : _submitSession,
                    child: const Text("Submit Session"),
                  ),

          ],
        ),
      ),
    );
  }
}