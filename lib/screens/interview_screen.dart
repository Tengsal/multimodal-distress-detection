import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/fsm_provider.dart';
import '../data/question_bank.dart';
import '../widgets/likert_scale.dart';

class InterviewScreen extends ConsumerWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fsmProvider);
    final notifier = ref.read(fsmProvider.notifier);

    // 🔹 If finished → show summary
    if (state.isComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text("Summary")),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: state.answers.entries.map((entry) {
            return Text("${entry.key} → ${entry.value}");
          }).toList(),
        ),
      );
    }

    final question =
        QuestionBank.questions[state.currentQuestionId]!;

    return Scaffold(
      appBar: AppBar(title: const Text("Mental Health Screening")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              question.text,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),
            LikertScale(
              onSelected: notifier.answer,
            ),
          ],
        ),
      ),
    );
  }
}