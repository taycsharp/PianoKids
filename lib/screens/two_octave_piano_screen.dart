import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_service.dart';
import '../widgets/two_octave_keyboard.dart';

enum _PianoMode { freePlay, demo, practice }

class _DemoNoteEvent {
  final String note;
  final bool isRightHand;
  final Duration duration;

  const _DemoNoteEvent({
    required this.note,
    required this.isRightHand,
    required this.duration,
  });
}

class TwoOctavePianoScreen extends StatefulWidget {
  const TwoOctavePianoScreen({super.key});

  @override
  State<TwoOctavePianoScreen> createState() => _TwoOctavePianoScreenState();
}

class _TwoOctavePianoScreenState extends State<TwoOctavePianoScreen> {
  static const List<_DemoNoteEvent> _twinkleDemo = [
    _DemoNoteEvent(note: 'C4', isRightHand: true, duration: Duration(milliseconds: 450)),
    _DemoNoteEvent(note: 'C4', isRightHand: false, duration: Duration(milliseconds: 450)),
    _DemoNoteEvent(note: 'G4', isRightHand: true, duration: Duration(milliseconds: 450)),
    _DemoNoteEvent(note: 'C3', isRightHand: false, duration: Duration(milliseconds: 450)),
    _DemoNoteEvent(note: 'A4', isRightHand: true, duration: Duration(milliseconds: 450)),
    _DemoNoteEvent(note: 'C3', isRightHand: false, duration: Duration(milliseconds: 450)),
    _DemoNoteEvent(note: 'G4', isRightHand: true, duration: Duration(milliseconds: 650)),
    _DemoNoteEvent(note: 'G3', isRightHand: false, duration: Duration(milliseconds: 500)),
    _DemoNoteEvent(note: 'F4', isRightHand: true, duration: Duration(milliseconds: 450)),
    _DemoNoteEvent(note: 'F3', isRightHand: false, duration: Duration(milliseconds: 450)),
    _DemoNoteEvent(note: 'E4', isRightHand: true, duration: Duration(milliseconds: 450)),
    _DemoNoteEvent(note: 'F3', isRightHand: false, duration: Duration(milliseconds: 450)),
    _DemoNoteEvent(note: 'D4', isRightHand: true, duration: Duration(milliseconds: 450)),
    _DemoNoteEvent(note: 'C3', isRightHand: false, duration: Duration(milliseconds: 450)),
    _DemoNoteEvent(note: 'C4', isRightHand: true, duration: Duration(milliseconds: 650)),
    _DemoNoteEvent(note: 'G3', isRightHand: false, duration: Duration(milliseconds: 550)),
  ];

  final Map<int, String> _activePresses = {};
  final ValueNotifier<Set<String>> _pressedNotes = ValueNotifier(const {});
  final ValueNotifier<Set<String>> _demoRightNotes = ValueNotifier(const {});
  final ValueNotifier<Set<String>> _demoLeftNotes = ValueNotifier(const {});

  _PianoMode _mode = _PianoMode.freePlay;
  bool _isDemoPlaying = false;
  double _demoProgress = 0;
  int _demoRunId = 0;
  int _demoPressSeed = -1000;

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

  Future<void> _selectMode(_PianoMode mode) async {
    if (_mode == mode && mode != _PianoMode.demo) return;
    setState(() => _mode = mode);
    if (mode == _PianoMode.demo) {
      await _startDemo();
    } else {
      _stopDemo(resetMode: false);
    }
  }

  Future<void> _startDemo() async {
    _stopDemo(resetMode: false);
    final runId = ++_demoRunId;
    if (mounted) {
      setState(() {
        _isDemoPlaying = true;
        _demoProgress = 0;
      });
    }

    for (var i = 0; i < _twinkleDemo.length; i++) {
      if (!mounted || runId != _demoRunId || !_isDemoPlaying) break;
      final event = _twinkleDemo[i];
      final pressId = _demoPressSeed--;

      final right = Set<String>.of(_demoRightNotes.value);
      final left = Set<String>.of(_demoLeftNotes.value);
      if (event.isRightHand) {
        right.add(event.note);
      } else {
        left.add(event.note);
      }
      _demoRightNotes.value = Set<String>.unmodifiable(right);
      _demoLeftNotes.value = Set<String>.unmodifiable(left);
      _startNote(event.note, pressId);

      await Future<void>.delayed(event.duration);

      _stopNote(event.note, pressId);
      final rightAfter = Set<String>.of(_demoRightNotes.value)..remove(event.note);
      final leftAfter = Set<String>.of(_demoLeftNotes.value)..remove(event.note);
      _demoRightNotes.value = Set<String>.unmodifiable(rightAfter);
      _demoLeftNotes.value = Set<String>.unmodifiable(leftAfter);

      if (mounted && runId == _demoRunId) {
        setState(() {
          _demoProgress = (i + 1) / _twinkleDemo.length;
        });
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    if (mounted && runId == _demoRunId) {
      setState(() {
        _isDemoPlaying = false;
      });
    }
    _clearDemoHighlights();
  }

  void _clearDemoHighlights() {
    _demoRightNotes.value = const {};
    _demoLeftNotes.value = const {};
  }

  void _stopDemo({bool resetMode = false}) {
    _demoRunId++;
    _isDemoPlaying = false;
    _clearDemoHighlights();
    if (resetMode && mounted) {
      setState(() => _mode = _PianoMode.freePlay);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _stopDemo();
    _pressedNotes.dispose();
    _demoRightNotes.dispose();
    _demoLeftNotes.dispose();
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
              padding: EdgeInsets.fromLTRB(horizontalPadding, topPadding, horizontalPadding, bottomPadding),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 22,
                        splashRadius: 20,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [Icon(Icons.music_note_rounded, size: 16), SizedBox(width: 4), Text('Twinkle Twinkle')],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: SegmentedButton<_PianoMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: _PianoMode.freePlay, label: Text('Free Play')),
                          ButtonSegment(value: _PianoMode.demo, label: Text('Demo')),
                          ButtonSegment(value: _PianoMode.practice, label: Text('Practice')),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (values) => _selectMode(values.first),
                      )),
                    ],
                  ),
                  if (_mode == _PianoMode.demo) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFF2F5FF), borderRadius: BorderRadius.circular(14)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_isDemoPlaying ? 'Demo Playing…' : 'Demo ready', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text('Listen and watch the keys', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: _demoProgress),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(onPressed: _isDemoPlaying ? _stopDemo : _startDemo, child: Text(_isDemoPlaying ? 'Stop' : 'Play')),
                        ),
                      ]),
                    ),
                  ],
                  if (_mode == _PianoMode.practice) ...[
                    const SizedBox(height: 6),
                    const Text('Practice mode coming next', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 6),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: audio.keyboardCacheReadyListenable,
                      builder: (context, isKeyboardReady, child) {
                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: isKeyboardReady ? 1 : 0.55,
                          child: TwoOctaveKeyboard(
                            highlightedNotesListenable: _pressedNotes,
                            rightHandHighlightedNotesListenable: _demoRightNotes,
                            leftHandHighlightedNotesListenable: _demoLeftNotes,
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
