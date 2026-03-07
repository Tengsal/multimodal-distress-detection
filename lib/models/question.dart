enum QuestionType { rating, text, task }

class Question {
  final String id;
  final String text;
  final String module;
  final Map<int, String> transitions;
  final QuestionType type;

  Question({
    required this.id,
    required this.text,
    required this.module,
    required this.transitions,
    this.type = QuestionType.rating,
  });
}