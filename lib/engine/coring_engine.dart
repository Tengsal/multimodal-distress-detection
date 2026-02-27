// lib/services/scoring_engine.dart

import '../models/session_model.dart';

// ================================================================
//  SCORING ENGINE
//
//  Responsibilities:
//    1. Accumulate per-module scores as the session progresses
//    2. Evaluate deterministic safety flag rules
//    3. Compute severity bands per module
//    4. Produce a final feature vector ready for ML ingestion
//
//  Usage:
//    final engine = ScoringEngine();
//    engine.record(questionId: "mood_19", module: "mood",
//                  questionText: "...", rating: 4);
//    final flags  = engine.safetyFlags;
//    final scores = engine.computeModuleScores();
// ================================================================

// ── Safety rule definition ────────────────────────────────────────

class _SafetyRule {
  final String questionId;
  final int threshold;       // flag fires when rating >= threshold
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

// ── Severity band thresholds (average score per module) ──────────

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

  // ── Internal accumulators ─────────────────────────────────────

  /// Raw responses recorded so far
  final List<SessionResponse> _responses = [];

  /// Per-module running totals:  module → [sum, count]
  final Map<String, List<int>> _moduleTotals = {};

  /// Fired safety flags (deduplicated by code)
  final Map<String, SafetyFlag> _flagMap = {};

  // ── Safety rules table ────────────────────────────────────────
  //
  //  Add as many deterministic rules as you need here.
  //  Rules are evaluated every time record() is called.

  static const List<_SafetyRule> _rules = [

    // ── Suicidal / self-harm ideation ────────────────────────
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

    // ── Severe hopelessness ───────────────────────────────────
    _SafetyRule(
      questionId: "mood_11",
      threshold: 4,
      code: "PERCEIVED_BURDENSOMENESS",
      label: "Strong sense of being a burden to others",
      severity: "MEDIUM",
    ),
    _SafetyRule(
      questionId: "mood_10",
      threshold: 5,
      code: "SEVERE_HOPELESSNESS",
      label: "Severe hopelessness — cannot imagine improvement",
      severity: "HIGH",
    ),

    // ── Panic attacks ─────────────────────────────────────────
    _SafetyRule(
      questionId: "anxiety_14",
      threshold: 4,
      code: "FREQUENT_PANIC_ATTACKS",
      label: "Frequent, severe panic attacks reported",
      severity: "MEDIUM",
    ),

    // ── Severe sleep deprivation ──────────────────────────────
    _SafetyRule(
      questionId: "sleep_16",
      threshold: 5,
      code: "SEVERE_SLEEP_IMPAIRMENT",
      label: "Sleep problems severely impair daily functioning",
      severity: "MEDIUM",
    ),

    // ── Substance use to sleep ────────────────────────────────
    _SafetyRule(
      questionId: "sleep_15",
      threshold: 4,
      code: "SUBSTANCE_SLEEP_DEPENDENCY",
      label: "Relying heavily on substances to sleep",
      severity: "MEDIUM",
    ),

    // ── Appetite / physical neglect ───────────────────────────
    _SafetyRule(
      questionId: "energy_10",
      threshold: 4,
      code: "DISORDERED_EATING_RISK",
      label: "Possible disordered eating pattern",
      severity: "MEDIUM",
    ),
    _SafetyRule(
      questionId: "energy_14",
      threshold: 4,
      code: "PHYSICAL_HEALTH_NEGLECT",
      label: "Significant self-neglect of physical health",
      severity: "MEDIUM",
    ),
  ];

  // ── Severity bands per module (keyed by average score) ───────

  static const Map<String, _SeverityBand> _bands = {
    "sleep": _SeverityBand(mild: 2.0, moderate: 3.0, severe: 4.0),
    "mood":  _SeverityBand(mild: 1.5, moderate: 2.5, severe: 3.5),
    "anxiety": _SeverityBand(mild: 2.0, moderate: 3.0, severe: 4.0),
    "social":  _SeverityBand(mild: 2.0, moderate: 3.0, severe: 4.0),
    "energy":  _SeverityBand(mild: 2.0, moderate: 3.0, severe: 4.0),
    "cognitive": _SeverityBand(mild: 2.0, moderate: 3.0, severe: 4.0),
  };

  // ── Public API ────────────────────────────────────────────────

  /// Record a single question response. Call this from your FSM provider
  /// every time the user answers a question.
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

  /// All raw responses recorded so far
  List<SessionResponse> get responses => List.unmodifiable(_responses);

  /// All currently triggered safety flags
  List<SafetyFlag> get safetyFlags => _flagMap.values.toList();

  /// True if any HIGH-severity flag has been triggered
  bool get isHighRisk =>
      _flagMap.values.any((f) => f.severity == "HIGH");

  /// Compute final module scores — call at end of session
  Map<String, ModuleScore> computeModuleScores() {
    final result = <String, ModuleScore>{};

    for (final entry in _moduleTotals.entries) {
      final module = entry.key;
      final sum    = entry.value[0];
      final count  = entry.value[1];
      final avg    = count > 0 ? sum / count : 0.0;
      final max    = count * 5;

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

  /// Flat feature vector for ML (module averages + flag booleans)
  ///
  /// Output shape (example with 6 modules + 13 flags = 19 features):
  ///   { "feat_sleep_avg": 3.2,  "feat_mood_avg": 4.1, ...
  ///     "flag_ACTIVE_SELF_HARM_IDEATION": 1, ... }
  Map<String, double> buildFeatureVector() {
    final scores  = computeModuleScores();
    final vector  = <String, double>{};

    // Module average scores (continuous features)
    for (final entry in scores.entries) {
      vector["feat_${entry.key}_avg"] = entry.value.averageScore;
      vector["feat_${entry.key}_total"] = entry.value.totalScore.toDouble();
    }

    // Safety flag booleans (binary features)
    for (final rule in _rules) {
      final triggered = _flagMap.containsKey(rule.code) ? 1.0 : 0.0;
      vector["flag_${rule.code}"] = triggered;
    }

    return vector;
  }

  // ── Private helpers ───────────────────────────────────────────

  void _accumulateModule(String module, int rating) {
    _moduleTotals.putIfAbsent(module, () => [0, 0]);
    _moduleTotals[module]![0] += rating;
    _moduleTotals[module]![1] += 1;
  }

  void _evaluateRules(String questionId, int rating) {
    for (final rule in _rules) {
      if (rule.questionId == questionId && rating >= rule.threshold) {
        // De-duplicate: highest severity wins if rule fires multiple times
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
    if (avg >= band.severe)   return "severe";
    if (avg >= band.moderate) return "moderate";
    if (avg >= band.mild)     return "mild";
    return "none";
  }

  /// Reset the engine for a new session
  void reset() {
    _responses.clear();
    _moduleTotals.clear();
    _flagMap.clear();
  }
}