/// Rule-based CBT chatbot response engine.
/// Matches user input to keywords and returns empathetic + actionable responses.
library chatbot_responses;

class BotResponse {
  final String message;
  final String? followUp;
  final String? exercisePrompt;

  const BotResponse({
    required this.message,
    this.followUp,
    this.exercisePrompt,
  });
}

class ChatbotEngine {
  static const String _greeting =
      "Hi, I'm here to listen. 💙\n\nTell me how you're feeling right now — there's no right or wrong answer.";

  static const Map<String, List<BotResponse>> _rules = {
    "stress|stressed|overwhelm|overwhelmed|pressure": [
      BotResponse(
        message: "That sounds really tough. Stress can feel all-consuming sometimes.",
        followUp: "What's been weighing on you the most today?",
        exercisePrompt: "Would you like to try a quick 4-7-8 breathing exercise? It can help within minutes.",
      ),
      BotResponse(
        message: "I hear you. Feeling overwhelmed is your mind's signal that it needs support.",
        followUp: "Is there one thing — even a tiny one — you could set aside for today?",
      ),
    ],
    "anxious|anxiety|nervous|panic|worry|scared|fear|afraid": [
      BotResponse(
        message: "Anxiety can feel very physical and real. You're not imagining it.",
        followUp: "Where do you feel it in your body right now?",
        exercisePrompt: "Try the 5-4-3-2-1 grounding technique — it can interrupt the anxiety cycle in under 2 minutes.",
      ),
      BotResponse(
        message: "That sounds frightening. Anxiety often makes things feel more threatening than they are.",
        followUp: "What's the worst thing you're afraid might happen? Let's look at it together.",
      ),
    ],
    "sad|sadness|unhappy|depressed|depression|hopeless|empty|numb": [
      BotResponse(
        message: "I'm really sorry you're feeling this way. It takes courage to acknowledge that.",
        followUp: "How long have you been feeling like this?",
        exercisePrompt: "Sometimes a 10-minute walk can create a small but real shift in mood. Would that be possible today?",
      ),
      BotResponse(
        message: "Feeling hopeless is one of the hardest experiences. But feelings, even the darkest ones, do change.",
        followUp: "Is there one small thing that has brought you even a tiny moment of comfort recently?",
      ),
    ],
    "lonely|alone|isolated|nobody|no one": [
      BotResponse(
        message: "Loneliness can hurt in a very deep way. It's one of the most painful human experiences.",
        followUp: "Is there anyone in your life you've been meaning to reconnect with?",
        exercisePrompt: "Even a brief message to someone can shift the feeling. Want to try a micro-connection goal?",
      ),
    ],
    "tired|exhausted|fatigue|no energy|drained": [
      BotResponse(
        message: "Emotional exhaustion is just as real as physical exhaustion — and often harder to recover from.",
        followUp: "What does rest look like for you? Do you get much of it?",
        exercisePrompt: "A 5-minute body scan can release stored tension and restore some energy. Want to try?",
      ),
    ],
    "sleep|insomnia|can't sleep|awake|nightmares": [
      BotResponse(
        message: "Poor sleep affects everything — mood, thinking, energy. It's not something to push through.",
        followUp: "What tends to happen when you try to sleep? Does your mind race?",
        exercisePrompt: "Progressive Muscle Relaxation before bed has strong evidence for improving sleep. Want the steps?",
      ),
    ],
    "angry|anger|rage|frustrated|irritable|annoyed": [
      BotResponse(
        message: "Anger is a valid emotion — it often signals that something important is being violated or ignored.",
        followUp: "What triggered this feeling? Was it something someone did, or a situation?",
        exercisePrompt: "Box breathing (4 counts in, hold 4, out 4, hold 4) can reduce anger arousal quickly.",
      ),
    ],
    "help|talk|listen|support": [
      BotResponse(
        message: "I'm here, and I'm listening. You don't have to face this alone.",
        followUp: "What's the heaviest thing you're carrying right now?",
      ),
    ],
    "die|suicide|kill|end it|don't want to live|not worth living": [
      BotResponse(
        message: "I hear you, and what you're feeling right now is serious. Please know that help is available right now.",
        followUp: "Please reach out to a helpline immediately. In India: Vandrevala Foundation — 1860-2662-345 (24/7, Free). You are not alone, and this moment will pass.",
      ),
    ],
    "good|fine|okay|better|great|happy": [
      BotResponse(
        message: "That's genuinely good to hear! What's been going well?",
        followUp: "Sometimes naming what's working helps us appreciate and protect it.",
      ),
    ],
    "thank|thanks|appreciate": [
      BotResponse(
        message: "Of course. You deserve support and someone to talk to. 💙",
        followUp: "Is there anything else on your mind?",
      ),
    ],
  };

  static String get greeting => _greeting;

  /// Returns a bot response given user input text.
  static BotResponse respond(String userInput) {
    final lower = userInput.toLowerCase();

    // Check rules in order (later rules don't override earlier matches)
    for (final entry in _rules.entries) {
      final patterns = entry.key.split('|');
      for (final pattern in patterns) {
        if (lower.contains(pattern)) {
          final responses = entry.value;
          // Cycle through responses using a simple hash to add variety
          final index = lower.length % responses.length;
          return responses[index];
        }
      }
    }

    // Default fallback
    return const BotResponse(
      message: "Tell me more about that. I want to understand what you're going through.",
      followUp: "How long have you been feeling this way?",
    );
  }
}
