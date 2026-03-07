import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/question_bank.dart';
import '../services/scoring_engine.dart';

class FsmState {
  final String? currentQuestionId;
  final Map<String, int> answers;
  final bool isComplete;
  final bool isSubmitting;
  final bool isHighRisk;
  final bool needsText;
  final String? userText;
  final String? submitError;

  const FsmState({
    this.currentQuestionId,
    this.answers = const {},
    this.isComplete = false,
    this.isSubmitting = false,
    this.isHighRisk = false,
    this.needsText = false,
    this.userText,
    this.submitError,
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
    );
  }
}

class FsmNotifier extends StateNotifier<FsmState> {

  FsmNotifier() : super(const FsmState(currentQuestionId: "sleep_01"));

  final ScoringEngine _engine = ScoringEngine();

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

    state = state.copyWith(
      userText: text,
      needsText: false,
      isComplete: true,
    );

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