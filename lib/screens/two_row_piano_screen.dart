import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../widgets/piano_keyboard.dart';

class TwoRowPianoScreen extends StatefulWidget {
  const TwoRowPianoScreen({super.key});

  @override
  State<TwoRowPianoScreen> createState() => _TwoRowPianoScreenState();
}

class _TwoRowPianoScreenState extends State<TwoRowPianoScreen> {
  final Map<int, String> _activePresses = {};
  final ValueNotifier<Set<String>> _pressedNotes = ValueNotifier(const {});

  void _startNote(String note, int pressId) {
    context.read<AudioService>().startKeyboardNoteForPress(note, pressId);
    _activePresses[pressId] = note;
    _pressedNotes.value = Set<String>.unmodifiable(_activePresses.values);
  }

  void _stopNote(String note, int pressId) {
    context.read<AudioService>().stopKeyboardNoteForPress(pressId);
    _activePresses.remove(pressId);
    _pressedNotes.value = Set<String>.unmodifiable(_activePresses.values);
  }

  @override
  void dispose() {
    _pressedNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Two Octave Piano')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final keyboardHeight = (constraints.maxHeight - 20)
                .clamp(220.0, constraints.maxHeight)
                .toDouble();

            return Padding(
              padding: const EdgeInsets.all(10),
              child: ValueListenableBuilder<bool>(
                valueListenable: audio.keyboardCacheReadyListenable,
                builder: (context, isReady, child) {
                  return RepaintBoundary(
                    child: AbsorbPointer(
                      absorbing: !isReady,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: isReady ? 1 : 0.55,
                        child: PianoKeyboard(
                          twoRowLayout: true,
                          height: keyboardHeight,
                          showNoteNames: false,
                          highlightedNotesListenable: _pressedNotes,
                          onKeyPressStarted: _startNote,
                          onKeyPressStopped: _stopNote,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
