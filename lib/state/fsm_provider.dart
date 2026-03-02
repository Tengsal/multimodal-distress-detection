import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/question_bank.dart';
import '../models/question.dart';
import '../services/scoring_engine.dart';
import '../services/session_service.dart';

class FsmState {
  final String? currentQuestionId;
  final Map<String, int> answers;
  final bool isComplete;
  final bool isSubmitting;
  final bool isHighRisk;
  final bool needsText;
  final String? submitError;

  const FsmState({
    this.currentQuestionId,
    this.answers = const {},
    this.isComplete = false,
    this.isSubmitting = false,
    this.isHighRisk = false,
    this.needsText = false,
    this.submitError,
  });

  FsmState copyWith({
    String? currentQuestionId,
    Map<String, int>? answers,
    bool? isComplete,
    bool? isSubmitting,
    bool? isHighRisk,
    bool? needsText,
    String? submitError,
  }) {
    return FsmState(
      currentQuestionId: currentQuestionId ?? this.currentQuestionId,
      answers: answers ?? this.answers,
      isComplete: isComplete ?? this.isComplete,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isHighRisk: isHighRisk ?? this.isHighRisk,
      needsText: needsText ?? this.needsText,
      submitError: submitError,
    );
  }
}

class FsmNotifier extends StateNotifier<FsmState> {
  FsmNotifier() : super(const FsmState(currentQuestionId: "sleep_01"));

  final ScoringEngine _engine = ScoringEngine();
  final DateTime _sessionStart = DateTime.now();

  // ─────────────────────────────────────────────
  // RECORD ANSWER
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
      // 🚀 DO NOT submit yet
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
  // FINAL SUBMIT WITH TEXT
  // ─────────────────────────────────────────────

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

final fsmProvider =
    StateNotifierProvider<FsmNotifier, FsmState>(
  (ref) => FsmNotifier(),
);