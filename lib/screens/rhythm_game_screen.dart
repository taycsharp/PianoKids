import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/progress_provider.dart';
import '../services/audio_service.dart';
import '../widgets/star_reward.dart';

class RhythmGameScreen extends StatefulWidget {
  const RhythmGameScreen({super.key});

  @override
  State<RhythmGameScreen> createState() => _RhythmGameScreenState();
}

class _RhythmGameScreenState extends State<RhythmGameScreen> {
  final List<List<int>> _patterns = const [
    [1, 1, 1],
    [1, 2, 1],
    [1, 1, 2],
  ];
  int _patternIndex = 0;
  int _tapCount = 0;
  String _message = 'Tap with the beat!';
  bool _showReward = false;

  List<int> get _pattern => _patterns[_patternIndex];

  Future<void> _tap() async {
    final audio = context.read<AudioService>();
    final progressProvider = context.read<ProgressProvider>();

    await audio.playTap();
    if (!mounted) return;

    setState(() {
      _tapCount++;
      _showReward = false;
    });

    final targetTaps = _pattern.fold<int>(0, (sum, value) => sum + value);
    if (_tapCount >= targetTaps) {
      final score = min(3, _patternIndex + 1);
      await progressProvider.updateRhythmScore(score);
      if (!mounted) return;
      setState(() {
        _message = score >= 3 ? 'Great rhythm!' : 'Good tapping!';
        _showReward = true;
        _tapCount = 0;
        _patternIndex = (_patternIndex + 1) % _patterns.length;
      });
    } else {
      setState(() => _message = 'Good! Keep tapping!');
    }
  }

  String _patternText() {
    return _pattern.map((count) => count == 1 ? 'Tap' : 'Tap Tap').join(' — ');
  }

  @override
  Widget build(BuildContext context) {
    final best = context.watch<ProgressProvider>().bestRhythmScore;
    final audio = context.read<AudioService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Rhythm Game')),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: audio.keyboardCacheReadyListenable,
          builder: (context, isAudioReady, child) {
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
              Text('Best score: $best ⭐', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 8))],
                ),
                child: Column(
                  children: [
                    const Text('Pattern', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(_patternText(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(_message, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              const Spacer(),
              if (_showReward) const StarReward(stars: 3, message: 'Rhythm Star!'),
              const Spacer(),
              if (!isAudioReady) ...[
                const _LoadingPianoSoundsBanner(),
                const SizedBox(height: 14),
              ],
              SizedBox(
                width: 210,
                height: 210,
                child: FilledButton(
                  onPressed: isAudioReady ? _tap : null,
                  style: FilledButton.styleFrom(shape: const CircleBorder()),
                  child: const Text('TAP', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
                ),
              ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingPianoSoundsBanner extends StatelessWidget {
  const _LoadingPianoSoundsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3B0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading piano sounds…',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
