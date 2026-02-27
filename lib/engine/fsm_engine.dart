import '../data/question_bank.dart';
import '../models/question.dart';

class FSMEngine {
  String currentState = "sleep_01";

  Question getCurrentQuestion() {
    return QuestionBank.questions[currentState]!;
  }

  void moveNext(int response) {
    final nextState =
        QuestionBank.questions[currentState]!.transitions[response];

    if (nextState != null) {
      currentState = nextState;
    }
  }

  bool isFinished() {
    return currentState == "end";
  }
}