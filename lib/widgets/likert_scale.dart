import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LikertScale extends StatelessWidget {
  const LikertScale({
    super.key,
    required this.onSelected,
    this.enabled = true,
  });

  final ValueChanged<int> onSelected;
  final bool enabled;

  static const List<(int, String, IconData)> _options = [
    (1, 'Not at all', Icons.sentiment_very_satisfied_rounded),
    (2, 'A little', Icons.sentiment_satisfied_rounded),
    (3, 'Sometimes', Icons.sentiment_neutral_rounded),
    (4, 'Mostly', Icons.sentiment_dissatisfied_rounded),
    (5, 'Always', Icons.sentiment_very_dissatisfied_rounded),
  ];

  static const List<Color> _badgeColors = [
    Color(0xFF34D399), // emerald
    Color(0xFF60A5FA), // blue
    Color(0xFFFBBF24), // amber
    Color(0xFFF97316), // orange
    Color(0xFFEF4444), // red
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final value = option.$1;
        final label = option.$2;
        final icon = option.$3;
        final color = _badgeColors[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LikertOption(
            value: value,
            label: label,
            icon: icon,
            color: color,
            enabled: enabled,
            onTap: () => onSelected(value),
          ),
        );
      }).toList(),
    );
  }
}

class _LikertOption extends StatefulWidget {
  const _LikertOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_LikertOption> createState() => _LikertOptionState();
}

class _LikertOptionState extends State<_LikertOption>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(_) {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed
                  ? widget.color.withValues(alpha: 0.5)
                  : const Color(0xFFF3F4F6),
              width: 1.5,
            ),
            color: _isPressed
                ? widget.color.withValues(alpha: 0.04)
                : Colors.white,
          ),
          child: Row(
            children: [
              // Gradient number badge
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.15),
                      widget.color.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.value.toString(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: widget.color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Label
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              // Icon
              Icon(
                widget.icon,
                color: widget.color.withValues(alpha: 0.6),
                size: 22,
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFE5E7EB),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
