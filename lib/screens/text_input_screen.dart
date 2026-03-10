import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/fsm_provider.dart';

class TextInputScreen extends ConsumerStatefulWidget {
  const TextInputScreen({super.key});

  @override
  ConsumerState<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends ConsumerState<TextInputScreen> {
  final TextEditingController _controller = TextEditingController();
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateWordCount);
  }

  void _updateWordCount() {
    final text = _controller.text.trim();
    setState(() {
      _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateWordCount);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fsmProvider);
    final notifier = ref.read(fsmProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
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
                    child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Final Reflection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  if (_wordCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$_wordCount words',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── Body ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24, 28, 24,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF818CF8).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.format_quote_rounded,
                        size: 32,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'In your own words,\nhow are you feeling\nright now?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        height: 1.3,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This helps add context to your answers. You can also skip this step.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF9CA3AF),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Text field
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
                        controller: _controller,
                        maxLines: 6,
                        cursorColor: const Color(0xFF6366F1),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF111827),
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: 'I\'ve been feeling overwhelmed lately and sleeping poorly...',
                          hintStyle: const TextStyle(
                            color: Color(0xFFD1D5DB),
                            fontSize: 15,
                          ),
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
                            borderSide: const BorderSide(
                              color: Color(0xFF818CF8),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Error banner
                    if (state.submitError != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.submitError!,
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    notifier.submitWithText(_controller.text.trim());
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF111827),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFD1D5DB),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: state.isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Finish & Save',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    notifier.submitWithText('');
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF9CA3AF),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                                side: const BorderSide(color: Color(0xFFF3F4F6)),
                              ),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
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
}
