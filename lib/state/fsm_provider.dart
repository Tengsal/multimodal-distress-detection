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

  // ── Phase 3: Adaptive Stages ───────────────────
  final bool isProbeStage;
  final String? currentProbeId;
  final bool isElicitationStage;

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
  }) {
    return FsmState(
      currentQuestionId: currentQuestionId ?? this.currentQuestionId,
      answers: answers ?? this.answers,
      isComplete: isComplete ?? this.isComplete,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isHighRisk: isHighRisk ?? this.isHighRisk,
      needsText: needsText ?? this.needsText,
      userText: userText ?? this.userText,
      submitError: submitError,
      submitSuccess: submitSuccess ?? this.submitSuccess,
      isProbeStage: isProbeStage ?? this.isProbeStage,
      currentProbeId: currentProbeId ?? this.currentProbeId,
      isElicitationStage: isElicitationStage ?? this.isElicitationStage,
    );
  }
}

class FsmNotifier extends StateNotifier<FsmState> {

  FsmNotifier() : super(const FsmState(currentQuestionId: "sleep_01"));

  final ScoringEngine _engine = ScoringEngine();
  ScoringEngine get engine => _engine;

  // ─────────────────────────────────────────────
  // RECORD QUESTION ANSWER
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
  // STORE TEXT INPUT
  // ─────────────────────────────────────────────

  void submitWithText(String text) {
    // 1. Store text
    // 2. Compute highest module to select probe
    final scores = _engine.computeModuleScores();
    String startProbe = "probe_generic_01";
    double maxAvg = 0.0;

    for (var entry in scores.entries) {
      if (entry.value.averageScore > maxAvg) {
        maxAvg = entry.value.averageScore;
        // Map module to probe entry point
        if (entry.key == "social") startProbe = "probe_social_01";
        if (entry.key == "mood") startProbe = "probe_mood_01";
        if (entry.key == "anxiety") startProbe = "probe_anxiety_01";
      }
    }

    state = state.copyWith(
      userText: text,
      needsText: false,
      isProbeStage: true,
      currentProbeId: startProbe,
    );
  }

  // ─────────────────────────────────────────────
  // RECORD PROBE ANSWER
  // ─────────────────────────────────────────────

  void answerProbe(int rating) {
    final pId = state.currentProbeId;
    if (pId == null) return;

    final probe = AdaptiveProbeBank.probes[pId];
    if (probe == null) return;

    // We can also record these in the engine for final logging
    _engine.record(
      questionId: pId,
      module: probe.module,
      questionText: probe.text,
      rating: rating,
    );

    final nextId = probe.transitions[rating];

    if (nextId == null || nextId == "end") {
       // Don't auto-complete for probes/tasks to allow screen to handle submission
    } else {
      // Check if we moved to elicitation
      final isElicitation = nextId.startsWith("task") || nextId.startsWith("elicitation");
      state = state.copyWith(
        currentProbeId: nextId,
        isProbeStage: !isElicitation,
        isElicitationStage: isElicitation,
      );
    }
  }

  void finish() {
    state = state.copyWith(
      isComplete: true,
      isProbeStage: false,
      isElicitationStage: false,
      currentProbeId: null,
    );
  }

  // ─────────────────────────────────────────────
  // SUBMIT SESSION
  // ─────────────────────────────────────────────

  Future<void> submitSession({
    required String faceImagePath,
    required String audioPath,
  }) async {
    state = state.copyWith(isSubmitting: true, submitError: null, submitSuccess: false);

    try {
      await SessionService.submitSession(
        engine: _engine,
        sessionStart: DateTime.now(), // Approximate
        userText: state.userText ?? "",
        faceImagePath: faceImagePath,
        audioPath: audioPath,
      );
      state = state.copyWith(isSubmitting: false, submitSuccess: true);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, submitError: e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // RESET SESSION
  // ─────────────────────────────────────────────

  void reset() {
    _engine.reset();
    state = const FsmState(currentQuestionId: "sleep_01");
  }

}

final fsmProvider =
    StateNotifierProvider<FsmNotifier, FsmState>(
  (ref) => FsmNotifier(),
);