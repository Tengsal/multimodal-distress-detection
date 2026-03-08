import 'package:flutter/material.dart';

const _labels = [
  "Not at all",
  "Rarely",
  "Sometimes",
  "Often",
  "Very often",
];

const _gradientColors = [
  Color(0xFF4CAF50), // 1 - green
  Color(0xFF8BC34A), // 2 - light green
  Color(0xFFFFC107), // 3 - amber
  Color(0xFFFF7043), // 4 - orange
  Color(0xFFE53935), // 5 - red
];

class LikertScale extends StatefulWidget {
  final Function(int) onSelected;

  const LikertScale({super.key, required this.onSelected});

  @override
  State<LikertScale> createState() => _LikertScaleState();
}

class _LikertScaleState extends State<LikertScale> {
  int? _selected;

  void _select(int value) {
    setState(() => _selected = value);
    // Small delay to show the selection animation before navigating
    Future.delayed(const Duration(milliseconds: 180), () {
      widget.onSelected(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Horizontal 5-button scale ──────────────────────
        Row(
          children: List.generate(5, (i) {
            final value = i + 1;
            final isSelected = _selected == value;
            final color = _gradientColors[i];

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => _select(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    height: isSelected ? 72 : 60,
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : color.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        "$value",
                        style: TextStyle(
                          fontSize: isSelected ? 22 : 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 10),

        // ── Labels row ─────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _labels[0],
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _labels[4],
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // ── Selected label ─────────────────────────────────
        if (_selected != null) ...[
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Container(
              key: ValueKey(_selected),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _gradientColors[_selected! - 1].withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _labels[_selected! - 1],
                style: TextStyle(
                  color: _gradientColors[_selected! - 1],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}