import 'package:flutter/material.dart';

typedef PianoKeyPressChanged = void Function(String note, int pressId);

/// A beginner-friendly one-octave piano keyboard.
///
/// It shows the real visual relationship between:
/// - white keys: C D E F G A B High C
/// - black keys: C# D# F# G# A#
///
/// For early piano education, this is important because children should learn
/// that C is found just to the left of the group of two black keys.
class PianoKeyboard extends StatelessWidget {
  final bool showNoteNames;
  final ValueChanged<String>? onNotePressed;
  final ValueChanged<String>? onNoteStarted;
  final ValueChanged<String>? onNoteStopped;
  final PianoKeyPressChanged? onKeyPressStarted;
  final PianoKeyPressChanged? onKeyPressStopped;
  final String? highlightedNote;
  final Set<String> highlightedNotes;
  final ValueListenable<Set<String>>? highlightedNotesListenable;

  static const bool _keyboardDebugLogs = false;

  static const whiteNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'High C'];
  static const blackNotes = ['C#', 'D#', 'F#', 'G#', 'A#'];

  /// Black key positions are measured as boundaries between white keys.
  /// C# sits between C and D, D# between D and E, etc.
  static const Map<String, double> blackKeyBoundaryPositions = {
    'C#': 1,
    'D#': 2,
    'F#': 4,
    'G#': 5,
    'A#': 6,
  };

  const PianoKeyboard({
    super.key,
    this.onNotePressed,
    this.onNoteStarted,
    this.onNoteStopped,
    this.onKeyPressStarted,
    this.onKeyPressStopped,
    this.showNoteNames = true,
    this.highlightedNote,
    this.highlightedNotes = const {},
    this.highlightedNotesListenable,
  });

  static String displayName(String note) {
    if (note == 'High C') return 'C';
    return note.replaceAll('#', '♯');
  }

  bool _isHighlighted(String note, Set<String> activeHighlights) {
    return note == highlightedNote || activeHighlights.contains(note);
  }

  void _startNote(String note, int pressId) {
    onNotePressed?.call(note);
    onNoteStarted?.call(note);
    onKeyPressStarted?.call(note, pressId);
  }

  void _stopNote(String note, int pressId) {
    onNoteStopped?.call(note);
    onKeyPressStopped?.call(note, pressId);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyWidth = constraints.maxWidth / whiteNotes.length;
        final blackKeyWidth = keyWidth * 0.58;

        return Container(
          height: 220,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF34344A),
            borderRadius: BorderRadius.circular(26),
          ),
          child: _HighlightedKeysBuilder(
            highlightedNotes: highlightedNotes,
            highlightedNotesListenable: highlightedNotesListenable,
            builder: (context, activeHighlights) {
              return Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final note in whiteNotes)
                        Expanded(
                          child: _WhiteKey(
                            note: note,
                            showName: showNoteNames,
                            isHighlighted: _isHighlighted(
                              note,
                              activeHighlights,
                            ),
                            onStart: (pressId) => _startNote(note, pressId),
                            onStop: (pressId) => _stopNote(note, pressId),
                          ),
                        ),
                    ],
                  ),
                  for (final entry in blackKeyBoundaryPositions.entries)
                    Positioned(
                      left: entry.value * keyWidth - blackKeyWidth / 2,
                      top: 0,
                      width: blackKeyWidth,
                      height: 132,
                      child: _BlackKey(
                        note: entry.key,
                        showName: showNoteNames,
                        isHighlighted: _isHighlighted(
                          entry.key,
                          activeHighlights,
                        ),
                        onStart: (pressId) => _startNote(entry.key, pressId),
                        onStop: (pressId) => _stopNote(entry.key, pressId),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

typedef _HighlightedKeysWidgetBuilder = Widget Function(
  BuildContext context,
  Set<String> activeHighlights,
);

class _HighlightedKeysBuilder extends StatelessWidget {
  final Set<String> highlightedNotes;
  final ValueListenable<Set<String>>? highlightedNotesListenable;
  final _HighlightedKeysWidgetBuilder builder;

  const _HighlightedKeysBuilder({
    required this.highlightedNotes,
    required this.highlightedNotesListenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final listenable = highlightedNotesListenable;
    if (listenable == null) return builder(context, highlightedNotes);

    return ValueListenableBuilder<Set<String>>(
      valueListenable: listenable,
      builder: (context, activeHighlights, child) {
        return builder(context, activeHighlights);
      },
    );
  }
}

class _WhiteKey extends StatelessWidget {
  final String note;
  final bool showName;
  final bool isHighlighted;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onStop;

  const _WhiteKey({
    required this.note,
    required this.showName,
    required this.isHighlighted,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: _PressablePianoKey(
        note: note,
        onStart: onStart,
        onStop: onStop,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          decoration: BoxDecoration(
            gradient: isHighlighted
                ? const LinearGradient(
                    colors: [Color(0xFFFFF3B0), Color(0xFFFFD166)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFFFF8E8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isHighlighted ? 0.18 : 0.08),
                blurRadius: isHighlighted ? 12 : 5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                showName ? PianoKeyboard.displayName(note) : '🎈',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: note == 'High C' ? 16 : 19,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF34344A),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlackKey extends StatelessWidget {
  final String note;
  final bool showName;
  final bool isHighlighted;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onStop;

  const _BlackKey({
    required this.note,
    required this.showName,
    required this.isHighlighted,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return _PressablePianoKey(
      note: note,
      onStart: onStart,
      onStop: onStop,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isHighlighted
                ? const [Color(0xFF8EECF5), Color(0xFF4D96FF)]
                : const [Color(0xFF222233), Color(0xFF050510)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(14),
            top: Radius.circular(9),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              showName ? PianoKeyboard.displayName(note) : '⭐',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PressablePianoKey extends StatefulWidget {
  final String note;
  final Widget child;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onStop;

  const _PressablePianoKey({
    required this.note,
    required this.child,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<_PressablePianoKey> createState() => _PressablePianoKeyState();
}

class _PressablePianoKeyState extends State<_PressablePianoKey> {
  final Set<int> _activePointers = {};
  int? _activePressId;

  void _handleDown(PointerDownEvent event) {
    final wasIdle = _activePointers.isEmpty;
    _activePointers.add(event.pointer);
    if (wasIdle) {
      _activePressId = event.pointer;
      if (PianoKeyboard._keyboardDebugLogs) {
        final debugNote = _debugNoteName(widget.note);
        final pointerDownMs = DateTime.now().millisecondsSinceEpoch;
        debugPrint(
          'Pointer down $debugNote at ${pointerDownMs}ms pointer=${event.pointer}',
        );
      }
      widget.onStart(event.pointer);
    } else {
      if (PianoKeyboard._keyboardDebugLogs) {
        final debugNote = _debugNoteName(widget.note);
        debugPrint(
          'Pointer down skipped: ${event.pointer} $debugNote is already held by another pointer',
        );
      }
    }
  }

  void _handleEnd(int pointer) {
    if (!_activePointers.remove(pointer)) {
      if (PianoKeyboard._keyboardDebugLogs) {
        final debugNote = _debugNoteName(widget.note);
        debugPrint('Pointer up skipped: $pointer $debugNote was not active');
      }
      return;
    }
    if (_activePointers.isEmpty) {
      final pressId = _activePressId;
      _activePressId = null;
      if (pressId == null) {
        if (PianoKeyboard._keyboardDebugLogs) {
          final debugNote = _debugNoteName(widget.note);
          debugPrint(
            'Pointer up skipped: $pointer $debugNote had no active press id',
          );
        }
        return;
      }
      if (PianoKeyboard._keyboardDebugLogs) {
        final debugNote = _debugNoteName(widget.note);
        debugPrint('Pointer up $debugNote highlight removed');
      }
      widget.onStop(pressId);
    }
  }

  @override
  void dispose() {
    final pressId = _activePressId;
    if (_activePointers.isNotEmpty && pressId != null) widget.onStop(pressId);
    super.dispose();
  }

  String _debugNoteName(String note) {
    if (note == 'High C') return 'C5';
    return '${note}4';
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handleDown,
      onPointerUp: (event) => _handleEnd(event.pointer),
      onPointerCancel: (event) => _handleEnd(event.pointer),
      child: Semantics(
        button: true,
        label: '${PianoKeyboard.displayName(widget.note)} piano key',
        child: widget.child,
      ),
    );
  }
}
