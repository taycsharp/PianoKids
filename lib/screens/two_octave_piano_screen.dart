import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../widgets/two_octave_keyboard.dart';

class TwoOctavePianoScreen extends StatefulWidget {
  const TwoOctavePianoScreen({super.key});

  @override
  State<TwoOctavePianoScreen> createState() => _TwoOctavePianoScreenState();
}

class _TwoOctavePianoScreenState extends State<TwoOctavePianoScreen> {
  final Map<int, String> _activePresses = {};
  final ValueNotifier<Set<String>> _pressedNotes = ValueNotifier(const {});

  void _startNote(String note, int pressId) {
    context.read<AudioService>().startKeyboardNoteForPress(note, pressId);
    _activePresses[pressId] = note;
    _pressedNotes.value = Set<String>.unmodifiable(_activePresses.values);
  }

  void _stopNote(String note, int pressId) {
    unawaited(context.read<AudioService>().stopKeyboardNoteForPress(pressId));
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
            final padding = constraints.maxHeight < 500 ? 10.0 : 16.0;
            return Padding(
              padding: EdgeInsets.all(padding),
              child: ValueListenableBuilder<bool>(
                valueListenable: audio.keyboardCacheReadyListenable,
                builder: (context, isKeyboardReady, child) {
                  return AbsorbPointer(
                    absorbing: !isKeyboardReady,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: isKeyboardReady ? 1 : 0.55,
                      child: TwoOctaveKeyboard(
                        highlightedNotesListenable: _pressedNotes,
                        onKeyPressStarted: _startNote,
                        onKeyPressStopped: _stopNote,
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
