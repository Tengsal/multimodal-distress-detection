import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/adaptive_probe_bank.dart';
import '../data/question_bank.dart';
import '../models/question.dart';
import '../services/scoring_engine.dart';
import '../services/session_service.dart';

class FsmState {
  final String? currentQuestionId;
  final Map<String, int> answers;
  final bool isComplete;
  final bool isSubmitting;
  final bool isSyncing;
  final bool isHighRisk;
  final bool needsText;
  final String? userText;
  final String? submitError;
  final bool submitSuccess;

  // Adaptive stages
  final bool isProbeStage;
  final String? currentProbeId;
  final bool isElicitationStage;
  final bool isVoiceStage;

  // Media buffers
  final Uint8List? videoBytes;
  final Uint8List? audioBytes;

  const FsmState({
    this.currentQuestionId,
    this.answers = const {},
    this.isComplete = false,
    this.isSubmitting = false,
    this.isSyncing = false,
    this.isHighRisk = false,
    this.needsText = false,
    this.userText,
    this.submitError,
    this.submitSuccess = false,
    this.isProbeStage = false,
    this.currentProbeId,
    this.isElicitationStage = false,
    this.isVoiceStage = false,
    this.videoBytes,
    this.audioBytes,
  });

  FsmState copyWith({
    String? currentQuestionId,
    Map<String, int>? answers,
    bool? isComplete,
    bool? isSubmitting,
    bool? isSyncing,
    bool? isHighRisk,
    bool? needsText,
    String? submitError,
    bool? submitSuccess,
    bool? isProbeStage,
    String? currentProbeId,
    bool? isElicitationStage,
    bool? isVoiceStage,
    Uint8List? videoBytes,
    Uint8List? audioBytes,
  }) {
    return FsmState(
      currentQuestionId: currentQuestionId ?? this.currentQuestionId,
      answers: answers ?? this.answers,
      isComplete: isComplete ?? this.isComplete,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSyncing: isSyncing ?? this.isSyncing,
      isHighRisk: isHighRisk ?? this.isHighRisk,
      needsText: needsText ?? this.needsText,
      submitError: submitError,
      submitSuccess: submitSuccess ?? this.submitSuccess,
      isProbeStage: isProbeStage ?? this.isProbeStage,
      currentProbeId: currentProbeId ?? this.currentProbeId,
      isElicitationStage: isElicitationStage ?? this.isElicitationStage,
      isVoiceStage: isVoiceStage ?? this.isVoiceStage,
      videoBytes: videoBytes ?? this.videoBytes,
      audioBytes: audioBytes ?? this.audioBytes,
    );
  }
}

class FsmNotifier extends StateNotifier<FsmState> {
  FsmNotifier() : super(const FsmState(currentQuestionId: "sleep_01"));

  final ScoringEngine _engine = ScoringEngine();
  final DateTime _sessionStart = DateTime.now();

  void answer(int rating) {
    final qId = state.currentQuestionId;
    if (qId == null) return;

    final question = QuestionBank.questions[qId];
    if (question == null) return;

    _engine.record(
      questionId: qId,
      module: question.module,
      questionText: question.text,
      rating: rating,
    );

    final nextId = question.transitions[rating];
    final updatedAnswers = <String, int>{...state.answers, qId: rating};

    if (nextId == null || nextId == "end") {
      state = state.copyWith(
        answers: updatedAnswers,
        needsText: true,
        isHighRisk: _engine.isHighRisk,
      );
    } else if (nextId == "ptsd_adaptive_01") {
      state = state.copyWith(
        currentQuestionId: nextId,
        answers: updatedAnswers,
        isHighRisk: _engine.isHighRisk,
        isElicitationStage: true,
        isProbeStage: true,
        currentProbeId: nextId,
      );
    } else {
      state = state.copyWith(
        currentQuestionId: nextId,
        answers: updatedAnswers,
        isHighRisk: _engine.isHighRisk,
      );
    }
  }

  void answerProbe(int rating) {
    final pId = state.currentProbeId;
    if (pId == null) return;

    final probe = AdaptiveProbeBank.probes[pId];
    if (probe == null) return;

    final nextId = probe.transitions[rating];
    if (nextId == null || nextId == "end") {
      state = state.copyWith(
        isProbeStage: false,
        needsText: true,
      );
    } else if (nextId == "voice_elicitation") {
      state = state.copyWith(
        isProbeStage: false,
        isVoiceStage: true,
      );
    } else {
      state = state.copyWith(currentProbeId: nextId);
    }
  }

  void saveVideoBytes(Uint8List bytes) {
    state = state.copyWith(videoBytes: bytes);
  }

  void saveAudioBytes(Uint8List bytes) {
    state = state.copyWith(audioBytes: bytes);
  }

  void finish() {
    state = state.copyWith(
      isComplete: true,
      needsText: false,
      isSubmitting: false,
    );
  }

  Future<void> submitSession() async {
    state = state.copyWith(isSubmitting: true);
    try {
      if (state.videoBytes != null && state.audioBytes != null) {
        await SessionService.submitSessionBytes(
          engine: _engine,
          sessionStart: _sessionStart,
          userText: state.userText ?? "",
          videoBytes: state.videoBytes!,
          audioBytes: state.audioBytes!,
        );
      } else {
        await SessionService.submitSession(
          engine: _engine,
          sessionStart: _sessionStart,
          userText: state.userText ?? "",
        );
      }
      state = state.copyWith(submitSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> submitWithText(String text) async {
    state = state.copyWith(isSubmitting: true);

    try {
      await SessionService.submitSession(
        engine: _engine,
        sessionStart: _sessionStart,
        userText: text,
      );

      state = state.copyWith(
        isSubmitting: false,
        isComplete: true,
        needsText: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString(),
      );
    }
  }

  void reset() {
    _engine.reset();
    state = const FsmState(currentQuestionId: "sleep_01");
  }
}

final fsmProvider = StateNotifierProvider<FsmNotifier, FsmState>(
  (ref) => FsmNotifier(),
);