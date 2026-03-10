import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/fsm_provider.dart';
import '../data/adaptive_probe_bank.dart';
import '../widgets/likert_scale.dart';
import '../models/question.dart';

class AdaptiveProbeScreen extends ConsumerStatefulWidget {
  const AdaptiveProbeScreen({super.key});

  @override
  ConsumerState<AdaptiveProbeScreen> createState() =>
      _AdaptiveProbeScreenState();
}

class _AdaptiveProbeScreenState extends ConsumerState<AdaptiveProbeScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fsmProvider);
    final notifier = ref.read(fsmProvider.notifier);

    final pId = state.currentProbeId;
    if (pId == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    final probe = AdaptiveProbeBank.probes[pId];
    if (probe == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Error: Probe not found")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────
            Container(
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
              child: Row(
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
                    child: const Icon(Icons.route_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Follow-up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFF7C3AED)),
                        SizedBox(width: 4),
                        Text(
                          'Adaptive',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Body ──────────────────────────────────────────────
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
                      child: Text(
                        probe.text,
                        key: ValueKey(pId),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          height: 1.3,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildInteractionUI(probe, notifier),
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

  Widget _buildInteractionUI(Question probe, FsmNotifier notifier) {
    switch (probe.type) {
      case QuestionType.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your response',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                maxLines: 4,
                cursorColor: const Color(0xFF6366F1),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF111827),
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: "Type your response here...",
                  hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 15),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _textController.clear();
                notifier.answerProbe(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      case QuestionType.rating:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How often does this apply to you?',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            LikertScale(onSelected: notifier.answerProbe),
          ],
        );
    }
  }
}
