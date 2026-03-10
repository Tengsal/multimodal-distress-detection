import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../state/fsm_provider.dart';
import '../data/adaptive_probe_bank.dart';
import '../services/hardware_sync.dart';

class VoiceElicitationScreen extends ConsumerStatefulWidget {
  const VoiceElicitationScreen({super.key});

  @override
  ConsumerState<VoiceElicitationScreen> createState() => _VoiceElicitationScreenState();
}

class _VoiceElicitationScreenState extends ConsumerState<VoiceElicitationScreen>
    with TickerProviderStateMixin {
  AudioRecorder? _audioRecorder;
  bool _isListening = false;
  bool _isSubmitting = false;
  String? _audioPath;

  late AnimationController _pulseController;
  late AnimationController _ringController;
  Timer? _timerTick;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (kIsWeb) {
      HardwareSync.forceReleaseHardware();
    }
  }

  void _startTimer() {
    _recordingSeconds = 0;
    _timerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });
  }

  void _stopTimer() {
    _timerTick?.cancel();
    _timerTick = null;
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _startVoiceRecording() async {
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 2500));
    }

    try {
      _audioRecorder?.dispose();
      _audioRecorder = AudioRecorder();

      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final ts = DateTime.now().millisecondsSinceEpoch;
        _audioPath = "${tempDir.path}/elicitation_$ts.wav";
      }

      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: kIsWeb ? "" : _audioPath ?? "",
      );

      if (mounted) {
        setState(() => _isListening = true);
        _ringController.repeat();
        _startTimer();
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint("Voice recording error: $e");
      final eStr = e.toString();
      String userMsg = "Could not start microphone.";

      if (eStr.contains("NotReadableError")) {
        userMsg = "Microphone is busy. Please wait and try again.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMsg),
            backgroundColor: const Color(0xFF111827),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: "Retry",
              textColor: const Color(0xFF818CF8),
              onPressed: _startVoiceRecording,
            ),
          ),
        );
      }
    }
  }

  Future<void> _finishAndSubmit() async {
    if (!_isListening) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    _stopTimer();
    _ringController.stop();

    try {
      final path = await _audioRecorder?.stop();
      if (path == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      Uint8List bytes;
      if (kIsWeb) {
        bytes = await http.readBytes(Uri.parse(path));
      } else {
        bytes = await File(path).readAsBytes();
      }

      final notifier = ref.read(fsmProvider.notifier);
      notifier.saveAudioBytes(bytes);
      await notifier.submitSession();
      notifier.finish();
    } catch (e) {
      debugPrint("Final submission error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Submission failed: $e"),
            backgroundColor: const Color(0xFF111827),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _audioRecorder?.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fsmProvider);
    final pId = state.currentProbeId;
    final probe = pId != null ? AdaptiveProbeBank.probes[pId] : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF111827).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Voice Check-In',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  if (_isListening)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _PulseDot(),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(_recordingSeconds),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // ── Body ──────────────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Mic visualization ──────────────────────────────
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated rings
                        if (_isListening) ...[
                          AnimatedBuilder(
                            animation: _ringController,
                            builder: (context, _) {
                              return _buildRing(1.0 + _ringController.value * 0.5,
                                  0.15 * (1 - _ringController.value));
                            },
                          ),
                          AnimatedBuilder(
                            animation: _ringController,
                            builder: (context, _) {
                              final delayed =
                                  (_ringController.value + 0.33) % 1.0;
                              return _buildRing(
                                  1.0 + delayed * 0.5, 0.12 * (1 - delayed));
                            },
                          ),
                        ],
                        // Core circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: _isListening ? 100 : 88,
                          height: _isListening ? 100 : 88,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isListening
                                  ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                  : [const Color(0xFF818CF8), const Color(0xFF6366F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF6366F1))
                                    .withValues(alpha: 0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  // ── Prompt text ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      probe?.text ?? "Tell us about your day...",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Speak naturally into your device's microphone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            // ── Bottom actions ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  if (_isSubmitting)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                    )
                  else if (!_isListening)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startVoiceRecording,
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
                            Icon(Icons.mic_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Start Recording',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _finishAndSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stop_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Finish & Submit',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRing(double scale, double opacity) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
    );
  }
}

// ── Pulsing Dot ───────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFFDC2626),
              const Color(0xFFFCA5A5),
              _controller.value,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
