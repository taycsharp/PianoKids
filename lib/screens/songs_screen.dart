import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/song_data.dart';
import '../providers/progress_provider.dart';
import '../services/audio_service.dart';
import '../widgets/song_card.dart';
import 'song_practice_screen.dart';

class SongsScreen extends StatelessWidget {
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Songs')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('Choose a song!', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          for (final song in SongData.songs)
            SongCard(
              song: song,
              completed: progress.progress.completedSongIds.contains(song.id),
              onDemo: () => context.read<AudioService>().playSongDemo(song),
              onPractice: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SongPracticeScreen(song: song)),
              ),
            ),
        ],
      ),
    );
  }
}
