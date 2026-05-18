import 'dart:async';

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
  static const bool _keyboardDebugLogs = false;
  static const Duration _messageUpdateInterval = Duration(milliseconds: 300);

  bool _showNames = true;
  bool _funMode = false;
  final Map<int, String> _activePresses = {};
  final ValueNotifier<Set<String>> _pressedNotes = ValueNotifier(const {});
  final ValueNotifier<String> _message = ValueNotifier('Play any note!');
  DateTime _lastMessageUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  final List<String> _sequence = [];
  final List<String> _rewardSequence = ['C', 'D', 'E'];

  void _startNote(String note, int pressId) {
    if (_keyboardDebugLogs) {
      final debugNote = _debugNoteName(note);
      debugPrint('Parent key down received: $pressId $debugNote');
    }

    final audio = context.read<AudioService>();
    if (_keyboardDebugLogs) {
      final debugNote = _debugNoteName(note);
      debugPrint('Parent calls playKeyboardNote before UI updates: $debugNote');
    }
    audio.playKeyboardNote(note);

    _activePresses[pressId] = note;
    if (_keyboardDebugLogs) {
      debugPrint('Parent active presses after down: ${_debugActivePresses()}');
    }

    _syncPressedNotesFromActivePresses();
    _updatePlayedMessage(note);

    if (_funMode) {
      _sequence.add(note);
      if (_sequence.length > _rewardSequence.length) _sequence.removeAt(0);
      if (_sequence.join(',') == _rewardSequence.join(',')) {
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 80), () async {
            await audio.playAnimalReward();
            if (mounted) _message.value = 'Animal reward! 🐶 ⭐';
          }),
        );
      }
    }
  }

  void _stopNote(String note, int pressId) {
    if (_keyboardDebugLogs) {
      final debugNote = _debugNoteName(note);
      debugPrint('Parent key up received: $pressId $debugNote');
    }

    _activePresses.remove(pressId);
    if (_keyboardDebugLogs) {
      debugPrint('Parent active presses after up: ${_debugActivePresses()}');
    }

    _syncPressedNotesFromActivePresses();
  }

  void _syncPressedNotesFromActivePresses() {
    _pressedNotes.value = Set<String>.unmodifiable(_activePresses.values);
  }

  void _updatePlayedMessage(String note) {
    final now = DateTime.now();
    if (now.difference(_lastMessageUpdate) < _messageUpdateInterval) return;

    _lastMessageUpdate = now;
    _message.value = 'You played $note!';
  }

  String _debugActivePresses() {
    final entries = _activePresses.entries
        .map((entry) => '${entry.key}: ${_debugNoteName(entry.value)}')
        .join(', ');
    return '{$entries}';
  }

  String _debugNoteName(String note) {
    if (note == 'High C') return 'C5';
    return '${note}4';
  }

  @override
  void dispose() {
    _pressedNotes.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Play Piano')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: _message,
                builder: (context, message, child) {
                  return StarReward(stars: 1, message: message);
                },
              ),
              const SizedBox(height: 18),
              SwitchListTile(
                value: _showNames,
                onChanged: (value) => setState(() => _showNames = value),
                title: const Text(
                  'Show note names',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                secondary: const Icon(Icons.abc),
              ),
              SwitchListTile(
                value: _funMode,
                onChanged: (value) => setState(() => _funMode = value),
                title: const Text(
                  'Fun reward mode',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text('Try C-D-E, then C♯-D♯!'),
                secondary: const Icon(Icons.pets),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: audio.keyboardCacheReadyListenable,
                  builder: (context, isKeyboardReady, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isKeyboardReady) ...[
                          const _LoadingPianoSoundsCard(),
                          const SizedBox(height: 10),
                        ],
                        RepaintBoundary(
                          child: AbsorbPointer(
                            absorbing: !isKeyboardReady,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: isKeyboardReady ? 1 : 0.55,
                              child: PianoKeyboard(
                                showNoteNames: _showNames,
                                highlightedNotesListenable: _pressedNotes,
                                onKeyPressStarted: _startNote,
                                onKeyPressStopped: _stopNote,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingPianoSoundsCard extends StatelessWidget {
  const _LoadingPianoSoundsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3B0),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading piano sounds…',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF34344A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
