import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/question_bank.dart';
import '../state/fsm_provider.dart';
import '../widgets/likert_scale.dart';
import 'text_input_screen.dart';

class InterviewScreen extends ConsumerWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fsmProvider);
    final notifier = ref.read(fsmProvider.notifier);
    final isCompact = MediaQuery.sizeOf(context).width < 760;

    if (state.needsText) {
      return const TextInputScreen();
    }

    if (state.isComplete) {
      return _SummaryScreen(
        state: state,
        onRestart: notifier.reset,
      );
    }

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Check-In'),
        actions: [
          if (state.isHighRisk)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2), // Red 50
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'High-risk indicators',
                  style: TextStyle(
                    color: Color(0xFF991B1B), // Red 800
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: progress,
                  color: const Color(0xFF111827), // Almost Black
                  backgroundColor: const Color(0xFFF3F4F6), // Light gray track
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Question ${answeredCount + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 48),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  question.text,
                  key: ValueKey(question.id),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: isCompact ? 28 : 34,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'How much did this apply to you recently?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 48),
              Expanded(
                child: SingleChildScrollView(
                  child: LikertScale(
                    onSelected: notifier.answer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryScreen extends StatelessWidget {
  const _SummaryScreen({
    required this.state,
    required this.onRestart,
  });

  final FsmState state;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final entries = state.answers.entries.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Summary'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Well done.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'You answered ${entries.length} questions. Here is your summary.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              if (state.isSyncing)
                const _StatusBanner(
                  color: Color(0xFFF0F9FF),
                  textColor: Color(0xFF0369A1),
                  message: 'Saving your response in the background...',
                ),
              if (!state.isSyncing && state.submitError != null)
                _StatusBanner(
                  color: const Color(0xFFFEFCE8),
                  textColor: Color(0xFF854D0E),
                  message: 'Completed locally, but cloud sync failed: ${state.submitError}',
                ),
              if (!state.isSyncing && state.submitError == null)
                const _StatusBanner(
                  color: Color(0xFFF0FDF4),
                  textColor: Color(0xFF166534),
                  message: 'Saved successfully.',
                ),
              if (state.isHighRisk) ...[
                const SizedBox(height: 12),
                const _StatusBanner(
                  color: Color(0xFFFEF2F2),
                  textColor: Color(0xFF991B1B),
                  message: 'High-risk indicators were detected. Consider immediate support resources.',
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Your Responses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                    color: Colors.white,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0xFFF3F4F6), height: 24),
                    itemBuilder: (context, index) {
                      final item = entries[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.key,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF4B5563),
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            height: 32,
                            width: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item.value.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRestart,
                child: const Text('Start New Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.color,
    required this.textColor,
    required this.message,
  });

  final Color color;
  final Color textColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }
}
