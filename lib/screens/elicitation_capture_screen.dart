import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../state/fsm_provider.dart';
import '../data/adaptive_probe_bank.dart';
import '../services/session_service.dart';

class ElicitationCaptureScreen extends ConsumerStatefulWidget {
  const ElicitationCaptureScreen({super.key});

  @override
  ConsumerState<ElicitationCaptureScreen> createState() => _ElicitationCaptureScreenState();
}

class _ElicitationCaptureScreenState extends ConsumerState<ElicitationCaptureScreen> {
  CameraController? _cameraController;
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isReady = false;
  bool _isRecording = false;
  bool _isSubmitting = false;
  
  String? _videoPath;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  Future<void> _initSensors() async {
    try {
      if (!kIsWeb) {
        await [Permission.camera, Permission.microphone].request();
      }
      
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false, // We'll record audio separately for better control
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() => _isReady = true);
      }
    } catch (e) {
      debugPrint("Elicitation init error: $e");
    }
  }

  Future<void> _startRecording() async {
    if (!_isReady || _isRecording) return;
    
    try {
      String audioPath;
      if (kIsWeb) {
        audioPath = "elicitation_recording.wav";
      } else {
        final tempDir = await getTemporaryDirectory();
        final ts = DateTime.now().millisecondsSinceEpoch;
        audioPath = "${tempDir.path}/elicitation_$ts.wav";
      }
      
      _audioPath = audioPath;
      
      await _cameraController!.startVideoRecording();
      await _audioRecorder.start(const RecordConfig(), path: _audioPath!);
      
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint("Start recording error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not start recording: $e")),
        );
      }
    }
  }

  Future<void> _stopAndSubmit() async {
    if (!_isRecording) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final xFile = await _cameraController!.stopVideoRecording();
      _videoPath = xFile.path;
      await _audioRecorder.stop();
      
      final notifier = ref.read(fsmProvider.notifier);
      
      // Perform submission via notifier
      await notifier.submitSession(
        faceImagePath: _videoPath!,
        audioPath: _audioPath!,
      );
      
      // FINALLY move to complete state
      notifier.finish();
    } catch (e) {
      debugPrint("Stop capture error: $e");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fsmProvider);
    final notifier = ref.read(fsmProvider.notifier);
    
    final pId = state.currentProbeId;
    final probe = pId != null ? AdaptiveProbeBank.probes[pId] : null;

    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Center(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
          
          // Recording Indicator
          if (_isRecording)
            Positioned(
              top: 50,
              right: 20,
              child: Row(
                children: [
                   const CircleAvatar(radius: 5, backgroundColor: Colors.red),
                   const SizedBox(width: 8),
                   Text("REC", style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          // Overlay Content
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isRecording) ...[
                    const Text(
                      "Final Stage: Behavioral Elicitation",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "I will guide you through a few exercises while recording.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _startRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text("Start Assessment"),
                    ),
                  ] else ...[
                    // Active Task Instruction
                    Text(
                      probe?.text ?? "Processing...",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 30),
                    
                    if (_isSubmitting)
                       const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: () {
                          final isFinalTask = probe?.transitions[1] == "end";
                          
                          if (isFinalTask) {
                            _stopAndSubmit();
                          } else {
                             notifier.answerProbe(1);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        ),
                        child: Text(probe?.transitions[1] == "end" ? "Finish & Submit" : "Next Step"),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
