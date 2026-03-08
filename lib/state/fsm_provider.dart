import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/question_bank.dart';
import '../services/scoring_engine.dart';
import '../services/session_service.dart';

const Object _noSubmitErrorUpdate = Object();

class FsmState {
  final String? currentQuestionId;
  final Map<String, int> answers;
  final bool isComplete;
  final bool isSubmitting;
  final bool isSyncing;
  final bool isHighRisk;
  final bool needsText;
  final String? submitError;

  const FsmState({
    this.currentQuestionId,
    this.answers = const {},
    this.isComplete = false,
    this.isSubmitting = false,
    this.isSyncing = false,
    this.isHighRisk = false,
    this.needsText = false,
    this.submitError,
  });

  FsmState copyWith({
    String? currentQuestionId,
    Map<String, int>? answers,
    bool? isComplete,
    bool? isSubmitting,
    bool? isSyncing,
    bool? isHighRisk,
    bool? needsText,
    Object? submitError = _noSubmitErrorUpdate,
  }) {
    return FsmState(
      currentQuestionId: currentQuestionId ?? this.currentQuestionId,
      answers: answers ?? this.answers,
      isComplete: isComplete ?? this.isComplete,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSyncing: isSyncing ?? this.isSyncing,
      isHighRisk: isHighRisk ?? this.isHighRisk,
      needsText: needsText ?? this.needsText,
      submitError: identical(submitError, _noSubmitErrorUpdate)
          ? this.submitError
          : submitError as String?,
    );
  }
}

class FsmNotifier extends StateNotifier<FsmState> {
  FsmNotifier() : super(const FsmState(currentQuestionId: 'sleep_01'));

  final ScoringEngine _engine = ScoringEngine();
  final DateTime _sessionStart = DateTime.now();
  int _syncRunId = 0;

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

    if (nextId == null || nextId == 'end') {
      state = state.copyWith(
        answers: updatedAnswers,
        needsText: true,
        isHighRisk: _engine.isHighRisk,
      );
      return;
    }

    state = state.copyWith(
      currentQuestionId: nextId,
      answers: updatedAnswers,
      isHighRisk: _engine.isHighRisk,
    );
  }

  void submitWithText(String text) {
    final syncId = ++_syncRunId;

    state = state.copyWith(
      isSubmitting: true,
      isSyncing: true,
      submitError: null,
    );

    final submitFuture = SessionService.submitSession(
      engine: _engine,
      sessionStart: _sessionStart,
      userText: text,
    );

    state = state.copyWith(
      isSubmitting: false,
      isComplete: true,
      needsText: false,
    );

    unawaited(
      submitFuture.then((_) {
        if (syncId != _syncRunId) return;
        state = state.copyWith(isSyncing: false);
      }).catchError((Object error) {
        if (syncId != _syncRunId) return;
        state = state.copyWith(
          isSyncing: false,
          submitError: error.toString(),
        );
      }),
    );
  }

  void reset() {
    _syncRunId++;
    _engine.reset();
    state = const FsmState(currentQuestionId: 'sleep_01');
  }
}

final fsmProvider = StateNotifierProvider<FsmNotifier, FsmState>(
  (ref) => FsmNotifier(),
);
