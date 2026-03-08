import 'package:flutter/material.dart';
import 'interview_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6), // Smooth light gray
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.spa_outlined,
                      color: Color(0xFF111827),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Mental Health\nCheck-In.',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A short, adaptive screening to understand how you have been feeling recently. Designed for clarity and ease.',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 48),
                  _buildListItem(
                    Icons.speed_rounded,
                    'Adaptive flow',
                    'Typically 20-30 brief prompts.',
                  ),
                  const SizedBox(height: 24),
                  _buildListItem(
                    Icons.edit_note_rounded,
                    'Optional notes',
                    'Add a free-text reflection at the end.',
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Subtle exit before navigation
                        _controller.reverse().then((_) {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  const InterviewScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                            ),
                          );
                        });
                      },
                      child: const Text('Start Screening'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: const Color(0xFF6B7280)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
