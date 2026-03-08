import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/fsm_provider.dart';

class TextInputScreen extends ConsumerStatefulWidget {
  const TextInputScreen({super.key});

  @override
  ConsumerState<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends ConsumerState<TextInputScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fsmProvider);
    final notifier = ref.read(fsmProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F6F1), Color(0xFFE5EDE6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Final Reflection',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'In your own words, how are you feeling right now? This helps add context to your answers.',
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _controller,
                            maxLines: 7,
                            decoration: InputDecoration(
                              hintText:
                                  'Example: I am feeling overwhelmed lately and sleeping poorly...',
                              filled: true,
                              fillColor: const Color(0xFFF9FBF9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0B6E4F),
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You can also skip this step.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          if (state.submitError != null)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4E5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                state.submitError!,
                                style: const TextStyle(
                                  color: Color(0xFF7A5206),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () {
                                          notifier.submitWithText(
                                            _controller.text.trim(),
                                          );
                                        },
                                  child: state.isSubmitting
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                          ),
                                        )
                                      : const Text('Finish and Save'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              TextButton(
                                onPressed: state.isSubmitting
                                    ? null
                                    : () {
                                        notifier.submitWithText('');
                                      },
                                child: const Text('Skip'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
