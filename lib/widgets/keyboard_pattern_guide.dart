import 'package:flutter/material.dart';

/// Small visual guide for teaching how white notes relate to black-key groups.
class KeyboardPatternGuide extends StatelessWidget {
  final String title;
  final String message;

  const KeyboardPatternGuide({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3B0), Color(0xFFFFD6E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎹', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.25),
          ),
          const SizedBox(height: 14),
          const _MiniKeyboardPattern(),
        ],
      ),
    );
  }
}

class _MiniKeyboardPattern extends StatelessWidget {
  const _MiniKeyboardPattern();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final keyWidth = constraints.maxWidth / 8;
          final blackWidth = keyWidth * 0.5;
          const blackPositions = [1.0, 2.0, 4.0, 5.0, 6.0];
          const labels = ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C'];

          return Stack(
            children: [
              Row(
                children: [
                  for (final label in labels)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.15)),
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
              for (final position in blackPositions)
                Positioned(
                  left: position * keyWidth - blackWidth / 2,
                  top: 0,
                  width: blackWidth,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF151521),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
