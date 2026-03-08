import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../state/fsm_provider.dart';
import '../data/adaptive_probe_bank.dart';

class ElicitationCaptureScreen extends ConsumerStatefulWidget {
  const ElicitationCaptureScreen({super.key});

  @override
  ConsumerState<ElicitationCaptureScreen> createState() => _ElicitationCaptureScreenState();
}

class _ElicitationCaptureScreenState extends ConsumerState<ElicitationCaptureScreen> {
  CameraController? _cameraController;
  
  bool _isReady = false;
  bool _isRecording = false;
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  Future<void> _initSensors() async {
    try {
      if (!kIsWeb) {
        await [Permission.camera].request();
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
        enableAudio: false, 
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
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint("Start recording error: $e");
    }
  }

  Future<void> _stopAndProceed() async {
    if (!_isRecording || _isStopping) return;
    
    setState(() => _isStopping = true);
    
    try {
      final xFile = await _cameraController!.stopVideoRecording();
      
      // READ AS BYTES IMMEDIATELY
      final bytes = await xFile.readAsBytes();
      
      if (kIsWeb) {
        // Workaround: flutter camera_web throws "Cannot add new events after calling close"
        // if the widget is disposed immediately after stopVideoRecording(). 
        // We add a tiny delay to let the browser's MediaRecorder finish its internal event stream.
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final notifier = ref.read(fsmProvider.notifier);
      
      // Save video BYTES and move to VOICE STAGE
      notifier.saveVideoBytes(bytes);

      // FSM will trigger navigation in InterviewScreen
    } catch (e) {
      debugPrint("Stop video error: $e");
      setState(() => _isStopping = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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
                      "Stage 4: Face Expression Capture",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Look at the camera and follow the expressions.",
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
                      child: const Text("Start Camera Stage"),
                    ),
                  ] else ...[
                    // Active Task Instruction
                    Text(
                      probe?.text ?? "Processing...",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 30),
                    
                    if (_isStopping)
                       const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: () async {
                          // Check if next is narrative
                          final nextId = probe?.transitions[1];
                          if (nextId == "task_narrative") {
                             // Await bytes capture before answering the probe to avoid unmounting the camera too early
                             await _stopAndProceed();
                             if (mounted) {
                               notifier.answerProbe(1);
                             }
                          } else {
                             notifier.answerProbe(1);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        ),
                        child: const Text("Next Step"),
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
