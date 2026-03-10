import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';


import '../state/fsm_provider.dart';
import '../data/adaptive_probe_bank.dart';

class ElicitationCaptureScreen extends ConsumerStatefulWidget {
  const ElicitationCaptureScreen({super.key});

  @override
  ConsumerState<ElicitationCaptureScreen> createState() => _ElicitationCaptureScreenState();
}

class _ElicitationCaptureScreenState extends ConsumerState<ElicitationCaptureScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;

  bool _isReady = false;
  bool _isRecording = false;
  bool _isStopping = false;

  late AnimationController _recDotController;

  @override
  void initState() {
    super.initState();
    _recDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
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
      HapticFeedback.mediumImpact();
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint("Start recording error: $e");
    }
  }

  Future<void> _stopAndProceed() async {
    if (!_isRecording || _isStopping) return;

    setState(() => _isStopping = true);
    HapticFeedback.mediumImpact();

    try {
      final xFile = await _cameraController!.stopVideoRecording();
      final bytes = await xFile.readAsBytes();

      await _cameraController?.dispose();
      _cameraController = null;

      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 1500));
      }

      final notifier = ref.read(fsmProvider.notifier);
      notifier.saveVideoBytes(bytes);
    } catch (e) {
      debugPrint("Stop video error: $e");
      setState(() => _isStopping = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _recDotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fsmProvider);
    final notifier = ref.read(fsmProvider.notifier);

    final pId = state.currentProbeId;
    final probe = pId != null ? AdaptiveProbeBank.probes[pId] : null;

    if (!_isReady) {
      return Scaffold(
        backgroundColor: const Color(0xFF111827),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                'Setting up camera...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF818CF8),
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera Preview ────────────────────────────────────
          Center(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),

          // ── Recording Indicator ──────────────────────────────
          if (_isRecording)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _recDotController,
                          builder: (context, _) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  const Color(0xFFEF4444),
                                  const Color(0xFFFCA5A5),
                                  _recDotController.value,
                                ),
                                shape: BoxShape.circle,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "REC",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Bottom Overlay Card ──────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24, 28, 24,
                    MediaQuery.of(context).padding.bottom + 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_isRecording) ...[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.face_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Face Expression Capture",
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Look at the camera and follow the expressions naturally.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _startRecording,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF111827),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Start Capture",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          probe?.text ?? "Processing...",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            letterSpacing: -0.5,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (_isStopping)
                          const CircularProgressIndicator(color: Color(0xFF6366F1))
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final nextId = probe?.transitions[1];
                                if (nextId == "task_narrative") {
                                  await _stopAndProceed();
                                  if (mounted) notifier.answerProbe(1);
                                } else {
                                  notifier.answerProbe(1);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF111827),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Next Step",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
