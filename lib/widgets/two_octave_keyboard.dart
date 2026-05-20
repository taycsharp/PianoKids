import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef TwoOctaveKeyPressChanged = void Function(String note, int pressId);

typedef _HighlightedKeysWidgetBuilder = Widget Function(
  BuildContext context,
  Set<String> activeHighlights,
);

class TwoOctaveKeyboard extends StatelessWidget {
  final ValueListenable<Set<String>>? highlightedNotesListenable;
  final Set<String> highlightedNotes;
  final TwoOctaveKeyPressChanged onKeyPressStarted;
  final TwoOctaveKeyPressChanged onKeyPressStopped;

  static const List<String> _bottomWhite = ['C3', 'D3', 'E3', 'F3', 'G3', 'A3', 'B3', 'C4'];
  static const List<String> _topWhite = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5'];
  static const Map<String, double> _blackBoundaryPositions = {'C#': 1, 'D#': 2, 'F#': 4, 'G#': 5, 'A#': 6};

  const TwoOctaveKeyboard({
    super.key,
    required this.onKeyPressStarted,
    required this.onKeyPressStopped,
    this.highlightedNotesListenable,
    this.highlightedNotes = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _TwoOctaveRow(
            whiteNotes: _topWhite,
            blackBoundaryPositions: _blackBoundaryPositions,
            highlightedNotes: highlightedNotes,
            highlightedNotesListenable: highlightedNotesListenable,
            onKeyPressStarted: onKeyPressStarted,
            onKeyPressStopped: onKeyPressStopped,
            cKeySemanticSuffix: 'upper',
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _TwoOctaveRow(
            whiteNotes: _bottomWhite,
            blackBoundaryPositions: _blackBoundaryPositions,
            highlightedNotes: highlightedNotes,
            highlightedNotesListenable: highlightedNotesListenable,
            onKeyPressStarted: onKeyPressStarted,
            onKeyPressStopped: onKeyPressStopped,
            cKeySemanticSuffix: 'lower',
          ),
        ),
      ],
    );
  }
}

class _TwoOctaveRow extends StatelessWidget { /* omitted for brevity in cmd? */
  final List<String> whiteNotes;
  final Map<String, double> blackBoundaryPositions;
  final ValueListenable<Set<String>>? highlightedNotesListenable;
  final Set<String> highlightedNotes;
  final TwoOctaveKeyPressChanged onKeyPressStarted;
  final TwoOctaveKeyPressChanged onKeyPressStopped;
  final String cKeySemanticSuffix;

  const _TwoOctaveRow({required this.whiteNotes, required this.blackBoundaryPositions, required this.highlightedNotes, required this.highlightedNotesListenable, required this.onKeyPressStarted, required this.onKeyPressStopped, required this.cKeySemanticSuffix});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final keyWidth = constraints.maxWidth / whiteNotes.length;
      final blackKeyWidth = keyWidth * 0.58;
      final blackKeyHeight = constraints.maxHeight * 0.64;
      final octave = whiteNotes.first.substring(1);
      final framePadding = constraints.maxHeight < 180 ? 5.0 : 7.0;

      return Container(
        padding: EdgeInsets.all(framePadding),
        decoration: BoxDecoration(color: const Color(0xFF34344A), borderRadius: BorderRadius.circular(26)),
        child: _HighlightedKeysBuilder(
          highlightedNotes: highlightedNotes,
          highlightedNotesListenable: highlightedNotesListenable,
          builder: (context, activeHighlights) => Stack(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final note in whiteNotes)
                Expanded(child: _PianoWhiteKey(note: note, isHighlighted: activeHighlights.contains(note), onStart: (pressId) => onKeyPressStarted(note, pressId), onStop: (pressId) => onKeyPressStopped(note, pressId), keyValue: note == 'C4' ? ValueKey<String>('piano-key-C4-$cKeySemanticSuffix') : ValueKey<String>('piano-key-$note'))),
            ]),
            for (final entry in blackBoundaryPositions.entries)
              Positioned(left: entry.value * keyWidth - blackKeyWidth / 2, top: 0, width: blackKeyWidth, height: blackKeyHeight, child: _PianoBlackKey(note: '${entry.key}$octave', isHighlighted: activeHighlights.contains('${entry.key}$octave'), onStart: (pressId) => onKeyPressStarted('${entry.key}$octave', pressId), onStop: (pressId) => onKeyPressStopped('${entry.key}$octave', pressId))),
          ]),
        ),
      );
    });
  }
}

class _HighlightedKeysBuilder extends StatelessWidget {
  final Set<String> highlightedNotes;
  final ValueListenable<Set<String>>? highlightedNotesListenable;
  final _HighlightedKeysWidgetBuilder builder;
  const _HighlightedKeysBuilder({required this.highlightedNotes, required this.highlightedNotesListenable, required this.builder});
  @override
  Widget build(BuildContext context) {
    final listenable = highlightedNotesListenable;
    if (listenable == null) return builder(context, highlightedNotes);
    return ValueListenableBuilder<Set<String>>(valueListenable: listenable, builder: (context, activeHighlights, child) => builder(context, activeHighlights));
  }
}

class _PianoWhiteKey extends StatelessWidget {
  final String note; final bool isHighlighted; final ValueChanged<int> onStart; final ValueChanged<int> onStop; final ValueKey<String> keyValue;
  const _PianoWhiteKey({required this.note, required this.isHighlighted, required this.onStart, required this.onStop, required this.keyValue});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 1.5), child: _PressablePianoKey(key: keyValue, note: note, onStart: onStart, onStop: onStop, child: AnimatedContainer(duration: const Duration(milliseconds: 90), decoration: BoxDecoration(gradient: isHighlighted ? const LinearGradient(colors: [Color(0xFFFFF3B0), Color(0xFFFFD166)], begin: Alignment.topCenter, end: Alignment.bottomCenter) : const LinearGradient(colors: [Colors.white, Color(0xFFFFF8E8)], begin: Alignment.topCenter, end: Alignment.bottomCenter), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withValues(alpha: 0.16))), child: Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(note, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF34344A))))))));
}

class _PianoBlackKey extends StatelessWidget {
  final String note; final bool isHighlighted; final ValueChanged<int> onStart; final ValueChanged<int> onStop;
  const _PianoBlackKey({required this.note, required this.isHighlighted, required this.onStart, required this.onStop});
  @override
  Widget build(BuildContext context) => _PressablePianoKey(key: ValueKey<String>('piano-key-$note'), note: note, onStart: onStart, onStop: onStop, child: AnimatedContainer(duration: const Duration(milliseconds: 90), decoration: BoxDecoration(gradient: LinearGradient(colors: isHighlighted ? const [Color(0xFF8EECF5), Color(0xFF4D96FF)] : const [Color(0xFF222233), Color(0xFF050510)], begin: Alignment.topCenter, end: Alignment.bottomCenter), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14), top: Radius.circular(9)), border: Border.all(color: Colors.white.withValues(alpha: 0.16))), child: Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(note, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900))))));
}

class _PressablePianoKey extends StatefulWidget {
  final String note; final Widget child; final ValueChanged<int> onStart; final ValueChanged<int> onStop;
  const _PressablePianoKey({super.key, required this.note, required this.child, required this.onStart, required this.onStop});
  @override State<_PressablePianoKey> createState() => _PressablePianoKeyState();
}

class _PressablePianoKeyState extends State<_PressablePianoKey> {
  final Set<int> _activePointers = {}; int? _activePressId;
  void _handleDown(PointerDownEvent event) { final wasIdle = _activePointers.isEmpty; _activePointers.add(event.pointer); if (wasIdle) { _activePressId = event.pointer; widget.onStart(event.pointer);} }
  void _handleUpOrCancel(int pointer) { _activePointers.remove(pointer); if (_activePointers.isNotEmpty) return; final pressId = _activePressId; _activePressId = null; if (pressId != null) widget.onStop(pressId); }
  @override
  Widget build(BuildContext context) => Listener(onPointerDown: _handleDown, onPointerUp: (event) => _handleUpOrCancel(event.pointer), onPointerCancel: (event) => _handleUpOrCancel(event.pointer), behavior: HitTestBehavior.opaque, child: widget.child);
}
