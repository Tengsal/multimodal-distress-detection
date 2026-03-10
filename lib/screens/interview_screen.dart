import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/question_bank.dart';
import '../state/fsm_provider.dart';
import '../widgets/likert_scale.dart';
import 'text_input_screen.dart';
import 'voice_elicitation_screen.dart';
import 'adaptive_probe_screen.dart';
import 'elicitation_capture_screen.dart';

class InterviewScreen extends ConsumerWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fsmProvider);
    final notifier = ref.read(fsmProvider.notifier);

    // ── Stage routing ────────────────────────────────────────────────
    if (state.needsText) return const TextInputScreen();
    if (state.isComplete) return _SummaryScreen(state: state, onRestart: notifier.reset);
    if (state.isElicitationStage && !state.isProbeStage && !state.isVoiceStage) {
      return const ElicitationCaptureScreen();
    }
    if (state.isVoiceStage) return const VoiceElicitationScreen();
    if (state.isProbeStage) return const AdaptiveProbeScreen();

    final question = QuestionBank.questions[state.currentQuestionId];
    if (question == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: ElevatedButton(
            onPressed: notifier.reset,
            child: const Text('Restart session'),
          ),
        ),
      );
    }

    final answeredCount = state.answers.length;
    final progress = (answeredCount / 24).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Custom Header ──────────────────────────────────────
            _buildHeader(context, progress, answeredCount, state.isHighRisk),
            // ── Question Area ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey(question.id),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.text,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                              height: 1.3,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'How much did this apply to you recently?',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    Expanded(
                      child: SingleChildScrollView(
                        child: LikertScale(onSelected: notifier.answer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double progress, int answeredCount, bool isHighRisk) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Check-In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              // Question counter pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Q ${answeredCount + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              if (isHighRisk) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                      SizedBox(width: 4),
                      Text(
                        'High-risk',
                        style: TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                  ),
                ),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Summary Screen
// ═════════════════════════════════════════════════════════════════════════════

class _SummaryScreen extends StatelessWidget {
  const _SummaryScreen({required this.state, required this.onRestart});

  final FsmState state;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final entries = state.answers.entries.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Well done.',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You answered ${entries.length} questions.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            // ── Status banners ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  if (state.isSyncing)
                    const _StatusBanner(
                      icon: Icons.cloud_sync_rounded,
                      color: Color(0xFFF0F9FF),
                      textColor: Color(0xFF0369A1),
                      message: 'Saving your response...',
                    ),
                  if (!state.isSyncing && state.submitError != null)
                    const _StatusBanner(
                      icon: Icons.warning_amber_rounded,
                      color: Color(0xFFFEFCE8),
                      textColor: Color(0xFF854D0E),
                      message: 'Saved locally. Cloud sync failed.',
                    ),
                  if (!state.isSyncing && state.submitError == null)
                    const _StatusBanner(
                      icon: Icons.check_circle_outline_rounded,
                      color: Color(0xFFF0FDF4),
                      textColor: Color(0xFF166534),
                      message: 'Saved successfully.',
                    ),
                  if (state.isHighRisk) ...[
                    const SizedBox(height: 12),
                    const _StatusBanner(
                      icon: Icons.shield_outlined,
                      color: Color(0xFFFEF2F2),
                      textColor: Color(0xFF991B1B),
                      message: 'High-risk indicators detected. Consider support resources.',
                    ),
                  ],
                ],
              ),
            ),
            // ── Responses list ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  const Text(
                    'Your Responses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${entries.length} items',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
                  color: Colors.white,
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Color(0xFFF3F4F6), height: 24),
                  itemBuilder: (context, index) {
                    final item = entries[index];
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.key,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            item.value.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // ── Restart button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRestart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: const Text(
                    'Start New Session',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Status Banner
// ═════════════════════════════════════════════════════════════════════════════

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.color,
    required this.textColor,
    required this.message,
    this.icon,
  });

  final Color color;
  final Color textColor;
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}