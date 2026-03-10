import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:typed_data';
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

class _VoiceElicitationScreenState extends ConsumerState<VoiceElicitationScreen> with SingleTickerProviderStateMixin {
  AudioRecorder? _audioRecorder; // Lazy initialization
  bool _isListening = false;
  bool _isSubmitting = false;
  String? _audioPath;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Proactive cleanup: Release tracks as soon as we enter this stage
    if (kIsWeb) {
      HardwareSync.forceReleaseHardware();
    }
  }

  Future<void> _startVoiceRecording() async {
    if (kIsWeb) {
      // 2. Cooldown to let browser reconcile media state
      await Future.delayed(const Duration(milliseconds: 2500));
    }

    try {
      // 3. Lazy initialization: Avoid creating the recorder until hardware is cleared
      _audioRecorder?.dispose();
      _audioRecorder = AudioRecorder();

      String? audioPath;
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final ts = DateTime.now().millisecondsSinceEpoch;
        audioPath = "${tempDir.path}/elicitation_$ts.wav";
        _audioPath = audioPath;
      }
      
      // Use WAV on Web as well for backend compatibility (librosa needs wav if ffmpeg is missing)
      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: kIsWeb ? "" : _audioPath ?? "",
      );
      if (mounted) setState(() => _isListening = true);
    } catch (e) {
      debugPrint("Voice recording error: $e");
      final eStr = e.toString();
      String userMsg = "Could not start microphone.";
      
      if (eStr.contains("NotReadableError")) {
        userMsg = "Microphone is busy. Please wait 3 seconds and click Start again.";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMsg),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: "Retry",
              textColor: Colors.white,
              onPressed: _startVoiceRecording,
            ),
          ),
        );
      }
    }
  }

  Future<void> _finishAndSubmit() async {
    if (!_isListening) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      print("SUBMIT: Stopping audio recorder...");
      final path = await _audioRecorder?.stop();
      print("SUBMIT: Audio recorder stopped. Path: $path");
      
      if (path == null) {
        print("SUBMIT: Error - Path is null");
        setState(() => _isSubmitting = false);
        return;
      }
      
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print("SUBMIT: Reading bytes from $path...");
      Uint8List bytes;
      if (kIsWeb) {
         bytes = await http.readBytes(Uri.parse(path));
      } else {
         bytes = await File(path).readAsBytes();
      }
      print("SUBMIT: Bytes read (${bytes.length} bytes). Sending to state...");
      
      final notifier = ref.read(fsmProvider.notifier);
      notifier.saveAudioBytes(bytes);
      
      print("SUBMIT: Calling submitSession()...");
      await notifier.submitSession();
      print("SUBMIT: submitSession() completed.");
      
      notifier.finish();
    } catch (e) {
      print("SUBMIT: CATCH ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Submission failed: $e"),
            backgroundColor: Colors.orange.shade900,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _audioRecorder?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fsmProvider);
    final pId = state.currentProbeId;
    final probe = pId != null ? AdaptiveProbeBank.probes[pId] : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
         title: const Text("Voice Analysis"),
         automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mic_none, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 30),
              Text(
                probe?.text ?? "Tell us about your day...",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "Click the button below and speak naturally.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 60),
              
              if (_isSubmitting)
                const CircularProgressIndicator()
              else if (!_isListening)
                ElevatedButton.icon(
                  onPressed: _startVoiceRecording,
                  icon: const Icon(Icons.mic),
                  label: const Text("Start Recording"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                )
              else ...[
                FadeTransition(
                  opacity: _pulseController,
                  child: const Text(
                    "Recording Voice...",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _finishAndSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text("Finish & Submit"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
