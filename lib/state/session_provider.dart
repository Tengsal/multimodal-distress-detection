import 'package:flutter/material.dart';
import '../engine/fsm_engine.dart';
import '../models/session.dart';
import '../models/response.dart';

class SessionProvider extends ChangeNotifier {
  final FSMEngine engine = FSMEngine();
  final Session session = Session();

  void answer(int value) {
    final question = engine.getCurrentQuestion();

    session.responses.add(
      Response(
        questionId: question.id,
        value: value,
        timestamp: DateTime.now(),
      ),
    );

    engine.moveNext(value);
    notifyListeners();
  }

  bool get isFinished => engine.isFinished();
}