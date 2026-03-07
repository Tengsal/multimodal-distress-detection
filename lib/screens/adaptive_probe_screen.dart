import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/fsm_provider.dart';
import '../data/adaptive_probe_bank.dart';
import '../widgets/likert_scale.dart';
import '../models/question.dart';

class AdaptiveProbeScreen extends ConsumerStatefulWidget {
  const AdaptiveProbeScreen({super.key});

  @override
  ConsumerState<AdaptiveProbeScreen> createState() => _AdaptiveProbeScreenState();
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final probe = AdaptiveProbeBank.probes[pId];
    if (probe == null) {
      return const Scaffold(body: Center(child: Text("Error: Probe not found")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Follow-up"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            Text(
              probe.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            _buildInteractionUI(probe, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionUI(Question probe, FsmNotifier notifier) {
    switch (probe.type) {
      case QuestionType.text:
        return Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Type your response here...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _textController.clear();
                notifier.answerProbe(1); // Nominal answer to trigger transition
              },
              child: const Text("Continue"),
            ),
          ],
        );
      case QuestionType.rating:
      default:
        return LikertScale(
          onSelected: notifier.answerProbe,
        );
    }
  }
}
