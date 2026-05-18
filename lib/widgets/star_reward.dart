import 'package:flutter/material.dart';

class StarReward extends StatefulWidget {
  final int stars;
  final String message;

  const StarReward({
    super.key,
    required this.stars,
    this.message = 'Great job!',
  });

  @override
  State<StarReward> createState() => _StarRewardState();
}

class _StarRewardState extends State<StarReward> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant StarReward oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message || oldWidget.stars != widget.stars) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.message, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(List.filled(widget.stars, '⭐').join(' '), style: const TextStyle(fontSize: 30)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
