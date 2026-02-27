import 'package:flutter/material.dart';

class LikertScale extends StatelessWidget {
  final Function(int) onSelected;

  const LikertScale({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        int value = index + 1;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ElevatedButton(
            onPressed: () => onSelected(value),
            child: Text(value.toString()),
          ),
        );
      }),
    );
  }
}