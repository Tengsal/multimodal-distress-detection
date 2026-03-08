import 'package:flutter/material.dart';

class LikertScale extends StatelessWidget {
  const LikertScale({
    super.key,
    required this.onSelected,
    this.enabled = true,
  });

  final ValueChanged<int> onSelected;
  final bool enabled;

  static const List<(int, String)> _options = [
    (1, 'Not at all'),
    (2, 'A little'),
    (3, 'Sometimes'),
    (4, 'Mostly'),
    (5, 'Always'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _options.map((option) {
        final value = option.$1;
        final label = option.$2;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: enabled ? () => onSelected(value) : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFD1D5DB),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
