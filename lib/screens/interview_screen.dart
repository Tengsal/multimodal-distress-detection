import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/session_provider.dart';
import '../widgets/likert_scale.dart';

class InterviewScreen extends StatelessWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SessionProvider>(context);

if (provider.isFinished) {
  return Scaffold(
    appBar: AppBar(title: const Text("Summary")),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: provider.session.responses.map((r) {
        return Text(
          "${r.questionId} → ${r.value} at ${r.timestamp}",
        );
      }).toList(),
    ),
  );
}

    final question = provider.engine.getCurrentQuestion();

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
              onSelected: provider.answer,
            ),
          ],
        ),
      ),
    );
  }
}