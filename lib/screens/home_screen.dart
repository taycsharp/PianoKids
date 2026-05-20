import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import 'learning_path_screen.dart';
import 'parent_zone_screen.dart';
import 'piano_screen.dart';
import 'two_octave_piano_screen.dart';
import 'progress_screen.dart';
import 'rhythm_game_screen.dart';
import 'songs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Happy Piano Kids')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            AppCard(
              title: 'Learning Path',
              subtitle: 'Follow lessons step by step',
              emoji: '🚀',
              colors: const [AppTheme.pink, AppTheme.purple],
              onTap: () => _go(context, const LearningPathScreen()),
            ),
            const SizedBox(height: 14),
            AppCard(
              title: 'Play Piano',
              subtitle: 'Tap piano keys',
              emoji: '🎹',
              colors: const [AppTheme.blue, AppTheme.green],
              onTap: () => _go(context, const PianoScreen()),
            ),
            const SizedBox(height: 14),
            AppCard(
              title: 'Two Octave Piano',
              subtitle: 'Play two rows',
              emoji: '🎼',
              colors: const [AppTheme.blue, AppTheme.purple],
              onTap: () => _go(context, const TwoOctavePianoScreen()),
            ),
            const SizedBox(height: 14),
            AppCard(
              title: 'Song Practice',
              subtitle: 'Practice easy songs',
              emoji: '🎵',
              colors: const [AppTheme.orange, AppTheme.yellow],
              onTap: () => _go(context, const SongsScreen()),
            ),
            const SizedBox(height: 14),
            AppCard(
              title: 'Rhythm Game',
              subtitle: 'Tap with the beat',
              emoji: '🥁',
              colors: const [AppTheme.purple, AppTheme.blue],
              onTap: () => _go(context, const RhythmGameScreen()),
            ),
            AppCard(
              title: 'Progress',
              subtitle: 'Stars and badges',
              emoji: '🏆',
              colors: const [AppTheme.yellow, AppTheme.pink],
              onTap: () => _go(context, const ProgressScreen()),
            ),
            const SizedBox(height: 14),
            AppCard(
              title: 'Parent Zone',
              subtitle: 'Tips and summary',
              emoji: '👨‍👩‍👧',
              colors: const [Color(0xFF607D8B), Color(0xFF90A4AE)],
              onTap: () => _go(context, const ParentZoneScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
