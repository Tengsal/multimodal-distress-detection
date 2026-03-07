import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import 'voice_capture_screen.dart';

class FaceCaptureScreen extends StatefulWidget {
  final String userText;

  const FaceCaptureScreen({
    super.key,
    required this.userText,
  });

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _controller;

  bool _isReady = false;
  bool _hasError = false;
  bool _isRecording = false;

  int _secondsRemaining = 15;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // ----------------------------------------------------
  // Initialize Camera
  // ----------------------------------------------------

  Future<void> _initializeCamera() async {
    try {
      final permission = await Permission.camera.request();

      if (!permission.isGranted) {
        setState(() => _hasError = true);
        return;
      }

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() => _hasError = true);
        return;
      }

      CameraDescription selectedCamera;

      try {
        selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (_) {
        selectedCamera = cameras.first;
      }

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _isReady = true;
      });
    } catch (e) {
      print("Camera initialization error: $e");

      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
    }
  }

  // ----------------------------------------------------
  // Start Recording
  // ----------------------------------------------------

  Future<void> _startRecording() async {
    if (_controller == null) return;
    if (!_controller!.value.isInitialized) return;
    if (_isRecording) return;

    try {
      await _controller!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _secondsRemaining = 15;
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
    } catch (e) {
      print("Start recording error: $e");
    }
  }

  // ----------------------------------------------------
  // Stop Recording
  // ----------------------------------------------------

  Future<void> _stopRecording() async {
    if (_controller == null) return;

    try {
      if (!_controller!.value.isRecordingVideo) return;

      final videoFile = await _controller!.stopVideoRecording();

      _timer?.cancel();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceCaptureScreen(
            userText: widget.userText,
            faceImagePath: videoFile.path,
          ),
        ),
      );
    } catch (e) {
      print("Stop recording error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
    }
  }

  // ----------------------------------------------------
  // Dispose
  // ----------------------------------------------------

  @override
  void dispose() {
    _controller?.dispose();
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
        title: const Text("Face Video Capture"),
      ),
      body: Column(
        children: [
          Expanded(
            child: _hasError
                ? const Center(child: Text("Camera unavailable"))
                : !_isReady
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          CameraPreview(_controller!),
                          if (_isRecording)
                            Container(
                              color: Colors.black45,
                              child: Center(
                                child: Text(
                                  "$_secondsRemaining",
                                  style: const TextStyle(
                                    fontSize: 80,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                        ],
                      ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: (_isReady && !_isRecording)
                  ? _startRecording
                  : null,
              child: _isRecording
                  ? const Text("Recording...")
                  : const Text("Start 15s Face Recording"),
            ),
          ),
        ],
      ),
    );
  }
}