import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/two_octave_demo_songs.dart';
import '../services/audio_service.dart';
import '../widgets/two_octave_keyboard.dart';

enum _PianoMode { freePlay, demo, practice }

class TwoOctavePianoScreen extends StatefulWidget {
  const TwoOctavePianoScreen({super.key});

  @override
  State<TwoOctavePianoScreen> createState() => _TwoOctavePianoScreenState();
}

class _TwoOctavePianoScreenState extends State<TwoOctavePianoScreen> {
  static final Map<String, DemoSong> _songsById = {
    for (final song in twoOctaveDemoSongs) song.id: song,
  };

  final Map<int, String> _activePresses = {};
  final ValueNotifier<Set<String>> _pressedNotes = ValueNotifier(const {});
  final ValueNotifier<Set<String>> _demoRightNotes = ValueNotifier(const {});
  final ValueNotifier<Set<String>> _demoLeftNotes = ValueNotifier(const {});
  final ValueNotifier<Set<String>> _practiceTargetNotes = ValueNotifier(const {});

  _PianoMode _mode = _PianoMode.freePlay;
  String _selectedSongId = twoOctaveDemoSongs.first.id;
  bool _isDemoPlaying = false;
  bool _isPracticeComplete = false;
  double _demoProgress = 0;
  int _practiceIndex = 0;
  String _practiceFeedback = 'Tap the glowing key';
  int _demoRunId = 0;
  int _demoPressSeed = -1000;
  final Set<Timer> _demoTimers = <Timer>{};

  DemoSong get _selectedSong => _songsById[_selectedSongId] ?? twoOctaveDemoSongs.first;

  List<DemoNoteEvent> get _selectedDemo => _selectedSong.events;

  Duration get _demoTotalDuration => _selectedDemo.fold(
    Duration.zero,
    (sum, event) => sum + event.duration + const Duration(milliseconds: 50),
  );

  Duration get _demoElapsedDuration =>
      _demoTotalDuration * _demoProgress.clamp(0, 1);

  List<String> get _practiceMelody =>
      _selectedDemo.where((event) => event.isRightHand).map((event) => event.note).toList(growable: false);

  void _startNote(String note, int pressId) {
    context.read<AudioService>().startKeyboardNoteForPress(note, pressId);
    _activePresses[pressId] = note;
    _pressedNotes.value = Set<String>.unmodifiable(_activePresses.values);
    if (_mode == _PianoMode.practice && pressId >= 0) {
      _handlePracticeInput(note);
    }
  }

  void _stopNote(String note, int pressId) {
    unawaited(context.read<AudioService>().stopKeyboardNoteForPress(pressId));
    _activePresses.remove(pressId);
    _pressedNotes.value = Set<String>.unmodifiable(_activePresses.values);
  }

  Future<void> _selectMode(_PianoMode mode) async {
    if (_mode == mode && mode != _PianoMode.demo) return;
    if (mounted) {
      setState(() => _mode = mode);
    }
    if (mode == _PianoMode.demo) {
      _resetPractice(updateUi: false);
      await _startDemo();
    } else if (mode == _PianoMode.practice) {
      _stopDemo();
      _startPractice();
    } else {
      _stopDemo();
      _resetPractice();
    }
  }

  void _startPractice() {
    _practiceIndex = 0;
    _isPracticeComplete = _practiceMelody.isEmpty;
    _practiceFeedback = _isPracticeComplete ? 'Great job! Song complete!' : 'Tap the glowing key';
    _practiceTargetNotes.value = _isPracticeComplete ? const {} : {_practiceMelody.first};
    if (mounted) {
      setState(() {});
    }
  }

  void _resetPractice({bool updateUi = true}) {
    _practiceIndex = 0;
    _isPracticeComplete = false;
    _practiceFeedback = 'Tap the glowing key';
    _practiceTargetNotes.value = const {};
    if (updateUi && mounted) {
      setState(() {});
    }
  }

  void _handlePracticeInput(String note) {
    if (_isPracticeComplete || _practiceMelody.isEmpty) return;
    final target = _practiceMelody[_practiceIndex];
    if (note != target) {
      setState(() => _practiceFeedback = 'Try again');
      return;
    }
    final nextIndex = _practiceIndex + 1;
    if (nextIndex >= _practiceMelody.length) {
      setState(() {
        _practiceIndex = nextIndex;
        _isPracticeComplete = true;
        _practiceFeedback = 'Great job! Song complete!';
      });
      _practiceTargetNotes.value = const {};
      return;
    }
    setState(() {
      _practiceIndex = nextIndex;
      _practiceFeedback = 'Great!';
    });
    _practiceTargetNotes.value = {_practiceMelody[nextIndex]};
  }

  Future<void> _waitForDemo(Duration delay, int runId) {
    final completer = Completer<void>();
    if (!_isDemoPlaying || runId != _demoRunId) {
      completer.complete();
      return completer.future;
    }

    late final Timer timer;
    timer = Timer(delay, () {
      _demoTimers.remove(timer);
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    _demoTimers.add(timer);
    return completer.future;
  }

  void _cancelDemoTimers() {
    for (final timer in _demoTimers) {
      timer.cancel();
    }
    _demoTimers.clear();
  }

  Future<void> _startDemo() async {
    _stopDemo(updateUi: false);
    final runId = ++_demoRunId;
    if (mounted) {
      setState(() {
        _isDemoPlaying = true;
        _demoProgress = 0;
      });
    }

    final currentSong = _selectedDemo;
    for (var i = 0; i < currentSong.length; i++) {
      if (!mounted || runId != _demoRunId || !_isDemoPlaying) break;
      final event = currentSong[i];
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

      await _waitForDemo(event.duration, runId);
      if (!mounted || runId != _demoRunId || !_isDemoPlaying) {
        _stopNote(event.note, pressId);
        break;
      }

      _stopNote(event.note, pressId);
      final rightAfter = Set<String>.of(_demoRightNotes.value)..remove(event.note);
      final leftAfter = Set<String>.of(_demoLeftNotes.value)..remove(event.note);
      _demoRightNotes.value = Set<String>.unmodifiable(rightAfter);
      _demoLeftNotes.value = Set<String>.unmodifiable(leftAfter);

      if (mounted && runId == _demoRunId && _isDemoPlaying) {
        setState(() {
          _demoProgress = (i + 1) / currentSong.length;
        });
      }

      await _waitForDemo(const Duration(milliseconds: 50), runId);
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

  void _stopDemo({bool updateUi = true}) {
    _demoRunId++;
    _isDemoPlaying = false;
    _demoProgress = 0;
    _cancelDemoTimers();
    _clearDemoHighlights();
    if (updateUi && mounted) {
      setState(() {});
    }
  }

  void _selectSong(String songId) {
    if (_selectedSongId == songId) {
      return;
    }
    _stopDemo(updateUi: false);
    if (!mounted) return;
    setState(() {
      _selectedSongId = songId;
    });
    if (_mode == _PianoMode.practice) {
      _startPractice();
    }
  }


  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  }

  @override
  void dispose() {
    _stopDemo(updateUi: false);
    _pressedNotes.dispose();
    _demoRightNotes.dispose();
    _demoLeftNotes.dispose();
    _practiceTargetNotes.dispose();
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioService>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            if (!isLandscape) {
              return const _RotateToLandscapePrompt();
            }

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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            key: const ValueKey<String>('demo-song-selector'),
                            value: _selectedSongId,
                            isDense: true,
                            borderRadius: BorderRadius.circular(12),
                            icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
                            items: twoOctaveDemoSongs
                                .map((song) => DropdownMenuItem<String>(value: song.id, child: Text(song.name, overflow: TextOverflow.ellipsis)))
                                .toList(growable: false),
                            onChanged: (song) {
                              if (song == null) return;
                              _selectSong(song);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 'free', label: Text('Free Play')),
                            ButtonSegment(value: 'demo', label: Text('Demo')),
                            ButtonSegment(value: 'practice', label: Text('Practice')),
                          ],
                          selected: {
                            _mode == _PianoMode.demo
                                ? 'demo'
                                : _mode == _PianoMode.practice
                                    ? 'practice'
                                    : 'free',
                          },
                          onSelectionChanged: (values) {
                            final value = values.first;
                            if (value == 'demo') {
                              unawaited(_selectMode(_PianoMode.demo));
                            } else if (value == 'practice') {
                              unawaited(_selectMode(_PianoMode.practice));
                            } else {
                              unawaited(_selectMode(_PianoMode.freePlay));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_mode == _PianoMode.demo) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFF2F5FF), borderRadius: BorderRadius.circular(14)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(
                          children: [
                            const Icon(Icons.music_note_rounded, color: Color(0xFF7E57F6)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_isDemoPlaying ? 'Demo Playing...' : 'Demo ready', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 2),
                                  const Text('Listen and watch the keys', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(colors: [Color(0xFFFF8A80), Color(0xFFFF5252)]),
                              ),
                              child: TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                                onPressed: _isDemoPlaying ? _stopDemo : _startDemo,
                                icon: Icon(_isDemoPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 16),
                                label: Text(_isDemoPlaying ? 'Stop' : 'Play'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: LinearProgressIndicator(value: _demoProgress, color: const Color(0xFF7E57F6), minHeight: 6, borderRadius: BorderRadius.circular(999))),
                            const SizedBox(width: 8),
                            Text('${_formatDuration(_demoElapsedDuration)} / ${_formatDuration(_demoTotalDuration)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ]),
                    ),
                  ],
                  if (_mode == _PianoMode.demo) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Expanded(child: _HandHint(dotColor: Color(0xFFA16DFF), title: 'Left Hand (Bass)', subtitle: 'Simple bass notes')),
                        SizedBox(width: 8),
                        Expanded(child: _HandHint(dotColor: Color(0xFF4D96FF), title: 'Right Hand (Melody)', subtitle: 'Main melody')),
                      ],
                    ),
                  ],
                  if (_mode == _PianoMode.practice) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFFFF9E8), borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF6A400)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Practice: ${_selectedSong.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                Text(_practiceFeedback, style: const TextStyle(fontSize: 12)),
                                Text(
                                  _isPracticeComplete ? 'Song complete!' : 'Note ${_practiceIndex + 1} / ${_practiceMelody.length}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (_isPracticeComplete)
                            TextButton(onPressed: _startPractice, child: const Text('Restart Practice ⭐')),
                        ],
                      ),
                    ),
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
                            rightHandHighlightedNotesListenable: _demoRightNotes,
                            leftHandHighlightedNotesListenable: _demoLeftNotes,
                            highlightedNotes: _mode == _PianoMode.practice ? _practiceTargetNotes.value : const {},
                            highlightedNotesListenable: _mode == _PianoMode.practice ? _practiceTargetNotes : _pressedNotes,
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


class _RotateToLandscapePrompt extends StatelessWidget {
  const _RotateToLandscapePrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const Spacer(),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6))],
              ),
              child: const Icon(Icons.screen_rotation_alt_rounded, size: 62, color: Color(0xFF4D96FF)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Rotate your iPhone',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF34344A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Two Octave Piano works best in landscape. Turn your phone sideways to play with bigger keys.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35, color: Color(0xFF56637A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFFFF6DA), borderRadius: BorderRadius.circular(14)),
              child: const Text('🎹 Big keys feel better in landscape!', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF7A5A00))),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _HandHint extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String subtitle;
  const _HandHint({required this.dotColor, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF5A6472))),
            ],
          ),
        ),
      ],
    );
  }
}
