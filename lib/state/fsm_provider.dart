// lib/providers/fsm_provider.dart

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
  final String? submitError;

  const FsmState({
    this.currentQuestionId,
    this.answers = const {},
    this.isComplete = false,
    this.isSubmitting = false,
    this.isHighRisk = false,
    this.submitError,
  });

  FsmState copyWith({
    String? currentQuestionId,
    Map<String, int>? answers,
    bool? isComplete,
    bool? isSubmitting,
    bool? isHighRisk,
    String? submitError,
  }) =>
      FsmState(
        currentQuestionId: currentQuestionId ?? this.currentQuestionId,
        answers: answers ?? this.answers,
        isComplete: isComplete ?? this.isComplete,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isHighRisk: isHighRisk ?? this.isHighRisk,
        submitError: submitError ?? this.submitError,
      );
}

class FsmNotifier extends StateNotifier<FsmState> {
  FsmNotifier() : super(const FsmState(currentQuestionId: "sleep_01"));

  final ScoringEngine _engine = ScoringEngine();
  final DateTime _sessionStart = DateTime.now();

  Future<void> answer(int rating) async {
    final qId = state.currentQuestionId;
    if (qId == null) return;

    final question = QuestionBank.questions[qId];
    if (question == null) return;

    // Record response in scoring engine
    _engine.record(
      questionId: qId,
      module: question.module,
      questionText: question.text,
      rating: rating,
    );

    final nextId = question.transitions[rating];
    final updatedAnswers = {...state.answers, qId: rating};

    // 🔥 If this is the END → submit FIRST, then mark complete
    if (nextId == null || nextId == "end") {
      state = state.copyWith(
        answers: updatedAnswers,
        isSubmitting: true,
        isHighRisk: _engine.isHighRisk,
      );

      try {
        await SessionService.submitSession(
          engine: _engine,
          sessionStart: _sessionStart,
        );
        // Only AFTER successful submission → complete
        state = state.copyWith(
          isSubmitting: false,
          isComplete: true,
        );
      } catch (e) {
        state = state.copyWith(
          isSubmitting: false,
          submitError: e.toString(),
        );
      }
    } else {
      // Normal transition
      state = state.copyWith(
        currentQuestionId: nextId,
        answers: updatedAnswers,
        isHighRisk: _engine.isHighRisk,
      );
    }
  }

  // Expose current module scores for live progress UI
  Map<String, dynamic> get currentScores =>
      _engine.computeModuleScores().map(
        (k, v) => MapEntry(k, v.toJson()),
      );

  // Expose current safety flags for live UI
  List<Map<String, dynamic>> get currentFlags =>
      _engine.safetyFlags.map((f) => f.toJson()).toList();

  // Expose flat feature vector for debug/display
  Map<String, double> get featureVector => _engine.buildFeatureVector();

  // Reset everything for a new session
  void reset() {
    _engine.reset();
    state = const FsmState(currentQuestionId: "sleep_01");
  }
}

final fsmProvider = StateNotifierProvider<FsmNotifier, FsmState>(
  (ref) => FsmNotifier(),
);