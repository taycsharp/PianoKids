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

enum _PitchBand { low, high }

class _EarTrainingScreenState extends State<EarTrainingScreen> {
  static const List<String> _lowNotes = ['C', 'D', 'E', 'F', 'G'];
  static const List<String> _highNotes = ['A', 'B', 'High C'];

  String _currentNote = 'C';
  _PitchBand _currentBand = _PitchBand.low;
  String _message = 'Listen and choose!';
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final band = Random().nextBool() ? _PitchBand.low : _PitchBand.high;
    final notes = band == _PitchBand.low ? _lowNotes : _highNotes;
    _currentBand = band;
    _currentNote = notes[Random().nextInt(notes.length)];
    _message = 'Listen and choose!';
  }

  Future<void> _playQuestion() async {
    await context.read<AudioService>().playPianoNote(
      _currentNote,
      duration: const Duration(milliseconds: 700),
    );
  }

  Future<void> _choose(_PitchBand guess) async {
    if (guess == _currentBand) {
      await context.read<AudioService>().playSuccess();
      setState(() {
        _score++;
        _message = 'Great listening!';
      });
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(_newRound);
      }
      return;
    }

    setState(() => _message = 'Good try! Listen again.');
    await _playQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ear Training'),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: audio.keyboardCacheReadyListenable,
          builder: (context, isAudioReady, child) {
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  StarReward(stars: min(_score, 3), message: _message),
                  const SizedBox(height: 8),
                  Text(
                    'Score: $_score',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF34344A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!isAudioReady) ...[
                    const _LoadingPianoSoundsBanner(),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 74,
                    child: FilledButton.icon(
                      onPressed: _playQuestion,
                      icon: const Icon(Icons.volume_up, size: 32),
                      label: const Text(
                        'Play Sound',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: FilledButton(
                      onPressed: () => _choose(_PitchBand.low),
                      child: const Text(
                        'Low Sound',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: OutlinedButton(
                      onPressed: () => _choose(_PitchBand.high),
                      child: const Text(
                        'High Sound',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                      ),
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
