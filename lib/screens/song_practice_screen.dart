import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/progress_provider.dart';
import '../services/audio_service.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/star_reward.dart';

class SongPracticeScreen extends StatefulWidget {
  final Song song;

  const SongPracticeScreen({super.key, required this.song});

  @override
  State<SongPracticeScreen> createState() => _SongPracticeScreenState();
}

class _SongPracticeScreenState extends State<SongPracticeScreen> {
  int _currentIndex = 0;
  int _mistakes = 0;
  String _message = 'Start the song!';
  final Set<String> _pressedNotes = {};

  bool get _finished => _currentIndex >= widget.song.notes.length;

  String get _currentNote => _finished ? widget.song.notes.last : widget.song.notes[_currentIndex];

  Future<void> _onNoteStarted(String note, int pressId) async {
    final audio = context.read<AudioService>();
    final progressProvider = context.read<ProgressProvider>();

    setState(() => _pressedNotes.add(note));
    await audio.startNoteForPress(note: note, pressId: pressId);

    if (_finished) return;

    if (note == _currentNote) {
      if (_currentIndex == widget.song.notes.length - 1) {
        await progressProvider.completeSong(widget.song.id);
        await audio.playSuccess();
        if (!mounted) return;
        setState(() {
          _currentIndex++;
          _message = 'You finished the song!';
        });
      } else {
        setState(() {
          _currentIndex++;
          _message = 'Great! Next note: ${widget.song.notes[_currentIndex]}';
        });
      }
    } else {
      setState(() {
        _mistakes++;
        _message = 'Almost! Try $_currentNote';
      });
    }
  }

  Future<void> _onNoteStopped(String note, int pressId) async {
    setState(() => _pressedNotes.remove(note));
    await context.read<AudioService>().stopNoteForPress(pressId);
  }

  @override
  Widget build(BuildContext context) {
    final visibleNotes = widget.song.notes.asMap().entries.map((entry) {
      final isCurrent = entry.key == _currentIndex;
      final isDone = entry.key < _currentIndex;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrent ? Colors.amber : isDone ? Colors.green.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(entry.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.song.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(_finished ? 'Congratulations! 🎉' : 'Tap: $_currentNote', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(_message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(alignment: WrapAlignment.center, children: visibleNotes),
            const SizedBox(height: 18),
            PianoKeyboard(
              showNoteNames: true,
              highlightedNotes: _pressedNotes,
              onKeyPressStarted: _onNoteStarted,
              onKeyPressStopped: _onNoteStopped,
            ),
            const SizedBox(height: 18),
            if (_finished)
              StarReward(
                stars: _mistakes == 0 ? 3 : _mistakes <= 3 ? 2 : 1,
                message: 'Song complete!',
              ),
          ],
        ),
      ),
    );
  }
}
