import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/star_reward.dart';

class PianoScreen extends StatefulWidget {
  const PianoScreen({super.key});

  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen> {
  bool _showNames = true;
  bool _funMode = true;
  final Set<String> _pressedNotes = {};
  String _message = 'Play any note!';
  final List<String> _sequence = [];
  final List<String> _rewardSequence = ['C', 'D', 'E'];

  Future<void> _startNote(String note) async {
    setState(() {
      _pressedNotes.add(note);
      _message = 'You played $note!';
    });

    final audio = context.read<AudioService>();
    await audio.startNote(note);

    if (_funMode) {
      _sequence.add(note);
      if (_sequence.length > _rewardSequence.length) _sequence.removeAt(0);
      if (_sequence.join(',') == _rewardSequence.join(',')) {
        await audio.playAnimalReward();
        if (mounted) setState(() => _message = 'Animal reward! 🐶 ⭐');
      }
    }
  }

  Future<void> _stopNote(String note) async {
    setState(() => _pressedNotes.remove(note));
    await context.read<AudioService>().stopNote(note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Piano'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            StarReward(stars: 1, message: _message),
            const SizedBox(height: 18),
            SwitchListTile(
              value: _showNames,
              onChanged: (value) => setState(() => _showNames = value),
              title: const Text('Show note names', style: TextStyle(fontWeight: FontWeight.w800)),
              secondary: const Icon(Icons.abc),
            ),
            SwitchListTile(
              value: _funMode,
              onChanged: (value) => setState(() => _funMode = value),
              title: const Text('Fun reward mode', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Try C-D-E, then C♯-D♯!'),
              secondary: const Icon(Icons.pets),
            ),
            const SizedBox(height: 12),
            PianoKeyboard(
              showNoteNames: _showNames,
              highlightedNotes: _pressedNotes,
              onNoteStarted: _startNote,
              onNoteStopped: _stopNote,
            ),
          ],
        ),
      ),
    );
  }
}
