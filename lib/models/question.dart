class Question {
  final String id;
  final String text;
  final String module;
  final Map<int, String> transitions;

  const Question({
    required this.id,
    required this.text,
    required this.module,
    required this.transitions,
  });
}
