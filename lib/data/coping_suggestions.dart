/// CBT-based coping suggestions mapped to each clinical module.
/// Each suggestion has a title, icon, and step-by-step instructions.
library coping_suggestions;

class CopingSuggestion {
  final String title;
  final String iconEmoji;
  final String description;
  final List<String> steps;

  const CopingSuggestion({
    required this.title,
    required this.iconEmoji,
    required this.description,
    required this.steps,
  });
}

class CopingSuggestions {
  static const Map<String, List<CopingSuggestion>> byModule = {
    // ─── ANXIETY ───────────────────────────────────────────────
    "anxiety": [
      CopingSuggestion(
        title: "4-7-8 Breathing Exercise",
        iconEmoji: "🌬️",
        description:
            "A clinically proven breathing pattern that activates the parasympathetic nervous system and reduces acute anxiety within minutes.",
        steps: [
          "Find a comfortable sitting position and close your eyes.",
          "Exhale completely through your mouth.",
          "Inhale quietly through your nose for 4 seconds.",
          "Hold your breath for 7 seconds.",
          "Exhale completely through your mouth for 8 seconds.",
          "Repeat this cycle 3–4 times.",
        ],
      ),
      CopingSuggestion(
        title: "5-4-3-2-1 Grounding",
        iconEmoji: "🌱",
        description:
            "A grounding technique that uses your five senses to anchor you in the present moment and interrupt anxious thought spirals.",
        steps: [
          "Notice 5 things you can SEE around you.",
          "Notice 4 things you can physically TOUCH.",
          "Notice 3 things you can HEAR right now.",
          "Notice 2 things you can SMELL.",
          "Notice 1 thing you can TASTE.",
          "Take a slow deep breath and check in with how you feel.",
        ],
      ),
    ],

    // ─── MOOD ──────────────────────────────────────────────────
    "mood": [
      CopingSuggestion(
        title: "Gratitude Journal Prompt",
        iconEmoji: "📓",
        description:
            "Writing about positive experiences rewires the brain's negativity bias and has been shown to improve mood over 2–4 weeks.",
        steps: [
          "Find a pen and paper or open a notes app.",
          "Write down 3 specific things that went well today — even small ones.",
          "For each item, write one sentence about WHY it happened.",
          "Read what you wrote out loud to yourself.",
          "Do this every evening for 1 week.",
        ],
      ),
      CopingSuggestion(
        title: "Behavioral Activation",
        iconEmoji: "🚶",
        description:
            "Depression often reduces activity, which in turn worsens mood. Behavioral activation breaks this cycle by scheduling meaningful micro-activities.",
        steps: [
          "Think of ONE small activity you used to enjoy (walk, music, cooking).",
          "Schedule it for a specific time today or tomorrow.",
          "Set a timer for just 10 minutes — start small.",
          "Do the activity even if you don't feel like it.",
          "Afterward, notice any shift in your mood, however small.",
        ],
      ),
    ],

    // ─── SLEEP ─────────────────────────────────────────────────
    "sleep": [
      CopingSuggestion(
        title: "Progressive Muscle Relaxation",
        iconEmoji: "😴",
        description:
            "Systematically tensing and releasing muscle groups reduces physical tension and signals the brain that it is safe to sleep.",
        steps: [
          "Lie down comfortably in bed.",
          "Start with your feet — tense the muscles tightly for 5 seconds.",
          "Release and notice the feeling of relaxation for 10 seconds.",
          "Move upward: calves, thighs, abdomen, hands, arms, shoulders, face.",
          "By the time you reach your face, your body should feel heavy and warm.",
          "Continue breathing slowly and let sleep come naturally.",
        ],
      ),
      CopingSuggestion(
        title: "Sleep Hygiene Protocol",
        iconEmoji: "🌙",
        description:
            "Small consistent habits that dramatically improve sleep quality over 1–2 weeks.",
        steps: [
          "Set a fixed wake-up time and stick to it even on weekends.",
          "No screens (phone, TV, laptop) for 30 minutes before bed.",
          "Keep your bedroom cool, dark, and quiet.",
          "Avoid caffeine after 2 PM.",
          "If you can't sleep after 20 minutes, get up and do a calm activity until sleepy.",
        ],
      ),
    ],

    // ─── SOCIAL ────────────────────────────────────────────────
    "social": [
      CopingSuggestion(
        title: "Micro Social Connection Goal",
        iconEmoji: "🤝",
        description:
            "Social isolation worsens over time if unaddressed. Small, low-pressure social actions rebuild the sense of connection.",
        steps: [
          "Think of ONE person you haven't spoken to recently.",
          "Send them a short message — even just 'Thinking of you' counts.",
          "Don't wait for a perfect moment. Do it in the next 30 minutes.",
          "Notice how it feels to reach out.",
          "Try to do one of these micro-connections each day.",
        ],
      ),
    ],

    // ─── ENERGY ────────────────────────────────────────────────
    "energy": [
      CopingSuggestion(
        title: "5-Minute Body Scan",
        iconEmoji: "⚡",
        description:
            "Low energy often comes from chronic tension stored in the body. A quick body scan releases this and restores vitality.",
        steps: [
          "Sit or lie in a comfortable position.",
          "Close your eyes and take 3 deep breaths.",
          "Slowly scan from the top of your head downward.",
          "Notice any areas of tension, tightness, or heaviness.",
          "Breathe into those areas and consciously release the tension.",
          "Finish with 3 deep breaths and open your eyes slowly.",
        ],
      ),
    ],

    // ─── COGNITIVE ─────────────────────────────────────────────
    "cognitive": [
      CopingSuggestion(
        title: "Thought Record",
        iconEmoji: "🧠",
        description:
            "A core CBT technique that challenges distorted thinking patterns by examining the evidence for and against automatic thoughts.",
        steps: [
          "Write down the situation that triggered the negative thought.",
          "Write the automatic thought exactly as it appeared (e.g. 'I can't do anything right').",
          "Rate how much you believe it (0–100%).",
          "Write evidence SUPPORTING this thought.",
          "Write evidence AGAINST this thought.",
          "Write a balanced alternative thought.",
          "Re-rate your belief in the original thought.",
        ],
      ),
    ],
  };

  /// Returns coping suggestions for the top distressed modules from the answers map.
  /// [answers] maps question_id to rating (1–5). We look at module-level averages.
  static List<CopingSuggestion> selectFor(Map<String, int> answers) {
    final Map<String, List<int>> moduleRatings = {};

    for (final entry in answers.entries) {
      final parts = entry.key.split('_');
      if (parts.isEmpty) continue;
      final module = parts[0]; // e.g. "sleep_01" → "sleep"
      moduleRatings.putIfAbsent(module, () => []).add(entry.value);
    }

    // Calculate module averages and sort descending
    final List<MapEntry<String, double>> sorted = moduleRatings.entries
        .map((e) => MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length))
        .where((e) => byModule.containsKey(e.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<CopingSuggestion> result = [];
    for (final entry in sorted.take(2)) {
      final suggestions = byModule[entry.key];
      if (suggestions != null && suggestions.isNotEmpty) {
        result.add(suggestions.first);
      }
    }

    // Always include at least one suggestion
    if (result.isEmpty && byModule['mood'] != null) {
      result.add(byModule['mood']!.first);
    }

    return result;
  }
}
