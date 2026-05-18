import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../providers/progress_provider.dart';
import '../services/audio_service.dart';
import '../widgets/keyboard_pattern_guide.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/primary_button.dart';
import '../widgets/star_reward.dart';
import 'rhythm_game_screen.dart';
import 'songs_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  final int lessonIndex;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.lessonIndex,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  int _currentTargetIndex = 0;
  int _mistakes = 0;
  String _feedback = 'Tap the note!';
  bool _completed = false;
  final Set<String> _pressedNotes = {};

  String? get _targetNote {
    if (widget.lesson.requiredNotes.isEmpty) return null;
    if (_currentTargetIndex >= widget.lesson.requiredNotes.length) return null;
    return widget.lesson.requiredNotes[_currentTargetIndex];
  }

  Future<void> _onNoteStarted(String note) async {
    final audio = context.read<AudioService>();
    setState(() => _pressedNotes.add(note));
    await audio.startNote(note);

    final target = _targetNote;
    if (target == null) return;

    if (note == target) {
      await audio.playSuccess();
      if (_currentTargetIndex == widget.lesson.requiredNotes.length - 1) {
        await _completeLesson();
      } else {
        setState(() {
          _currentTargetIndex++;
          _feedback = 'Great! Now tap ${_displayNote(widget.lesson.requiredNotes[_currentTargetIndex])}';
        });
      }
    } else {
      setState(() {
        _mistakes++;
        _feedback = 'Almost! Try ${_displayNote(target)}';
      });
    }
  }

  Future<void> _onNoteStopped(String note) async {
    setState(() => _pressedNotes.remove(note));
    await context.read<AudioService>().stopNote(note);
  }

  String _displayNote(String note) => PianoKeyboard.displayName(note);

  String get _guideTitle {
    switch (widget.lesson.id) {
      case 'lesson_1':
        return 'White keys are the big keys';
      case 'lesson_2':
        return 'Black keys come in 2 and 3';
      case 'lesson_3':
        return 'C is left of two black keys';
      case 'lesson_4':
        return 'F starts near three black keys';
      case 'lesson_5':
        return 'Black keys have sharp names';
      default:
        return 'Look at the keyboard pattern';
    }
  }

  String get _guideMessage {
    switch (widget.lesson.id) {
      case 'lesson_1':
        return 'Tap the white keys first. They are easier for small hands.';
      case 'lesson_2':
        return 'The black keys are shorter. First find the pair: C♯ and D♯.';
      case 'lesson_3':
        return 'Every C is just before a group of two black keys. This is the most important map trick.';
      case 'lesson_4':
        return 'F is just before a group of three black keys. Then comes G, A, and B.';
      case 'lesson_5':
        return 'A sharp note is the black key just to the right of a white note.';
      default:
        return 'White and black keys work together to make melodies.';
    }
  }

  Future<void> _completeLesson() async {
    if (_completed) return;
    final stars = _mistakes == 0 ? 3 : _mistakes <= 2 ? 2 : 1;

    await context.read<ProgressProvider>().completeLesson(widget.lesson.id, stars);
    if (!mounted) return;
    setState(() {
      _completed = true;
      _feedback = 'Amazing!';
    });
  }

  Future<void> _playInstruction() async {
    final target = _targetNote;
    if (target != null) {
      await context.read<AudioService>().playNote(target);
    } else {
      await context.read<AudioService>().playTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetNote;

    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Text(widget.lesson.icon, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 8),
                  Text(widget.lesson.title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(widget.lesson.description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(text: target == null ? 'Hear sound' : 'Hear ${_displayNote(target)}', icon: Icons.volume_up, onPressed: _playInstruction),
            const SizedBox(height: 18),
            if (widget.lesson.taskType != LessonTaskType.rhythm && widget.lesson.taskType != LessonTaskType.song) ...[
              KeyboardPatternGuide(title: _guideTitle, message: _guideMessage),
              const SizedBox(height: 18),
            ],
            if (widget.lesson.taskType == LessonTaskType.rhythm)
              PrimaryButton(
                text: 'Open Rhythm Game',
                icon: Icons.touch_app,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RhythmGameScreen())),
              )
            else if (widget.lesson.taskType == LessonTaskType.song)
              PrimaryButton(
                text: 'Open Songs',
                icon: Icons.music_note,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SongsScreen())),
              )
            else ...[
              Text(
                _completed
                    ? 'You completed this lesson!'
                    : target == null
                        ? 'Explore the piano!'
                        : _feedback == 'Tap the note!'
                            ? 'Tap ${_displayNote(target)}'
                            : _feedback,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              PianoKeyboard(
                showNoteNames: true,
                highlightedNotes: _pressedNotes,
                onNoteStarted: _onNoteStarted,
                onNoteStopped: _onNoteStopped,
              ),
            ],
            const SizedBox(height: 18),
            if (_completed)
              Column(
                children: [
                  StarReward(
                    stars: context.read<ProgressProvider>().starsForLesson(widget.lesson.id),
                    message: 'Great job!',
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Back to Learning Path',
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              )
            else
              PrimaryButton(
                text: 'Complete Lesson',
                icon: Icons.check_circle,
                onPressed: _completeLesson,
              ),
          ],
        ),
      ),
    );
  }
}
