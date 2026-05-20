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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 700 ? 8.0 : 12.0;
            final topPadding = constraints.maxHeight < 420 ? 4.0 : 6.0;
            final bottomPadding = constraints.maxHeight < 420 ? 4.0 : 8.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                bottomPadding,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 22,
                      splashRadius: 20,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: audio.keyboardCacheReadyListenable,
                      builder: (context, isKeyboardReady, child) {
                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: isKeyboardReady ? 1 : 0.55,
                          child: TwoOctaveKeyboard(
                            highlightedNotesListenable: _pressedNotes,
                            onKeyPressStarted: _startNote,
                            onKeyPressStopped: _stopNote,
                          ),
                        );
                      },
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
