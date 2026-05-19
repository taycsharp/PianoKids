import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef PianoKeyPressChanged = void Function(String note, int pressId);

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
  final double height;

  static const bool _keyboardDebugLogs = false;

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
    this.height = 320,
  });

  static String displayName(String note) => note.replaceAll('#', '♯');
  static String noteNameWithoutOctave(String note) =>
      note.replaceAll(RegExp(r'\d'), '').replaceAll('#', '♯');

  bool _isHighlighted(String note, Set<String> activeHighlights) =>
      note == highlightedNote || activeHighlights.contains(note);

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
    const rows = [
      _KeyboardRowSpec(octave: 3, first: 'C3', last: 'C4', c4KeyId: 'C4-lower'),
      _KeyboardRowSpec(octave: 4, first: 'C4', last: 'C5', c4KeyId: 'C4-upper'),
    ];

    return _HighlightedKeysBuilder(
      highlightedNotes: highlightedNotes,
      highlightedNotesListenable: highlightedNotesListenable,
      builder: (context, activeHighlights) {
        final isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final rowHeight = (isLandscape ? height * 0.45 : height * 0.5)
            .clamp(120.0, 180.0)
            .toDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              _PianoOctaveRow(
                row: rows[i],
                rowHeight: rowHeight,
                showNoteNames: showNoteNames,
                activeHighlights: activeHighlights,
                isHighlighted: _isHighlighted,
                onStart: _startNote,
                onStop: _stopNote,
              ),
              if (i == 0) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _KeyboardRowSpec {
  final int octave;
  final String first;
  final String last;
  final String c4KeyId;

  const _KeyboardRowSpec({
    required this.octave,
    required this.first,
    required this.last,
    required this.c4KeyId,
  });
}

class _PianoOctaveRow extends StatelessWidget {
  final _KeyboardRowSpec row;
  final double rowHeight;
  final bool showNoteNames;
  final Set<String> activeHighlights;
  final bool Function(String note, Set<String> activeHighlights) isHighlighted;
  final void Function(String note, int pressId) onStart;
  final void Function(String note, int pressId) onStop;

  static const _whiteNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const _blackOffsetsByWhiteIndex = {0: 'C#', 1: 'D#', 3: 'F#', 4: 'G#', 5: 'A#'};

  const _PianoOctaveRow({
    required this.row,
    required this.rowHeight,
    required this.showNoteNames,
    required this.activeHighlights,
    required this.isHighlighted,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isLandscape =
          MediaQuery.orientationOf(context) == Orientation.landscape;
      const totalWhiteKeys = 8;
      const minWhiteKeyWidth = 52.0;
      final canFit = constraints.maxWidth >= totalWhiteKeys * minWhiteKeyWidth;
      final whiteKeyWidth = canFit
          ? constraints.maxWidth / totalWhiteKeys
          : (isLandscape ? 68.0 : minWhiteKeyWidth);
      final rowWidth = canFit ? constraints.maxWidth : whiteKeyWidth * totalWhiteKeys;
      final blackKeyWidth = whiteKeyWidth * 0.58;
      final blackKeyHeight = rowHeight * 0.6;

      final whiteNotes = [
        for (final note in _whiteNotes) '$note${row.octave}',
        row.last,
      ];

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: rowWidth,
          height: rowHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF34344A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final note in whiteNotes)
                    SizedBox(
                      width: whiteKeyWidth,
                      child: _WhiteKey(
                        note: note,
                        keyId: note == 'C4' ? row.c4KeyId : note,
                        showName: showNoteNames,
                        isHighlighted: isHighlighted(note, activeHighlights),
                        onStart: (pressId) => onStart(note, pressId),
                        onStop: (pressId) => onStop(note, pressId),
                      ),
                    ),
                ],
              ),
              for (final entry in _blackOffsetsByWhiteIndex.entries)
                Positioned(
                  left: (entry.key + 1) * whiteKeyWidth - blackKeyWidth / 2,
                  top: 0,
                  width: blackKeyWidth,
                  height: blackKeyHeight,
                  child: _BlackKey(
                    note: '${entry.value}${row.octave}',
                    showName: showNoteNames,
                    isHighlighted: isHighlighted(
                      '${entry.value}${row.octave}',
                      activeHighlights,
                    ),
                    onStart: (pressId) => onStart('${entry.value}${row.octave}', pressId),
                    onStop: (pressId) => onStop('${entry.value}${row.octave}', pressId),
                  ),
                ),
            ],
          ),
        ),
      );
    });
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
  final String keyId;
  final bool showName;
  final bool isHighlighted;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onStop;

  const _WhiteKey({
    required this.note,
    required this.keyId,
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
        keyId: keyId,
        onStart: onStart,
        onStop: onStop,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          decoration: BoxDecoration(
            gradient: isHighlighted
                ? const LinearGradient(colors: [Color(0xFFFFF3B0), Color(0xFFFFD166)])
                : const LinearGradient(colors: [Colors.white, Color(0xFFFFF8E8)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.16)),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                showName ? PianoKeyboard.noteNameWithoutOctave(note) : '🎈',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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

  const _BlackKey({required this.note, required this.showName, required this.isHighlighted, required this.onStart, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return _PressablePianoKey(
      note: note,
      keyId: note,
      onStart: onStart,
      onStop: onStop,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isHighlighted ? const [Color(0xFF8EECF5), Color(0xFF4D96FF)] : const [Color(0xFF222233), Color(0xFF050510)],
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14), top: Radius.circular(9)),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              showName ? PianoKeyboard.noteNameWithoutOctave(note) : '⭐',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

class _PressablePianoKey extends StatefulWidget {
  final String note;
  final String keyId;
  final Widget child;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onStop;

  const _PressablePianoKey({required this.note, required this.keyId, required this.child, required this.onStart, required this.onStop});

  @override
  State<_PressablePianoKey> createState() => _PressablePianoKeyState();
}

class _PressablePianoKeyState extends State<_PressablePianoKey> {
  final Set<int> _activePointers = {};
  int? _activePressId;
  void _handleDown(PointerDownEvent event) { final wasIdle = _activePointers.isEmpty; _activePointers.add(event.pointer); if (wasIdle) { _activePressId = event.pointer; widget.onStart(event.pointer);} }
  void _handleEnd(int pointer) { if (!_activePointers.remove(pointer)) return; if (_activePointers.isEmpty) { final pressId = _activePressId; _activePressId = null; if (pressId != null) widget.onStop(pressId); } }
  @override
  void dispose() { final pressId = _activePressId; if (_activePointers.isNotEmpty && pressId != null) widget.onStop(pressId); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handleDown,
      onPointerUp: (event) => _handleEnd(event.pointer),
      onPointerCancel: (event) => _handleEnd(event.pointer),
      child: Semantics(button: true, label: 'piano-key-${widget.keyId}', child: widget.child),
    );
  }
}
