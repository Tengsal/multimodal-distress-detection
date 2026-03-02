// lib/services/scoring_engine.dart

import '../models/session_model.dart';

/// ================================================================
/// SCORING ENGINE
/// ================================================================
/// Responsibilities:
///   • Record responses
///   • Track per-module scoring
///   • Trigger deterministic safety rules
///   • Compute severity bands
///   • Produce ML-ready feature vector
/// ================================================================

class _SafetyRule {
  final String questionId;
  final int threshold;
  final String code;
  final String label;
  final String severity;

  const _SafetyRule({
    required this.questionId,
    required this.threshold,
    required this.code,
    required this.label,
    required this.severity,
  });
}

class _SeverityBand {
  final double mild;
  final double moderate;
  final double severe;

  const _SeverityBand({
    required this.mild,
    required this.moderate,
    required this.severe,
  });
}

class ScoringEngine {
  // ==============================================================
  // INTERNAL STATE
  // ==============================================================

  final List<SessionResponse> _responses = [];
  final Map<String, List<int>> _moduleTotals = {};
  final Map<String, SafetyFlag> _flagMap = {};

  // ==============================================================
  // SAFETY RULES
  // ==============================================================

  static const List<_SafetyRule> _rules = [

    _SafetyRule(
      questionId: "mood_18",
      threshold: 3,
      code: "PASSIVE_SUICIDAL_IDEATION",
      label: "Passive suicidal ideation reported",
      severity: "HIGH",
    ),
    _SafetyRule(
      questionId: "mood_19",
      threshold: 3,
      code: "ACTIVE_SELF_HARM_IDEATION",
      label: "Active self-harm or suicidal thoughts reported",
      severity: "HIGH",
    ),
    _SafetyRule(
      questionId: "mood_20",
      threshold: 3,
      code: "PERSISTENT_SUICIDAL_IDEATION",
      label: "Frequent and persistent suicidal ideation",
      severity: "HIGH",
    ),
    _SafetyRule(
      questionId: "mood_21",
      threshold: 3,
      code: "SUICIDAL_PLAN",
      label: "User may have a plan for self-harm",
      severity: "HIGH",
    ),
    _SafetyRule(
      questionId: "mood_22",
      threshold: 1,
      code: "NO_HELP_SOUGHT_IDEATION",
      label: "User has ideation but has not sought help",
      severity: "MEDIUM",
    ),
    _SafetyRule(
      questionId: "mood_11",
      threshold: 4,
      code: "PERCEIVED_BURDENSOMENESS",
      label: "Strong sense of being a burden",
      severity: "MEDIUM",
    ),
    _SafetyRule(
      questionId: "mood_10",
      threshold: 5,
      code: "SEVERE_HOPELESSNESS",
      label: "Severe hopelessness",
      severity: "HIGH",
    ),
    _SafetyRule(
      questionId: "anxiety_14",
      threshold: 4,
      code: "FREQUENT_PANIC_ATTACKS",
      label: "Frequent severe panic attacks",
      severity: "MEDIUM",
    ),
    _SafetyRule(
      questionId: "sleep_16",
      threshold: 5,
      code: "SEVERE_SLEEP_IMPAIRMENT",
      label: "Sleep severely impairing functioning",
      severity: "MEDIUM",
    ),
    _SafetyRule(
      questionId: "sleep_15",
      threshold: 4,
      code: "SUBSTANCE_SLEEP_DEPENDENCY",
      label: "Substance dependency for sleep",
      severity: "MEDIUM",
    ),
    _SafetyRule(
      questionId: "energy_10",
      threshold: 4,
      code: "DISORDERED_EATING_RISK",
      label: "Possible disordered eating",
      severity: "MEDIUM",
    ),
    _SafetyRule(
      questionId: "energy_14",
      threshold: 4,
      code: "PHYSICAL_HEALTH_NEGLECT",
      label: "Significant self-neglect",
      severity: "MEDIUM",
    ),
  ];

  // ==============================================================
  // SEVERITY BANDS
  // ==============================================================

  static const Map<String, _SeverityBand> _bands = {
    "sleep": _SeverityBand(mild: 2.0, moderate: 3.0, severe: 4.0),
    "mood": _SeverityBand(mild: 1.5, moderate: 2.5, severe: 3.5),
    "anxiety": _SeverityBand(mild: 2.0, moderate: 3.0, severe: 4.0),
    "social": _SeverityBand(mild: 2.0, moderate: 3.0, severe: 4.0),
    "energy": _SeverityBand(mild: 2.0, moderate: 3.0, severe: 4.0),
    "cognitive": _SeverityBand(mild: 2.0, moderate: 3.0, severe: 4.0),
  };

  // ==============================================================
  // PUBLIC API
  // ==============================================================

  void record({
    required String questionId,
    required String module,
    required String questionText,
    required int rating,
  }) {
    final response = SessionResponse(
      questionId: questionId,
      module: module,
      questionText: questionText,
      rating: rating,
      answeredAt: DateTime.now(),
    );

    _responses.add(response);
    _accumulateModule(module, rating);
    _evaluateRules(questionId, rating);
  }

  List<SessionResponse> get responses =>
      List.unmodifiable(_responses);

  List<SafetyFlag> get safetyFlags =>
      _flagMap.values.toList();

  bool get isHighRisk =>
      _flagMap.values.any((f) => f.severity == "HIGH");

  Map<String, ModuleScore> computeModuleScores() {
    final result = <String, ModuleScore>{};

    for (final entry in _moduleTotals.entries) {
      final module = entry.key;
      final sum = entry.value[0];
      final count = entry.value[1];
      final avg = count > 0 ? sum / count : 0.0;
      final max = count * 5;

      result[module] = ModuleScore(
        module: module,
        totalScore: sum,
        questionCount: count,
        averageScore: avg,
        maxPossible: max,
        severity: _severity(module, avg),
      );
    }

    return result;
  }

  Map<String, double> buildFeatureVector() {
    final scores = computeModuleScores();
    final vector = <String, double>{};

    for (final entry in scores.entries) {
      vector["feat_${entry.key}_avg"] =
          entry.value.averageScore;
      vector["feat_${entry.key}_total"] =
          entry.value.totalScore.toDouble();
    }

    for (final rule in _rules) {
      final triggered =
          _flagMap.containsKey(rule.code) ? 1.0 : 0.0;
      vector["flag_${rule.code}"] = triggered;
    }

    return vector;
  }

  // ==============================================================
  // PRIVATE HELPERS
  // ==============================================================

  void _accumulateModule(String module, int rating) {
    _moduleTotals.putIfAbsent(module, () => [0, 0]);
    _moduleTotals[module]![0] += rating;
    _moduleTotals[module]![1] += 1;
  }

  void _evaluateRules(String questionId, int rating) {
    for (final rule in _rules) {
      if (rule.questionId == questionId &&
          rating >= rule.threshold) {
        if (!_flagMap.containsKey(rule.code)) {
          _flagMap[rule.code] = SafetyFlag(
            code: rule.code,
            label: rule.label,
            triggeredBy: questionId,
            rating: rating,
            severity: rule.severity,
          );
        }
      }
    }
  }

  String _severity(String module, double avg) {
    final band = _bands[module];
    if (band == null || avg == 0) return "none";
    if (avg >= band.severe) return "severe";
    if (avg >= band.moderate) return "moderate";
    if (avg >= band.mild) return "mild";
    return "none";
  }

  void reset() {
    _responses.clear();
    _moduleTotals.clear();
    _flagMap.clear();
  }
}