import '../models/question.dart';

class AdaptiveProbeBank {
  static final Map<String, Question> probes = {
    // ---------------------------------------------------------
    // SOCIAL PROBES (Triggered by high social score)
    // ---------------------------------------------------------
    "probe_social_01": Question(
      id: "probe_social_01",
      module: "social",
      type: QuestionType.rating,
      text: "How often do you feel truly disconnected from others, even when they are physically there?",
      transitions: {
        1: "probe_social_02",
        2: "probe_social_02",
        3: "probe_social_02",
        4: "probe_social_02",
        5: "probe_social_02",
      },
    ),
    "probe_social_02": Question(
      id: "probe_social_02",
      module: "social",
      type: QuestionType.rating,
      text: "Is there someone in your life you feel comfortable talking to when you're struggling?",
      transitions: {
        1: "probe_generic_01",
        2: "probe_generic_01",
        3: "probe_generic_01",
        4: "probe_generic_01",
        5: "probe_generic_01",
      },
    ),

    // ---------------------------------------------------------
    // MOOD PROBES (Triggered by high mood score)
    // ---------------------------------------------------------
    "probe_mood_01": Question(
      id: "probe_mood_01",
      module: "mood",
      type: QuestionType.rating,
      text: "What is one thing that usually makes you feel even a little bit better when you're feeling low?",
      transitions: {
        1: "probe_mood_02",
        2: "probe_mood_02",
        3: "probe_mood_02",
        4: "probe_mood_02",
        5: "probe_mood_02",
      },
    ),
    "probe_mood_02": Question(
      id: "probe_mood_02",
      module: "mood",
      type: QuestionType.rating,
      text: "Do you feel like your low mood has a specific 'trigger', or does it just happen?",
      transitions: {
        1: "probe_generic_01",
        2: "probe_generic_01",
        3: "probe_generic_01",
        4: "probe_generic_01",
        5: "probe_generic_01",
      },
    ),

    // ---------------------------------------------------------
    // ANXIETY PROBES (Triggered by high anxiety score)
    // ---------------------------------------------------------
    "probe_anxiety_01": Question(
      id: "probe_anxiety_01",
      module: "anxiety",
      type: QuestionType.rating,
      text: "Do you ever feel overwhelmed by your daily responsibilities lately?",
      transitions: {
        1: "probe_anxiety_02",
        2: "probe_anxiety_02",
        3: "probe_anxiety_02",
        4: "probe_anxiety_02",
        5: "probe_anxiety_02",
      },
    ),
    "probe_anxiety_02": Question(
      id: "probe_anxiety_02",
      module: "anxiety",
      type: QuestionType.rating,
      text: "Does the tension you feel manifest physically, like in your chest or shoulders?",
      transitions: {
        1: "probe_generic_01",
        2: "probe_generic_01",
        3: "probe_generic_01",
        4: "probe_generic_01",
        5: "probe_generic_01",
      },
    ),

    // ---------------------------------------------------------
    // GENERIC FALLBACK (Text Probes)
    // ---------------------------------------------------------
    "probe_generic_01": Question(
      id: "probe_generic_01",
      module: "general",
      type: QuestionType.text,
      text: "Is there anything else on your mind that we haven't covered yet?",
      transitions: {
        1: "elicitation_intro",
      },
    ),

    // ---------------------------------------------------------
    // ELICITATION TASKS (Active Sensors)
    // ---------------------------------------------------------
    "elicitation_intro": Question(
      id: "elicitation_intro",
      module: "elicitation",
      type: QuestionType.task,
      text: "Now, I'd like to try a few simple exercises to help me understand your facial expressions and voice better. Ready?",
      transitions: {
        1: "task_smile",
      },
    ),
    "task_smile": Question(
      id: "task_smile",
      module: "elicitation_task",
      type: QuestionType.task,
      text: "Please try to smile broadly for about 3 seconds... 🙂",
      transitions: {
        1: "task_neutral",
      },
    ),
    "task_neutral": Question(
      id: "task_neutral",
      module: "elicitation_task",
      type: QuestionType.task,
      text: "Thank you. Now, please hold a neutral, relaxed face for a moment.",
      transitions: {
        1: "task_narrative",
      },
    ),
    "task_narrative": Question(
      id: "task_narrative",
      module: "elicitation_task",
      type: QuestionType.task,
      text: "Finally, tell me about something that made you happy recently. I'll listen to your voice tone.",
      transitions: {
        1: "end",
      },
    ),
  };
}
