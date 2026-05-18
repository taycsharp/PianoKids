import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../widgets/star_reward.dart';

class EarTrainingScreen extends StatefulWidget {
  const EarTrainingScreen({super.key});

  @override
  State<EarTrainingScreen> createState() => _EarTrainingScreenState();
}

class _EarTrainingScreenState extends State<EarTrainingScreen> {
  final List<String> _choices = ['C', 'D', 'E'];
  String _currentNote = 'C';
  String _message = 'Listen and choose!';
  int _correct = 0;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _currentNote = _choices[Random().nextInt(_choices.length)];
    _message = 'Listen and choose!';
  }

  Future<void> _playQuestion() async {
    await context.read<AudioService>().playNote(_currentNote);
  }

  Future<void> _choose(String note) async {
    if (note == _currentNote) {
      await context.read<AudioService>().playSuccess();
      setState(() {
        _correct++;
        _message = 'Great ears! It was $note!';
      });
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(_newRound);
    } else {
      setState(() => _message = 'Almost! Listen one more time.');
      await _playQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ear Training'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              StarReward(stars: min(_correct, 3), message: _message),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 74,
                child: FilledButton.icon(
                  onPressed: _playQuestion,
                  icon: const Icon(Icons.volume_up, size: 32),
                  label: const Text('Play Note', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 28),
              for (final note in _choices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 68,
                    child: OutlinedButton(
                      onPressed: () => _choose(note),
                      child: Text(note, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
