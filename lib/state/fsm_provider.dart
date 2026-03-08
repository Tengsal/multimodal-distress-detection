import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/question_bank.dart';
import '../data/adaptive_probe_bank.dart';
import '../services/scoring_engine.dart';
import '../services/session_service.dart';

class FsmState {
  final String? currentQuestionId;
  final Map<String, int> answers;
  final bool isComplete;
  final bool isSubmitting;
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
    bool? isHighRisk,
    bool? needsText,
    String? userText,
    String? submitError,
    bool? submitSuccess,
    bool? isProbeStage,
    String? currentProbeId,
    bool? isElicitationStage,
    bool? isVoiceStage,
    Uint8List? videoBytes,
    Uint8List? audioBytes,
    bool clearError = false,
  }) {
    return FsmState(
      currentQuestionId: currentQuestionId ?? this.currentQuestionId,
      answers: answers ?? this.answers,
      isComplete: isComplete ?? this.isComplete,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isHighRisk: isHighRisk ?? this.isHighRisk,
      needsText: needsText ?? this.needsText,
      userText: userText ?? this.userText,
      submitError: clearError ? null : (submitError ?? this.submitError),
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
  ScoringEngine get engine => _engine;

  // ─────────────────────────────────────────────
  // QUESTIONNAIRE ANSWERS
  // ─────────────────────────────────────────────

  Future<void> answer(int rating) async {
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
    final updatedAnswers = {...state.answers, qId: rating};

    if (nextId == null || nextId == "end") {

      state = state.copyWith(
        answers: updatedAnswers,
        needsText: true,
        isHighRisk: _engine.isHighRisk,
      );

    } else {

      state = state.copyWith(
        currentQuestionId: nextId,
        answers: updatedAnswers,
        isHighRisk: _engine.isHighRisk,
      );

    }
  }

  // ─────────────────────────────────────────────
  // TEXT INPUT → START ADAPTIVE PROBES
  // ─────────────────────────────────────────────

  void submitWithText(String text) {

    final scores = _engine.computeModuleScores();

    // Sort modules by severity
    List<MapEntry<String, dynamic>> sorted = scores.entries.toList()
      ..sort((a, b) => b.value.averageScore.compareTo(a.value.averageScore));

    List<String> probeQueue = [];

    // Select top 2 meaningful modules
    for (var entry in sorted.take(2)) {

      if (entry.value.averageScore >= 2.0) {

        if (entry.key == "social") {
          probeQueue.add("probe_social_01");
        }

        if (entry.key == "mood") {
          probeQueue.add("probe_mood_01");
        }

        if (entry.key == "anxiety") {
          probeQueue.add("probe_anxiety_01");
        }

      }
    }

    // Fallback
    if (probeQueue.isEmpty) {
      probeQueue.add("probe_generic_01");
    }

    state = state.copyWith(
      userText: text,
      needsText: false,
      isProbeStage: true,
      currentProbeId: probeQueue.first,
    );
  }

  // ─────────────────────────────────────────────
  // PROBE ANSWERS
  // ─────────────────────────────────────────────

  void answerProbe(int rating) {

    final pId = state.currentProbeId;
    if (pId == null) return;

    final probe = AdaptiveProbeBank.probes[pId];
    if (probe == null) return;

    _engine.record(
      questionId: pId,
      module: probe.module,
      questionText: probe.text,
      rating: rating,
    );

    final nextId = probe.transitions[rating];

    if (nextId == null || nextId == "end") return;

    final isElicitation =
        nextId.startsWith("task_") || nextId.startsWith("elicitation");

    final isNarrative = nextId == "task_narrative";

    state = state.copyWith(
      currentProbeId: nextId,
      isProbeStage: !isElicitation,
      isElicitationStage: isElicitation && !isNarrative,
      isVoiceStage: isNarrative,
    );
  }

  // ─────────────────────────────────────────────
  // MEDIA STORAGE
  // ─────────────────────────────────────────────

  void saveVideoBytes(Uint8List bytes) {
    state = state.copyWith(videoBytes: bytes);
  }

  void saveAudioBytes(Uint8List bytes) {
    state = state.copyWith(audioBytes: bytes);
  }

  // ─────────────────────────────────────────────
  // FINISH INTERVIEW
  // ─────────────────────────────────────────────

  void finish() {

    state = state.copyWith(
      isComplete: true,
      isProbeStage: false,
      isElicitationStage: false,
      isVoiceStage: false,
      currentProbeId: null,
    );

  }

  // ─────────────────────────────────────────────
  // SUBMIT SESSION
  // ─────────────────────────────────────────────

  Future<void> submitSession() async {

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      submitSuccess: false,
    );

    try {

      final result = await SessionService.submitSessionBytes(
        engine: _engine,
        sessionStart: DateTime.now(),
        userText: state.userText ?? "",
        videoBytes: state.videoBytes!,
        audioBytes: state.audioBytes!,
      );

      // Read is_high_risk from backend response to power the helpline escalation card
      final backendHighRisk = result['risk_level'] == 'HIGH' || result['is_high_risk'] == true;

      state = state.copyWith(
        isSubmitting: false,
        submitSuccess: true,
        isHighRisk: backendHighRisk,
      );

    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: e.toString(),
      );
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // RESET SESSION
  // ─────────────────────────────────────────────

  void reset() {

    _engine.reset();

    state = const FsmState(
      currentQuestionId: "sleep_01",
    );

  }
}

final fsmProvider =
    StateNotifierProvider<FsmNotifier, FsmState>((ref) {
  return FsmNotifier();
});