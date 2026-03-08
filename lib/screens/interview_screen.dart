import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/fsm_provider.dart';
import '../data/question_bank.dart';
import 'text_input_screen.dart';
import 'adaptive_probe_screen.dart';
import 'elicitation_capture_screen.dart';
import 'voice_elicitation_screen.dart';
import '../widgets/likert_scale.dart';

class InterviewScreen extends ConsumerWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fsmProvider);
    final notifier = ref.read(fsmProvider.notifier);

    // ─────────────────────────────────────────────
    // STAGE 4: ACTIVE ELICITATION CAPTURE
    // ─────────────────────────────────────────────
    if (state.isElicitationStage) {
      return const ElicitationCaptureScreen();
    }

    if (state.isVoiceStage) {
      return const VoiceElicitationScreen();
    }

    // ─────────────────────────────────────────────
    // STAGE 2: TEXT INPUT
    // ─────────────────────────────────────────────
    if (state.needsText) {
      return const TextInputScreen();
    }

    // ─────────────────────────────────────────────
    // STAGE 3: ADAPTIVE PROBES / ELICITATION
    // ─────────────────────────────────────────────
    if (state.isProbeStage) {
      return const AdaptiveProbeScreen();
    }

    // ─────────────────────────────────────────────
    // SHOW SUMMARY AFTER SUBMIT
    // ─────────────────────────────────────────────
    if (state.isComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text("Session Summary")),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "Questionnaire Results",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...state.answers.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                trailing: Text(entry.value.toString()),
              );
            }),
            const SizedBox(height: 40),
            
            // ─────────────────────────────────────────────
            // SUBMISSION STATUS AREA
            // ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  if (state.isSubmitting) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text("Submitting your session to the backend..."),
                  ] else if (state.submitSuccess) ...[
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      "Submission Successful!",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    const Text("Your diagnostic data has been saved."),
                  ] else if (state.submitError != null) ...[
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "Submission Failed",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    Text(state.submitError!, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => notifier.reset(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text("Start New Session"),
            ),
          ],
        ),
      );
    }

    // ─────────────────────────────────────────────
    // NORMAL QUESTION FLOW
    // ─────────────────────────────────────────────
    final question =
        QuestionBank.questions[state.currentQuestionId]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mental Health Screening"),
      ),
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