// lib/models/session_model.dart

class SafetyFlag {
  final String code;       // e.g. "HIGH_RISK_SUICIDAL_IDEATION"
  final String label;      // human-readable label
  final String triggeredBy; // question id that triggered this
  final int rating;         // the rating that triggered it
  final String severity;    // "HIGH" | "MEDIUM" | "LOW"

  const SafetyFlag({
    required this.code,
    required this.label,
    required this.triggeredBy,
    required this.rating,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
    "code": code,
    "label": label,
    "triggered_by": triggeredBy,
    "rating": rating,
    "severity": severity,
  };
}

class ModuleScore {
  final String module;
  final int totalScore;
  final int questionCount;
  final double averageScore;
  final int maxPossible;
  final String severity; // "none" | "mild" | "moderate" | "severe"

  const ModuleScore({
    required this.module,
    required this.totalScore,
    required this.questionCount,
    required this.averageScore,
    required this.maxPossible,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
    "module": module,
    "total_score": totalScore,
    "question_count": questionCount,
    "average_score": double.parse(averageScore.toStringAsFixed(2)),
    "max_possible": maxPossible,
    "severity": severity,
  };
}

class SessionResponse {
  final String questionId;
  final String module;
  final String questionText;
  final int rating;
  final DateTime answeredAt;

  const SessionResponse({
    required this.questionId,
    required this.module,
    required this.questionText,
    required this.rating,
    required this.answeredAt,
  });

  Map<String, dynamic> toJson() => {
    "question_id": questionId,
    "module": module,
    "question_text": questionText,
    "rating": rating,
    "answered_at": answeredAt.toIso8601String(),
  };
}

class SessionModel {
  final String sessionId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<SessionResponse> responses;
  final Map<String, ModuleScore> moduleScores;
  final List<SafetyFlag> safetyFlags;
  final bool isHighRisk;
  final int totalQuestionsAnswered;
  final String appVersion;

  const SessionModel({
    required this.sessionId,
    required this.startedAt,
    this.completedAt,
    required this.responses,
    required this.moduleScores,
    required this.safetyFlags,
    required this.isHighRisk,
    required this.totalQuestionsAnswered,
    this.appVersion = "1.0.0",
  });

  Map<String, dynamic> toJson() => {
    "session_id": sessionId,
    "started_at": startedAt.toIso8601String(),
    "completed_at": completedAt?.toIso8601String(),
    "app_version": appVersion,
    "total_questions_answered": totalQuestionsAnswered,
    "is_high_risk": isHighRisk,
    "safety_flags": safetyFlags.map((f) => f.toJson()).toList(),
    "module_scores": moduleScores.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    "responses": responses.map((r) => r.toJson()).toList(),
  };
}