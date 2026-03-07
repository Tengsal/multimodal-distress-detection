import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/fsm_provider.dart';

class TextInputScreen extends ConsumerStatefulWidget {
  const TextInputScreen({super.key});

  @override
  ConsumerState<TextInputScreen> createState() =>
      _TextInputScreenState();
}

class _TextInputScreenState
    extends ConsumerState<TextInputScreen> {

  final TextEditingController _controller =
      TextEditingController();

  @override
  Widget build(BuildContext context) {

    final state = ref.watch(fsmProvider);
    final notifier = ref.read(fsmProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tell Us More"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "In your own words, how are you feeling?",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            state.isSubmitting
                ? const CircularProgressIndicator()
                : ElevatedButton(

                    onPressed: () {

                      final text = _controller.text.trim();

                      if (text.isEmpty) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please enter some text first.",
                            ),
                          ),
                        );

                        return;
                      }

                      // Store text in FSM
                      // This will trigger isProbeStage = true which InterviewScreen watches
                      notifier.submitWithText(text);
                    },
                    child: const Text("Continue"),
                  ),

          ],
        ),
      ),
    );
  }
}