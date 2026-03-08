import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/fsm_provider.dart';
import '../data/question_bank.dart';
import '../data/coping_suggestions.dart';
import '../data/helpline_data.dart';
import 'text_input_screen.dart';
import 'adaptive_probe_screen.dart';
import 'elicitation_capture_screen.dart';
import 'voice_elicitation_screen.dart';
import 'chatbot_screen.dart';
import '../widgets/likert_scale.dart';

class InterviewScreen extends ConsumerWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fsmProvider);
    final notifier = ref.read(fsmProvider.notifier);

    // ─── STAGE 4: ACTIVE ELICITATION CAPTURE ───────────
    if (state.isElicitationStage) {
      return const ElicitationCaptureScreen();
    }

    if (state.isVoiceStage) {
      return const VoiceElicitationScreen();
    }

    // ─── STAGE 2: TEXT INPUT ────────────────────────────
    if (state.needsText) {
      return const TextInputScreen();
    }

    // ─── STAGE 3: ADAPTIVE PROBES ───────────────────────
    if (state.isProbeStage) {
      return const AdaptiveProbeScreen();
    }

    // ─── SHOW SUMMARY AFTER SUBMIT ──────────────────────
    if (state.isComplete) {
      final suggestions = CopingSuggestions.selectFor(state.answers);

      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: const Text("Session Summary"),
          backgroundColor: const Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatbotScreen()),
          ),
          backgroundColor: const Color(0xFF1A73E8),
          icon: const Text("💙", style: TextStyle(fontSize: 20)),
          label: const Text(
            "Talk to Bot",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ══════════════════════════════════════
            // 🆘 HELPLINE ESCALATION (HIGH RISK)
            // ══════════════════════════════════════
            if (state.isHighRisk && state.submitSuccess) ...[
              _HelplinesCard(),
              const SizedBox(height: 20),
            ],

            // ══════════════════════════════════════
            // ✅ SUBMISSION STATUS
            // ══════════════════════════════════════
            _SubmissionStatusCard(state: state),
            const SizedBox(height: 20),

            // ══════════════════════════════════════
            // 📋 QUESTIONNAIRE RESULTS
            // ══════════════════════════════════════
            _SectionHeader(title: "Questionnaire Results", emoji: "📋"),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Column(
                children: state.answers.entries.map((entry) {
                  return ListTile(
                    title: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF444C5E)),
                    ),
                    trailing: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _ratingColor(entry.value).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _ratingColor(entry.value),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ══════════════════════════════════════
            // 💡 CBT COPING SUGGESTIONS
            // ══════════════════════════════════════
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 28),
              _SectionHeader(title: "Personalized Coping Exercises", emoji: "💡"),
              const SizedBox(height: 4),
              const Text(
                "Based on your responses, here are a few evidence-based exercises that may help.",
                style: TextStyle(color: Color(0xFF7A839A), fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...suggestions.map((s) => _CopingCard(suggestion: s)),
            ],

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      );
    }

    // ─── NORMAL QUESTION FLOW ───────────────────────────
    final question = QuestionBank.questions[state.currentQuestionId]!;
    final answered = state.answers.length;
    final total = QuestionBank.questions.length;
    final progress = total > 0 ? answered / total : 0.0;
    final module = state.currentQuestionId?.split('_').first ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFF1A73E8), Color(0xFF42A5F5)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Mental Health Check‑In",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${answered + 1} / $total",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress bar ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Question Card ───────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Module badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          module.isNotEmpty
                              ? module[0].toUpperCase() + module.substring(1)
                              : "Screening",
                          style: const TextStyle(
                            color: Color(0xFF1A73E8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Question text
                      Text(
                        question.text,
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.55,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1D2B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Likert Scale ────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "How often does this apply to you?",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7A839A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LikertScale(onSelected: notifier.answer),
                  ],
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Color _ratingColor(int rating) {
    if (rating <= 2) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
  }
}

// ══════════════════════════════════════════════════════════
// Submission Status Card
// ══════════════════════════════════════════════════════════

class _SubmissionStatusCard extends StatelessWidget {
  final FsmState state;
  const _SubmissionStatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          if (state.isSubmitting) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            const Text("Submitting your session to the backend..."),
          ] else if (state.submitSuccess) ...[
            const Icon(Icons.check_circle_rounded, color: Color(0xFF34A853), size: 52),
            const SizedBox(height: 12),
            const Text(
              "Session Submitted Successfully!",
              style: TextStyle(
                color: Color(0xFF34A853),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.isHighRisk
                  ? "Your assessment shows elevated distress. Please see the resources below."
                  : "Your diagnostic data has been saved. Keep going! 🌱",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7A839A), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                return OutlinedButton.icon(
                  onPressed: () => ref.read(fsmProvider.notifier).reset(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Start New Session"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A73E8),
                    side: const BorderSide(color: Color(0xFF1A73E8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                );
              },
            ),
          ] else if (state.submitError != null) ...[
            const Icon(Icons.error_rounded, color: Colors.red, size: 52),
            const SizedBox(height: 12),
            const Text(
              "Submission Failed",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.submitError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7A839A), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Helpline Card
// ══════════════════════════════════════════════════════════

class _HelplinesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text("🆘", style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "You Are Not Alone",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Your assessment indicates elevated distress. Trained counsellors are available right now — please reach out.",
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          ...HelplineData.helplines.map((h) => _HelplineRow(helpline: h)),
        ],
      ),
    );
  }
}

class _HelplineRow extends StatelessWidget {
  final Helpline helpline;
  const _HelplineRow({required this.helpline});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Copy number to clipboard when tapped
        Clipboard.setData(ClipboardData(text: helpline.number));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${helpline.name}: ${helpline.number} copied to clipboard"),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone_rounded, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    helpline.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "${helpline.number}  •  ${helpline.hours}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// CBT Coping Card
// ══════════════════════════════════════════════════════════

class _CopingCard extends StatelessWidget {
  final CopingSuggestion suggestion;
  const _CopingCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: ExpansionTile(
        leading: Text(suggestion.iconEmoji, style: const TextStyle(fontSize: 28)),
        title: Text(
          suggestion.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1A1D2B),
          ),
        ),
        subtitle: Text(
          suggestion.description,
          style: const TextStyle(fontSize: 12, color: Color(0xFF7A839A), height: 1.4),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          const Divider(),
          const SizedBox(height: 8),
          ...suggestion.steps.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F0FE),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "${entry.key + 1}",
                        style: const TextStyle(
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF444C5E),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Section Header
// ══════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final String emoji;
  const _SectionHeader({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1D2B),
          ),
        ),
      ],
    );
  }
}